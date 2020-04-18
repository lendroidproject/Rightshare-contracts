pragma solidity 0.5.11;

library Strings {
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
      bytes memory ba = bytes(a);
      bytes memory bb = bytes(b);
      bytes memory bc = bytes(c);
      bytes memory bd = bytes(d);
      bytes memory be = bytes(e);
      string memory abcde = new string(ba.length + bb.length + bc.length + bd.length + be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < ba.length; i++) babcde[k++] = ba[i];
      for (uint i = 0; i < bb.length; i++) babcde[k++] = bb[i];
      for (uint i = 0; i < bc.length; i++) babcde[k++] = bc[i];
      for (uint i = 0; i < bd.length; i++) babcde[k++] = bd[i];
      for (uint i = 0; i < be.length; i++) babcde[k++] = be[i];
      return string(babcde);
    }

    function strConcat(string memory a, string memory b, string memory c, string memory d) internal pure returns (string memory) {
        return strConcat(a, b, c, d, "");
    }

    function strConcat(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return strConcat(a, b, c, "", "");
    }

    function strConcat(string memory a, string memory b) internal pure returns (string memory) {
        return strConcat(a, b, "", "", "");
    }

    function uint2str(uint i) internal pure returns (string memory _uintAsString) {
        if (i == 0) {
            return "0";
        }
        uint j = i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0) {
            bstr[k--] = byte(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }

    function bool2str(bool b) internal pure returns (string memory _boolAsString) {
        _boolAsString = b ? "1" : "0";
    }

    function address2str(address addr) internal pure returns (string memory addressAsString) {
        bytes32 _bytes = bytes32(uint256(addr));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for(uint i = 0; i < 20; i++) {
            _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        addressAsString = string(_string);
    }
}
