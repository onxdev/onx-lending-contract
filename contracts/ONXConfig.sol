// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
import "./libraries/SafeMath.sol";
import "./modules/ConfigNames.sol";

interface IERC20 {
	function balanceOf(address owner) external view returns (uint256);

	function decimals() external view returns (uint8);
}

interface IONXPool {
	function collateralToken() external view returns (address);
}

contract ONXConfig {
	using SafeMath for uint256;
	using SafeMath for uint8;
	address public owner;
	address public poo;
	address public platform;
	address public developer;
	address public mint;
	address public token;
	address public share;
	address public base;
	address public governor;
	address public WETH;
	uint256 public lastPriceBlock;
	uint256 public DAY = 6400;
	uint256 public HOUR = 267;
	struct ConfigItem {
		uint256 min;
		uint256 max;
		uint256 span;
		uint256 value;
	}

	mapping(bytes32 => ConfigItem) public poolParams;
	mapping(bytes32 => ConfigItem) public params;
	mapping(bytes32 => address) public wallets;
	mapping(address => uint256) public prices;
	event PriceChange(address token, uint256 value);
	event ParameterChange(bytes32 key, uint256 value);
	event PoolParameterChange(bytes32 key, uint256 value);

	constructor() public {
		owner = msg.sender;
		developer = msg.sender;
		uint256 id;
		assembly {
			id := chainid()
		}
		if (id != 1) {
			DAY = 28800;
			HOUR = 1200;
		}
	}

	function initialize(
		address _platform,
		address _mint,
		address _token,
		address _share,
		address _governor,
		address _base,
		address _WETH
	) external {
		require(msg.sender == owner || msg.sender == developer, "ONX: Config FORBIDDEN");
		mint = _mint;
		platform = _platform;
		token = _token;
		share = _share;
		governor = _governor;
		base = _base;
		WETH = _WETH;
	}

	function changeDeveloper(address _developer) external {
		require(msg.sender == owner || msg.sender == developer, "ONX: Config FORBIDDEN");
		developer = _developer;
	}

	function setWallets(bytes32[] calldata _names, address[] calldata _wallets) external {
		require(msg.sender == owner || msg.sender == developer, "ONX: ONLY DEVELOPER");
		require(_names.length == _wallets.length, "ONX: WALLETS LENGTH MISMATCH");
		for (uint256 i = 0; i < _names.length; i++) {
			wallets[_names[i]] = _wallets[i];
		}
	}

	function initParameter() external {
		require(msg.sender == owner || msg.sender == developer, "ONX: Config FORBIDDEN");
		_setParams(ConfigNames.STAKE_LOCK_TIME, 0, 7 * DAY, 1 * DAY, 0);
		_setParams(ConfigNames.MINT_AMOUNT_PER_BLOCK, 0, 10000 * 1e18, 1e17, 1e17);
		_setParams(ConfigNames.INTEREST_PLATFORM_SHARE, 0, 1e18, 1e17, 1e17);
		_setParams(ConfigNames.INTEREST_BUYBACK_SHARE, 10000, 10000, 0, 10000);
		_setParams(ConfigNames.CHANGE_PRICE_DURATION, 0, 500, 100, 0);
		_setParams(ConfigNames.CHANGE_PRICE_PERCENT, 1, 100, 1, 20);
		_setParams(ConfigNames.ONX_USER_MINT, 0, 0, 0, 3000);
		_setParams(ConfigNames.ONX_TEAM_MINT, 0, 0, 0, 7142);
		_setParams(ConfigNames.ONX_REWAED_MINT, 0, 0, 0, 5000);
		_setParams(ConfigNames.DEPOSIT_ENABLE, 0, 0, 0, 1);
		_setParams(ConfigNames.WITHDRAW_ENABLE, 0, 0, 0, 1);
		_setParams(ConfigNames.BORROW_ENABLE, 0, 0, 0, 1);
		_setParams(ConfigNames.REPAY_ENABLE, 0, 0, 0, 1);
		_setParams(ConfigNames.LIQUIDATION_ENABLE, 0, 0, 0, 1);
		_setParams(ConfigNames.REINVEST_ENABLE, 0, 0, 0, 1);
		_setParams(ConfigNames.POOL_REWARD_RATE, 0, 1e18, 1e17, 5e16);
		_setParams(ConfigNames.POOL_ARBITRARY_RATE, 0, 1e18, 1e17, 9e16);
		_setPoolParams(ConfigNames.POOL_BASE_INTERESTS, 0, 1e18, 1e16, 2e17);
		_setPoolParams(ConfigNames.POOL_MARKET_FRENZY, 0, 1e18, 1e16, 2e17);
		_setPoolParams(ConfigNames.POOL_PLEDGE_RATE, 0, 1e18, 1e16, 6e17);
		_setPoolParams(ConfigNames.POOL_LIQUIDATION_RATE, 0, 1e18, 1e16, 9e17);
		_setPoolParams(ConfigNames.POOL_MINT_POWER, 0, 0, 0, 10000);
		_setPoolParams(ConfigNames.POOL_MINT_BORROW_PERCENT, 0, 10000, 1000, 5000);
	}

	function _setPoolValue(bytes32 _key, uint256 _value) internal {
		poolParams[_key].value = _value;
		emit PoolParameterChange(_key, _value);
	}

	function _setParams(
		bytes32 _key,
		uint256 _min,
		uint256 _max,
		uint256 _span,
		uint256 _value
	) internal {
		params[_key] = ConfigItem(_min, _max, _span, _value);
		emit ParameterChange(_key, _value);
	}

	function _setPoolParams(
		bytes32 _key,
		uint256 _min,
		uint256 _max,
		uint256 _span,
		uint256 _value
	) internal {
		poolParams[_key] = ConfigItem(_min, _max, _span, _value);
		emit PoolParameterChange(_key, _value);
	}

	function _setPrice(address _token, uint256 _value) internal {
		prices[_token] = _value;
		emit PriceChange(_token, _value);
	}

	function setTokenPrice(address[] calldata _tokens, uint256[] calldata _prices) external {
		uint256 duration = params[ConfigNames.CHANGE_PRICE_DURATION].value;
		uint256 maxPercent = params[ConfigNames.CHANGE_PRICE_PERCENT].value;
		require(block.number >= lastPriceBlock.add(duration), "ONX: Price Duration");
		require(msg.sender == wallets[bytes32("price")], "ONX: Config FORBIDDEN");
		require(_tokens.length == _prices.length, "ONX: PRICES LENGTH MISMATCH");
		for (uint256 i = 0; i < _tokens.length; i++) {
			if (prices[_tokens[i]] == 0) {
				_setPrice(_tokens[i], _prices[i]);
			} else {
				uint256 currentPrice = prices[_tokens[i]];
				if (_prices[i] > currentPrice) {
					uint256 maxPrice = currentPrice.add(currentPrice.mul(maxPercent).div(10000));
					_setPrice(_tokens[i], _prices[i] > maxPrice ? maxPrice : _prices[i]);
				} else {
					uint256 minPrice = currentPrice.sub(currentPrice.mul(maxPercent).div(10000));
					_setPrice(_tokens[i], _prices[i] < minPrice ? minPrice : _prices[i]);
				}
			}
		}

		lastPriceBlock = block.number;
	}

	function setValue(bytes32 _key, uint256 _value) external {
		require(
			msg.sender == owner || msg.sender == governor || msg.sender == platform || msg.sender == developer,
			"ONX: ONLY DEVELOPER"
		);
		params[_key].value = _value;
		emit ParameterChange(_key, _value);
	}

	function setPoolValue(bytes32 _key, uint256 _value) external {
		require(
			msg.sender == owner || msg.sender == governor || msg.sender == platform || msg.sender == developer,
			"ONX: FORBIDDEN"
		);
		_setPoolValue(_key, _value);
	}

	function getValue(bytes32 _key) external view returns (uint256) {
		return params[_key].value;
	}

	function getPoolValue(bytes32 _key) external view returns (uint256) {
		return poolParams[_key].value;
	}

	function setParams(
		bytes32 _key,
		uint256 _min,
		uint256 _max,
		uint256 _span,
		uint256 _value
	) external {
		require(
			msg.sender == owner || msg.sender == governor || msg.sender == platform || msg.sender == developer,
			"ONX: FORBIDDEN"
		);
		_setParams(_key, _min, _max, _span, _value);
	}

	function setPoolParams(
		bytes32 _key,
		uint256 _min,
		uint256 _max,
		uint256 _span,
		uint256 _value
	) external {
		require(
			msg.sender == owner || msg.sender == governor || msg.sender == platform || msg.sender == developer,
			"ONX: FORBIDDEN"
		);
		_setPoolParams(_key, _min, _max, _span, _value);
	}

	function getParams(bytes32 _key)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256
		)
	{
		ConfigItem memory item = params[_key];
		return (item.min, item.max, item.span, item.value);
	}

	function getPoolParams(bytes32 _key)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256
		)
	{
		ConfigItem memory item = poolParams[_key];
		return (item.min, item.max, item.span, item.value);
	}

	function convertTokenAmount(
		address _fromToken,
		address _toToken,
		uint256 _fromAmount
	) external view returns (uint256 toAmount) {
		uint256 fromPrice = prices[_fromToken];
		uint256 toPrice = prices[_toToken];
		uint8 fromDecimals = IERC20(_fromToken).decimals();
		uint8 toDecimals = IERC20(_toToken).decimals();
		toAmount = _fromAmount.mul(fromPrice).div(toPrice);
		if (fromDecimals > toDecimals) {
			toAmount = toAmount.div(10**(fromDecimals.sub(toDecimals)));
		} else if (toDecimals > fromDecimals) {
			toAmount = toAmount.mul(10**(toDecimals.sub(fromDecimals)));
		}
	}
}
