// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {CrowdfundingContract} from "../src/CrowdfundingContract.sol";

/// @title CrowdfundingContractTest
/// @notice This contract is used to test the CrowdfundingContract using Foundry's Test framework.
contract CrowdfundingContractTest is Test {
    CrowdfundingContract public crowdfunding; // Instance of the CrowdfundingContract
    address owner = address(1); // Address of the contract owner
    address contributor1 = address(2); // Address of the first contributor
    address contributor2 = address(3); // Address of the second contributor

    uint goal = 1 ether; // Funding goal set to 1 ether
    uint duration = 1 days; // Campaign duration set to 1 day

    /// @notice Sets up the initial state for each test.
    ///         Deploys a new CrowdfundingContract and assigns the owner.
    function setUp() public {
        vm.startPrank(owner); // Start impersonating the owner address
        crowdfunding = new CrowdfundingContract(goal, duration); // Deploy the contract with the specified goal and duration
        vm.stopPrank(); // Stop impersonating the owner address
    }

    /// @notice Tests the initial setup of the CrowdfundingContract.
    function testInitialSetup() public {
        assertEq(crowdfunding.goal(), goal); // Check that the goal is correctly set
        assertEq(crowdfunding.deadline(), block.timestamp + duration); // Check that the deadline is correctly set
        assertEq(crowdfunding.fundsRaised(), 0); // Check that no funds have been raised initially
        assertEq(crowdfunding.paused(), false); // Check that the contract is not paused initially
    }
    /// @notice Tests the contribute functionality of the CrowdfundingContract.
    function testContribute() public {
        vm.deal(contributor1, 2 ether); // Fund contributor1 with 2 ether to simulate available funds
        vm.prank(contributor1); // Impersonate contributor1 for the next call
        crowdfunding.contribute{value: 1 ether}(); // Call the contribute function with 1 ether

        // Check that the contribution of contributor1 is recorded correctly
        assertEq(crowdfunding.contributions(contributor1), 1 ether);

        // Check that the total funds raised is updated correctly
        assertEq(crowdfunding.fundsRaised(), 1 ether);
    }
}
