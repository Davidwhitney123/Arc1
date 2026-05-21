import { ethers } from "ethers";
import hre from "hardhat";

async function main() {
  console.log("🚀 Deploying ArtemisB to Arc Testnet...");
  console.log("─────────────────────────────────────────");

  // Get deployer account
  const [deployer] = await hre.ethers.getSigners();
  console.log("📋 Deploying with account:", deployer.address);

  // USDC contract address on Arc Testnet
  const USDC_ARC_TESTNET = "0x3600000000000000000000000000000000000000";
  console.log("💵 USDC Address:", USDC_ARC_TESTNET);

  // Deploy ArtemisB
  console.log("\n⏳ Deploying ArtemisB contract...");
  const ArtemisB = await hre.ethers.getContractFactory("ArtemisB");
  const artemisB = await ArtemisB.deploy(USDC_ARC_TESTNET);

  // Wait for deployment
  await artemisB.waitForDeployment();

  const contractAddress = await artemisB.getAddress();

  console.log("─────────────────────────────────────────");
  console.log("✅ ArtemisB deployed successfully!");
  console.log("📍 Contract Address:", contractAddress);
  console.log("🔍 View on Explorer:");
  console.log(`   https://testnet.arcscan.app/address/${contractAddress}`);
  console.log("─────────────────────────────────────────");
  console.log("\n📝 Save this contract address — you'll need it for the frontend!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });