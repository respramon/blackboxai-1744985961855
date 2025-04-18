const EHR = artifacts.require("EHR");
const fs = require('fs');
const path = require('path');

module.exports = async function(deployer, network, accounts) {
  try {
    // Deploy the EHR contract
    await deployer.deploy(EHR);
    const ehrContract = await EHR.deployed();

    console.log('EHR contract deployed at:', ehrContract.address);

    // Save the contract address and ABI to a JSON file
    const contractData = {
      address: ehrContract.address,
      abi: ehrContract.abi,
      network: network,
      deployedAt: new Date().toISOString()
    };

    // Create the contract data directory if it doesn't exist
    const contractDataDir = path.join(__dirname, '../../api/blockchain/contracts');
    if (!fs.existsSync(contractDataDir)) {
      fs.mkdirSync(contractDataDir, { recursive: true });
    }

    // Write the contract data to a JSON file
    fs.writeFileSync(
      path.join(contractDataDir, 'EHR.json'),
      JSON.stringify(contractData, null, 2)
    );

    // If we're not in development, verify the contract on Etherscan
    if (network !== 'development' && network !== 'test') {
      try {
        await hre.run("verify:verify", {
          address: ehrContract.address,
          constructorArguments: []
        });
        console.log('Contract verified on Etherscan');
      } catch (error) {
        console.error('Error verifying contract:', error);
      }
    }

    // Update the .env file with the contract address
    const envPath = path.join(__dirname, '../../api/.env');
    if (fs.existsSync(envPath)) {
      let envContent = fs.readFileSync(envPath, 'utf8');
      const addressRegex = /EHR_CONTRACT_ADDRESS=.*/;
      const newAddressLine = `EHR_CONTRACT_ADDRESS=${ehrContract.address}`;

      if (addressRegex.test(envContent)) {
        // Replace existing contract address
        envContent = envContent.replace(addressRegex, newAddressLine);
      } else {
        // Add new contract address
        envContent += `\n${newAddressLine}`;
      }

      fs.writeFileSync(envPath, envContent);
      console.log('.env file updated with contract address');
    }

  } catch (error) {
    console.error('Error during deployment:', error);
    throw error;
  }
};
