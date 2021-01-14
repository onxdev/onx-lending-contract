// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "./libraries/SafeMath.sol";
import "./modules/Configable.sol";

contract ONXToken is Configable {
	using SafeMath for uint256; // implementation of ERC20 interfaces.
	string public name = "ONX Token";
	string public symbol = "ONX";
	uint8 public decimals = 18;
	uint256 public totalSupply = 10240000 * (1e18);
	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	constructor() public {
		balanceOf[msg.sender] = totalSupply;
	}

	function _transfer(
		address from,
		address to,
		uint256 value
	) internal {
		require(balanceOf[from] >= value, "ONX: INSUFFICIENT_BALANCE");
		balanceOf[from] = balanceOf[from].sub(value);
		balanceOf[to] = balanceOf[to].add(value);
		if (to == address(0)) {
			// burn
			totalSupply = totalSupply.sub(value);
		}
		emit Transfer(from, to, value);
	}

	function approve(address spender, uint256 value) external returns (bool) {
		allowance[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
	}

	function transfer(address to, uint256 value) external returns (bool) {
		_transfer(msg.sender, to, value);
		return true;
	}

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool) {
		require(allowance[from][msg.sender] >= value, "ONX: INSUFFICIENT_ALLOWANCE");
		allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
		_transfer(from, to, value);
		return true;
	}
}
