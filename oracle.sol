pragma solidity ^0.4.22;
import "github.com/provable-things/ethereum-api/provableAPI_0.4.25.sol";

contract ExampleContract is usingProvable {

   string public lon;
   string public lat;
   string public x;
   event LogGeo(string lat,string lon);


   function ExampleContract() payable {
       
   }
   function substring(string memory str, uint startIndex, uint endIndex) pure private returns (string memory) {
  	bytes memory strBytes = bytes(str);
		if (endIndex == 0) {
			endIndex = strBytes.length;
		}
  	bytes memory result = new bytes(endIndex - startIndex);
  	for (uint i = startIndex; i < endIndex; i++) {
      result[i - startIndex] = strBytes[i];
    }
  	return string(result);
	}


	function indexOfComma(string memory str) pure private returns (uint) {
		bytes memory strBytes = bytes(str);
		uint length = strBytes.length;
		for (uint i = 0; i < length; i++) {
			if (strBytes[i] == ",") {
				return i;
			}
		}
		return 0;
	}

function getLat(string memory str) pure private returns (string memory) {
		uint index = indexOfComma(str);
		return substring(str, 0, index);
	}
function getLon(string memory str) pure private returns (string memory) {
		uint index = indexOfComma(str);
		return substring(str, index + 1, 0);
	}
   function __callback(bytes32 myid, string result) {
     
       lat =  getLat(result);
       lon =  getLon(result);
       emit LogGeo(lat,lon);
   }
	
   function getGeo(string a,string b) payable {
       if (provable_getPrice("URL") <= this.balance) {
           x = string(abi.encodePacked('json(http://geo.superworldapp.com/api/json/token/get?tokenId=',a,'&blockchain=e&networkId=',b,').data.geoId'));
           provable_query("URL", x );
          
       }
     
   }

}
