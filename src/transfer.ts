import 'dotenv/config';
import {initiateDeveloperControlledWalletsClient} from "@circle-fin/developer-controlled-wallets";


const client = initiateDeveloperControlledWalletsClient({ 
    apiKey: process.env.CIRCLE_API_KEY!, 
    entitySecret: process.env.CIRCLE_ENTITY_SECRET!
})

const Wallet_A_ID = process.env.WALLET_A_ID!
const Wallet_B_Address = process.env.WALLET_B_ADDRESS!
const Chain = 'ETH_SEPOLIA'

const response = await client.getWalletTokenBalance({
    id: Wallet_A_ID
})

console.log(response.data?.tokenBalances) 

const USDC_TOKEN_ID = process.env.USDC_ID!

const transfer = await client.createTransaction({
    amount: ['0.01'],
    destinationAddress: Wallet_B_Address,
    tokenId: USDC_TOKEN_ID ,
    walletId: Wallet_A_ID,

  fee: {
    type: 'level',
    config: {
      feeLevel: 'HIGH',
    },
  },
});

console.log("Transfer submitted ID:", transfer.data?.id) 

let state = "INITIATED"
let transactionHash = ""

while(state != "CONFIRMED"){
    const {data} = await client.getTransaction({id: transfer.data?.id!})

    state = data?.transaction?.state!; 
    transactionHash = data?.transaction?.txHash!

    if(state != "CONFIRMED"){
        console.log("status", state)
        await new Promise(r => setTimeout(r, 1000))
    }
}

console.log('Transfer Confirmed')
console.log('Transaction Hash', transactionHash)