const { ethers, upgrades } = require("hardhat");
const { getImplementationAddress } = require("@openzeppelin/upgrades-core");

const delay = (ms:number) => new Promise(resolve => setTimeout(resolve, ms));

async function main() {
  // Deploy the SampleToken contract
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const SampleToken = await ethers.getContractFactory("SampleToken", deployer);
  const token = await SampleToken.deploy("Sample Token", "SMP", "1000000");
  await token.waitForDeployment();
  const tokAddress = await token.getAddress();
  console.log("SampleToken deployed to:", tokAddress);

  await delay(10000);
  await hre.run("verify:verify", {
    address: tokAddress,
    constructorArguments: ["Sample Token", "SMP", "1000000"],
  });

  // Deploy the VestingContractUpgradeable contract
  const VestingContract = await ethers.getContractFactory("VestingContract");
  const vesting = await upgrades.deployProxy(VestingContract, [tokAddress], { initializer: 'initialize' });
  await vesting.waitForDeployment();
  const vestingAddress = await vesting.getAddress();
  console.log("VestingContract deployed to:", vestingAddress);
  
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(vestingAddress);
  console.log("VestingContract implementation deployed to:", implementationAddress);

  await delay(10000);
  await hre.run("verify:verify", {
    address: implementationAddress,
    constructorArguments: [], // Constructor arguments for the proxy contract
  });
  await delay(10000);
  await hre.run("verify:verify", {
    address: vestingAddress,
    constructorArguments: [tokAddress], // Constructor arguments for the proxy contract
  });
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});