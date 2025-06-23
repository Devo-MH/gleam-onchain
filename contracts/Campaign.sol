// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Campaign is VRFConsumerBaseV2 {
    using SafeERC20 for IERC20;

    address public creator;
    IERC20 public rewardToken;
    uint256 public rewardAmount;
    uint256 public endTime;
    uint256 public maxWinners;

    address[] public participants;
    mapping(address => bool) public joined;
    mapping(address => bool) public isWinner;
    mapping(address => bool) public hasClaimed;

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 200000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords;

    uint256 public requestId;
    address[] public randomWinners;

    constructor(
        address _creator,
        address _rewardToken,
        uint256 _rewardAmount,
        uint256 _endTime,
        uint256 _maxWinners,
        address vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) VRFConsumerBaseV2(vrfCoordinator) {
        creator = _creator;
        rewardToken = IERC20(_rewardToken);
        rewardAmount = _rewardAmount;
        endTime = _endTime;
        maxWinners = _maxWinners;

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        numWords = uint32(_maxWinners);
    }

    function joinCampaign() external {
        require(block.timestamp < endTime, "Campaign ended");
        require(!joined[msg.sender], "Already joined");

        participants.push(msg.sender);
        joined[msg.sender] = true;
    }

    function fundCampaign() external {
        require(msg.sender == creator, "Only creator");
        rewardToken.safeTransferFrom(msg.sender, address(this), rewardAmount);
    }

    function requestRandomWinners() external {
        require(msg.sender == creator, "Only creator");
        require(block.timestamp >= endTime, "Campaign not ended");
        require(participants.length >= maxWinners, "Not enough participants");

        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        for (uint256 i = 0; i < randomWords.length; i++) {
            uint256 index = randomWords[i] % participants.length;
            address winner = participants[index];
            if (!isWinner[winner]) {
                isWinner[winner] = true;
                randomWinners.push(winner);
            }
        }
    }

    function claimReward() external {
        require(isWinner[msg.sender], "Not a winner");
        require(!hasClaimed[msg.sender], "Already claimed");

        uint256 share = rewardAmount / maxWinners;
        hasClaimed[msg.sender] = true;
        rewardToken.safeTransfer(msg.sender, share);
    }

    function getParticipants() external view returns (address[] memory) {
        return participants;
    }

    function getWinners() external view returns (address[] memory) {
        return randomWinners;
    }
}
