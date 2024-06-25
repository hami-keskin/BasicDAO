# Basic DAO on Scroll Blockchain

## Introduction

This project implements a basic Decentralized Autonomous Organization (DAO) on the Scroll blockchain. The DAO allows members to join by paying a membership fee, create proposals, and vote on them.

## Contract Address

Deployed on the Scroll Sepolia testnet: 0xEF88cf32fB039AeC2a705F6eDd9FA481145ddc93

## How It Works

### Membership

- `join()`: Members join by paying a membership fee.
- Membership fee is set during contract deployment.

### Proposals

- `createProposal(string memory _description, uint _duration)`: Members create proposals with a description and voting deadline.
- Proposals are stored in an array.

### Voting

- `vote(uint _proposalId, bool _vote)`: Members vote "yes" or "no" on proposals.
- Votes are tallied to determine if a proposal passes.

### Finalizing Proposals

- `finalizeProposal(uint _proposalId)`: Only the owner can finalize proposals once the voting period is over.

## Contract Functions

### Membership

- `join()`: Pay the membership fee to join the DAO.
    ```solidity
    function join() external payable {
        require(msg.value >= membershipFee, "Insufficient membership fee");
        require(!members[msg.sender].isMember, "Already a member");
        
        members[msg.sender] = Member(true, msg.value);
        emit MemberJoined(msg.sender);
    }
    ```

### Proposals

- `createProposal(string memory _description, uint _duration)`: Create a new proposal.
    ```solidity
    function createProposal(string memory _description, uint _duration) external onlyMember {
        require(_duration > 0, "Duration must be greater than zero");
        
        proposals.push(Proposal({
            description: _description,
            deadline: block.timestamp + _duration,
            yesVotes: 0,
            noVotes: 0,
            status: ProposalStatus.Pending
        }));
        
        proposalCount++;
        emit ProposalCreated(proposalCount - 1, _description, block.timestamp + _duration);
    }
    ```

### Voting

- `vote(uint _proposalId, bool _vote)`: Vote on a proposal.
    ```solidity
    function vote(uint _proposalId, bool _vote) external onlyMember {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.deadline, "Voting period is over");
        require(proposal.status == ProposalStatus.Pending, "Proposal is not pending");
        
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        
        emit Voted(_proposalId, msg.sender, _vote);
    }
    ```

### Finalizing Proposals

- `finalizeProposal(uint _proposalId)`: Finalize a proposal.
    ```solidity
    function finalizeProposal(uint _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.deadline, "Voting period is not over");
        require(proposal.status == ProposalStatus.Pending, "Proposal already finalized");
        
        if (proposal.yesVotes > proposal.noVotes) {
            proposal.status = ProposalStatus.Approved;
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
        
        emit ProposalFinalized(_proposalId, proposal.status);
    }
    ```

## Setting Up Development Environment with thirdweb

### Clone the Repository

```sh
git clone https://github.com/hami-keskin/BasicDAO.git
```

### Install Dependencies

```sh
npm install
```

### Configure thirdweb for Deployment

1. Install thirdweb:
    ```sh
    npm install @thirdweb-dev/sdk ethers
    ```

2. Create a `thirdweb.config.js` file in the root directory with the following content:

    ```javascript
    import { ThirdwebSDK } from "@thirdweb-dev/sdk";
    import { ethers } from "ethers";

    // Initialize thirdweb SDK with the Scroll Sepolia RPC URL
    const sdk = new ThirdwebSDK(new ethers.Wallet(
        process.env.PRIVATE_KEY, 
        ethers.getDefaultProvider("https://sepolia-rpc.scroll.io")
    ));

    export default sdk;
    ```

### Deploy the Contract

1. Create a `scripts/deploy.js` file with the following content:

    ```javascript
    import sdk from "../thirdweb.config.js";
    import fs from "fs";

    (async () => {
        try {
            const contract = await sdk.deployContract({
                abi: JSON.parse(fs.readFileSync("./artifacts/contracts/BasicDAO.sol/BasicDAO.json")).abi,
                bytecode: JSON.parse(fs.readFileSync("./artifacts/contracts/BasicDAO.sol/BasicDAO.json")).bytecode,
                constructorArgs: [1000000000000], // Set your membership fee here
            });

            console.log("Contract deployed to address:", contract.address);
        } catch (error) {
            console.error("Failed to deploy contract:", error);
        }
    })();
    ```

2. Deploy the contract:
    ```sh
    node scripts/deploy.js
    ```

### Verify Deployment

- Check the deployed contract functions using a Web3 provider or thirdweb SDK.
- Ensure the contract address is correctly documented in this README.md file.

## Enhancements

- **Token-Based Voting:** Implement voting power based on the number of governance tokens.
- **Proposal Types:** Different proposal types (e.g., financial, rule changes).
- **Quadratic Voting:** Implement a quadratic voting mechanism.

## License

MIT

---

By following these instructions, you'll be able to set up and deploy a basic DAO on the Scroll blockchain using thirdweb. This setup allows for easy collaboration and further development, providing a foundation for more advanced DAO features.
