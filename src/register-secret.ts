import 'dotenv/config'; 
import fs from 'fs'
import {registerEntitySecretCiphertext} from '@circle-fin/developer-controlled-wallets'

(async function main() {
  const apiKey = process.env.CIRCLE_API_KEY;
  const entitySecret = process.env.CIRCLE_ENTITY_SECRET!

  if (!apiKey || !entitySecret) {
    throw new Error(
      "CIRCLE_API_KEY is required. Add it to .env or set it as an environment variable."
    );
  }

  const response = await registerEntitySecretCiphertext({
    apiKey,
    entitySecret,
    recoveryFileDownloadPath: '',
  });

  fs.writeFileSync(
    'recovery_file_data', 
    response.data?.recoveryFile ?? '',
  )

  console.log("Entity secret registered and recovery file saved")
})()
