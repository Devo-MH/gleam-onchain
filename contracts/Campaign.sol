// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Campaign is VRFConsumerBaseV2, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum CampaignStatus { OPEN, CLOSED, FINISHED }

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
    CampaignStatus public status;

    event CampaignJoined(address indexed participant);
    event WinnerSelected(address indexed winner);
    event RewardClaimed(address indexed claimant, uint256 amount);
    event CampaignFunded(uint256 amount);
    event CampaignClosed();

    modifier onlyCreator() {
        require(msg.sender == creator, "Only creator");
        _;
    }

    modifier inStatus(CampaignStatus _status) {
        require(status == _status, "Invalid campaign status");
        _;
    }

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
        status = CampaignStatus.OPEN;
    }

    function joinCampaign() external inStatus(CampaignStatus.OPEN) {
        require(block.timestamp < endTime, "Campaign ended");
        require(!joined[msg.sender], "Already joined");

        participants.push(msg.sender);
        joined[msg.sender] = true;

        emit CampaignJoined(msg.sender);
    }

    function fundCampaign() external onlyCreator inStatus(CampaignStatus.OPEN) {
        rewardToken.safeTransferFrom(msg.sender, address(this), rewardAmount);
        emit CampaignFunded(rewardAmount);
    }

    function closeCampaign() external onlyCreator inStatus(CampaignStatus.OPEN) {
        require(block.timestamp >= endTime, "Campaign not yet ended");
        require(participants.length >= maxWinners, "Not enough participants");

        status = CampaignStatus.CLOSED;
        emit CampaignClosed();
    }

    function requestRandomWinners() external onlyCreator inStatus(CampaignStatus.CLOSED) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        uint256 attempts = 0;
        for (uint256 i = 0; i < randomWords.length && randomWinners.length < maxWinners; i++) {
            uint256 index = randomWords[i] % participants.length;
            address winner = participants[index];
            if (!isWinner[winner]) {
                isWinner[winner] = true;
                randomWinners.push(winner);
                emit WinnerSelected(winner);
            } else {
                // If duplicate, try more randomness if needed
                attempts++;
            }
        }
        status = CampaignStatus.FINISHED;
    }

    function claimReward() external nonReentrant inStatus(CampaignStatus.FINISHED) {
        require(isWinner[msg.sender], "Not a winner");
        require(!hasClaimed[msg.sender], "Already claimed");

        uint256 share = rewardAmount / maxWinners;
        hasClaimed[msg.sender] = true;
        rewardToken.safeTransfer(msg.sender, share);

        emit RewardClaimed(msg.sender, share);
    }

    function getParticipants() external view returns (address[] memory) {
        return participants;
    }

    function getWinners() external view returns (address[] memory) {
        return randomWinners;
    }
    // ONLY for testing locally! Remove on mainnet!
function mockFulfill(uint256 _reqId, uint256[] memory randomWords) external {
    fulfillRandomWords(_reqId, randomWords);
}


} 
