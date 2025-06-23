// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Campaign.sol";

contract CampaignFactory {
    address[] public allCampaigns;

    event CampaignCreated(address indexed creator, address campaignAddress);

    function createCampaign(
    address rewardToken,
    uint256 rewardAmount,
    uint256 endTime,
    uint256 maxWinners,
    address vrfCoordinator,
    bytes32 keyHash,
    uint64 subscriptionId
) external {
    Campaign newCampaign = new Campaign(
        msg.sender,
        rewardToken,
        rewardAmount,
        endTime,
        maxWinners,
        vrfCoordinator,
        keyHash,
        subscriptionId
    );

    allCampaigns.push(address(newCampaign));
    emit CampaignCreated(msg.sender, address(newCampaign));
}


    function getAllCampaigns() external view returns (address[] memory) {
        return allCampaigns;
    }
}
