# Crowdfunding Contract Audit Report

## Table of Contents
- [Crowdfunding Contract Audit Report](#crowdfunding-contract-audit-report)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Scope](#scope)
  - [Findings Summary](#findings-summary)
  - [Detailed Findings](#detailed-findings)
    - [Reentrancy Attack](#reentrancy-attack)
    - [Unchecked External Call](#unchecked-external-call)
    - [Input Validation](#input-validation)
    - [Best Practices](#best-practices)
  - [Recommendations](#recommendations)
    - [Use OpenZeppelin Libraries](#use-openzeppelin-libraries)
    - [Add Event Logging](#add-event-logging)
    - [Implement Circuit Breaker Pattern](#implement-circuit-breaker-pattern)
    - [Gas Optimization](#gas-optimization)
    - [Other Improvements](#other-improvements)
  - [Final Implementation](#final-implementation)

## Introduction

This audit report reviews the security and functionality of the Crowdfunding Contract implemented in Solidity. The primary goal of this audit is to identify and address potential vulnerabilities, ensuring the contract adheres to best practices in Solidity development.

## Scope

The audit focuses on the following aspects:
- Security vulnerabilities
- Logical errors
- Adherence to Solidity best practices
- Gas optimization
- Code readability and maintainability

## Findings Summary

- **Reentrancy Attack**: The original contract is susceptible to reentrancy attacks in the `withdrawFunds` and `getRefund` functions.
- **Unchecked External Call**: The contract uses the `call` method for transferring funds without proper checks.
- **Input Validation**: The constructor lacks validation for input parameters.
- **Best Practices**: Missing event logging and circuit breaker mechanism.

## Detailed Findings

### Reentrancy Attack

**Description**: The `withdrawFunds` and `getRefund` functions update state variables after transferring funds, making them vulnerable to reentrancy attacks.

**Recommendation**: Use OpenZeppelin's `ReentrancyGuard` to prevent reentrancy.

### Unchecked External Call

**Description**: The contract uses `call` for transferring funds, which can fail silently.

**Recommendation**: Ensure the return value of `call` is properly checked.

### Input Validation

**Description**: The constructor does not validate the `_goal` and `_duration` parameters.

**Recommendation**: Add validation to ensure these parameters are greater than zero.

### Best Practices

**Description**: The contract lacks event logging for critical functions and a mechanism to pause contract operations in emergencies.

**Recommendation**: Implement event logging and a circuit breaker pattern.

## Recommendations

### Use OpenZeppelin Libraries

Integrate OpenZeppelin's `Ownable` for ownership management and `ReentrancyGuard` for preventing reentrancy attacks.

### Add Event Logging

Emit events for critical actions like contributions, withdrawals, and refunds.

### Implement Circuit Breaker Pattern

Add functionality to pause and unpause the contract to handle emergencies.

### Gas Optimization

Use `SafeMath` for arithmetic operations to prevent overflow and underflow issues.

### Other Improvements

- Add `immutable` keyword for `goal` and `deadline` to optimize gas usage.
- Validate constructor inputs to ensure they are reasonable.
- Consider using `transfer` or `send` for fund transfers to limit gas forwarded and prevent certain reentrancy attacks.

## Final Implementation

Here is the improved and secure version of the Crowdfunding Contract:

```solidity

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
