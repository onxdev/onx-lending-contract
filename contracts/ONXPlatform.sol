// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "./modules/Configable.sol";
import "./modules/ConfigNames.sol";
import "./libraries/SafeMath.sol";
import "./libraries/TransferHelper.sol";

interface IONXMint {
	function increaseProductivity(address user, uint256 value) external returns (bool);

	function decreaseProductivity(address user, uint256 value) external returns (bool);

	function getProductivity(address user) external view returns (uint256, uint256);
}

interface IWETH {
	function deposit() external payable;

	function withdraw(uint256) external;
}

interface IONXPool {
	function deposit(uint256 _amountDeposit, address _from) external;

	function withdraw(uint256 _amountWithdraw, address _from) external returns (uint256, uint256);

	function borrow(
		uint256 _amountCollateral,
		uint256 _repayAmount,
		uint256 _expectBorrow,
		address _from
	) external;

	function repay(uint256 _amountCollateral, address _from) external returns (uint256, uint256);

	function liquidation(address _user, address _from) external returns (uint256);

	function reinvest(address _from) external returns (uint256);

	function supplys(address user)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256,
			uint256
		);

	function borrows(address user)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256,
			uint256
		);

	function getTotalAmount() external view returns (uint256);

	function supplyToken() external view returns (address);

	function interestPerBorrow() external view returns (uint256);

	function interestPerSupply() external view returns (uint256);

	function lastInterestUpdate() external view returns (uint256);

	function getInterests() external view returns (uint256);

	function totalBorrow() external view returns (uint256);

	function remainSupply() external view returns (uint256);

	function liquidationPerSupply() external view returns (uint256);

	function totalLiquidationSupplyAmount() external view returns (uint256);

	function totalLiquidation() external view returns (uint256);
}

interface IStkrETH {
	function ratio() external view returns (uint256);
}

contract ONXPlatform is Configable {
	using SafeMath for uint256;
	uint256 private unlocked = 1;
	address public lendToken;
	address public collateralToken;
	address public pool;
	address public stkrEth;

	modifier lock() {
		require(unlocked == 1, "Locked");
		unlocked = 0;
		_;
		unlocked = 1;
	}

	modifier poolExist() {
		require(pool != address(0), "POOL NOT EXIST");
		_;
	}

	receive() external payable {}

	function initialize(
		address _pool,
		address _lendToken,
		address _collateralToken,
		address _strkEth
	) external onlyOwner {
		pool = _pool;
		lendToken = _lendToken;
		collateralToken = _collateralToken;
		stkrEth = _strkEth;
	}

	function deposit(uint256 _amountDeposit) external lock poolExist {
		require(IConfig(config).getValue(ConfigNames.DEPOSIT_ENABLE) == 1, "NOT ENABLE NOW");
		TransferHelper.safeTransferFrom(lendToken, msg.sender, pool, _amountDeposit);
		IONXPool(pool).deposit(_amountDeposit, msg.sender);
		_updateProdutivity();
	}

	function depositETH() external payable lock poolExist {
		require(lendToken == IConfig(config).WETH(), "INVALID WETH POOL");
		require(IConfig(config).getValue(ConfigNames.DEPOSIT_ENABLE) == 1, "NOT ENABLE NOW");
		IWETH(IConfig(config).WETH()).deposit{value: msg.value}();
		TransferHelper.safeTransfer(lendToken, pool, msg.value);
		IONXPool(pool).deposit(msg.value, msg.sender);
		_updateProdutivity();
	}

	function withdraw(uint256 _amountWithdraw) external lock poolExist {
		require(IConfig(config).getValue(ConfigNames.WITHDRAW_ENABLE) == 1, "NOT ENABLE NOW");
		(uint256 withdrawSupplyAmount, uint256 withdrawLiquidationAmount) =
			IONXPool(pool).withdraw(_amountWithdraw, msg.sender);
		if (withdrawSupplyAmount > 0) _innerTransfer(lendToken, msg.sender, withdrawSupplyAmount);
		if (withdrawLiquidationAmount > 0) _innerTransfer(collateralToken, msg.sender, withdrawLiquidationAmount);
		_updateProdutivity();
	}

	function borrow(uint256 _amountCollateral, uint256 _expectBorrow) external lock poolExist {
		require(IConfig(config).getValue(ConfigNames.BORROW_ENABLE) == 1, "NOT ENABLE NOW");
		if (_amountCollateral > 0) {
			TransferHelper.safeTransferFrom(collateralToken, msg.sender, pool, _amountCollateral);
		}

		(, uint256 borrowAmountCollateral, , , ) = IONXPool(pool).borrows(msg.sender);
		uint256 repayAmount = getRepayAmount(borrowAmountCollateral, msg.sender);
		IONXPool(pool).borrow(_amountCollateral, repayAmount, _expectBorrow, msg.sender);
		if (_expectBorrow > 0) _innerTransfer(lendToken, msg.sender, _expectBorrow);
		_updateProdutivity();
	}

	function borrowTokenWithETH(uint256 _expectBorrow) external payable lock poolExist {
		require(collateralToken == IConfig(config).WETH(), "INVALID WETH POOL");
		require(IConfig(config).getValue(ConfigNames.BORROW_ENABLE) == 1, "NOT ENABLE NOW");
		if (msg.value > 0) {
			IWETH(IConfig(config).WETH()).deposit{value: msg.value}();
			TransferHelper.safeTransfer(collateralToken, pool, msg.value);
		}

		(, uint256 borrowAmountCollateral, , , ) = IONXPool(pool).borrows(msg.sender);
		uint256 repayAmount = getRepayAmount(borrowAmountCollateral, msg.sender);
		IONXPool(pool).borrow(msg.value, repayAmount, _expectBorrow, msg.sender);
		if (_expectBorrow > 0) _innerTransfer(lendToken, msg.sender, _expectBorrow);
		_updateProdutivity();
	}

	function repay(uint256 _amountCollateral) external lock poolExist {
		require(IConfig(config).getValue(ConfigNames.REPAY_ENABLE) == 1, "NOT ENABLE NOW");
		uint256 repayAmount = getRepayAmount(_amountCollateral, msg.sender);
		if (repayAmount > 0) {
			TransferHelper.safeTransferFrom(lendToken, msg.sender, pool, repayAmount);
		}

		IONXPool(pool).repay(_amountCollateral, msg.sender);
		_innerTransfer(collateralToken, msg.sender, _amountCollateral);
		_updateProdutivity();
	}

	function repayETH(uint256 _amountCollateral) external payable lock poolExist {
		require(IConfig(config).getValue(ConfigNames.REPAY_ENABLE) == 1, "NOT ENABLE NOW");
		require(lendToken == IConfig(config).WETH(), "INVALID WETH POOL");
		uint256 repayAmount = getRepayAmount(_amountCollateral, msg.sender);
		require(repayAmount <= msg.value, "INVALID VALUE");
		if (repayAmount > 0) {
			IWETH(IConfig(config).WETH()).deposit{value: repayAmount}();
			TransferHelper.safeTransfer(lendToken, pool, repayAmount);
		}

		IONXPool(pool).repay(_amountCollateral, msg.sender);
		_innerTransfer(collateralToken, msg.sender, _amountCollateral);
		if (msg.value > repayAmount) TransferHelper.safeTransferETH(msg.sender, msg.value.sub(repayAmount));
		_updateProdutivity();
	}

	function liquidation(address _user) external lock poolExist {
		require(IConfig(config).getValue(ConfigNames.LIQUIDATION_ENABLE) == 1, "NOT ENABLE NOW");
		IONXPool(pool).liquidation(_user, msg.sender);
		_updateProdutivity();
	}

	function reinvest() external lock {
		require(IConfig(config).getValue(ConfigNames.REINVEST_ENABLE) == 1, "NOT ENABLE NOW");
		IONXPool(pool).reinvest(msg.sender);
		_updateProdutivity();
	}

	function _innerTransfer(
		address _token,
		address _to,
		uint256 _amount
	) internal {
		if (_token == IConfig(config).WETH()) {
			IWETH(_token).withdraw(_amount);
			TransferHelper.safeTransferETH(_to, _amount);
		} else {
			TransferHelper.safeTransfer(_token, _to, _amount);
		}
	}

	function _updateProdutivity() internal {
		uint256 power = IConfig(config).getPoolValue(ConfigNames.POOL_MINT_POWER);
		uint256 amount = IONXPool(pool).getTotalAmount().mul(power).div(10000);
		(uint256 old, ) = IONXMint(IConfig(config).mint()).getProductivity(pool);
		if (old > 0) {
			IONXMint(IConfig(config).mint()).decreaseProductivity(pool, old);
		}

		address token = IONXPool(pool).supplyToken();
		uint256 baseAmount = IConfig(config).convertTokenAmount(token, IConfig(config).base(), amount);
		if (baseAmount > 0) {
			IONXMint(IConfig(config).mint()).increaseProductivity(pool, baseAmount);
		}
	}

	function getRepayAmount(uint256 amountCollateral, address from) public view returns (uint256 repayAmount) {
		(, uint256 borrowAmountCollateral, uint256 interestSettled, uint256 amountBorrow, uint256 borrowInterests) =
			IONXPool(pool).borrows(from);
		uint256 _interestPerBorrow =
			IONXPool(pool).interestPerBorrow().add(
				IONXPool(pool).getInterests().mul(block.number - IONXPool(pool).lastInterestUpdate())
			);
		uint256 _totalInterest =
			borrowInterests.add(_interestPerBorrow.mul(amountBorrow).div(1e18).sub(interestSettled));
		uint256 repayInterest =
			borrowAmountCollateral == 0 ? 0 : _totalInterest.mul(amountCollateral).div(borrowAmountCollateral);
		repayAmount = borrowAmountCollateral == 0
			? 0
			: amountBorrow.mul(amountCollateral).div(borrowAmountCollateral).add(repayInterest);
	}

	function getMaximumBorrowAmount(uint256 amountCollateral) external view returns (uint256 amountBorrow) {
		uint256 pledgeAmount = IConfig(config).convertTokenAmount(collateralToken, lendToken, amountCollateral);
		uint256 pledgeRate = IConfig(config).getPoolValue(ConfigNames.POOL_PLEDGE_RATE);
		amountBorrow = pledgeAmount.mul(pledgeRate).div(1e18);
	}

	function getLiquidationAmount(address from) public view returns (uint256 liquidationAmount) {
		(uint256 amountSupply, , uint256 liquidationSettled, , uint256 supplyLiquidation) =
			IONXPool(pool).supplys(from);
		liquidationAmount = supplyLiquidation.add(
			IONXPool(pool).liquidationPerSupply().mul(amountSupply).div(1e18).sub(liquidationSettled)
		);
	}

	function getInterestAmount(address from) public view returns (uint256 interestAmount) {
		uint256 totalBorrow = IONXPool(pool).totalBorrow();
		uint256 totalSupply = totalBorrow + IONXPool(pool).remainSupply();
		(uint256 amountSupply, uint256 interestSettled, , uint256 interests, ) = IONXPool(pool).supplys(from);
		uint256 _interestPerSupply =
			IONXPool(pool).interestPerSupply().add(
				totalSupply == 0
					? 0
					: IONXPool(pool)
						.getInterests()
						.mul(block.number - IONXPool(pool).lastInterestUpdate())
						.mul(totalBorrow)
						.div(totalSupply)
			);
		interestAmount = interests.add(_interestPerSupply.mul(amountSupply).div(1e18).sub(interestSettled));
	}

	function getWithdrawAmount(address from)
		external
		view
		returns (
			uint256 withdrawAmount,
			uint256 interestAmount,
			uint256 liquidationAmount
		)
	{
		uint256 _totalInterest = getInterestAmount(from);
		liquidationAmount = getLiquidationAmount(from);
		uint256 platformShare =
			_totalInterest.mul(IConfig(config).getValue(ConfigNames.INTEREST_PLATFORM_SHARE)).div(1e18);
		interestAmount = _totalInterest.sub(platformShare);
		uint256 totalLiquidation = IONXPool(pool).totalLiquidation();
		uint256 withdrawLiquidationSupplyAmount =
			totalLiquidation == 0
				? 0
				: liquidationAmount.mul(IONXPool(pool).totalLiquidationSupplyAmount()).div(totalLiquidation);
		(uint256 amountSupply, , , , ) = IONXPool(pool).supplys(from);
		if (withdrawLiquidationSupplyAmount > amountSupply.add(interestAmount)) withdrawAmount = 0;
		else withdrawAmount = amountSupply.add(interestAmount).sub(withdrawLiquidationSupplyAmount);
	}

	function updatePoolParameter(bytes32 _key, uint256 _value) external onlyDeveloper {
		IConfig(config).setPoolValue(_key, _value);
	}
}
