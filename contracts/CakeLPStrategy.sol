// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "./libraries/TransferHelper.sol";
import "./libraries/SafeMath.sol";
import "./modules/BaseShareField.sol";

interface ICollateralStrategy {
	function invest(address user, uint256 amount) external;

	function withdraw(address user, uint256 amount) external;

	function liquidation(address user) external;

	function claim(
		address user,
		uint256 amount,
		uint256 total
	) external;

	function exit(uint256 amount) external;

	function query() external view returns (uint256);

	function mint() external;

	function interestToken() external returns (address);

	function collateralToken() external returns (address);
}

interface IMasterChef {
	function deposit(uint256 _pid, uint256 _amount) external;

	function withdraw(uint256 _pid, uint256 _amount) external;

	function pendingCake(uint256 _pid, address _user) external view returns (uint256);

	function poolInfo(uint256 _index)
		external
		view
		returns (
			address,
			uint256,
			uint256,
			uint256
		);
}

contract CakeLPStrategy is ICollateralStrategy, BaseShareField {
	event Mint(address indexed user, uint256 amount);
	using SafeMath for uint256;
	address public override interestToken;
	address public override collateralToken;
	address public poolAddress;
	address public masterChef;
	uint256 public lpPoolpid;
	address public factory;

	constructor() public {
		factory = msg.sender;
	}

	function initialize(
		address _interestToken,
		address _collateralToken,
		address _poolAddress,
		address _cakeMasterChef,
		uint256 _lpPoolpid
	) public {
		require(msg.sender == factory, "STRATEGY FORBIDDEN");
		interestToken = _interestToken;
		collateralToken = _collateralToken;
		poolAddress = _poolAddress;
		masterChef = _cakeMasterChef;
		lpPoolpid = _lpPoolpid;
		_setShareToken(_interestToken);
	}

	function invest(address user, uint256 amount) external override {
		require(msg.sender == poolAddress, "INVALID CALLER");
		TransferHelper.safeTransferFrom(collateralToken, msg.sender, address(this), amount);
		IERC20(collateralToken).approve(masterChef, amount);
		IMasterChef(masterChef).deposit(lpPoolpid, amount);
		_increaseProductivity(user, amount);
	}

	function withdraw(address user, uint256 amount) external override {
		require(msg.sender == poolAddress, "INVALID CALLER");
		IMasterChef(masterChef).withdraw(lpPoolpid, amount);
		TransferHelper.safeTransfer(collateralToken, msg.sender, amount);
		_decreaseProductivity(user, amount);
	}

	function liquidation(address user) external override {
		require(msg.sender == poolAddress, "INVALID CALLER");
		uint256 amount = users[user].amount;
		_decreaseProductivity(user, amount);
		uint256 reward = users[user].rewardEarn;
		users[msg.sender].rewardEarn = users[msg.sender].rewardEarn.add(reward);
		users[user].rewardEarn = 0;
		_increaseProductivity(msg.sender, amount);
	}

	function claim(
		address user,
		uint256 amount,
		uint256 total
	) external override {
		require(msg.sender == poolAddress, "INVALID CALLER");
		IMasterChef(masterChef).withdraw(lpPoolpid, amount);
		TransferHelper.safeTransfer(collateralToken, msg.sender, amount);
		_decreaseProductivity(msg.sender, amount);
		uint256 claimAmount = users[msg.sender].rewardEarn.mul(amount).div(total);
		users[user].rewardEarn = users[user].rewardEarn.add(claimAmount);
		users[msg.sender].rewardEarn = users[msg.sender].rewardEarn.sub(claimAmount);
	}

	function exit(uint256 amount) external override {
		require(msg.sender == poolAddress, "INVALID CALLER");
		IMasterChef(masterChef).withdraw(lpPoolpid, amount);
		TransferHelper.safeTransfer(collateralToken, msg.sender, amount);
	}

	function _currentReward() internal view override returns (uint256) {
		return
			mintedShare
				.add(IERC20(shareToken).balanceOf(address(this)))
				.add(IMasterChef(masterChef).pendingCake(lpPoolpid, address(this)))
				.sub(totalShare);
	}

	function query() external view override returns (uint256) {
		return _takeWithAddress(msg.sender);
	}

	function mint() external override {
		IMasterChef(masterChef).deposit(lpPoolpid, 0);
		uint256 amount = _mint(msg.sender);
		emit Mint(msg.sender, amount);
	}
}
