//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;   

// 0x0A7a9dd62Af0638DE94903235682d1630DF09Cf3 use for ropsten coin   rinkeby 0x80845b05179a5E720d6950679a631B71A45d4323
// 10 percentage cut
// 1000000000000000 baseprice
// http://geo.superworldapp.com/api/json/metadata/get/ metaurl

import "https://github.com/kole-swapnil/openzepkole/token/ERC721/ERC721.sol";
import "https://github.com/kole-swapnil/openzepkole/access/Ownable.sol";

abstract contract ERC20Interface {
    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public virtual returns (bool success);

    function balanceOf(address tokenOwner)
        public
        virtual
        view
        returns (uint256 balance); //"constant" deprecated at 0.5.0
}


contract SuperWorldToken is ERC721, Ownable {
    // address public owner;
    address public coinAddress;
    ERC20Interface public superWorldCoin;

    uint256 public percentageCut;
    uint256 public basePrice;
    uint256 public buyId = 0;
    uint256 public listId = 0;

    // tokenId => bought price in wei
    mapping(uint256 => uint256) public boughtPrices;

    // tokenId => sell price in wei
    mapping(uint256 => uint256) public sellPrices;

    // tokenId => is selling
    mapping(uint256 => bool) public isSellings;
    // tokenId => buyId
    mapping(uint256 => uint256) public buyIds;
    
    // events
    // TODO: add timestamp (block or UTC)
    event EventBuyToken(
        uint256 buyId,
        string lon,
        string lat,
        address indexed buyer,
        address indexed seller,
        uint256 price,
        uint256 timestamp,
        bytes32 indexed tokenId
    );
    event EventBuyTokenNearby(
        uint256 buyId,
        bytes32 indexed tokenId1,
        string lon,
        string lat,
        address buyer,
        address seller,
        uint256 price,
        uint256 timestamp
    );
    event EventListToken(
        uint256 listId,
        uint256 buyId,
        string lon,
        string lat,
        address indexed seller,
        uint256 price,
        bool isListed,
        uint256 timestamp,
        bytes32 indexed tokenId
    );
    event EventListTokenNearby(
        uint256 listId,
        uint256 buyId,
        bytes32 indexed tokenId1,
        string lon,
        string lat,
        address seller,
        uint256 price,
        bool isListed,
        uint256 timestamp
    );
    event EventReceiveApproval(
        address buyer,
        uint256 coins,
        address _coinAddress,
        bytes32 _data
    );

    constructor(
        address _coinAddress,
        uint256 _percentageCut,
        uint256 _basePrice,
        string memory metaUrl
    ) public ERC721("SuperWorld", "SUPERWORLD") {
        coinAddress = _coinAddress;
        superWorldCoin = ERC20Interface(coinAddress);
        percentageCut = _percentageCut;
        basePrice = _basePrice;
        buyId = 0;
        listId = 0;
        _setBaseURI(metaUrl);
    }
    
    function setBasePrice(uint256 _basePrice) public onlyOwner() {
        require(_basePrice > 0);
        basePrice = _basePrice;
    }

    function setPercentageCut(uint256 _percentageCut) public onlyOwner() {
        require(_percentageCut > 0);
        percentageCut = _percentageCut;
    }

    function createToken(
        address buyer,
        uint256 tokenId,
        uint256 price
    ) private {
        _mint(buyer, tokenId);
        recordTransaction(tokenId, price);
    }

    function recordTransaction(uint256 tokenId, uint256 price) private {
        boughtPrices[tokenId] = price;
    }

    function getTokenId(string memory lat, string memory lon)
        public
        pure
        returns (bytes32 tokenId)
    {
        if (bytes(lat).length == 0 || bytes(lon).length == 0) {
            return 0x0;
        }
        
        string memory geo = string(abi.encodePacked(lat, ",", lon));
        assembly {
            tokenId := mload(add(geo, 32))
        }
    }
    
    function getGeoFromTokenId(bytes32 tokenId)
        public
        pure
        returns (
            string memory lat,
            string memory lon
        )
    {
        uint8 n = 32;
        while (n > 0 && tokenId[n-1] == 0) {
            n--;
        }
        bytes memory bytesArray = new bytes(n);
        for (uint8 i = 0; i < n; i++) {
            bytesArray[i] = tokenId[i];
        }
        string memory geoId = string(bytesArray);
        lat = getLat(geoId);
        lon = getLon(geoId);
    }

    function getInfo(string memory lat, string memory lon)
        public
        view
        returns (
            bytes32 tokenId,
            address tokenOwner,
            bool isOwned,
            bool isSelling,
            uint256 price
        )
    {
        tokenId = getTokenId(lat, lon);
        uint256 intTokenId = uint256(tokenId);
        if (_tokenOwners.contains(intTokenId)) {
            tokenOwner = _tokenOwners.get(intTokenId);
            isOwned = true;
        } else {
            tokenOwner = address(0);
            isOwned = false;
        }
        isSelling = isSellings[intTokenId];
        price = getPrice(intTokenId);
    }
    
    // Bulk transfer
    function giftToken(
        string calldata lat,
        string calldata lon,
        address tokenOwner,
        uint256 buyPrice
    ) external onlyOwner() {
        uint256 tokenId = uint256(getTokenId(lat, lon));
        createToken(tokenOwner, tokenId, buyPrice);
        emitBuyTokenEvents(
            tokenId,
            lon,
            lat,
            tokenOwner,
            address(0),
            buyPrice,
            now
        );
    }
    
    // Bulk listing
    function relistToken(
        string calldata lat,
        string calldata lon,
        uint256 sellPrice
    ) external onlyOwner() {
        uint256 tokenId = uint256(getTokenId(lat, lon));
        require(_tokenOwners.contains(tokenId));
        
        isSellings[tokenId] = true;
        sellPrices[tokenId] = sellPrice;
        emitListTokenEvents(
            buyIds[tokenId],
            lon,
            lat,
            _tokenOwners.get(tokenId),
            sellPrice,
            true,
            now
        );
    }
    
    function receiveApproval(
        address buyer,
        uint256 coins,
        address _coinAddress,
        bytes32 _data
    ) public {
        emit EventReceiveApproval(buyer, coins, _coinAddress, _data);
        require(_coinAddress == coinAddress);
        string memory dataString = bytes32ToString(_data);
        buyTokenWithCoins(buyer, coins, getLat(dataString), getLon(dataString));
    }

    function buyTokenWithCoins(
        address buyer,
        uint256 coins,
        string memory lat,
        string memory lon
    ) public returns (bool) {
        uint256 tokenId = uint256(getTokenId(lat, lon));
        // address seller = _tokenOwners.get(tokenId);

        if (!_tokenOwners.contains(tokenId)) {
            // not owned
            require(coins >= basePrice);
            require(superWorldCoin.balanceOf(buyer) >= basePrice);
            if (!superWorldCoin.transferFrom(buyer, address(this), basePrice)) {
                return false;
            }
            createToken(buyer, tokenId, basePrice);
            _tokenOwners.set(tokenId, buyer);
            emitBuyTokenEvents(
                tokenId,
                lon,
                lat,
                buyer,
                address(0),
                basePrice,
                now
            );
            return true;
        }

        return false;
    }

    function buyToken(string memory lat, string memory lon)
        public
        payable
        returns (bool)
    {
        uint256 offerPrice = msg.value;
        // address seller = address(0x0); // _tokenOwners[tokenId];
        return _buyToken(lat, lon, offerPrice);
    }
    
    function _buyToken(string memory lat, string memory lon, uint256 offerPrice)
        private
        returns (bool)
    {
        uint256 tokenId = uint256(getTokenId(lat, lon));
        
        // unique token not bought yet
        if (!_tokenOwners.contains(tokenId)) {
            require(offerPrice >= basePrice);
            createToken(msg.sender, tokenId, offerPrice);
            _tokenOwners.set(tokenId, msg.sender);
            emitBuyTokenEvents(
                tokenId,
                lon,
                lat,
                msg.sender,
                address(0),
                offerPrice,
                now
            );
            return true;
        }

        address seller = _tokenOwners.get(tokenId);
        // check selling
        require(isSellings[tokenId] == true);
        // check sell price > 0
        require(sellPrices[tokenId] > 0);
        // check offer price >= sell price
        require(offerPrice >= sellPrices[tokenId]);
        // check seller != buyer
        require(msg.sender != seller);

        // send percentage of cut to contract owner
        uint256 fee = SafeMath.div(
            SafeMath.mul(offerPrice, percentageCut),
            100
        );
        uint256 priceAfterFee = SafeMath.sub(offerPrice, fee);

        // mark not selling
        isSellings[tokenId] = false;

        // send payment
        address payable _seller = payable(seller);
        if (!_seller.send(priceAfterFee)) {
            // if failed to send, mark selling
            isSellings[tokenId] = true;
            return false;
        }

        // transfer token
        //removeTokenFrom(seller, tokenId);
        //addTokenTo(msg.sender, tokenId);
        _holderTokens[seller].remove(tokenId);
        _holderTokens[msg.sender].add(tokenId);
        recordTransaction(tokenId, offerPrice);
        sellPrices[tokenId] = offerPrice;
        _tokenOwners.set(tokenId, msg.sender);
        emitBuyTokenEvents(
            tokenId,
            lon,
            lat,
            msg.sender,
            seller,
            offerPrice,
            now
        );
        return true;
    }
    
    function bulkBuy(
        string memory lat1, string memory lon1,
        string memory lat2, string memory lon2,
        string memory lat3, string memory lon3,
        string memory lat4, string memory lon4,
        string memory lat5, string memory lon5
    )
        public
        payable
        returns (bool)
    {
        string[5] memory lat = [lat1, lat2, lat3, lat4, lat5];
        string[5] memory lon = [lon1, lon2, lon3, lon4, lon5];
        uint256 n = 0;
        for (; n < 5; n++) {
            if (bytes(lat[n]).length == 0 || bytes(lon[n]).length == 0) {
                break;
            }
        }
        
        uint256 offerPrice = msg.value;
        uint256[5] memory prices;
        for (uint256 i = 0; i < n; i++) {
            uint256 tokenId = uint256(getTokenId(lat[i], lon[i]));
            prices[i] = basePrice;
            if (EnumerableMap.contains(_tokenOwners, tokenId)) {
                require(isSellings[tokenId]);
                prices[i] = sellPrices[tokenId];
            }
        }
        
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < n; i++) {
            totalPrice = SafeMath.add(totalPrice, prices[i]);
        }
        require(offerPrice >= totalPrice);
        for (uint256 i = 0; i < n; i++) {
            _buyToken(lat[i], lon[i], prices[i]);
        }
        return true;
    }

    function emitBuyTokenEvents(
        uint256 tokenId,
        string memory lon,
        string memory lat,
        address buyer,
        address seller,
        uint256 offerPrice,
        uint256 timestamp
    ) private {
        buyId++;
        buyIds[tokenId] = buyId;
        emit EventBuyToken(
            buyId,
            lon,
            lat,
            buyer,
            seller,
            offerPrice,
            timestamp,
            bytes32(tokenId)
        );
        emit EventBuyTokenNearby(
            buyId,
            getTokenId(truncateDecimals(lat, 1), truncateDecimals(lon, 1)),
            lon,
            lat,
            buyer,
            seller,
            offerPrice,
            timestamp
        );
    }

    // list / delist

    function listToken(
        string memory lat,
        string memory lon,
        uint256 sellPrice
    ) public {
        uint256 tokenId = uint256(getTokenId(lat, lon));
        require(_tokenOwners.contains(tokenId));
        require(msg.sender == _tokenOwners.get(tokenId));
        isSellings[tokenId] = true;
        sellPrices[tokenId] = sellPrice;
        emitListTokenEvents(
            buyIds[tokenId],
            lon,
            lat,
            msg.sender,
            sellPrice,
            true,
            now
        );
    }

    function delistToken(string memory lat, string memory lon) public {
        uint256 tokenId = uint256(getTokenId(lat, lon));
        require(_tokenOwners.contains(tokenId));
        require(msg.sender == _tokenOwners.get(tokenId));
        isSellings[tokenId] = false;
        emitListTokenEvents(
            buyIds[tokenId],
            lon,
            lat,
            msg.sender,
            sellPrices[tokenId],
            false,
            now
        );
        sellPrices[tokenId] = 0;
    }

    function emitListTokenEvents(
        uint256 _buyId,
        string memory lon,
        string memory lat,
        address seller,
        uint256 sellPrice,
        bool isListed,
        uint256 timestamp
    ) private {
        listId++;
        bytes32 tokenId = getTokenId(lat, lon);
        emit EventListToken(
            listId,
            _buyId,
            lon,
            lat,
            seller,
            sellPrice,
            isListed,
            timestamp,
            tokenId
        );
        emit EventListTokenNearby(
            listId,
            _buyId,
            getTokenId(truncateDecimals(lat, 1), truncateDecimals(lon, 1)),
            lon,
            lat,
            seller,
            sellPrice,
            isListed,
            timestamp
        );
    }

    function getPrice(uint256 tokenId) public view returns (uint256) {
        if (!_tokenOwners.contains(tokenId)) {
            // not owned
            return basePrice;
        } else {
            // owned
            if (isSellings[tokenId]) {
                return sellPrices[tokenId];
            } else {
                return boughtPrices[tokenId];
            }
        }
    }
    
    function truncateDecimals(string memory str, uint256 decimal)
        internal
        pure
        returns (string memory)
    {
        uint256 decimalIndex = indexOfChar(str, byte("."), 0);
        bytes memory strBytes = bytes(str);
        uint256 length = strBytes.length;
        return (decimalIndex + decimal + 1 > length) ? substring(str, 0, length) : substring(str, 0, decimalIndex + decimal + 1);
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (endIndex == 0) {
            endIndex = strBytes.length;
        }
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function indexOfChar(string memory str, byte char, uint256 startIndex) private pure returns (uint256) {
        bytes memory strBytes = bytes(str);
        uint256 length = strBytes.length;
        for (uint256 i = startIndex; i < length; i++) {
            if (strBytes[i] == char) {
                return i;
            }
        }
        return 0;
    }

    function getLat(string memory str) private pure returns (string memory) {
        uint256 index = indexOfChar(str, byte(","), 0);
        return substring(str, 0, index);
    }

    function getLon(string memory str) private pure returns (string memory) {
        uint256 index = indexOfChar(str, byte(","), 0);
        return substring(str, index + 1, 0);
    }

    function bytes32ToString(bytes32 _dataBytes32)
        private
        pure
        returns (string memory)
    {
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;
        uint256 j;
        for (j = 0; j < 32; j++) {
            //outscope declaration
            byte char = byte(bytes32(uint256(_dataBytes32) * 2**(8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function withdrawBalance() public payable onlyOwner() {
        uint256 balance = address(this).balance;
        (msg.sender).transfer(balance);
    }
    
    function toHexString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 16;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            uint256 digit = temp % 16;
            if (digit < 10) {
                buffer[index--] = byte(uint8(48 + digit));
            } else {
                buffer[index--] = byte(uint8(87 + digit));
            }
            temp /= 16;
        }
        return string(buffer);
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory x = string(abi.encodePacked('http://geo.superworldapp.com/api/json/metadata/get/', '0x', toHexString(tokenId)));
        return x;
    }
}
