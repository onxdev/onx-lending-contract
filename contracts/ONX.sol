// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "./libraries/TransferHelper.sol";
import "./libraries/SafeMath.sol";
import "./modules/Configable.sol";
import "./modules/ConfigNames.sol";
import "./modules/BaseMintField.sol";

interface IONXMint {
	function take() external view returns (uint256);

	function mint() external returns (uint256);
}

contract ONXPool is Configable, BaseMintField {
	using SafeMath for uint256;

	address public supplyToken;
	address public collateralToken;

	struct SupplyStruct {
		uint256 amountSupply;
		uint256 interestSettled;
		uint256 liquidationSettled;
		uint256 interests;
		uint256 liquidation;
	}

	struct BorrowStruct {
		uint256 index;
		uint256 amountCollateral;
		uint256 interestSettled;
		uint256 amountBorrow;
		uint256 interests;
	}

	struct LiquidationStruct {
		uint256 amountCollateral;
		uint256 liquidationAmount;
		uint256 timestamp;
	}

	address[] public borrowerList;
	uint256 public numberBorrowers;

	mapping(address => SupplyStruct) public supplys;
	mapping(address => BorrowStruct) public borrows;
	mapping(address => LiquidationStruct[]) public liquidationHistory;
	mapping(address => uint256) public liquidationHistoryLength;

	uint256 public interestPerSupply;
	uint256 public liquidationPerSupply;
	uint256 public interestPerBorrow;

	uint256 public totalLiquidation;
	uint256 public totalLiquidationSupplyAmount;

	uint256 public totalStake;
	uint256 public totalBorrow;
	uint256 public totalPledge;

	uint256 public remainSupply;

	uint256 public lastInterestUpdate;

	event Deposit(address indexed _user, uint256 _amount, uint256 _collateralAmount);
	event Withdraw(address indexed _user, uint256 _supplyAmount, uint256 _collateralAmount, uint256 _interestAmount);
	event Borrow(address indexed _user, uint256 _supplyAmount, uint256 _collateralAmount);
	event Repay(address indexed _user, uint256 _supplyAmount, uint256 _collateralAmount, uint256 _interestAmount);
	event Liquidation(
		address indexed _liquidator,
		address indexed _user,
		uint256 _supplyAmount,
		uint256 _collateralAmount
	);
	event Reinvest(address indexed _user, uint256 _reinvestAmount);

	function init(address _supplyToken, address _collateralToken) external onlyOwner {
		supplyToken = _supplyToken;
		collateralToken = _collateralToken;

		lastInterestUpdate = block.number;
	}

	function updateInterests() internal {
		uint256 totalSupply = totalBorrow + remainSupply;
		uint256 interestPerBlock = getInterests();

		interestPerSupply = interestPerSupply.add(
			totalSupply == 0
				? 0
				: interestPerBlock.mul(block.number - lastInterestUpdate).mul(totalBorrow).div(totalSupply)
		);
		interestPerBorrow = interestPerBorrow.add(interestPerBlock.mul(block.number - lastInterestUpdate));
		lastInterestUpdate = block.number;
	}

	function getInterests() public view returns (uint256 interestPerBlock) {
		uint256 totalSupply = totalBorrow + remainSupply;
		uint256 baseInterests = IConfig(config).getPoolValue(ConfigNames.POOL_BASE_INTERESTS);
		uint256 marketFrenzy = IConfig(config).getPoolValue(ConfigNames.POOL_MARKET_FRENZY);
		uint256 aDay = IConfig(config).DAY();
		interestPerBlock = totalSupply == 0
			? 0
			: baseInterests.add(totalBorrow.mul(marketFrenzy).div(totalSupply)).div(365 * aDay);
	}

	function updateLiquidation(uint256 _liquidation) internal {
		uint256 totalSupply = totalBorrow + remainSupply;
		liquidationPerSupply = liquidationPerSupply.add(totalSupply == 0 ? 0 : _liquidation.mul(1e18).div(totalSupply));
	}

	function deposit(uint256 amountDeposit, address from) public onlyPlatform {
		require(amountDeposit > 0, "ONX: INVALID AMOUNT");
		uint256 amountIn = IERC20(supplyToken).balanceOf(address(this)).sub(remainSupply);
		require(amountIn >= amountDeposit, "ONX: INVALID AMOUNT");

		updateInterests();

		uint256 addLiquidation =
			liquidationPerSupply.mul(supplys[from].amountSupply).div(1e18).sub(supplys[from].liquidationSettled);

		supplys[from].interests = supplys[from].interests.add(
			interestPerSupply.mul(supplys[from].amountSupply).div(1e18).sub(supplys[from].interestSettled)
		);
		supplys[from].liquidation = supplys[from].liquidation.add(addLiquidation);

		supplys[from].amountSupply = supplys[from].amountSupply.add(amountDeposit);
		remainSupply = remainSupply.add(amountDeposit);

		totalStake = totalStake.add(amountDeposit);
		_mintToPool();
		_increaseLenderProductivity(from, amountDeposit);

		supplys[from].interestSettled = interestPerSupply.mul(supplys[from].amountSupply).div(1e18);
		supplys[from].liquidationSettled = liquidationPerSupply.mul(supplys[from].amountSupply).div(1e18);
		emit Deposit(from, amountDeposit, addLiquidation);
	}

	function reinvest(address from) public onlyPlatform returns (uint256 reinvestAmount) {
		updateInterests();

		uint256 addLiquidation =
			liquidationPerSupply.mul(supplys[from].amountSupply).div(1e18).sub(supplys[from].liquidationSettled);

		supplys[from].interests = supplys[from].interests.add(
			interestPerSupply.mul(supplys[from].amountSupply).div(1e18).sub(supplys[from].interestSettled)
		);
		supplys[from].liquidation = supplys[from].liquidation.add(addLiquidation);

		reinvestAmount = supplys[from].interests;

		uint256 platformShare =
			reinvestAmount.mul(IConfig(config).getValue(ConfigNames.INTEREST_PLATFORM_SHARE)).div(1e18);
		reinvestAmount = reinvestAmount.sub(platformShare);

		supplys[from].amountSupply = supplys[from].amountSupply.add(reinvestAmount);
		totalStake = totalStake.add(reinvestAmount);
		supplys[from].interests = 0;

		supplys[from].interestSettled = supplys[from].amountSupply == 0
			? 0
			: interestPerSupply.mul(supplys[from].amountSupply).div(1e18);
		supplys[from].liquidationSettled = supplys[from].amountSupply == 0
			? 0
			: liquidationPerSupply.mul(supplys[from].amountSupply).div(1e18);

		distributePlatformShare(platformShare);
		_mintToPool();
		if (reinvestAmount > 0) {
			_increaseLenderProductivity(from, reinvestAmount);
		}

		emit Reinvest(from, reinvestAmount);
	}

	function distributePlatformShare(uint256 platformShare) internal {
		require(platformShare <= remainSupply, "ONX: NOT ENOUGH PLATFORM SHARE");
		if (platformShare > 0) {
			uint256 buybackShare = IConfig(config).getValue(ConfigNames.INTEREST_BUYBACK_SHARE);
			uint256 buybackAmount = platformShare.mul(buybackShare).div(1e18);
			uint256 dividendAmount = platformShare.sub(buybackAmount);
			if (dividendAmount > 0) TransferHelper.safeTransfer(supplyToken, IConfig(config).share(), dividendAmount);
			if (buybackAmount > 0)
				TransferHelper.safeTransfer(supplyToken, IConfig(config).wallets(bytes32("team")), buybackAmount);
			remainSupply = remainSupply.sub(platformShare);
		}
	}

	function withdraw(uint256 amountWithdraw, address from)
		public
		onlyPlatform
		returns (uint256 withdrawSupplyAmount, uint256 withdrawLiquidation)
	{
		require(amountWithdraw > 0, "ONX: INVALID AMOUNT");
		require(amountWithdraw <= supplys[from].amountSupply, "ONX: NOT ENOUGH BALANCE");

		updateInterests();

		uint256 addLiquidation =
			liquidationPerSupply.mul(supplys[from].amountSupply).div(1e18).sub(supplys[from].liquidationSettled);

		supplys[from].interests = supplys[from].interests.add(
			interestPerSupply.mul(supplys[from].amountSupply).div(1e18).sub(supplys[from].interestSettled)
		);
		supplys[from].liquidation = supplys[from].liquidation.add(addLiquidation);

		withdrawLiquidation = supplys[from].liquidation.mul(amountWithdraw).div(supplys[from].amountSupply);
		uint256 withdrawInterest = supplys[from].interests.mul(amountWithdraw).div(supplys[from].amountSupply);

		uint256 platformShare =
			withdrawInterest.mul(IConfig(config).getValue(ConfigNames.INTEREST_PLATFORM_SHARE)).div(1e18);
		uint256 userShare = withdrawInterest.sub(platformShare);

		distributePlatformShare(platformShare);

		uint256 withdrawLiquidationSupplyAmount =
			totalLiquidation == 0 ? 0 : withdrawLiquidation.mul(totalLiquidationSupplyAmount).div(totalLiquidation);

		if (withdrawLiquidationSupplyAmount < amountWithdraw.add(userShare))
			withdrawSupplyAmount = amountWithdraw.add(userShare).sub(withdrawLiquidationSupplyAmount);

		require(withdrawSupplyAmount <= remainSupply, "ONX: NOT ENOUGH POOL BALANCE");
		require(withdrawLiquidation <= totalLiquidation, "ONX: NOT ENOUGH LIQUIDATION");

		remainSupply = remainSupply.sub(withdrawSupplyAmount);
		totalLiquidation = totalLiquidation.sub(withdrawLiquidation);
		totalLiquidationSupplyAmount = totalLiquidationSupplyAmount.sub(withdrawLiquidationSupplyAmount);
		totalPledge = totalPledge.sub(withdrawLiquidation);

		supplys[from].interests = supplys[from].interests.sub(withdrawInterest);
		supplys[from].liquidation = supplys[from].liquidation.sub(withdrawLiquidation);
		supplys[from].amountSupply = supplys[from].amountSupply.sub(amountWithdraw);
		totalStake = totalStake.sub(amountWithdraw);

		supplys[from].interestSettled = supplys[from].amountSupply == 0
			? 0
			: interestPerSupply.mul(supplys[from].amountSupply).div(1e18);
		supplys[from].liquidationSettled = supplys[from].amountSupply == 0
			? 0
			: liquidationPerSupply.mul(supplys[from].amountSupply).div(1e18);

		_mintToPool();
		if (withdrawSupplyAmount > 0) {
			TransferHelper.safeTransfer(supplyToken, msg.sender, withdrawSupplyAmount);
		}

		_decreaseLenderProductivity(from, amountWithdraw);

		if (withdrawLiquidation > 0) {
			TransferHelper.safeTransfer(collateralToken, msg.sender, withdrawLiquidation);
		}

		emit Withdraw(from, withdrawSupplyAmount, withdrawLiquidation, withdrawInterest);
	}

	function borrow(
		uint256 amountCollateral,
		uint256 repayAmount,
		uint256 expectBorrow,
		address from
	) public onlyPlatform {
		uint256 amountIn = IERC20(collateralToken).balanceOf(address(this)).sub(totalPledge);

		require(amountIn == amountCollateral, "ONX: INVALID AMOUNT");

		// if(amountCollateral > 0) TransferHelper.safeTransferFrom(collateralToken, from, address(this), amountCollateral);

		updateInterests();

		uint256 pledgeRate = IConfig(config).getPoolValue(ConfigNames.POOL_PLEDGE_RATE);
		uint256 maxAmount =
			IConfig(config).convertTokenAmount(
				collateralToken,
				supplyToken,
				borrows[from].amountCollateral.add(amountCollateral)
			);

		uint256 maximumBorrow = maxAmount.mul(pledgeRate).div(1e18);
		// uint repayAmount = getRepayAmount(borrows[from].amountCollateral, from);

		require(repayAmount + expectBorrow <= maximumBorrow, "ONX: EXCEED MAX ALLOWED");
		require(expectBorrow <= remainSupply, "ONX: INVALID BORROW");

		totalBorrow = totalBorrow.add(expectBorrow);
		totalPledge = totalPledge.add(amountCollateral);
		remainSupply = remainSupply.sub(expectBorrow);

		if (borrows[from].index == 0) {
			borrowerList.push(from);
			borrows[from].index = borrowerList.length;
			numberBorrowers++;
		}

		borrows[from].interests = borrows[from].interests.add(
			interestPerBorrow.mul(borrows[from].amountBorrow).div(1e18).sub(borrows[from].interestSettled)
		);
		borrows[from].amountCollateral = borrows[from].amountCollateral.add(amountCollateral);
		borrows[from].amountBorrow = borrows[from].amountBorrow.add(expectBorrow);
		borrows[from].interestSettled = interestPerBorrow.mul(borrows[from].amountBorrow).div(1e18);

		_mintToPool();
		if (expectBorrow > 0) {
			TransferHelper.safeTransfer(supplyToken, msg.sender, expectBorrow);
			_increaseBorrowerProductivity(from, expectBorrow);
		}

		emit Borrow(from, expectBorrow, amountCollateral);
	}

	function repay(uint256 amountCollateral, address from)
		public
		onlyPlatform
		returns (uint256 repayAmount, uint256 repayInterest)
	{
		require(amountCollateral <= borrows[from].amountCollateral, "ONX: NOT ENOUGH COLLATERAL");
		require(amountCollateral > 0, "ONX: INVALID AMOUNT");

		uint256 amountIn = IERC20(supplyToken).balanceOf(address(this)).sub(remainSupply);

		updateInterests();

		borrows[from].interests = borrows[from].interests.add(
			interestPerBorrow.mul(borrows[from].amountBorrow).div(1e18).sub(borrows[from].interestSettled)
		);

		repayAmount = borrows[from].amountBorrow.mul(amountCollateral).div(borrows[from].amountCollateral);
		repayInterest = borrows[from].interests.mul(amountCollateral).div(borrows[from].amountCollateral);

		totalPledge = totalPledge.sub(amountCollateral);
		totalBorrow = totalBorrow.sub(repayAmount);

		borrows[from].amountCollateral = borrows[from].amountCollateral.sub(amountCollateral);
		borrows[from].amountBorrow = borrows[from].amountBorrow.sub(repayAmount);
		borrows[from].interests = borrows[from].interests.sub(repayInterest);
		borrows[from].interestSettled = borrows[from].amountBorrow == 0
			? 0
			: interestPerBorrow.mul(borrows[from].amountBorrow).div(1e18);

		remainSupply = remainSupply.add(repayAmount.add(repayInterest));

		TransferHelper.safeTransfer(collateralToken, msg.sender, amountCollateral);
		require(amountIn >= repayAmount.add(repayInterest), "ONX: INVALID AMOUNT");
		// TransferHelper.safeTransferFrom(supplyToken, from, address(this), repayAmount.add(repayInterest));

		_mintToPool();
		if (repayAmount > 0) {
			_decreaseBorrowerProductivity(from, repayAmount);
		}

		emit Repay(from, repayAmount, amountCollateral, repayInterest);
	}

	function liquidation(address _user, address from) public onlyPlatform returns (uint256 borrowAmount) {
		require(supplys[from].amountSupply > 0, "ONX: ONLY SUPPLIER");

		updateInterests();

		borrows[_user].interests = borrows[_user].interests.add(
			interestPerBorrow.mul(borrows[_user].amountBorrow).div(1e18).sub(borrows[_user].interestSettled)
		);

		uint256 liquidationRate = IConfig(config).getPoolValue(ConfigNames.POOL_LIQUIDATION_RATE);

		// uint pledgePrice = IConfig(config).getPoolValue(address(this), ConfigNames.POOL_PRICE);
		// uint collateralValue = borrows[_user].amountCollateral.mul(pledgePrice).div(1e18);
		uint256 collateralValue =
			IConfig(config).convertTokenAmount(collateralToken, supplyToken, borrows[_user].amountCollateral);

		uint256 expectedRepay = borrows[_user].amountBorrow.add(borrows[_user].interests);

		require(expectedRepay >= collateralValue.mul(liquidationRate).div(1e18), "ONX: NOT LIQUIDABLE");

		updateLiquidation(borrows[_user].amountCollateral);

		totalLiquidation = totalLiquidation.add(borrows[_user].amountCollateral);
		totalLiquidationSupplyAmount = totalLiquidationSupplyAmount.add(expectedRepay);
		totalBorrow = totalBorrow.sub(borrows[_user].amountBorrow);

		borrowAmount = borrows[_user].amountBorrow;

		LiquidationStruct memory liq;
		liq.amountCollateral = borrows[_user].amountCollateral;
		liq.liquidationAmount = expectedRepay;
		liq.timestamp = block.timestamp;

		liquidationHistory[_user].push(liq);
		liquidationHistoryLength[_user]++;

		emit Liquidation(from, _user, borrows[_user].amountBorrow, borrows[_user].amountCollateral);

		borrows[_user].amountCollateral = 0;
		borrows[_user].amountBorrow = 0;
		borrows[_user].interests = 0;
		borrows[_user].interestSettled = 0;

		_mintToPool();
		if (borrowAmount > 0) {
			_decreaseBorrowerProductivity(_user, borrowAmount);
		}
	}

	function getTotalAmount() external view returns (uint256) {
		return totalStake.add(totalBorrow);
	}

	function _mintToPool() internal {
		if (IONXMint(IConfig(config).mint()).take() > 0) {
			IONXMint(IConfig(config).mint()).mint();
		}
	}

	function mint() external {
		_mintToPool();
		_mintLender();
		_mintBorrower();
	}

	function _currentReward() internal view override returns (uint256) {
		uint256 remain = IONXMint(IConfig(config).mint()).take();
		return remain.add(mintedShare).add(IERC20(IConfig(config).token()).balanceOf(address(this))).sub(totalShare);
	}
}
