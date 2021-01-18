// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "./libraries/SafeMath.sol";
import "./modules/Configable.sol";
import "./ONXToken.sol";

contract ONXAETH is ONXToken {
	string public name = "ONX aETH Token";
	string public symbol = "onxaETH";
}
