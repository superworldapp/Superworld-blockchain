//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

library SuperWorldEvent {
    /*
    THE EVENTS ARE EMBEDDED IN FUNCTIONS, AND ALWAYS LOG TO THE BLOCKCHAIN USING THE PARAMS SENT IN
    */
    
    // @dev logs and saves the params EventBuyToken to the blockchain on a block
    // @param takes in a buyId, the geolocation, the address of the buyer and the seller, the price bought at,
    //        the time bought, and id of the property bought.
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
    
    // @dev logs and saves the params of EventBuyTokenNearby, specified for buying a token nearby based on the area
    // @param takes in a buyer id, and the id of the token, as well as the geolocation, the address of buyer and seller,
    //        as well as the price of token and when the token was bought.
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
    
    // @dev lists the token on the blockchain and saves/logs the params of the token.
    // @param takes in the id of the list, the id of the buy, the geolocation, seller address, the price selling/sold at,
    //        whether it is up for a listing or not, when it was sold, and the tokenId.
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
    
    // @dev Listing/selling the token through the event, and logging it through the blockchain
    // @param the id of the list, the id of the buy, the tokenid, the geolocation and the address of the seller,
    //        the listed price, and whether it is listed or not, and when it was sold.
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
    
    // @dev getting approval on the "event" on the real estate purchase
    // @param address of the buyer, the coins spent on it, where the coins are going, and the data for the event.
    event EventReceiveApproval(
        address buyer,
        uint256 coins,
        address _coinAddress,
        bytes32 _data
    );
}