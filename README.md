# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.ts
```

Hi,
Here are the modifications you need to make to the vesting contract:

- Two simple vesting type, with 25% and 50% release after 12 months.

- The custom vesting schedule must have the percentage release (10, 20, 25, 30, 50) instead of release amount.

- The Deposit token function must have a function to stop paying for a participant that's no longer working with us.

Other related tasks:

 - Create a document describing all parts and functions in the "read as proxy" and "write as proxy".

- Create an interface for the vesting contract