// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;
pragma experimental ABIEncoderV2;

interface IConfig {
	function developer() external view returns (address);

	function platform() external view returns (address);

	function mint() external view returns (address);

	function token() external view returns (address);

	function developPercent() external view returns (uint256);

	function share() external view returns (address);

	function base() external view returns (address);

	function governor() external view returns (address);

	function getPoolValue(bytes32 key) external view returns (uint256);

	function getValue(bytes32 key) external view returns (uint256);

	function getParams(bytes32 key)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256
		);

	function getPoolParams(bytes32 key)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256
		);

	function wallets(bytes32 key) external view returns (address);

	function setValue(bytes32 key, uint256 value) external;

	function setPoolValue(bytes32 key, uint256 value) external;

	function setParams(
		bytes32 _key,
		uint256 _min,
		uint256 _max,
		uint256 _span,
		uint256 _value
	) external;

	function setPoolParams(
		bytes32 _key,
		uint256 _min,
		uint256 _max,
		uint256 _span,
		uint256 _value
	) external;

	function isMintToken(address _token) external returns (bool);

	function prices(address _token) external returns (uint256);

	function convertTokenAmount(
		address _fromToken,
		address _toToken,
		uint256 _fromAmount
	) external view returns (uint256);

	function DAY() external view returns (uint256);

	function WETH() external view returns (address);
}

contract Configable {
	address public config;
	address public owner;
	event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);

	constructor() public {
		owner = msg.sender;
	}

	function setupConfig(address _config) external onlyOwner {
		config = _config;
		owner = IConfig(config).developer();
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "OWNER FORBIDDEN");
		_;
	}

	modifier onlyDeveloper() {
		require(msg.sender == IConfig(config).developer(), "DEVELOPER FORBIDDEN");
		_;
	}

	modifier onlyPlatform() {
		require(msg.sender == IConfig(config).platform(), "PLATFORM FORBIDDEN");
		_;
	}

	modifier onlyGovernor() {
		require(msg.sender == IConfig(config).governor(), "Governor FORBIDDEN");
		_;
	}
}
