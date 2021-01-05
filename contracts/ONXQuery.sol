// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

import "./libraries/SafeMath.sol";
import './modules/ConfigNames.sol';

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
}

interface IConfig {
    function developer() external view returns (address);
    function platform() external view returns (address);
    function factory() external view returns (address);
    function mint() external view returns (address);
    function token() external view returns (address);
    function developPercent() external view returns (uint);
    function wallet() external view returns (address);
    function base() external view returns (address);
    function share() external view returns (address);
    function params(bytes32 key) external view returns(uint);
    function setParameter(uint[] calldata _keys, uint[] calldata _values) external;
    function setPoolParameter(address _pool, bytes32 _key, uint _value) external;
    function getValue(bytes32 _key) external view returns (uint);
    function getPoolValue(address _pool, bytes32 _key) external view returns (uint);
    function getParams(bytes32 _key) external view returns (uint, uint, uint, uint);
    function getPoolParams(address _pool, bytes32 _key) external view returns (uint, uint, uint, uint);
    function convertTokenAmount(address _fromToken, address _toToken, uint _fromAmount) external view returns(uint toAmount);
}

interface IONXFactory {
    function countPools() external view returns(uint);
    function countBallots() external view returns(uint);
    function allBallots(uint index) external view returns(address);
    function allPools(uint index) external view returns(address);
    function isPool(address addr) external view returns(bool);
    function getPool(address lend, address collateral) external view returns(address);
}

interface IONXPlatform {
    function getRepayAmount(address _lendToken, address _collateralToken, uint amountCollateral, address from) external view returns(uint);
    function getMaximumBorrowAmount(address _lendToken, address _collateralToken, uint amountCollateral) external view returns(uint amountBorrow);
}

interface IONXPool {
    function supplyToken() external view returns(address);
    function collateralToken() external view returns(address);
    function totalBorrow() external view returns(uint);
    function totalPledge() external view returns(uint);
    function remainSupply() external view returns(uint);
    function getInterests() external view returns(uint);
    function numberBorrowers() external view returns(uint);
    function borrowerList(uint index) external view returns(address);
    function borrows(address user) external view returns(uint,uint,uint,uint,uint);
    function getRepayAmount(uint amountCollateral, address from) external view returns(uint);
    function liquidationHistory(address user, uint index) external view returns(uint,uint,uint);
    function liquidationHistoryLength(address user) external view returns(uint);
    function interestPerBorrow() external view returns(uint);
    function lastInterestUpdate() external view returns(uint);
    function interestPerSupply() external view returns(uint);
    function supplys(address user) external view returns(uint,uint,uint,uint,uint);
}

interface IONXMint {
    function maxSupply() external view returns(uint);
    function mintCumulation() external view returns(uint);
    function takeLendWithAddress(address user) external view returns (uint);
    function takeBorrowWithAddress(address user) external view returns (uint);
}

interface ISwapPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IONXBallot {
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted proposal 0 YES, 1 NO
        bool claimed; // already claimed reward
    }
    function name() external view returns(bytes32);
    function subject() external view returns(string memory);
    function content() external view returns(string memory);
    function createdBlock() external view returns(uint);
    function createdTime() external view returns(uint);
    function creator() external view returns(address);
    function proposals(uint index) external view returns(uint);
    function end() external view returns (bool);
    function pass() external view returns (bool);
    function expire() external view returns (bool);
    function pool() external view returns (address);
    function value() external view returns (uint);
    function total() external view returns (uint);
    function reward() external view returns (uint);
    function voters(address user) external view returns (Voter memory);
}

contract ONXQuery {
    address public owner;
    address public config;
    using SafeMath for uint;

    struct PoolInfoStruct {
        address pair;
        uint totalBorrow;
        uint totalPledge;
        uint totalPledgeValue;
        uint remainSupply;
        uint totalSupplyValue;
        uint borrowInterests;
        uint supplyInterests;
        address supplyToken;
        address collateralToken;
        uint8 supplyTokenDecimals;
        uint8 collateralTokenDecimals;
        string lpToken0Symbol;
        string lpToken1Symbol;
        string supplyTokenSymbol;
        string collateralTokenSymbol;
    }

    struct TokenStruct {
        string name;
        string symbol;
        uint8 decimals;
        uint balance;
        uint totalSupply;
        uint allowance;
    }

    struct MintTokenStruct {
        uint mintCumulation;
        uint maxSupply;
        uint takeBorrow;
        uint takeLend;
    }

     struct SupplyInfo {
        uint amountSupply;
        uint interestSettled;
        uint liquidationSettled;

        uint interests;
        uint liquidation;
    }

    struct BorrowInfo {
        address user;
        uint amountCollateral;
        uint interestSettled;
        uint amountBorrow;
        uint interests;
    }

    struct LiquidationStruct {
        address pool;
        address user;
        uint amountCollateral;
        uint expectedRepay;
        uint liquidationRate;
    }

    struct PoolConfigInfo {
        uint baseInterests;
        uint marketFrenzy;
        uint pledgeRate;
        uint pledgePrice;
        uint liquidationRate;   
    }

    struct UserLiquidationStruct {
        uint amountCollateral;
        uint liquidationAmount;
        uint timestamp;
    }

    struct BallotStruct {
        address ballot;
        bytes32 name;
        address pool; // pool address or address(0)
        address creator;
        uint currentValue;
        uint    value;
        uint    createdBlock;
        uint    createdTime;
        uint    total;
        uint    reward;
        uint YES;
        uint NO;
        uint weight;
        bool voted;
        uint voteIndex;
        bool claimed;
        uint myReward;
        bool end;
        bool pass;
        bool expire;
        string  subject;
        string  content;
    }

    constructor() public {
        owner = msg.sender;
    }
    
    function setupConfig (address _config) external {
        require(msg.sender == owner, "FORBIDDEN");
        config = _config;
    }
        
    function getPoolInterests(address pair) public view returns (uint, uint) {
        uint borrowInterests = IONXPool(pair).getInterests();
        uint supplyInterests = 0;
        uint borrow = IONXPool(pair).totalBorrow();
        uint total = borrow + IONXPool(pair).remainSupply();
        if(total > 0) {
            supplyInterests = borrowInterests * borrow / total;
        }
        return (supplyInterests, borrowInterests);
    }

    function getPoolInfoByIndex(uint index) public view returns (PoolInfoStruct memory info) {
        uint count = IONXFactory(IConfig(config).factory()).countPools();
        if (index >= count || count == 0) {
            return info;
        }
        address pair = IONXFactory(IConfig(config).factory()).allPools(index);
        return getPoolInfo(pair);
    }

    function getPoolInfoByTokens(address lend, address collateral) public view returns (PoolInfoStruct memory info) {
        address pair = IONXFactory(IConfig(config).factory()).getPool(lend, collateral);
        return getPoolInfo(pair);
    }
    
    function getPoolInfo(address pair) public view returns (PoolInfoStruct memory info) {
        if(!IONXFactory(IConfig(config).factory()).isPool(pair)) {
            return info;
        }
        info.pair = pair;
        info.totalBorrow = IONXPool(pair).totalBorrow();
        info.totalPledge = IONXPool(pair).totalPledge();
        info.remainSupply = IONXPool(pair).remainSupply();
        info.borrowInterests = IONXPool(pair).getInterests();
        info.supplyToken = IONXPool(pair).supplyToken();
        info.collateralToken = IONXPool(pair).collateralToken();
        info.supplyTokenDecimals = IERC20(info.supplyToken).decimals();
        info.collateralTokenDecimals = IERC20(info.collateralToken).decimals();
        info.supplyTokenSymbol = IERC20(info.supplyToken).symbol();
        info.collateralTokenSymbol = IERC20(info.collateralToken).symbol();
        address lpToken0 = ISwapPair(info.collateralToken).token0();
        address lpToken1 = ISwapPair(info.collateralToken).token1();
        info.lpToken0Symbol = IERC20(lpToken0).symbol();
        info.lpToken1Symbol = IERC20(lpToken1).symbol();

        info.totalSupplyValue = IConfig(config).convertTokenAmount(info.supplyToken, IConfig(config).base(), info.remainSupply.add(info.totalBorrow));
        info.totalPledgeValue = IConfig(config).convertTokenAmount(info.collateralToken, IConfig(config).base(), info.totalPledge);

        if(info.totalBorrow + info.remainSupply > 0) {
            info.supplyInterests = info.borrowInterests * info.totalBorrow / (info.totalBorrow + info.remainSupply);
        }
    }

    function queryPoolList() public view returns (PoolInfoStruct[] memory list) {
        uint count = IONXFactory(IConfig(config).factory()).countPools();
        if(count > 0) {
            list = new PoolInfoStruct[](count);
            for(uint i = 0;i < count;i++) {
                list[i] = getPoolInfoByIndex(i);
            }
        }
    }

    function queryPoolListByToken(address token) public view returns (PoolInfoStruct[] memory list) {
        uint count = IONXFactory(IConfig(config).factory()).countPools();
        uint outCount = 0;
        if(count > 0) {
            for(uint i = 0;i < count;i++) {
                PoolInfoStruct memory info = getPoolInfoByIndex(i);
                if(info.supplyToken == token) {
                    outCount++;
                }
            }
            if(outCount == 0) return list;
            list = new PoolInfoStruct[](outCount);
            uint index = 0;
            for(uint i = 0;i < count;i++) {
                PoolInfoStruct memory info = getPoolInfoByIndex(i);
                if(info.supplyToken == token) {
                    list[index] = info;
                    index++;
                }
            }
        }
        return list;
    }

    function queryToken(address user, address spender, address token) public view returns (TokenStruct memory info) {
        info.name = IERC20(token).name();
        info.symbol = IERC20(token).symbol();
        info.decimals = IERC20(token).decimals();
        info.balance = IERC20(token).balanceOf(user);
        info.totalSupply = IERC20(token).totalSupply();
        if(spender != user) {
            info.allowance = IERC20(token).allowance(user, spender);
        }
    }

    function queryTokenList(address user, address spender, address[] memory tokens) public view returns (TokenStruct[] memory token_list) {
        uint count = tokens.length;
        if(count > 0) {
            token_list = new TokenStruct[](count);
            for(uint i = 0;i < count;i++) {
                token_list[i] = queryToken(user, spender, tokens[i]);
            }
        }
    }

    function queryMintToken(address user) public view returns (MintTokenStruct memory info) {
        address token = IConfig(config).mint();
        info.mintCumulation = IONXMint(token).mintCumulation();
        info.maxSupply = IONXMint(token).maxSupply();
        info.takeBorrow = IONXMint(token).takeBorrowWithAddress(user);
        info.takeLend = IONXMint(token).takeLendWithAddress(user);
    }

    function getBorrowInfo(address _pair, address _user) public view returns (BorrowInfo memory info){
        (, uint amountCollateral, uint interestSettled, uint amountBorrow, uint interests) = IONXPool(_pair).borrows(_user);
        info = BorrowInfo(_user, amountCollateral, interestSettled, amountBorrow, interests);
    }

    function iterateBorrowInfo(address _pair, uint _start, uint _end) public view returns (BorrowInfo[] memory list){
        require(_start <= _end && _start >= 0 && _end >= 0, "INVAID_PARAMTERS");
        uint count = IONXPool(_pair).numberBorrowers();
        if (_end > count) _end = count;
        count = _end - _start;
        list = new BorrowInfo[](count);
        uint index = 0;
        for(uint i = _start; i < _end; i++) {
            address user = IONXPool(_pair).borrowerList(i);
            list[index] = getBorrowInfo(_pair, user);
            index++;
        }
    }

    function iteratePairLiquidationInfo(address _pair, uint _start, uint _end) public view returns (
        LiquidationStruct[] memory list)
    {
        require(_start <= _end && _start >= 0 && _end >= 0, "INVAID_PARAMTERS");
        address supplyToken = IONXPool(_pair).supplyToken();
        address collateralToken = IONXPool(_pair).collateralToken();

        uint count = IONXPool(_pair).numberBorrowers();
        if (_end > count) _end = count;
        count = _end - _start;
        uint index = 0;
        uint liquidationRate = IConfig(config).getPoolValue(_pair, ConfigNames.POOL_LIQUIDATION_RATE);
        uint pledgeRate = IConfig(config).getPoolValue(_pair, ConfigNames.POOL_PLEDGE_RATE);
        
        for(uint i = _start; i < _end; i++) {
            address user = IONXPool(_pair).borrowerList(i);
            (, uint amountCollateral, , , ) = IONXPool(_pair).borrows(user);
            uint pledgeAmount = IConfig(config).convertTokenAmount(collateralToken, supplyToken, amountCollateral);
            uint repayAmount = IONXPlatform(IConfig(config).platform()).getRepayAmount(supplyToken, collateralToken, amountCollateral, user);
            if(repayAmount > pledgeAmount.mul(pledgeRate).div(1e18).mul(liquidationRate).div(1e18))
            {
                index++;
            }
        }
        list = new LiquidationStruct[](index);
        index = 0;
        for(uint i = _start; i < _end; i++) {
            address user = IONXPool(_pair).borrowerList(i);
            (, uint amountCollateral, , , ) = IONXPool(_pair).borrows(user);
            uint pledgeAmount = IConfig(config).convertTokenAmount(collateralToken, supplyToken, amountCollateral);
            uint repayAmount = IONXPlatform(IConfig(config).platform()).getRepayAmount(supplyToken, collateralToken, amountCollateral, user);
            if(repayAmount > pledgeAmount.mul(pledgeRate).div(1e18).mul(liquidationRate).div(1e18))
            {
                list[index].user             = user;
                list[index].pool             = _pair;
                list[index].amountCollateral = amountCollateral;
                list[index].expectedRepay    = repayAmount;
                list[index].liquidationRate  = liquidationRate;
                index++;
            }
        }
    }

    function getPoolConf(address _pair) public view returns (PoolConfigInfo memory info) {
        info.baseInterests = IConfig(config).getPoolValue(_pair, ConfigNames.POOL_BASE_INTERESTS);
        info.marketFrenzy = IConfig(config).getPoolValue(_pair, ConfigNames.POOL_MARKET_FRENZY);
        info.pledgeRate = IConfig(config).getPoolValue(_pair, ConfigNames.POOL_PLEDGE_RATE);
        info.pledgePrice = IConfig(config).getPoolValue(_pair, ConfigNames.POOL_PRICE);
        info.liquidationRate = IConfig(config).getPoolValue(_pair, ConfigNames.POOL_LIQUIDATION_RATE);
    }

    function queryUserLiquidationList(address _pair, address _user) public view returns (UserLiquidationStruct[] memory list) {
        uint count = IONXPool(_pair).liquidationHistoryLength(_user);
        if(count > 0) {
            list = new UserLiquidationStruct[](count);
            for(uint i = 0;i < count; i++) {
                (uint amountCollateral, uint liquidationAmount, uint timestamp) = IONXPool(_pair).liquidationHistory(_user, i);
                list[i] = UserLiquidationStruct(amountCollateral, liquidationAmount, timestamp);
            }
        }
    }

    function getSwapPairReserve(address _pair) public view returns (address token0, address token1, uint8 decimals0, uint8 decimals1, uint reserve0, uint reserve1) {
        token0 = ISwapPair(_pair).token0();
        token1 = ISwapPair(_pair).token1();
        decimals0 = IERC20(token0).decimals();
        decimals1 = IERC20(token1).decimals();
        (reserve0, reserve1, ) = ISwapPair(_pair).getReserves();
    }

    function getCanMaxBorrowAmount(address _pair, address _user, uint _blocks) public view returns(uint) {
        (, uint amountCollateral, uint interestSettled, uint amountBorrow, uint interests) = IONXPool(_pair).borrows(_user);
        uint maxBorrow = IONXPlatform(IConfig(config).platform()).getMaximumBorrowAmount(IONXPool(_pair).supplyToken(), IONXPool(_pair).collateralToken(), amountCollateral);
        uint poolBalance = IERC20(IONXPool(_pair).supplyToken()).balanceOf(_pair);

        uint _interestPerBorrow = IONXPool(_pair).interestPerBorrow().add(IONXPool(_pair).getInterests().mul(block.number+_blocks - IONXPool(_pair).lastInterestUpdate()));
        uint _totalInterest = interests.add(_interestPerBorrow.mul(amountBorrow).div(1e18).sub(interestSettled));

        uint repayInterest = amountCollateral == 0 ? 0 : _totalInterest.mul(amountCollateral).div(amountCollateral);
        uint repayAmount = amountCollateral == 0 ? 0 : amountBorrow.mul(amountCollateral).div(amountCollateral).add(repayInterest);

        uint result = maxBorrow.sub(repayAmount);
        if(poolBalance < result) {
            result = poolBalance;
        }
        return result;
    }

    function canReinvest(address _pair, address _user) public view returns(bool) {
        uint interestPerSupply = IONXPool(_pair).interestPerSupply();
        (uint amountSupply, uint interestSettled, , uint interests, ) = IONXPool(_pair).supplys(_user);
        uint remainSupply = IONXPool(_pair).remainSupply();
        uint platformShare = IConfig(config).params(ConfigNames.INTEREST_PLATFORM_SHARE);

        uint curInterests = interestPerSupply.mul(amountSupply).div(1e18).sub(interestSettled);
        interests = interests.add(curInterests);
        uint reinvestAmount = interests.mul(platformShare).div(1e18);
  
        if(reinvestAmount < remainSupply) {
            return true;
        } else {
            return false;
        }
    }

    function getBallotInfo(address _ballot, address _user) public view returns (BallotStruct memory proposal){
        proposal.ballot = _ballot;
        proposal.name = IONXBallot(_ballot).name();
        proposal.creator = IONXBallot(_ballot).creator();
        proposal.subject = IONXBallot(_ballot).subject();
        proposal.content = IONXBallot(_ballot).content();
        proposal.createdTime = IONXBallot(_ballot).createdTime();
        proposal.createdBlock = IONXBallot(_ballot).createdBlock();
        proposal.end = IONXBallot(_ballot).end();
        proposal.pass = IONXBallot(_ballot).pass();
        proposal.expire = IONXBallot(_ballot).expire();
        proposal.YES = IONXBallot(_ballot).proposals(0);
        proposal.NO = IONXBallot(_ballot).proposals(1);
        proposal.reward = IONXBallot(_ballot).reward();
        proposal.voted = IONXBallot(_ballot).voters(_user).voted;
        proposal.voteIndex = IONXBallot(_ballot).voters(_user).vote;
        proposal.weight = IONXBallot(_ballot).voters(_user).weight;
        proposal.claimed = IONXBallot(_ballot).voters(_user).claimed;
        proposal.value = IONXBallot(_ballot).value();
        proposal.total = IONXBallot(_ballot).total();
        proposal.pool = IONXBallot(_ballot).pool();
        if(proposal.pool != address(0)) {
            proposal.currentValue = IConfig(config).getPoolValue(proposal.pool, proposal.name);
        } else {
            proposal.currentValue = IConfig(config).getValue(proposal.name);
        }

        if(proposal.total > 0) {
           proposal.myReward = proposal.reward * proposal.weight / proposal.total;
        }
    }


    function iterateBallotList(uint _start, uint _end) public view returns (BallotStruct[] memory ballots){
        require(_start <= _end && _start >= 0 && _end >= 0, "INVAID_PARAMTERS");
        uint count = IONXFactory(IConfig(config).factory()).countBallots();
        if (_end > count) _end = count;
        count = _end - _start;
        ballots = new BallotStruct[](count);
        if (count == 0) return ballots;
        uint index = 0;
        for(uint i = _start;i < _end;i++) {
            address ballot = IONXFactory(IConfig(config).factory()).allBallots(i);
            ballots[index] = getBallotInfo(ballot, msg.sender);
            index++;
        }
        return ballots;
    }

    function iterateReverseBallotList(uint _start, uint _end) public view returns (BallotStruct[] memory ballots){
        require(_end <= _start && _end >= 0 && _start >= 0, "INVAID_PARAMTERS");
        uint count = IONXFactory(IConfig(config).factory()).countBallots();
        if (_start > count) _start = count;
        count = _start - _end;
        ballots = new BallotStruct[](count);
        if (count == 0) return ballots;
        uint index = 0;
        for(uint i = _end;i < _start; i++) {
            uint j = _start - i -1;
            address ballot = IONXFactory(IConfig(config).factory()).allBallots(j);
            ballots[index] = getBallotInfo(ballot, msg.sender);
            index++;
        }
        return ballots;
    }

}