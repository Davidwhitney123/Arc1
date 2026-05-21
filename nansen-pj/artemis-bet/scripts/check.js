import { ethers } from "ethers";

async function main() {
  const provider = new ethers.JsonRpcProvider("https://rpc.testnet.arc.network");
  
  const CONTRACT_ADDRESS = "0xa0c9f29BF93Cabf58d45b19Ca2b19e11e613d303";
  const ABI = ["function owner() view returns (address)"];
  
  const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, provider);
  const owner = await contract.owner();
  console.log("Contract owner:", owner);
}

main().catch(console.error);