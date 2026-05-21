import { ethers } from "ethers";
import * as dotenv from "dotenv";
import * as fs from "fs";
import * as path from "path";

dotenv.config();

async function main() {
  console.log("🚀 Deploying ArtemisB to Arc Testnet...");
  console.log("─────────────────────────────────────────");

  // Network configuration
  const RPC_URL = "https://rpc.testnet.arc.network";
  const PRIVATE_KEY = process.env.PRIVATE_KEY;

  if (!PRIVATE_KEY) {
    throw new Error("PRIVATE_KEY not set in environment variables");
  }

  // Create provider and signer
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const signer = new ethers.Wallet(PRIVATE_KEY, provider);

  console.log("📋 Deploying with account:", signer.address);

  // USDC contract address on Arc Testnet
  const USDC_ARC_TESTNET = "0x3600000000000000000000000000000000000000";
  console.log("💵 USDC Address:", USDC_ARC_TESTNET);

  // Load contract artifact
  console.log("\n⏳ Loading ArtemisB contract...");
  const artifactPath = path.join(
    process.cwd(),
    "artifacts",
    "contracts",
    "ArtemisB.sol",
    "ArtemisB.json"
  );

  if (!fs.existsSync(artifactPath)) {
    throw new Error(
      `Contract artifact not found at ${artifactPath}. Please run 'npx hardhat compile' first.`
    );
  }

  const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));
  const abi = artifact.abi;
  const bytecode = artifact.bytecode;

  // Create contract factory and deploy
  const factory = new ethers.ContractFactory(abi, bytecode, signer);
  const artemisB = await factory.deploy(USDC_ARC_TESTNET);

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
