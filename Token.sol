//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import './String.sol';

library Token {
    // @dev provides the token id based on the coordinates(longitude and latitude) of the property
    // @param a longitude string and a latitude string
    // @return returns the token id as a 32 bit object, otherwise it returns a 0 as a hex if the lat and lon are empty
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
    
    // @dev the opposite of the getTokenId, gives the lat and lon using tokenId
    // @param takes in a 32 bit tokenId object.
    // @return returns the latitude and longitude of a location
    function getGeoFromTokenId(bytes32 tokenId)
        public
        pure
        returns (
            string memory lat,
            string memory lon
        )
    {
        uint256 n = 32;
        while (n > 0 && tokenId[n-1] == 0) {
            n--;
        }
        bytes memory bytesArray = new bytes(n);
        for (uint256 i = 0; i < n; i++) {
            bytesArray[i] = tokenId[i];
        }
        string memory geoId = string(bytesArray);
        lat = getLat(geoId);
        lon = getLon(geoId);
    }
    
    // @dev gets the latitude of the token from a geoId
    // @param takes in a string of form "Lat,Lon" as a parameter
    // @return returns the str of the latitude
    function getLat(string memory str) public pure returns (string memory) {
        uint256 index = String.indexOfChar(str, byte(","), 0);
        return String.substring(str, 0, index);
    }

    // @dev gets the longitude of the token from a geoId
    // @param takes in a string of form "Lat,Lon" as a parameter
    // @return returns the str of the longitude
    function getLon(string memory str) public pure returns (string memory) {
        uint256 index = String.indexOfChar(str, byte(","), 0);
        return String.substring(str, index + 1, 0);
    }

}
