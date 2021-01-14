// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

library ConfigNames {
	//GOVERNANCE
	bytes32 public constant STAKE_LOCK_TIME = bytes32("STAKE_LOCK_TIME");
	bytes32 public constant MINT_AMOUNT_PER_BLOCK = bytes32("MINT_AMOUNT_PER_BLOCK");
	bytes32 public constant INTEREST_PLATFORM_SHARE = bytes32("INTEREST_PLATFORM_SHARE");
	bytes32 public constant CHANGE_PRICE_DURATION = bytes32("CHANGE_PRICE_DURATION");
	bytes32 public constant CHANGE_PRICE_PERCENT = bytes32("CHANGE_PRICE_PERCENT"); // POOL
	bytes32 public constant POOL_BASE_INTERESTS = bytes32("POOL_BASE_INTERESTS");
	bytes32 public constant POOL_MARKET_FRENZY = bytes32("POOL_MARKET_FRENZY");
	bytes32 public constant POOL_PLEDGE_RATE = bytes32("POOL_PLEDGE_RATE");
	bytes32 public constant POOL_LIQUIDATION_RATE = bytes32("POOL_LIQUIDATION_RATE");
	bytes32 public constant POOL_MINT_BORROW_PERCENT = bytes32("POOL_MINT_BORROW_PERCENT");
	bytes32 public constant POOL_MINT_POWER = bytes32("POOL_MINT_POWER");
	bytes32 public constant POOL_REWARD_RATE = bytes32("POOL_REWARD_RATE");
	bytes32 public constant POOL_ARBITRARY_RATE = bytes32("POOL_ARBITRARY_RATE");

	//NOT GOVERNANCE
	bytes32 public constant ONX_USER_MINT = bytes32("ONX_USER_MINT");
	bytes32 public constant ONX_TEAM_MINT = bytes32("ONX_TEAM_MINT");
	bytes32 public constant ONX_REWAED_MINT = bytes32("ONX_REWAED_MINT");
	bytes32 public constant DEPOSIT_ENABLE = bytes32("DEPOSIT_ENABLE");
	bytes32 public constant WITHDRAW_ENABLE = bytes32("WITHDRAW_ENABLE");
	bytes32 public constant BORROW_ENABLE = bytes32("BORROW_ENABLE");
	bytes32 public constant REPAY_ENABLE = bytes32("REPAY_ENABLE");
	bytes32 public constant LIQUIDATION_ENABLE = bytes32("LIQUIDATION_ENABLE");
	bytes32 public constant REINVEST_ENABLE = bytes32("REINVEST_ENABLE");
	bytes32 public constant INTEREST_BUYBACK_SHARE = bytes32("INTEREST_BUYBACK_SHARE"); //POOL
	bytes32 public constant POOL_PRICE = bytes32("POOL_PRICE"); //wallet
	bytes32 public constant TEAM = bytes32("team");
	bytes32 public constant SPARE = bytes32("spare");
	bytes32 public constant REWARD = bytes32("reward");
}
