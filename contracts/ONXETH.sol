// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "./libraries/SafeMath.sol";
import "./modules/Configable.sol";
import "./ONXToken.sol";

contract ONXETH is ONXToken {
	string public name = "ONX ETH Token";
	string public symbol = "onxETH";
}
