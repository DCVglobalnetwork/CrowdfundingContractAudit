// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {SafeMath} from "../lib/openzeppelin-contracts-upgradeable/contracts/governance/utils/SafeMath.sol";

/// @title CrowdfundingContract
/// @notice This contract enables users to contribute funds towards a specific goal within a set duration.
///         The owner can withdraw funds if the goal is met and the campaign duration has ended.
///         Contributors can request a refund if the goal is not met within the campaign duration.
contract CrowdfundingContract is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMath for uint;

    /// @notice The funding goal in wei.
    uint public immutable goal;

    /// @notice The campaign deadline as a Unix timestamp.
    uint public immutable deadline;

    /// @notice The total amount of funds raised so far.
    uint public fundsRaised;

    /// @notice Indicates whether the contract is paused.
    bool public paused = false;

    /// @notice Tracks the amount contributed by each address.
    mapping(address => uint) public contributions;

    /// @dev Emitted when a contribution is received.
    /// @param contributor The address of the contributor.
    /// @param amount The amount contributed in wei.
    event ContributionReceived(address indexed contributor, uint amount);

    /// @dev Emitted when funds are withdrawn by the owner.
    /// @param owner The address of the contract owner.
    /// @param amount The amount withdrawn in wei.
    event FundsWithdrawn(address indexed owner, uint amount);

    /// @dev Emitted when a refund is issued to a contributor.
    /// @param contributor The address of the contributor.
    /// @param amount The amount refunded in wei.
    event RefundIssued(address indexed contributor, uint amount);

    /// @dev Emitted when the contract is paused.
    event Paused();

    /// @dev Emitted when the contract is unpaused.
    event Unpaused();

    /// @notice Initializes the crowdfunding campaign with a goal and duration.
    /// @param _goal The funding goal in wei.
    /// @param _duration The duration of the campaign in seconds.
    constructor(uint _goal, uint _duration) {
        require(_goal > 0, "Goal must be greater than zero");
        require(_duration > 0, "Duration must be greater than zero");
        goal = _goal;
        deadline = block.timestamp + _duration;
    }

    /// @dev Modifier to ensure functions are only called when the contract is not paused.
    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    /// @dev Modifier to ensure functions are only called when the contract is paused.
    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    /// @notice Pauses the contract, preventing further contributions.
    ///         Only callable by the owner.
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused();
    }

    /// @notice Unpauses the contract, allowing contributions.
    ///         Only callable by the owner.
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused();
    }

    /// @notice Allows users to contribute to the campaign.
    /// @dev Contributions can only be made if the campaign is active and the contract is not paused.
    function contribute() external payable nonReentrant whenNotPaused {
        require(block.timestamp < deadline, "Campaign is over");
        require(msg.value > 0, "Contribution must be greater than zero");
        contributions[msg.sender] = contributions[msg.sender].add(msg.value);
        fundsRaised = fundsRaised.add(msg.value);

        emit ContributionReceived(msg.sender, msg.value);
    }

    /// @notice Allows the owner to withdraw the funds if the goal is met and the campaign has ended.
    /// @dev Transfers the entire balance to the owner and emits a FundsWithdrawn event.
    function withdrawFunds() external onlyOwner nonReentrant whenNotPaused {
        require(block.timestamp >= deadline, "Campaign is not over yet");
        require(fundsRaised >= goal, "Funding goal not reached");
        uint balance = address(this).balance;
        (bool sent, ) = payable(owner()).call{value: balance}("");
        require(sent, "Transfer failed");

        emit FundsWithdrawn(owner(), balance);
    }

    /// @notice Allows contributors to get a refund if the goal is not met by the deadline.
    /// @dev Refunds the contributed amount to the sender and emits a RefundIssued event.
    function getRefund() external nonReentrant whenNotPaused {
        require(block.timestamp >= deadline, "Campaign is not over yet");
        require(fundsRaised < goal, "Funding goal was reached");
        uint amount = contributions[msg.sender];
        require(amount > 0, "No contributions found");
        contributions[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Transfer failed");

        emit RefundIssued(msg.sender, amount);
    }
}
