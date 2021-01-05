let fs = require("fs");
let path = require("path");
const ethers = require("ethers")
const ERC20 = require("../build/ERC20TOKEN.json")
const ONXBallot = require("../build/ONXBallot.json")
const ONXConfig = require("../build/ONXConfig.json")
const ONXPlateForm = require("../build/ONXPlatform.json")
const ONXToken = require("../build/ONXToken")
const ONXPool = require("../build/ONXPool")
const ONXFactory = require("../build/ONXFactory.json")
const ONXGovernance = require("../build/ONXGovernance.json")
const ONXMint = require("../build/ONXMint.json")
const ONXShare = require("../build/ONXShare.json")
const ONXQuery = require("../build/ONXQuery.json")
const MasterChef = require("../build/MasterChef.json");
const CakeLPStrategy = require("../build/CakeLPStrategy.json");

async function run() {
  let res = ethers.utils.keccak256('0x'+ ONXBallot.bytecode)
  console.log(res)
}
run()
