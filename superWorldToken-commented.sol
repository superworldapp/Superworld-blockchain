//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;   

// 0x0A7a9dd62Af0638DE94903235682d1630DF09Cf3 use for ropsten coin   rinkeby 0x47c393cb164A0D58Ac757d4615e72f62eC170fE8
// 10 percentage cut
// 1000000000000000 baseprice
// http://geo.superworldapp.com/api/json/metadata/get/ metaurl

import "https://github.com/kole-swapnil/openzepkole/token/ERC721/ERC721.sol";
import "https://github.com/kole-swapnil/openzepkole/access/Ownable.sol";

abstract contract ERC20Interface {
    //@dev: checks whether the transaction between the two addresses of the token went through
    //@params: takes in two addresses, and a single uint as a token number
    //@returns: returns a boolean, true is successful and false if not
    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public virtual returns (bool success);

    //@dev: checks the balance of the inputted address
    //@params: the address you are checking the balance of
    //@returns: returns the balance as a uint
    function balanceOf(address tokenOwner)
        public
        virtual
        view
        returns (uint256 balance); //"constant" deprecated at 0.5.0
}

//super world token contract inherits ERC721 and ownable contracts
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

    //@dev 
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
    //@dev: creates a base price that has to be greater than zero for the token
    //@params: takes in a uint that represents the baseprice you want.
    //@returns: no return, mutators
    function setBasePrice(uint256 _basePrice) public onlyOwner() {
        require(_basePrice > 0);
        basePrice = _basePrice;
    }
    //@dev: sets the percentage cut of the token for the contract variable
    //@params: takes in a uint representing the percentageCut
    //@returns: no return, mutator
    function setPercentageCut(uint256 _percentageCut) public onlyOwner() {
        require(_percentageCut > 0);
        percentageCut = _percentageCut;
    }
    
    //@dev: generates a new token, using recordTransactions directly below, private method
    //@parmas: takes in a buyer address, the id of the token, and the price of the token
    //@returns: returns nothing, creates a token 
    function createToken(
        address buyer,
        uint256 tokenId,
        uint256 price
    ) private {
        _mint(buyer, tokenId);
        recordTransaction(tokenId, price);
    }
    
    //@dev: used by createToken, adds to the array at the token id spot, the price of the token based on its id
    //@params: takes the token's id and the price of the tokenId
    //@return: returns nothing
    function recordTransaction(uint256 tokenId, uint256 price) private {
        boughtPrices[tokenId] = price;
    }
    
    //@dev: provides the token id based on the coordinates(longitude and latitude) of the property
    //@params: a longitude string and a latitude string
    //@returns: returns the token id as a 32 bit object, otherwise it returns a 0 as a hex if the lat and lon are empty
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
    
    //@dev: the opposite of the getTokenId, gives the lat and lon using tokenId
    //@params: takes in a 32 bit tokenId object.
    //@returns: returns the latitude and longitude of a location
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
    
    //@dev: returns all info on the token using lat and lon
    //@params: takes in two strings, latitude and longitude.
    //@returns: the token id, the address of the token owner, if it is owned, if it is up for sale, and the price it is going for in ether
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
    //@dev: using lat and lon to transfer the token owner
    //@params: takes in a geo location(lat and lon), as well as an owner address and the price to buy at
    //@returns: returns nothing, but logs to the transaction logs of the even Buy Token
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
    //@dev: takes in the geolocation to relist the token on the market, buy selling the property
    //@params: takes in a geolocation and the price sold at
    //@returns: returns nothing, but logs to transactions using ListTokens event
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
    //@dev: get approval for the transaction to go through
    //@params: takes in a buyer address, a seller address, and the coins spending, as well as the data with the transaction?
    //@returns: returns nothing, emits a event receive approval obj, and logs it to transactions
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
    
    //@dev: Indicates the status of transfer (false if it didnt go through)
    //@params: takes in the buyer address, the coins spent,and the geolocation of the token
    //@returns: returns the status of the transfer of coins for the token
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
    
    //@dev: buy a token
    //@params: takes in a geolocation
    //@return: returns a boolean, whether the transfer was successful or not
    function buyToken(string memory lat, string memory lon)
        public
        payable
        returns (bool)
    {
        uint256 tokenId = uint256(getTokenId(lat, lon));
        uint256 offerPrice = msg.value;
        // address seller = address(0x0); // _tokenOwners[tokenId];

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

    //@dev: allows the processing of buying a token using event emitting
    //@params: takes in the token id, the geolocation, the address of the buyer and seller, the price of the offer and when it was bought.
    //@returns: returns nothing, but creates an event emitter that logs the buying of
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
  //@dev: list the token on the superworld market, for a certain price user wants to sell at
  //@params: takes in the geolocation of the token, and the price it is selling at
  //@returns: returns nothing, emits a ListToken event logging it to transactions.
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
    //@dev: take the token off the market
    //@params: requests the geolocation of the token
    //@returns: returns nothing, emits a List Token event
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
    //@dev: does the list token event, used by many previous functions
    //@params: takes in the buyerid, the geolocation, the seller address and price selling at, as well as whether it is listed or not, and when it sold
    //@returns: returns nothing, but emits the event List token to log to the transactions on the blockchain
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

    //@dev: provides the price for the tokenId
    //@params: takes in the tokenId as a uint parameter
    //@returns a uint of the price returned
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
    //@dev: trims the decimals to a certain substring and gives it back
    //@params: takes in the string, and trims based on the decimal integer
    //@returns: returns the substring based on the decimal values.
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
    //@dev: creates a smaller string based on the starting and ending indices; helper method
    //@params: takes in a string, and a starting and ending index of the string to cut it by.
    //@returns: returns a string
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
4w    }
    //@dev: gets the index of a certain character inside of a string; helper method
    //@params: requires a string, a certain character, and the index to start checking from
    //@returns: returns the index of the character in the string
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
    //@dev: gets the latitude of the token
    //@params: takes in a string as a parameter
    //@returns: returns the str of the latitude
    function getLat(string memory str) private pure returns (string memory) {
        uint256 index = indexOfChar(str, byte(","), 0);
        return substring(str, 0, index);
    }
    //@dev: gets the longitude of the token
    //@params: takes in a string as a parameter
    //@returns: returns the str of the longitude
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
    
    //@devs: withdraws a certain amount from the owner
    //@params: no params taken in
    //@returns: doesn't return anything, but transfers the balance from the message sender to the address intended.
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
