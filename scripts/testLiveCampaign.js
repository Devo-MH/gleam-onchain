const { ethers } = require("hardhat");

async function main() {
  const campaignAddress = "0xb68A2c619d6B3Cfe28f77bab6779a76A2DcE1B19";

  // Load deployed contract
  const campaign = await ethers.getContractAt("Campaign", campaignAddress);

  // Get additional signers (deployer is signer[0])
  const signers = await ethers.getSigners();
  const users = signers.slice(1, 6); // Simulate 5 participants

  for (let i = 0; i < users.length; i++) {
    const user = campaign.connect(users[i]);
    try {
      const tx = await user.joinCampaign();
      await tx.wait();
      console.log(`✅ User ${i + 1} (${users[i].address}) joined the campaign`);
    } catch (err) {
      console.log(`⚠️  User ${i + 1} failed to join:`, err.message);
    }
  }

  const participants = await campaign.getParticipants();
  console.log("👥 Current participants:", participants);
}

main().catch(console.error);
