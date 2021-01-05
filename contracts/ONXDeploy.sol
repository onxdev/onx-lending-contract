// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

import './modules/ConfigNames.sol';

interface IConfigable {
    function setupConfig(address config) external;
}

interface IConfig {
    function developer() external view returns (address);
    function platform() external view returns (address);
    function factory() external view returns (address);
    function mint() external view returns (address);
    function token() external view returns (address);
    function share() external view returns (address);
    function governor() external view returns (address);
    function initialize (address _platform, address _factory, address _mint, address _token, address _share, address _governor) external;
    function initParameter() external;
    function setWallets(bytes32[] calldata _names, address[] calldata _wallets) external;
    function changeDeveloper(address _developer) external;
    function setValue(bytes32 _key, uint _value) external;
}

interface IONXMint {
    function sync() external;
}

interface IONXShare {
    function setShareToken(address _shareToken) external;
}

interface IONXToken {
    function initialize() external;
}

interface IONXFactory {
    function countPools() external view returns(uint);
    function countBallots() external view returns(uint);
    function allBallots(uint index) external view returns(address);
    function allPools(uint index) external view returns(address);
    function isPool(address addr) external view returns(bool);
    function getPool(address lend, address collateral) external view returns(address);
    function createPool(address _lendToken, address _collateralToken) external returns (address pool);
    function changeBallotByteHash(bytes32 _hash) external;
}

interface IMasterChef {
    function cake() external view returns(address);
}

interface ILPStrategyFactory {
    function createStrategy(address _collateralToken, address _poolAddress, uint _lpPoolpid) external returns (address _strategy);
}

interface IONXPlatform {
    function switchStrategy(address _lendToken, address _collateralToken, address _collateralStrategy) external;
    function updatePoolParameter(address _lendToken, address _collateralToken, bytes32 _key, uint _value) external;
}

contract ONXDeploy {
    address public owner;
    address public config;
    address public LPStrategyFactory;

    modifier onlyOwner() {
        require(msg.sender == owner, 'OWNER FORBIDDEN');
        _;
    }
 
    constructor() public {
        owner = msg.sender;
    }
    
    function setupConfig(address _config) onlyOwner external {
        require(_config != address(0), "ZERO ADDRESS");
        config = _config;
    }

    function changeDeveloper(address _developer) onlyOwner external {
        IConfig(config).changeDeveloper(_developer);
    }
    
    function setMasterchef(address _LPStrategyFactory) onlyOwner external {
        LPStrategyFactory = _LPStrategyFactory;
    }

    function createPool(address _lendToken, address _collateralToken, uint _lpPoolpid) onlyOwner public {
        address pool = IONXFactory(IConfig(config).factory()).createPool(_lendToken, _collateralToken);
        address strategy = ILPStrategyFactory(LPStrategyFactory).createStrategy(_collateralToken, pool, _lpPoolpid);
        IONXPlatform(IConfig(config).platform()).switchStrategy(_lendToken, _collateralToken, strategy);
    }

    function changeBallotByteHash(bytes32 _hash) onlyOwner external {
        IONXFactory(IConfig(config).factory()).changeBallotByteHash(_hash);
    }

    function changeMintPerBlock(uint _value) onlyOwner external {
        IConfig(config).setValue(ConfigNames.MINT_AMOUNT_PER_BLOCK, _value);
        IONXMint(IConfig(config).mint()).sync();
    }

    function setShareToken(address _shareToken) onlyOwner external {
        IONXShare(IConfig(config).share()).setShareToken(_shareToken);
    }

    function updatePoolParameter(address _lendToken, address _collateralToken, bytes32 _key, uint _value) onlyOwner external {
        IONXPlatform(IConfig(config).platform()).updatePoolParameter(_lendToken, _collateralToken, _key, _value);
    }

  }