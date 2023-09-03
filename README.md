# NFT Marketplace Smart Contracts

This project demonstrates a NFTs Marketplace smart contract with optimal code and low gas fee on every transaction.

Open terminal/cmd in your project directory, type the following. and deploy these contract on your selected blockchain uisng hardhat tool: 

```shell
npm install -d hardhat
```

You’ll be greeted with a CLI hardhat interface. Select the second option, "Create an empty hardhat.config.js", and press enter.

```sehll
npx hardhat
npm install --save-dev @nomiclabs/hardhat-ethers
```

Make the env file and set envirnmental variable keys and create script/deploy.js file for use your choosen blockcahin network.

For deploy on you selected blockchain network:

```shell
npx hardhat run scripts/deploy.js --network [Your selected blockchain network name]
```

Harhat tool other commands:
```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```
