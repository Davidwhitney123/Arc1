import { ethers } from "ethers";

async function main() {
  const provider = new ethers.JsonRpcProvider("https://rpc.testnet.arc.network");
  
  const CONTRACT = "0xa0c9f29BF93Cabf58d45b19Ca2b19e11e613d303";
  
  const ABI = [
    "function owner() view returns (address)",
    "function matchCount() view returns (uint256)",
    "function usdc() view returns (address)",
  ];
  
  const contract = new ethers.Contract(CONTRACT, ABI, provider);
  
  const owner = await contract.owner();
  console.log("Owner:", owner);
  
  const matchCount = await contract.matchCount();
  console.log("Match count:", matchCount.toString());
  
  const usdc = await contract.usdc();
  console.log("USDC address:", usdc);
}

main().catch(console.error);