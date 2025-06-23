const hre = require("hardhat");
const { ethers } = hre;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contract with account:", deployer.address);

  const Campaign = await ethers.getContractFactory("Campaign");

  // ✅ Replace with actual ERC20 token address you want to use (test token)
  const rewardToken = "0x779877A7B0D9E8603169DdbD7836e478b4624789"; // placeholder

  // ✅ Fixed value parsing for ethers v6
  const rewardAmount = ethers.parseUnits("10", 18); // 10 tokens, 18 decimals
  const endTime = Math.floor(Date.now() / 1000) + 86400; // ends in 24 hours
  const maxWinners = 3;

  // ✅ Chainlink Sepolia VRF details
  const vrfCoordinator = "0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625";
  const keyHash = "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c";
  const subscriptionId = 439256;

  const campaign = await Campaign.deploy(
    deployer.address,
    rewardToken,
    rewardAmount,
    endTime,
    maxWinners,
    vrfCoordinator,
    keyHash,
    subscriptionId
  );

  await campaign.waitForDeployment();

  console.log("✅ Campaign deployed to:", campaign.target);
}

main().catch((error) => {
  console.error("❌ Error during deployment:", error);
  process.exitCode = 1;
});
