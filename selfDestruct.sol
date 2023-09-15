// SPDX-License-Identifier: MIT
    pragma solidity <0.7.0;
    
    contract selfDestruct {
        function explode() public {
            selfdestruct(address(0));
        }
    }
