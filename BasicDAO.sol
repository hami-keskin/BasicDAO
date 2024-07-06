// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BasicDAO is ReentrancyGuard {
    address public owner;
    uint public membershipFee;
    uint public proposalCount;

    enum ProposalStatus { Pending, Approved, Rejected }

    struct Member {
        bool isMember;
        uint tokens;
    }

    struct Proposal {
        string description;
        uint deadline;
        uint yesVotes;
        uint noVotes;
        ProposalStatus status;
    }

    mapping(address => Member) public members;
    Proposal[] public proposals;

    event MemberJoined(address member);
    event ProposalCreated(uint proposalId, string description, uint deadline);
    event Voted(uint proposalId, address voter, bool vote);
    event ProposalFinalized(uint proposalId, ProposalStatus status);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isMember, "Not a member");
        _;
    }

    constructor() {
        owner = msg.sender;
        membershipFee = 1000000000000; // 0.000001 Ether in Wei
    }

    function join() external payable {
        require(msg.value >= membershipFee, "Insufficient membership fee");
        require(!members[msg.sender].isMember, "Already a member");

        members[msg.sender] = Member(true, msg.value);
        emit MemberJoined(msg.sender);
    }

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

    function getProposals() external view returns (Proposal[] memory) {
        return proposals;
    }
}
