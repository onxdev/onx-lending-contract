let fs = require("fs");
let path = require("path");
const ethers = require("ethers")
const ERC20 = require("../build/ERC20TOKEN.json")
const UNIPAIR = require("../build/UniswapPairTest.json")
const ONXBallot = require("../build/ONXBallot.json")
const ONXConfig = require("../build/ONXConfig.json")
const ONXPlateForm = require("../build/ONXPlatform.json")
const ONXToken = require("../build/ONXToken")
const ONXPool = require("../build/ONXPool")
const ONXFactory = require("../build/ONXFactory.json")
const ONXGovernance = require("../build/ONXGovernance.json")
const ONXMint = require("../build/ONXMint.json")
const ONXShare = require("../build/ONXShare.json")
const ONXReward = require("../build/ONXReward.json")
const ONXQuery = require("../build/ONXQuery.json")
const ONXQuery2 = require("../build/ONXQuery2.json")
const MasterChef = require("../build/MasterChef.json");
const CakeLPStrategy = require("../build/CakeLPStrategy.json");

let ONX_ADDRESS = ""
let USDT_ADDRESS = ""
let BUSD_ADDRESS = ""
let LP_TOKEN_ADDRESS = ""
let REWARD_TOKEN_ADDRESS = ""
let PLATFORM_ADDRESS = ""
let GOVERNANCE_ADDRESS = ""
let CONFIG_ADDRESS = ""
let FACTORY_ADDRESS = ""
let MINT_ADDRESS = ""
let SHARE_ADDRESS = ""
let REWARD_ADDRESS = ""
let QUERY_ADDRESS = ""
let QUERY2_ADDRESS = ""

let MASTERCHEF_ADDRESS = ""
let STRATEGY_ADDRESS = ""
let STRATEGY2_ADDRESS = ""

let WBTC_TOKEN_ADDRESS = ""
let BURGER_TOKEN_ADDRESS = ""


let config = {
    "url": "",
    "pk": "",
    "gasPrice": "10",
    "walletDev": "", 
    "walletTeam": "", 
    "walletSpare": "", 
    "walletPrice": "",
    "users":[]
}

if(fs.existsSync(path.join(__dirname, ".config.json"))) {
    let _config = JSON.parse(fs.readFileSync(path.join(__dirname, ".config.json")).toString());
    for(let k in config) {
        config[k] = _config[k];
    }
}

let ETHER_SEND_CONFIG = {
    gasPrice: ethers.utils.parseUnits(config.gasPrice, "gwei")
}
  

console.log("current endpoint  ", config.url)
let provider = new ethers.providers.JsonRpcProvider(config.url)
let walletWithProvider = new ethers.Wallet(config.pk, provider)

function getWallet(key = config.pk) {
  return new ethers.Wallet(key, provider)
}

const sleep = ms =>
  new Promise(resolve =>
    setTimeout(() => {
      resolve()
    }, ms)
  )

async function waitForMint(tx) {
  console.log('tx:', tx)
  let result = null
  do {
    result = await provider.getTransactionReceipt(tx)
    await sleep(100)
  } while (result === null)
  await sleep(200)
}

async function getBlockNumber() {
  return await provider.getBlockNumber()
}

async function deploy() {
  
  // erc 20 Token
  let factory = new ethers.ContractFactory(
    ERC20.abi,
    ERC20.bytecode,
    walletWithProvider
  )
  let ins = await factory.deploy('USDT','USDT','18','100000000000000000000000000',ETHER_SEND_CONFIG)
  await waitForMint(ins.deployTransaction.hash)
  USDT_ADDRESS = ins.address

  ins = await factory.deploy('BUSDT','BUSD','18','100000000000000000000000000',ETHER_SEND_CONFIG)
  await waitForMint(ins.deployTransaction.hash)
  BUSD_ADDRESS = ins.address

  ins = await factory.deploy('CAKE','CAKE','18','100000000000000000000000000',ETHER_SEND_CONFIG)
  await waitForMint(ins.deployTransaction.hash)
  REWARD_TOKEN_ADDRESS = ins.address

  ins = await factory.deploy('WBTC','WBTC','18','100000000000000000000000000',ETHER_SEND_CONFIG)
  await waitForMint(ins.deployTransaction.hash)
  WBTC_TOKEN_ADDRESS = ins.address

  ins = await factory.deploy('BURGER','BURGER','18','100000000000000000000000000',ETHER_SEND_CONFIG)
  await waitForMint(ins.deployTransaction.hash)
  BURGER_TOKEN_ADDRESS = ins.address

  // LP
  factory = new ethers.ContractFactory(
    UNIPAIR.abi,
    UNIPAIR.bytecode,
    walletWithProvider
  )
  ins = await factory.deploy(ETHER_SEND_CONFIG)
  await waitForMint(ins.deployTransaction.hash)
  LP_TOKEN_ADDRESS = ins.address
  
  // PLATFORM
  factory = new ethers.ContractFactory(
    ONXPlateForm.abi,
    ONXPlateForm.bytecode,
    walletWithProvider
  )
  ins = await factory.deploy(ETHER_SEND_CONFIG)
  await waitForMint(ins.deployTransaction.hash)
  PLATFORM_ADDRESS = ins.address

  // ONX
  factory = new ethers.ContractFactory(
    ONXToken.abi,
    ONXToken.bytecode,
    walletWithProvider
  )
  ins = await factory.deploy(ETHER_SEND_CONFIG)
  await waitForMint(ins.deployTransaction.hash)
  ONX_ADDRESS = ins.address

  // GOVERNANCE
  factory = new ethers.ContractFactory(
    ONXGovernance.abi,
    ONXGovernance.bytecode,
    walletWithProvider
  )
  ins = await factory.deploy(ETHER_SEND_CONFIG)
  await waitForMint(ins.deployTransaction.hash)
  GOVERNANCE_ADDRESS = ins.address

  // CONFIG
  factory = new ethers.ContractFactory(
    ONXConfig.abi,
    ONXConfig.bytecode,
    walletWithProvider
  )
  ins = await factory.deploy(ETHER_SEND_CONFIG)
  await waitForMint(ins.deployTransaction.hash)
  CONFIG_ADDRESS = ins.address

  // FACTORY
  factory = new ethers.ContractFactory(
    ONXFactory.abi,
    ONXFactory.bytecode,
    walletWithProvider
  )
  ins = await factory.deploy(ETHER_SEND_CONFIG)
  await waitForMint(ins.deployTransaction.hash)
  FACTORY_ADDRESS = ins.address

  // MINT
  factory = new ethers.ContractFactory(
    ONXMint.abi,
    ONXMint.bytecode,
    walletWithProvider
  )
  ins = await factory.deploy(ETHER_SEND_CONFIG)
  await waitForMint(ins.deployTransaction.hash)
  MINT_ADDRESS = ins.address

  // SHARE
  factory = new ethers.ContractFactory(
    ONXShare.abi,
    ONXShare.bytecode,
    walletWithProvider
  )
  ins = await factory.deploy(ETHER_SEND_CONFIG)
  await waitForMint(ins.deployTransaction.hash)
  SHARE_ADDRESS = ins.address

  // REWARD
  factory = new ethers.ContractFactory(
    ONXReward.abi,
    ONXReward.bytecode,
    walletWithProvider
  )
  ins = await factory.deploy(ETHER_SEND_CONFIG)
  await waitForMint(ins.deployTransaction.hash)
  REWARD_ADDRESS = ins.address

  // QUERY
  factory = new ethers.ContractFactory(
    ONXQuery.abi,
    ONXQuery.bytecode,
    walletWithProvider
  )
  ins = await factory.deploy(ETHER_SEND_CONFIG)
  await waitForMint(ins.deployTransaction.hash)
  QUERY_ADDRESS = ins.address

  // QUERY2
  factory = new ethers.ContractFactory(
    ONXQuery2.abi,
    ONXQuery2.bytecode,
    walletWithProvider
  )
  ins = await factory.deploy(ETHER_SEND_CONFIG)
  await waitForMint(ins.deployTransaction.hash)
  QUERY2_ADDRESS = ins.address

  // MASTERCHEF
  factory = new ethers.ContractFactory(
    MasterChef.abi,
    MasterChef.bytecode,
    walletWithProvider
  )
  ins = await factory.deploy(REWARD_TOKEN_ADDRESS, REWARD_TOKEN_ADDRESS, config.walletDev, 20000000, 0, ETHER_SEND_CONFIG)
  await waitForMint(ins.deployTransaction.hash)
  MASTERCHEF_ADDRESS = ins.address

}

async function initialize() {
    let ins = new ethers.Contract(
        SHARE_ADDRESS,
        ONXShare.abi,
        getWallet()
      )
    let tx = await ins.setupConfig(CONFIG_ADDRESS, ETHER_SEND_CONFIG)
    await waitForMint(tx.hash)

    ins = new ethers.Contract(
        FACTORY_ADDRESS,
        ONXFactory.abi,
        getWallet()
      )
    tx = await ins.setupConfig(CONFIG_ADDRESS, ETHER_SEND_CONFIG)
    await waitForMint(tx.hash)

    let codeHash = ethers.utils.keccak256('0x'+ ONXBallot.bytecode)
    tx = await ins.changeBallotByteHash(codeHash, ETHER_SEND_CONFIG)
    await waitForMint(tx.hash)
    
    ins = new ethers.Contract(
        MINT_ADDRESS,
        ONXMint.abi,
        getWallet()
      )
    tx = await ins.setupConfig(CONFIG_ADDRESS, ETHER_SEND_CONFIG)
    await waitForMint(tx.hash)

    ins = new ethers.Contract(
        PLATFORM_ADDRESS,
        ONXPlateForm.abi,
        getWallet()
      )
    tx = await ins.setupConfig(CONFIG_ADDRESS, ETHER_SEND_CONFIG)
    await waitForMint(tx.hash)

    ins = new ethers.Contract(
        GOVERNANCE_ADDRESS,
        ONXGovernance.abi,
        getWallet()
      )
    tx = await ins.setupConfig(CONFIG_ADDRESS, ETHER_SEND_CONFIG)
    await waitForMint(tx.hash)

    ins = new ethers.Contract(
        ONX_ADDRESS,
        ONXToken.abi,
        getWallet()
      )
    tx = await ins.setupConfig(CONFIG_ADDRESS, ETHER_SEND_CONFIG)
    await waitForMint(tx.hash)

    ins = new ethers.Contract(
        QUERY_ADDRESS,
        ONXQuery.abi,
        getWallet()
      )
    tx = await ins.setupConfig(CONFIG_ADDRESS, ETHER_SEND_CONFIG)
    await waitForMint(tx.hash)

    ins = new ethers.Contract(
        QUERY2_ADDRESS,
        ONXQuery2.abi,
        getWallet()
      )
    tx = await ins.setupConfig(CONFIG_ADDRESS, ETHER_SEND_CONFIG)
    await waitForMint(tx.hash)

    ins = new ethers.Contract(
        CONFIG_ADDRESS,
        ONXConfig.abi,
        getWallet()
      )
    tx = await ins.initialize(
        PLATFORM_ADDRESS, 
        FACTORY_ADDRESS,
        MINT_ADDRESS,
        ONX_ADDRESS,
        SHARE_ADDRESS,
        config.walletDev,
        ETHER_SEND_CONFIG
    )
    console.log('ONXConfig initialize')
    await waitForMint(tx.hash)

    tx = await ins.initParameter(ETHER_SEND_CONFIG)
    console.log('ONXConfig initParameter')
    await waitForMint(tx.hash)

    // tx = await ins.addMintToken(USDT_ADDRESS, ETHER_SEND_CONFIG)
    // console.log('ONXConfig addMintToken')
    // await waitForMint(tx.hash)
    // console.log('ONXConfig addMintToken')
    // tx = await ins.addMintToken(BUSD_ADDRESS, ETHER_SEND_CONFIG)
    // await waitForMint(tx.hash)

    tx = await ins.setWallets(
        [
            ethers.utils.formatBytes32String("team"), 
            ethers.utils.formatBytes32String("spare"), 
            ethers.utils.formatBytes32String("reward"), 
            ethers.utils.formatBytes32String("price")
        ], 
        [
            config.walletTeam, 
            config.walletSpare, 
            REWARD_ADDRESS,
            config.walletPrice
        ],
        ETHER_SEND_CONFIG
    )
    console.log('ONXConfig setWallets')
    await waitForMint(tx.hash)

    ins = new ethers.Contract(
        MINT_ADDRESS,
        ONXMint.abi,
        getWallet()
      )
    tx = await ins.initialize(ETHER_SEND_CONFIG)
    console.log('ONXMint initialize')
    await waitForMint(tx.hash)
    // tx = await ins.changeBorrowPower('5000', ETHER_SEND_CONFIG)
    // await waitForMint(tx.hash)
    // tx = await ins.changeInterestRatePerBlock('1000000000000000000',ETHER_SEND_CONFIG)
    // await waitForMint(tx.hash)

    ins = new ethers.Contract(
        REWARD_ADDRESS,
        ONXReward.abi,
        getWallet()
      )
    tx = await ins.initialize(BURGER_TOKEN_ADDRESS, ONX_ADDRESS, ETHER_SEND_CONFIG)
    console.log('ONXReward initialize')
    await waitForMint(tx.hash)

    tx = await ins.changeAmountPerBlock('1000000000000000000')
    console.log('ONXReward changeAmountPerBlock')
    await waitForMint(tx.hash)

    ins = new ethers.Contract(
        ONX_ADDRESS,
        ONXToken.abi,
        getWallet()
      )
    tx = await ins.initialize(ETHER_SEND_CONFIG)
    console.log('ONXToken initialize')
    await waitForMint(tx.hash)


    ins = new ethers.Contract(
      CONFIG_ADDRESS,
      ONXConfig.abi,
      getWallet()
    )
    tx = await ins.initialize(
        PLATFORM_ADDRESS, 
        FACTORY_ADDRESS,
        MINT_ADDRESS,
        ONX_ADDRESS,
        SHARE_ADDRESS,
        GOVERNANCE_ADDRESS,
        ETHER_SEND_CONFIG
    )
    console.log('ONXConfig initialize')
    await waitForMint(tx.hash)
    // tx = await ins.setValue(ethers.utils.formatBytes32String("ONX_USER_MINT"), '3000', ETHER_SEND_CONFIG)
    // await waitForMint(tx.hash)
    // tx = await ins.setValue(ethers.utils.formatBytes32String("ONX_TEAM_MINT"), '7142', ETHER_SEND_CONFIG)
    // await waitForMint(tx.hash)
    // tx = await ins.setValue(ethers.utils.formatBytes32String("ONX_REWAED_MINT"), '5000', ETHER_SEND_CONFIG)
    // await waitForMint(tx.hash)

    // for pool
    ins = new ethers.Contract(
        LP_TOKEN_ADDRESS,
        UNIPAIR.abi,
        getWallet()
      )
    tx = await ins.initialize(WBTC_TOKEN_ADDRESS, USDT_ADDRESS, ETHER_SEND_CONFIG)
    console.log('UNIPAIR initialize')
    await waitForMint(tx.hash)
    tx = await ins.mint(config.walletDev, '100000000000000000000000000', ETHER_SEND_CONFIG)
    console.log('UNIPAIR mint')
    await waitForMint(tx.hash)

    ins = new ethers.Contract(
        MASTERCHEF_ADDRESS,
        MasterChef.abi,
        getWallet()
      )
    tx = await ins.add(100, LP_TOKEN_ADDRESS, false, ETHER_SEND_CONFIG)
    console.log('MasterChef add')
    await waitForMint(tx.hash)

    ins = new ethers.Contract(
        FACTORY_ADDRESS,
        ONXFactory.abi,
        getWallet()
      )
    tx = await ins.createPool(USDT_ADDRESS, LP_TOKEN_ADDRESS, ETHER_SEND_CONFIG)
    console.log('ONXFactory createPool USDT', USDT_ADDRESS)
    await waitForMint(tx.hash)
    let poolAddr = await ins.getPool(USDT_ADDRESS, LP_TOKEN_ADDRESS)
    console.log('pool address:', poolAddr)

    tx = await ins.createPool(BUSD_ADDRESS, LP_TOKEN_ADDRESS, ETHER_SEND_CONFIG)
    console.log('ONXFactory createPool BUSD', BUSD_ADDRESS)
    await waitForMint(tx.hash)
    let poolAddr2 = await ins.getPool(BUSD_ADDRESS, LP_TOKEN_ADDRESS)
    console.log('pool2 address:', poolAddr2)

    // CakeLPStrategy
    factory = new ethers.ContractFactory(
        CakeLPStrategy.abi,
        CakeLPStrategy.bytecode,
        walletWithProvider
    )
    ins = await factory.deploy(ETHER_SEND_CONFIG)
    console.log('CakeLPStrategy deploy')
    await waitForMint(ins.deployTransaction.hash)
    STRATEGY_ADDRESS = ins.address
    tx = await ins.initialize(REWARD_TOKEN_ADDRESS, LP_TOKEN_ADDRESS, poolAddr, MASTERCHEF_ADDRESS, 1, ETHER_SEND_CONFIG)
    console.log('CakeLPStrategy initialize')
    await waitForMint(tx.hash)

    ins = await factory.deploy(ETHER_SEND_CONFIG)
    console.log('CakeLPStrategy deploy')
    await waitForMint(ins.deployTransaction.hash)
    STRATEGY2_ADDRESS = ins.address
    tx = await ins.initialize(REWARD_TOKEN_ADDRESS, LP_TOKEN_ADDRESS, poolAddr2, MASTERCHEF_ADDRESS, 1, ETHER_SEND_CONFIG)
    console.log('CakeLPStrategy initialize')
    await waitForMint(tx.hash)

    ins = new ethers.Contract(
        PLATFORM_ADDRESS,
        ONXPlateForm.abi,
        getWallet()
      )
    tx = await ins.switchStrategy(USDT_ADDRESS, LP_TOKEN_ADDRESS, STRATEGY_ADDRESS, ETHER_SEND_CONFIG)
    console.log('ONXPlateForm switchStrategy')
    await waitForMint(tx.hash)

    tx = await ins.switchStrategy(BUSD_ADDRESS, LP_TOKEN_ADDRESS, STRATEGY2_ADDRESS, ETHER_SEND_CONFIG)
    console.log('ONXPlateForm switchStrategy')
    await waitForMint(tx.hash)

    console.log('transfer...')
    await transfer()
}

async function transfer() {
    ins = new ethers.Contract(
        REWARD_TOKEN_ADDRESS,
        ERC20.abi,
        getWallet()
      )
    tx = await ins.transfer(MASTERCHEF_ADDRESS, '5000000000000000000000', ETHER_SEND_CONFIG)
    await waitForMint(tx.hash)

    for(let user of config.users) {
        ins = new ethers.Contract(
            USDT_ADDRESS,
            ERC20.abi,
            getWallet()
          )
        tx = await ins.transfer(user, '5000000000000000000000', ETHER_SEND_CONFIG)
        await waitForMint(tx.hash)

        ins = new ethers.Contract(
          BUSD_ADDRESS,
          ERC20.abi,
          getWallet()
        )
        tx = await ins.transfer(user, '5000000000000000000000', ETHER_SEND_CONFIG)
        await waitForMint(tx.hash)

        ins = new ethers.Contract(
            BURGER_TOKEN_ADDRESS,
            ERC20.abi,
            getWallet()
          )
        tx = await ins.transfer(user, '5000000000000000000000', ETHER_SEND_CONFIG)
        await waitForMint(tx.hash)

        ins = new ethers.Contract(
            LP_TOKEN_ADDRESS,
            UNIPAIR.abi,
            getWallet()
          )
        tx = await ins.mint(user, '5000000000000000000000', ETHER_SEND_CONFIG)
        await waitForMint(tx.hash)
    }
}

async function run() {
    console.log('deploy...')
    await deploy()
    console.log('initialize...')
    await initialize()
    console.log(`
    ONX_ADDRESS = ${ONX_ADDRESS}
    PLATFORM_ADDRESS = ${PLATFORM_ADDRESS}
    GOVERNANCE_ADDRESS = ${GOVERNANCE_ADDRESS}
    CONFIG_ADDRESS = ${CONFIG_ADDRESS}
    FACTORY_ADDRESS = ${FACTORY_ADDRESS}
    MINT_ADDRESS = ${MINT_ADDRESS}
    SHARE_ADDRESS = ${SHARE_ADDRESS}
    REWARD_ADDRESS = ${REWARD_ADDRESS}
    QUERY_ADDRESS = ${QUERY_ADDRESS}
    QUERY2_ADDRESS = ${QUERY2_ADDRESS}

    ===============================
    MASTERCHEF_ADDRESS = ${MASTERCHEF_ADDRESS}
    STRATEGY_ADDRESS = ${STRATEGY_ADDRESS}
    STRATEGY2_ADDRESS = ${STRATEGY2_ADDRESS}
    
    USDT_ADDRESS = ${USDT_ADDRESS}
    BUSD_ADDRESS = ${BUSD_ADDRESS}
    LP_TOKEN_ADDRESS = ${LP_TOKEN_ADDRESS}
    REWARD_TOKEN_ADDRESS = ${REWARD_TOKEN_ADDRESS}
    BURGER_TOKEN_ADDRESS = ${BURGER_TOKEN_ADDRESS}
    WBTC_TOKEN_ADDRESS = ${WBTC_TOKEN_ADDRESS}
    `)
}

run()
