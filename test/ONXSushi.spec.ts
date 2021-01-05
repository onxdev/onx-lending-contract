// import {expect, use} from 'chai';
// import {Contract, ethers, BigNumber} from 'ethers';
// import {deployContract, MockProvider, solidity} from 'ethereum-waffle';
// import ONX from '../build/ONXPool.json';
// import ONXConfig from '../build/ONXConfig.json';
// import ONXMint from '../build/ONXMint.json';
// import ONXFactory from '../build/ONXFactory.json';
// import ONXPlatform from '../build/ONXPlatform.json';
// import ONXToken from '../build/ONXToken.json';
// import ONXShare from '../build/ONXShare.json';
// import ONXQuery from '../build/ONXQuery.json';
// import ONXBallot from '../build/ONXBallot.json';
// import ONXGovernance from '../build/ONXGovernance.json';
// import ERC20 from '../build/ERC20Token.json';
// import StakingReward from '../build/StakingRewards.json';
// import SushiMasterChef from '../build/SushiMasterChef.json';
// import StakingRewardFactory from '../build/StakingRewardsFactory.json';
// import UniLPStrategy from '../build/UniLPStrategy.json';
// import SLPStrategy from '../build/SLPStrategy.json';
// import { BigNumber as BN } from 'bignumber.js'

// use(solidity);

// function convertBigNumber(bnAmount: BigNumber, divider: number) {
// 	return new BN(bnAmount.toString()).dividedBy(new BN(divider)).toFixed();
// }

// let address0 = "0x0000000000000000000000000000000000000000";

// describe('deploy', () => {
// 	let provider = new MockProvider({ganacheOptions : {gasLimit : 8000000}});
// 	const [walletMe, walletOther, walletDeveloper, walletTeam, walletSpare, walletPrice, wallet1, wallet2, wallet3, wallet4] = provider.getWallets();
// 	let configContract: Contract;
// 	let factoryContract: Contract;
// 	let mintContract:  Contract;
// 	let platformContract: Contract;
// 	let tokenContract: Contract;
// 	let shareContract: Contract;
// 	let masterChef 	: Contract;
// 	let tokenUSDT 	: Contract;
// 	let tokenLP	 	: Contract;
// 	let poolContract: Contract;
// 	let queryContract : Contract;
// 	let governanceContract : Contract;
// 	let stakingReward : Contract;
// 	let stakingRewardFactory : Contract;
// 	let rewardToken : Contract;
// 	let strategy : Contract;
// 	let tx: any;
// 	let receipt: any;

// 	async function getBlockNumber() {
// 		const blockNumber = await provider.getBlockNumber()
// 		console.log("Current block number: " + blockNumber);
// 		return blockNumber;
// 	}

// 	async function mineBlock(provider: MockProvider, timestamp: number): Promise<void> {
// 		  return provider.send('evm_mine', [timestamp])
// 	}

// 	before(async () => {
// 		console.log('before deploy...')
// 		shareContract = await deployContract(walletDeveloper, ONXShare);
// 		configContract  = await deployContract(walletDeveloper, ONXConfig);
// 		factoryContract  = await deployContract(walletDeveloper, ONXFactory, [], {gasLimit: 7000000});
// 		mintContract  = await deployContract(walletDeveloper, ONXMint);
// 		platformContract  = await deployContract(walletDeveloper, ONXPlatform);
// 		tokenContract  = await deployContract(walletDeveloper, ONXToken);
// 		tokenUSDT 	= await deployContract(walletOther, ERC20, ['USDT', 'USDT', 18, ethers.utils.parseEther('1000000')]);
// 		// tokenUSDT 	= await deployContract(walletMe, ERC20, ['File Coin', 'FIL', 18, ethers.utils.parseEther('1000000')]);
// 		tokenLP 	= await deployContract(walletMe, ERC20, ['PancakeSwap LP CAKE/BNB', 'PancakeSwap LP CAKE/BNB', 18, ethers.utils.parseEther('1000000')]);
// 		rewardToken = await deployContract(walletDeveloper, ERC20, ['CAKE', 'CAKE', 18, ethers.utils.parseEther('1000000')]);
// 		queryContract = await deployContract(walletDeveloper, ONXQuery, [], {gasLimit: 7000000});
// 		governanceContract = await deployContract(walletDeveloper, ONXGovernance);
// 		masterChef  = await deployContract(walletDeveloper, SushiMasterChef, 
// 			[rewardToken.address, rewardToken.address, walletDeveloper.address, ethers.utils.parseEther('1'), 0]);

// 		await (await masterChef.connect(walletDeveloper).add(100, tokenLP.address, false)).wait();

// 		console.log('masterChef 0 lp:', (await masterChef.poolInfo(0)).lpToken);

// 		await getBlockNumber();
// 		// stakingRewardFactory = await deployContract(walletMe, StakingRewardFactory, [rewardToken.address, 50]);
// 		stakingReward = await deployContract(walletMe, StakingReward, [walletDeveloper.address, rewardToken.address, tokenLP.address]);
// 		// rewardToken.connect(walletDeveloper).transfer(stakingReward.address, ethers.utils.parseEther('100'));
// 		// stakingReward.connect(walletDeveloper).notifyRewardAmount(ethers.utils.parseEther('100'));

// 	    await rewardToken.connect(walletDeveloper).transfer(masterChef.address, ethers.utils.parseEther('100'));
// 		// await stakingReward.connect(walletDeveloper).notifyRewardAmount(ethers.utils.parseEther('100'));

// 		const rewardsDuration = await stakingReward.rewardsDuration()
// 		const startTime: BigNumber = await stakingReward.lastUpdateTime()
// 	    const endTime: BigNumber = await stakingReward.periodFinish()

// 		console.log('configContract = ', configContract.address);
// 		console.log('factoryContract = ', factoryContract.address);
// 		console.log('mintContract address = ', mintContract.address);
// 		console.log('platformContract address = ', platformContract.address);
// 		console.log('tokenContract address = ', tokenContract.address);
// 		console.log('tokenUSDT address = ', tokenUSDT.address);
// 		console.log('rewardToken address = ', rewardToken.address);
// 		console.log('tokenLP address = ', tokenLP.address);
// 		console.log('stakingReward address = ', stakingReward.address);

// 		console.log('team:', ethers.utils.formatBytes32String("team"))
// 		console.log('spare:', ethers.utils.formatBytes32String("spare"))
// 		console.log('reward:', ethers.utils.formatBytes32String("reward"))
// 		console.log('price:', ethers.utils.formatBytes32String("price"))
// 		console.log('POOL_PRICE:', ethers.utils.formatBytes32String("POOL_PRICE"))
// 		console.log('ONXTokenUserMint:', ethers.utils.formatBytes32String("ONX_USER_MINT"))
// 		console.log('changePricePercent:', ethers.utils.formatBytes32String("CHANGE_PRICE_PERCENT"))
// 		console.log('liquidationRate:', ethers.utils.formatBytes32String("POOL_LIQUIDATION_RATE"))
		
// 		await configContract.connect(walletDeveloper).initialize(
// 			platformContract.address, 
// 			factoryContract.address, 
// 			mintContract.address, 
// 			tokenContract.address,
// 			shareContract.address,
// 			governanceContract.address,
// 			tokenUSDT.address
// 		);
		
// 		await shareContract.connect(walletDeveloper).setupConfig(configContract.address);
// 		await factoryContract.connect(walletDeveloper).setupConfig(configContract.address);
// 		await mintContract.connect(walletDeveloper).setupConfig(configContract.address);
// 		await platformContract.connect(walletDeveloper).setupConfig(configContract.address);
// 		await governanceContract.connect(walletDeveloper).setupConfig(configContract.address);
// 		await tokenContract.connect(walletDeveloper).setupConfig(configContract.address);
// 		await governanceContract.connect(walletDeveloper).setupConfig(configContract.address);
// 		await queryContract.connect(walletDeveloper).setupConfig(configContract.address);

// 		await configContract.connect(walletDeveloper).initParameter();
// 		await configContract.connect(walletDeveloper).setWallets([
// 			ethers.utils.formatBytes32String("team"), 
// 			ethers.utils.formatBytes32String("spare"), 
// 			ethers.utils.formatBytes32String("price")
// 		], [
// 			walletTeam.address, 
// 			walletSpare.address, 
// 			walletPrice.address
// 		]);
// 		//await shareContract.connect(walletDeveloper).initialize();
// 		//await tokenContract.connect(walletDeveloper).initialize();

// 		let bytecodeHash = ethers.utils.keccak256('0x'+ONXBallot.bytecode);
// 		console.log('hello world', bytecodeHash);
// 		let developer = await configContract.connect(walletDeveloper).developer();
// 		console.log('developer:', developer, walletDeveloper.address)
// 		await factoryContract.connect(walletDeveloper).changeBallotByteHash(bytecodeHash);
		
// 		await configContract.connect(walletDeveloper).addMintToken(tokenUSDT.address);
// 		await configContract.connect(walletPrice).setTokenPrice([tokenUSDT.address, tokenLP.address],  [ethers.utils.parseEther('1'), ethers.utils.parseEther('0.02')]);
// 		await factoryContract.connect(walletDeveloper).createPool(tokenUSDT.address, tokenLP.address);

// 		let pool = await factoryContract.connect(walletDeveloper).getPool(tokenUSDT.address, tokenLP.address);
// 		poolContract  = new Contract(pool, ONX.abi, provider).connect(walletMe);

// 		// strategy = await deployContract(walletMe, UniLPStrategy, [rewardToken.address, tokenLP.address, poolContract.address, stakingReward.address]);
// 		strategy = await deployContract(walletDeveloper, SLPStrategy, []);
// 		await strategy.connect(walletDeveloper).initialize(rewardToken.address, tokenLP.address, poolContract.address, masterChef.address, 0);

// 		console.log(strategy.address);
// 		await (await platformContract.connect(walletDeveloper).switchStrategy(tokenUSDT.address, tokenLP.address, strategy.address)).wait();

// 		// await tokenUSDT.connect(walletMe).approve(poolContract.address, ethers.utils.parseEther('1000000'));
// 		// await tokenUSDT.connect(walletOther).approve(poolContract.address, ethers.utils.parseEther('1000000'));
// 		await (await tokenUSDT.connect(walletOther).approve(poolContract.address, ethers.utils.parseEther('1000000'))).wait();
// 		await (await tokenLP.connect(walletOther).approve(poolContract.address, ethers.utils.parseEther('1000000'))).wait();
// 		await (await tokenLP.connect(walletMe).approve(poolContract.address, ethers.utils.parseEther('1000000'))).wait();
// 		await (await tokenUSDT.connect(walletMe).approve(poolContract.address, ethers.utils.parseEther('1000000'))).wait();
// 		await (await tokenLP.connect(walletMe).transfer(walletOther.address, ethers.utils.parseEther('100000'))).wait();
// 		await (await tokenUSDT.connect(walletOther).transfer(walletMe.address, ethers.utils.parseEther('100000'))).wait();

// 		await (await tokenContract.connect(walletDeveloper).approve(mintContract.address, ethers.utils.parseEther('1000000'))).wait();
// 		await (await mintContract.connect(walletDeveloper).addMintAmount(ethers.utils.parseEther('100000'))).wait();
// 	})

// 	it("simple test", async () => {
// 		console.log('simple test...')
// 		await (await configContract.connect(walletDeveloper).setValue(ethers.utils.formatBytes32String("MINT_AMOUNT_PER_BLOCK"), ethers.utils.parseEther('2000')))
// 		await (await mintContract.connect(walletDeveloper).sync()).wait();

// 		let pool = await factoryContract.connect(walletDeveloper).getPool(tokenUSDT.address, tokenLP.address);
// 		await (await platformContract.connect(walletMe).deposit(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('1000'))).wait();
// 		const poolContract  = new Contract(pool, ONX.abi, provider).connect(walletMe);

// 		console.log(convertBigNumber((await poolContract.supplys(walletMe.address)).amountSupply, 1e18));

// 		expect(convertBigNumber((await poolContract.supplys(walletMe.address)).amountSupply, 1e18)).to.equals('1000');
// 		expect(convertBigNumber(await poolContract.remainSupply(), 1e18)).to.equals('1000');

// 		console.log("1111", convertBigNumber(await poolContract.connect(walletMe).takeLendWithAddress(walletMe.address), 1));


// 		await (await platformContract.connect(walletMe).withdraw(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('500'))).wait();
// 		expect(convertBigNumber(await tokenUSDT.balanceOf(walletMe.address), 1e18)).to.equals('99500');
// 		expect(convertBigNumber((await poolContract.supplys(walletMe.address)).amountSupply, 1e18)).to.equals('500');
// 		expect(convertBigNumber(await poolContract.remainSupply(), 1e18)).to.equals('500');

// 		console.log("ONX", convertBigNumber(await tokenContract.balanceOf(poolContract.address), 1));
// 		console.log("bbbb", convertBigNumber(await mintContract.connect(walletMe).takeWithAddress(poolContract.address), 1));
// 		console.log("2222", convertBigNumber(await poolContract.connect(walletMe).takeLendWithAddress(walletMe.address), 1));
		
// 		await (await platformContract.connect(walletMe).withdraw(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('500'))).wait();

// 		expect(convertBigNumber(await tokenUSDT.balanceOf(walletMe.address), 1e18)).to.equals('100000');

// 		expect(convertBigNumber((await poolContract.supplys(walletMe.address)).amountSupply, 1e18)).to.equals('0');
// 		expect(convertBigNumber(await poolContract.remainSupply(), 1e18)).to.equals('0');

// 		console.log("3333", convertBigNumber(await poolContract.connect(walletMe).takeLendWithAddress(walletMe.address), 1));
// 		await (await poolContract.connect(walletMe).mint()).wait();
// 		console.log(convertBigNumber(await tokenContract.balanceOf(walletMe.address), 1));
// 		console.log(convertBigNumber(await tokenContract.balanceOf(walletTeam.address), 1));
// 		console.log(convertBigNumber(await tokenContract.balanceOf(walletSpare.address), 1));
// 		console.log(convertBigNumber(await poolContract.connect(walletMe).takeLendWithAddress(walletMe.address), 1));
// 	})

// 	async function sevenInfo() {
// 		let result = {
// 			interestPerSupply: await poolContract.interestPerSupply(),
// 			liquidationPerSupply: await poolContract.liquidationPerSupply(),
// 			interestPerBorrow : await poolContract.interestPerBorrow(),
// 			totalLiquidation: await poolContract.totalLiquidation(),
// 			totalLiquidationSupplyAmount: await poolContract.totalLiquidationSupplyAmount(),
// 			totalBorrow: await poolContract.totalBorrow(),
// 			totalPledge: await poolContract.totalPledge(),
// 			remainSupply: await poolContract.remainSupply(),
// 			lastInterestUpdate: await poolContract.lastInterestUpdate()
// 		};

// 		console.log('===sevenInfo begin===');
// 		for (let k in result) {
// 			console.log(k+':', convertBigNumber(result[k], 1))
// 		}
// 		console.log('===sevenInfo end===')
// 		return result;
// 	};

// 	async function SupplyStruct(user:any) {
// 		let result = await poolContract.supplys(user);

// 		console.log('===SupplyStruct begin===');
// 		for (let k in result) {
// 			console.log(k+':', convertBigNumber(result[k], 1))
// 		}
// 		console.log('===SupplyStruct end===');
// 		return result;
// 	};

// 	async function BorrowStruct(user:any) {
// 		let result = await poolContract.borrows(user);

// 		console.log('===BorrowStruct begin===');
// 		for (let k in result) {
// 			console.log(k+':', convertBigNumber(result[k], 1))
// 		}
// 		console.log('===BorrowStruct end===');
// 		return result;
// 	};

// 	it('deposit(1000) -> borrow(100) -> repay(100) -> withdraw(1000)', async() => {
// 		await(await platformContract.connect(walletMe).deposit(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('1000'))).wait();
// 		console.log('after deposit: ', 
// 			'pool USDT', convertBigNumber(await tokenUSDT.balanceOf(poolContract.address), 1), 
// 			'pool LP', convertBigNumber(await tokenLP.balanceOf(poolContract.address), 1));

// 		let maxBorrow = await poolContract.getMaximumBorrowAmount(ethers.utils.parseEther('100'));
// 		console.log('maxBorrow:', convertBigNumber(maxBorrow, 1), 'USDT');
// 		await(await platformContract.connect(walletOther).borrow(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('100'), maxBorrow)).wait();
// 		console.log('after borrow: ', 
// 			'wallet USDT', convertBigNumber(await tokenUSDT.balanceOf(walletOther.address), 1),
// 			'wallet LP', convertBigNumber(await tokenLP.balanceOf(walletOther.address), 1),
// 			'pool USDT', convertBigNumber(await tokenUSDT.balanceOf(poolContract.address), 1), 
// 			'pool LP', convertBigNumber(await tokenLP.balanceOf(poolContract.address), 1));

// 		console.log('getInterests:', convertBigNumber(await poolContract.getInterests(),1));

// 		console.log('before repay:', 
// 			convertBigNumber(await tokenUSDT.balanceOf(walletOther.address), 1e18),
// 			convertBigNumber(await tokenLP.balanceOf(walletOther.address), 1e18));

// 		tx = await platformContract.connect(walletOther).repay(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('100'));
// 		let receipt = await tx.wait()
// 		console.log('repay gas:', receipt.gasUsed.toString())
// 		// console.log('events:', receipt.events)
// 		// console.log(receipt.events[2].event, 'args:', receipt.events[2].args)
// 		// console.log('_supplyAmount:', convertBigNumber(receipt.events[2].args._supplyAmount, 1))
// 		// console.log('_collateralAmount:', convertBigNumber(receipt.events[2].args._collateralAmount, 1))
// 		// console.log('_interestAmount:', convertBigNumber(receipt.events[2].args._interestAmount, 1))

		 
// 		await strategy.connect(walletOther).mint();
// 		console.log('after repay with UNI: ', 
// 			convertBigNumber(await tokenUSDT.balanceOf(poolContract.address), 1), 
// 			convertBigNumber(await tokenLP.balanceOf(poolContract.address), 1),
// 			convertBigNumber(await tokenLP.balanceOf(walletOther.address), 1),
// 			convertBigNumber(await rewardToken.balanceOf(walletOther.address), 1), 
// 			convertBigNumber(await rewardToken.balanceOf(strategy.address), 1));

// 		// await SupplyStruct(walletMe.address);
// 		// await sevenInfo();
// 		await platformContract.connect(walletMe).withdraw(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('1000'));
// 		console.log('after withdraw: ', 
// 			convertBigNumber(await tokenUSDT.balanceOf(poolContract.address), 1), 
// 			convertBigNumber(await tokenLP.balanceOf(poolContract.address), 1));
// 		console.log('wallet team:', convertBigNumber(await tokenUSDT.balanceOf(walletTeam.address),1e18))
// 	});

// 	it('deposit(1000) -> borrow(100) -> liquidation(100) -> withdraw(1000)', async() => {
// 		await(await platformContract.connect(walletMe).deposit(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('1000'))).wait();
// 		console.log('after deposit: ', 
// 			convertBigNumber(await tokenUSDT.balanceOf(poolContract.address), 1), 
// 			convertBigNumber(await tokenLP.balanceOf(poolContract.address), 1));
// 		let maxBorrow = await poolContract.getMaximumBorrowAmount(ethers.utils.parseEther('10000'));
// 		console.log('max borrow', convertBigNumber(maxBorrow, 1e18));
// 		await(await platformContract.connect(walletOther).borrow(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('10000'), maxBorrow)).wait();
// 		console.log('after borrow: ', 
// 			convertBigNumber(await tokenUSDT.balanceOf(poolContract.address), 1), 
// 			convertBigNumber(await tokenLP.balanceOf(poolContract.address), 1));
// 		await(await platformContract.connect(walletDeveloper).updatePoolParameter(
// 			tokenUSDT.address, tokenLP.address, ethers.utils.formatBytes32String("POOL_PRICE"), ethers.utils.parseEther('0.01'))).wait();

// 		let poolPrice = convertBigNumber(await configContract.getPoolValue(poolContract.address, ethers.utils.formatBytes32String("POOL_PRICE")), 1e18);
// 		let amountCollateral = convertBigNumber((await poolContract.borrows(walletOther.address)).amountCollateral, 1e18);
// 		let amountBorrow = convertBigNumber((await poolContract.borrows(walletOther.address)).amountBorrow, 1e18);

// 		console.log(poolPrice, amountCollateral, amountBorrow);

// 		await(await platformContract.connect(walletMe).liquidation(tokenUSDT.address, tokenLP.address, walletOther.address)).wait();
// 		console.log('after liquidation: ', 
// 			convertBigNumber(await tokenUSDT.balanceOf(poolContract.address), 1), 
// 			convertBigNumber(await tokenLP.balanceOf(poolContract.address), 1));

// 		// await SupplyStruct(walletMe.address);
// 		// await sevenInfo();
// 		await(await platformContract.connect(walletDeveloper).updatePoolParameter(
// 			tokenUSDT.address, tokenLP.address, ethers.utils.formatBytes32String("POOL_PRICE"), ethers.utils.parseEther('0.02'))).wait();
// 		await(await platformContract.connect(walletMe).withdraw(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('1000'))).wait();

// 		console.log('after withdraw: ', 
// 			convertBigNumber(await tokenUSDT.balanceOf(poolContract.address), 1), 
// 			convertBigNumber(await tokenLP.balanceOf(poolContract.address), 1));
// 		console.log('wallet team:', convertBigNumber(await tokenUSDT.balanceOf(walletTeam.address),1e18))
// 	});

// 	it('deposit(1000) -> borrow(100) -> liquidation(100) -> reinvest() -> withdraw(1000)', async() => {
// 		await(await platformContract.connect(walletMe).deposit(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('1000'))).wait();
// 		console.log('after deposit: ', 
// 			convertBigNumber(await tokenUSDT.balanceOf(poolContract.address), 1), 
// 			convertBigNumber(await tokenLP.balanceOf(poolContract.address), 1));
// 		let maxBorrow = await poolContract.getMaximumBorrowAmount(ethers.utils.parseEther('10000'));
// 		console.log('before borrow', 
// 			convertBigNumber(await tokenLP.balanceOf(walletOther.address), 1), 
// 			convertBigNumber(await tokenUSDT.balanceOf(walletOther.address), 1)
// 			)
// 		await(await platformContract.connect(walletOther).borrow(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('10000'), maxBorrow)).wait();
// 		console.log('after borrow: ', 
// 			convertBigNumber(await tokenUSDT.balanceOf(poolContract.address), 1), 
// 			convertBigNumber(await tokenUSDT.balanceOf(poolContract.address), 1));

// 		await(await platformContract.connect(walletDeveloper).updatePoolParameter(
// 			tokenUSDT.address, tokenLP.address, ethers.utils.formatBytes32String("POOL_PRICE"), ethers.utils.parseEther('0.01'))).wait();
// 		await(await platformContract.connect(walletMe).liquidation(tokenUSDT.address, tokenLP.address, walletOther.address)).wait();

// 		console.log('after liquidation: ', 
// 			convertBigNumber(await tokenUSDT.balanceOf(poolContract.address), 1), 
// 			convertBigNumber(await tokenUSDT.balanceOf(poolContract.address), 1));
// 		let tx = await poolContract.liquidationHistory(walletOther.address, 0);

// 		// console.log(tx)
// 		// await SupplyStruct(walletMe.address);
// 		// console.log('wallet team:', convertBigNumber(await tokenUSDT.balanceOf(walletTeam.address),1e18))
// 		await(await platformContract.connect(walletMe).reinvest(tokenUSDT.address, tokenLP.address)).wait();
// 		console.log('after reinvest');
// 		// console.log('wallet team:', convertBigNumber(await tokenUSDT.balanceOf(walletTeam.address),1e18))
// 		// await SupplyStruct(walletMe.address);
// 		// await sevenInfo();
// 		await(await platformContract.connect(walletDeveloper).updatePoolParameter(
// 			tokenUSDT.address, tokenLP.address, ethers.utils.formatBytes32String("POOL_PRICE"), ethers.utils.parseEther('0.02'))).wait(); 

// 		console.log('before withdraw');
// 		await platformContract.connect(walletMe).withdraw(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('1000'));

// 		console.log('after withdraw: ', 
// 			convertBigNumber(await tokenUSDT.balanceOf(poolContract.address), 1), 
// 			convertBigNumber(await tokenUSDT.balanceOf(poolContract.address), 1));
// 		// await sevenInfo();
// 	});

// 	it('liquidation list test', async() => {
// 		// console.log('1')
// 		// await platformContract.connect(walletMe).deposit(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('1000'));
// 		// console.log('2')
// 		// await tokenLP.connect(walletOther).transfer(wallet1.address, ethers.utils.parseEther('1000'));
// 		// await tokenLP.connect(walletOther).transfer(wallet2.address, ethers.utils.parseEther('1000'));
// 		// await tokenLP.connect(walletOther).transfer(wallet3.address, ethers.utils.parseEther('1000'));
// 		// await tokenLP.connect(walletOther).transfer(wallet4.address, ethers.utils.parseEther('1000'));
// 		// console.log('3')
// 		// await tokenLP.connect(wallet1).approve(poolContract.address, ethers.utils.parseEther('1000000'));
// 		// await tokenLP.connect(wallet2).approve(poolContract.address, ethers.utils.parseEther('1000000'));
// 		// await tokenLP.connect(wallet3).approve(poolContract.address, ethers.utils.parseEther('1000000'));
// 		// await tokenLP.connect(wallet4).approve(poolContract.address, ethers.utils.parseEther('1000000'));
// 		// // console.log('wallet team2:', convertBigNumber(await tokenUSDT.balanceOf(walletTeam.address),1e18))
// 		// console.log('4')
// 		// await platformContract.connect(wallet1).borrow(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('1000'), ethers.utils.parseEther('1'));
// 		// // await platformContract.connect(wallet2).borrow(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('1000'), ethers.utils.parseEther('1'));
// 		// // await platformContract.connect(wallet3).borrow(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('1000'), ethers.utils.parseEther('1'));
// 		// // await platformContract.connect(wallet4).borrow(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('1000'), ethers.utils.parseEther('1'));
// 		// //await platformContract.connect(wallet5).borrow(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('1000'), ethers.utils.parseEther('1'));
// 		// console.log('5')
// 		// await platformContract.connect(walletMe).withdraw(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('500'));
// 		// // console.log('wallet share:', convertBigNumber(await tokenUSDT.balanceOf(shareContract.address),1e18))
// 		// // console.log('wallet team3:', convertBigNumber(await tokenUSDT.balanceOf(walletTeam.address),1e18))
// 		// // console.log('user:', await mintContract.connect(walletOther).numberOfLender(), await mintContract.connect(walletOther).numberOfBorrower());
// 		// console.log('6')
// 		// await platformContract.connect(walletDeveloper).updatePoolParameter(
// 		// 	tokenUSDT.address, tokenLP.address, ethers.utils.formatBytes32String("POOL_PRICE"), ethers.utils.parseEther('0')); 
// 		// // console.log('wallet team4:', convertBigNumber(await tokenUSDT.balanceOf(walletTeam.address),1e18))
// 		// // await platformContract.connect(walletDeveloper).updatePoolParameter(
// 		// // 	tokenUSDT.address, tokenLP.address, ethers.utils.formatBytes32String("POOL_PRICE"), ethers.utils.parseEther('0.001')); 
// 		// await platformContract.connect(walletMe).liquidation(tokenUSDT.address, tokenLP.address, wallet1.address);


// 		// await platformContract.connect(walletMe).withdraw(tokenUSDT.address, tokenLP.address, ethers.utils.parseEther('500'));

// 		// // console.log('hello world')

// 		// let tx = await queryContract.iterateLiquidationInfo(0, 0, 10);

// 		// for(var i = 0 ;i < tx.liquidationCount.toNumber(); i ++)
// 		// {
// 		// 	console.log(tx.liquidationList[i].user, tx.liquidationList[i].expectedRepay.toString(), tx.liquidationList[i].amountCollateral.toString())
// 		// }


// 		// console.log(tx.liquidationCount.toString())
// 		// console.log(tx.poolIndex.toString())
// 		// console.log(tx.userIndex.toString())
// 		//1000000000000000000000
// 		//   1000000038717656007
// 	});

// 	it('test circuit breaker', async()=>{
// 		console.log('wallet team:', convertBigNumber(await tokenUSDT.balanceOf(walletTeam.address),1e18))
// 		console.log('wallet share:', convertBigNumber(await tokenUSDT.balanceOf(shareContract.address),1e18))

// 		// let priceDurationKey = ethers.utils.formatBytes32String('POOL_LIQUIDATION_RATE');
// 		// let price002 = ethers.utils.parseEther('0.002')
// 		// let price001 = ethers.utils.parseEther('0.001')
// 		// console.log((await configContract.params(priceDurationKey)).toString())
// 		// // await configContract.connect(walletPrice).setPoolPrice([poolContract.address], [price002]); 
// 		// expect(await configContract.connect(walletPrice).setPoolPrice([poolContract.address], [price002])).to.be.revertedWith('7UP: Price FORBIDDEN'); 
// 		// console.log('hello world')
// 		// expect(await configContract.connect(walletPrice).setPoolPrice([poolContract.address], [price002])).to.be.revertedWith('7UP: Price FORBIDDEN'); 
		
// 		// await configContract.connect(walletDeveloper).setParameter([priceDurationKey],[0]);
// 		// console.log((await configContract.params(priceDurationKey)).toString())
// 		// expect(await configContract.connect(walletPrice).setPoolPrice([poolContract.address], [price002])).to.be.revertedWith('7UP: Config FORBIDDEN'); 
// 		// console.log('set price to 0.002')
// 		// await configContract.connect(walletPrice).setPoolPrice([poolContract.address], [price002]); 
// 		// console.log('set price to 0.001')
// 		// await configContract.connect(walletDeveloper).setPoolPrice([poolContract.address], [ethers.utils.parseEther('0.001')]); 
// 	});

// 	it('test withdrawable/reinvestable', async() => {
// 		let platformShare = await configContract.getValue(ethers.utils.formatBytes32String('INTEREST_PLATFORM_SHARE'));
// 		let totalSupply = (await poolContract.totalBorrow()).add(await poolContract.remainSupply());
// 		let interestPerSupply = await poolContract.interestPerSupply(); 
// 		let interests = await poolContract.getInterests();
// 		let totalBorrow = await poolContract.totalBorrow();
// 		let meInterests = (await poolContract.supplys(walletMe.address)).interests;
// 		let interestSettled = (await  poolContract.supplys(walletMe.address)).interestSettled;
// 		let meSupply = (await poolContract.supplys(walletMe.address)).amountSupply;
// 		let remainSupply = (await poolContract.remainSupply());
// 		let deltaBlock = (await provider.getBlockNumber()) - (await poolContract.lastInterestUpdate());

// 		meInterests = meInterests.add(interestPerSupply.mul(meSupply).div(ethers.utils.parseEther('1')).sub(interestSettled));

// 		console.log('deltaBlock=', deltaBlock);
// 		console.log('totalSupply=', convertBigNumber(totalSupply, 1e18));
// 		console.log('interestPerSupply=', convertBigNumber(interestPerSupply, 1e18));
// 		console.log('interests=', convertBigNumber(interests, 1e18));
// 		console.log('totalBorrow=', convertBigNumber(totalBorrow, 1e18));
// 		console.log('meInterests=', convertBigNumber(meInterests, 1e18));
// 		console.log('interestSettled=', convertBigNumber(interestSettled, 1e18));
// 		console.log('meSupply=', convertBigNumber(meSupply,1e18));
// 		console.log('platformShare=', convertBigNumber(platformShare, 1e18));
// 		console.log('remainSupply=', convertBigNumber(remainSupply, 1e18));

// 		//test reinvestable :
// 		let reinvestAmount = meInterests * platformShare / 1e18
// 		if(reinvestAmount < remainSupply)
// 		{
// 			console.log('ok to invest');
// 		}
// 		else 
// 		{
// 			console.log('not enough money to pay');
// 		}

// 		//test withdrawable :
// 		let a = meInterests - meInterests.mul(platformShare).div(ethers.utils.parseEther('1'));
// 		console.log('a=', a);
// 		let withdrawAmount = meSupply.add(a);
// 		console.log('withdrawAmount=', convertBigNumber(withdrawAmount, 1e18));
// 		if(withdrawAmount < remainSupply)
// 		{
// 			console.log('ok  to withdraw');
// 		}
// 		else
// 		{
// 			console.log('not enough money to withdraw');
// 		}
// 	})

// })
