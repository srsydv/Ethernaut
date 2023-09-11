// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Privacy {
    // Slot 0 -> 1 byte
    bool public locked = true;
    // Slot 1 -> 32 bytes
    uint256 public ID = block.timestamp;
    // Slot 2 -> 8 bits
    uint8 private flattening = 10;
    // Slot 2 -> 8 bits
    uint8 private denomination = 255;
    // Slot 2 -> 16 bits
    uint16 private awkwardness = uint16(block.timestamp);
    // Slot 3, 4, 5, 6 -> 32 bytes each (At slot 3 size of array will store)
    bytes32[3] private data;

    constructor(bytes32[3] memory _data) {
        data = _data;
    }

    function unlock(bytes16 _key) public {
        require(_key == bytes16(data[2]));
        locked = false;
    }

    /*
    A bunch of super advanced solidity algorithms...

      ,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`
      .,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,
      *.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^         ,---/V\
      `*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.    ~|__(o.o)
      ^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'  UU  UU
  */
}
