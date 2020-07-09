//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;   

// 0x0A7a9dd62Af0638DE94903235682d1630DF09Cf3 use for ropsten coin   rinkeby 0x47c393cb164A0D58Ac757d4615e72f62eC170fE8
// 10 percentage cut
// 1000000000000000 baseprice

import "https://github.com/kole-swapnil/openzepkole/token/ERC721/ERC721.sol";


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


contract SuperWorldToken is ERC721 {
    address public owner;
    address public coinAddress;
    ERC20Interface public superWorldCoin;

    uint256 public percentageCut;
    uint256 public basePrice;
    uint256 public buyId = 0;
    uint256 public listId = 0;

    // tokenId => base price in wei
    mapping(uint256 => uint256) public basePrices;

    // tokenId => bought price in wei
    mapping(uint256 => uint256) public boughtPrices;

    // tokenId => sell price in wei
    mapping(uint256 => uint256) public sellPrices;

    // tokenId => is selling
    mapping(uint256 => bool) public isSellings;
    // tokenId => buyId
    mapping(uint256 => uint256) public buyIds;

    // token history
    struct TokenHistory {
        uint256 tokenId;
        address owner;
        uint256 price;
    }
    // tokenId => token history array
    mapping(uint256 => TokenHistory[]) public tokenHistories;

    // events
    // TODO: add timestamp (block or UTC)
    event EventBuyToken(
        uint256 buyId,
        string lon,
        string lat,
        address indexed buyer,
        address indexed seller,
        uint256 price,
        uint256 timestamp
    );
    event EventBuyTokenFail(
        uint256 buyId,
        string lon,
        string lat,
        address indexed buyer,
        address indexed seller,
        uint256 price,
        uint256 timestamp
    );
    event EventBuyTokenId1(
        uint256 buyId,
        uint256 indexed tokenId1,
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
        uint256 timestamp
    );
    event EventListTokenId1(
        uint256 listId,
        uint256 buyId,
        uint256 indexed tokenId1,
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
        owner = msg.sender;
        coinAddress = _coinAddress;
        superWorldCoin = ERC20Interface(coinAddress);
        percentageCut = _percentageCut;
        basePrice = _basePrice;
        buyId = 0;
        listId = 0;
        _setBaseURI(metaUrl);
    }

    function setBasePrice(uint256 _basePrice) public {
        require(msg.sender == owner);
        require(_basePrice > 0);
        basePrice = _basePrice;
    }

    function setBasePrice(
        string memory lat,
        string memory lon,
        uint256 _basePrice
    ) public {
        require(msg.sender == owner);
        require(_basePrice > 0);
        uint256 tokenId = uint256(getTokenId(lat, lon));
        basePrices[tokenId] = _basePrice;
    }

    function setPercentageCut(uint256 _percentageCut) public {
        require(msg.sender == owner);
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
        tokenHistories[tokenId].push(TokenHistory(tokenId, msg.sender, price));
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
            uint256 tokenId,
            address tokenOwner,
            bool isOwned,
            bool isSelling,
            uint256 price
        )
    {
        tokenId = uint256(getTokenId(lat, lon));
        if (EnumerableMap.contains(_tokenOwners, tokenId)) {
            tokenOwner = EnumerableMap.get(_tokenOwners, tokenId);
            isOwned = true;
        } else {
            tokenOwner = address(0);
            isOwned = false;
        }
        isSelling = isSellings[tokenId];
        price = getPrice(tokenId);
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
        // address seller = EnumerableMap.get(_tokenOwners, tokenId);

        if (!EnumerableMap.contains(_tokenOwners, tokenId)) {
            // not owned
            require(coins >= basePrice);
            require(superWorldCoin.balanceOf(buyer) >= basePrice);
            if (!superWorldCoin.transferFrom(buyer, address(this), basePrice)) {
                return false;
            }
            createToken(buyer, tokenId, basePrice);
            EnumerableMap.set(_tokenOwners, tokenId, buyer);
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
        uint256 tokenId = uint256(getTokenId(lat, lon));
        uint256 offerPrice = msg.value;
        // address seller = address(0x0); // _tokenOwners[tokenId];

        // unique token not bought yet
        if (!EnumerableMap.contains(_tokenOwners, tokenId)) {
            require(offerPrice >= basePrice);
            require(offerPrice >= basePrices[tokenId]);
            createToken(msg.sender, tokenId, offerPrice);
            EnumerableMap.set(_tokenOwners, tokenId, msg.sender);
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

        address seller = EnumerableMap.get(_tokenOwners, tokenId);
        // check selling
        require(isSellings[tokenId] == true);
        // check sell price > 0
        require(sellPrices[tokenId] > 0);
        // check offer price >= sell price
        require(offerPrice >= sellPrices[tokenId]);

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
            emit EventBuyTokenFail(
                tokenId,
                lon,
                lat,
                msg.sender,
                seller,
                offerPrice,
                now
            );
            return false;
        }

        // transfer token
        //removeTokenFrom(seller, tokenId);
        //addTokenTo(msg.sender, tokenId);
        _holderTokens[seller].remove(tokenId);
        _holderTokens[msg.sender].add(tokenId);
        recordTransaction(tokenId, offerPrice);
        sellPrices[tokenId] = offerPrice;
        EnumerableMap.set(_tokenOwners, tokenId, msg.sender);
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
            timestamp
        );
        emit EventBuyTokenId1(
            buyId,
            uint256(getTokenId(truncateDecimals(lat, 1), truncateDecimals(lon, 1))),
            truncateDecimals(lon, 1),
            truncateDecimals(lat, 1),
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
        require(EnumerableMap.contains(_tokenOwners, tokenId));
        require(msg.sender == EnumerableMap.get(_tokenOwners, tokenId));
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
        require(EnumerableMap.contains(_tokenOwners, tokenId));
        require(msg.sender == EnumerableMap.get(_tokenOwners, tokenId));
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
        emit EventListToken(
            listId,
            _buyId,
            lon,
            lat,
            seller,
            sellPrice,
            isListed,
            timestamp
        );
        emit EventListTokenId1(
            listId,
            _buyId,
            uint256(getTokenId(truncateDecimals(lon, 1), truncateDecimals(lat, 1))),
            lon,
            lat,
            seller,
            sellPrice,
            isListed,
            timestamp
        );
    }

    function getPrice(uint256 tokenId) public view returns (uint256) {
        if (!EnumerableMap.contains(_tokenOwners, tokenId)) {
            // not owned
            uint256 _basePrice = basePrices[tokenId];
            if (_basePrice == 0) {
                return basePrice;
            } else {
                return _basePrice;
            }
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
        public
        pure
        returns (string memory)
    {
        bytes memory strBytes = bytes(str);
        uint256 length = strBytes.length;
        uint256 endIndex = length - 1;
        uint256 i;
        for (i = 0; i < length; i++) {
            if (strBytes[i] == ".") {
                endIndex = i;
            }
            if (i == endIndex + decimal + 1) {
                break;
            }
        }
        if (i >= length) {
            return str;
        }
        return substring(str, 0, i);
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

    function indexOfComma(string memory str) private pure returns (uint256) {
        bytes memory strBytes = bytes(str);
        uint256 length = strBytes.length;
        for (uint256 i = 0; i < length; i++) {
            if (strBytes[i] == ",") {
                return i;
            }
        }
        return 0;
    }

    function getLat(string memory str) private pure returns (string memory) {
        uint256 index = indexOfComma(str);
        return substring(str, 0, index);
    }

    function getLon(string memory str) private pure returns (string memory) {
        uint256 index = indexOfComma(str);
        return substring(str, index + 1, 0);
    }

    function bytesToString(bytes memory _dataBytes)
        private
        pure
        returns (string memory)
    {
        if (_dataBytes.length == 0) {
            return "";
        }

        bytes32 dataBytes32;

        assembly {
            dataBytes32 := mload(add(_dataBytes, 32))
        }
        return bytes32ToString(dataBytes32);
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
            bytes1 char = bytes1(bytes32(uint256(_dataBytes32) * 2**(8 * j)));
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

    function withdrawBalance() public payable {
        require(msg.sender == owner);
        uint256 balance = address(this).balance;
        (msg.sender).transfer(balance);
    }
    function tokenURI(uint256 tokenId) public view override returns (string memory){
       string memory x = string(abi.encodePacked('http://geo.superworldapp.com/api/json/token/get?tokenId=',tokenId,'&blockchain=e&networkId=4'));
       return x;
    }
}
