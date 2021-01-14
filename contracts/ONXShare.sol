// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "./libraries/SafeMath.sol";
import "./libraries/TransferHelper.sol";
import "./modules/Configable.sol";
import "./modules/BaseShareField.sol";
import "./modules/ConfigNames.sol";

contract ONXShare is Configable, BaseShareField {
	mapping(address => uint256) public locks;
	event ProductivityIncreased(address indexed user, uint256 value);
	event ProductivityDecreased(address indexed user, uint256 value);
	event Mint(address indexed user, uint256 amount);

	function setShareToken(address _shareToken) external onlyDeveloper {
		shareToken = _shareToken;
	}

	function stake(uint256 _amount) external {
		TransferHelper.safeTransferFrom(IConfig(config).token(), msg.sender, address(this), _amount);
		_increaseProductivity(msg.sender, _amount);
		locks[msg.sender] = block.number;
		emit ProductivityIncreased(msg.sender, _amount);
	}

	function lockStake(address _user) external onlyGovernor {
		locks[_user] = block.number;
	}

	function withdraw(uint256 _amount) external {
		require(
			block.number > locks[msg.sender].add(IConfig(config).getValue(ConfigNames.STAKE_LOCK_TIME)),
			"STAKE LOCKED NOW"
		);
		_decreaseProductivity(msg.sender, _amount);
		TransferHelper.safeTransfer(IConfig(config).token(), msg.sender, _amount);
		emit ProductivityDecreased(msg.sender, _amount);
	}

	function queryReward() external view returns (uint256) {
		return _takeWithAddress(msg.sender);
	}

	function mintReward() external {
		uint256 amount = _mint(msg.sender);
		emit Mint(msg.sender, amount);
	}
}
