# Crowdfunding Contract Audit

This repository contains the Crowdfunding Smart Contract and its audit report. The contract allows users to contribute funds towards a specific goal within a set duration. The owner can withdraw funds if the goal is met, and contributors can request a refund if the goal is not met within the campaign duration.

## Contracts

- `CrowdfundingContract.sol`: The main contract file.

## Tests

- `CrowdfundingContractTest.t.sol`: Test file for the contract using Foundry.

## Audit Report

[Link to the detailed audit report](https://github.com/DCVglobalnetwork/CrowdfundingContractAudit/blob/main/AuditReport.md) 

## Project Structure

CrowdfundingContractAudit/
│
├── src/
│   └── CrowdfundingContract.sol
├── test/
│   └── CrowdfundingContractTest.t.sol
├── README.md
└── audit/
    └── audit_report.pdf (or any other audit report files)


## Usage

### Prerequisites

- [Foundry](https://github.com/foundry-rs/foundry) toolchain installed.

### Installation

1. Clone the repository:
    ```bash
    git clone https://github.com/yourusername/CrowdfundingContractAudit.git
    cd CrowdfundingContractAudit
    ```

2. Install dependencies (OpenZeppelin Contracts):
    ```bash
    forge install OpenZeppelin/openzeppelin-contracts-upgradeable
    ```

### Running Tests

To run the tests using Foundry:

```bash
forge test
```


### Security Considerations
The contract uses the OpenZeppelin upgradeable contracts for security and upgradability.
Implements reentrancy protection using ReentrancyGuardUpgradeable.
Includes pause functionality to allow the owner to pause the contract in case of emergencies.

### License
This project is licensed under the MIT License.

### Contributions
Contributions are welcome! Please open an issue or submit a pull request.

### Contact
For any questions or suggestions, feel free to open an issue or contact the project maintainers.


