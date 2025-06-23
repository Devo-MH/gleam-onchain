// scripts/simulateCampaign.js
const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
  const [deployer, user1, user2, user3, user4, user5] = await ethers.getSigners();

  // 1. Deploy Mock ERC20 token
  const Token = await ethers.getContractFactory("MockERC20");
  const token = await Token.deploy("TestToken", "TT");
  await token.waitForDeployment();
  console.log("🪙 Token deployed at:", token.target);

  // 2. Mint tokens to deployer
  await token.mint(deployer.address, ethers.parseEther("1000"));
  console.log("💸 Minted 1000 TT to deployer");

  // 3. Deploy Campaign contract
  const Campaign = await ethers.getContractFactory("Campaign");
  const campaign = await Campaign.deploy(
    deployer.address,
    token.target,
    ethers.parseEther("100"), // reward pool
    Math.floor(Date.now() / 1000) + 60, // ends in 1 min
    3, // max winners
    ethers.ZeroAddress, // VRF not used locally
    ethers.ZeroHash,
    0
  );
  await campaign.waitForDeployment();
  console.log("🎯 Campaign deployed at:", campaign.target);

  // 4. Fund campaign
  await token.approve(campaign.target, ethers.parseEther("100"));
  await campaign.fundCampaign();
  console.log("✅ Campaign funded");

  // 5. Users join
  const participants = [user1, user2, user3, user4, user5];
  for (const user of participants) {
    await campaign.connect(user).joinCampaign();
    console.log(`👤 ${user.address} joined`);
  }

  // 6. Fast forward time
  await ethers.provider.send("evm_increaseTime", [120]);
  await ethers.provider.send("evm_mine");
  console.log("⏩ Campaign time fast-forwarded");

  // 7. Close campaign
  await campaign.closeCampaign();
  console.log("🔒 Campaign closed");

  // 8. Simulate VRF callback manually
  const mockRandomWords = [123, 456, 789];
  await campaign.mockFulfill(0, mockRandomWords);
  console.log("🧠 Winners fulfilled (mocked)");

  // 9. Read and print winners
  const winners = await campaign.getWinners();
  console.log("🏆 Winners:", winners);

  // 10. Claim rewards
  for (const winner of winners) {
    const signer = await ethers.getSigner(winner);
    await campaign.connect(signer).claimReward();
    const balance = await token.balanceOf(winner);
    console.log(`💸 ${winner} claimed reward — balance: ${ethers.formatEther(balance)} TT`);
  }

  console.log("✅ Campaign simulation completed");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
