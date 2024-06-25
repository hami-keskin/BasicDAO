// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Lottery is ReentrancyGuard {
    mapping(address => uint) public ticketCounts;
    mapping(address => uint) public prizePoolContributions;
    mapping(address => uint) public participantContributions;
    address payable[] public players;
    address payable[] public contributors;
    address payable[] public winners;
    uint public ticketPrice;
    uint public numberOfWinners;
    uint public lastWinnerShare;
    uint public minParticipants;
    uint public endTime;
    bool public isOpen;

    address public owner;

    event LotteryInitialized(uint ticketPrice, uint numberOfWinners, uint minParticipants, uint endTime);
    event ParticipantJoined(address participant, uint numberOfTickets);
    event PrizePoolIncreased(address contributor, uint amount);
    event WinnersDrawn(address payable[] winners, uint totalPrize);
    event LotteryClosed();
    event LotteryClosedAndReset();
    event FundsWithdrawn(uint amount);

    constructor() {
        owner = msg.sender;
    }

    modifier whenOpen() {
        require(isOpen, "Lottery is closed.");
        _;
    }

    modifier whenClosed() {
        require(!isOpen, "Lottery is open.");
        _;
    }

    function initializeLottery(uint _ticketPriceInWei, uint _numberOfWinners, uint _minParticipants, uint _durationInMinutes) external whenClosed {
        require(_numberOfWinners > 0, "Number of winners must be greater than zero.");
        require(_minParticipants > 0, "Minimum participants must be greater than zero.");
        require(_minParticipants >= _numberOfWinners, "Minimum participants must be greater than or equal to number of winners.");
        require(_durationInMinutes > 0, "Duration must be greater than zero.");
        
        ticketPrice = _ticketPriceInWei; 
        numberOfWinners = _numberOfWinners;
        minParticipants = _minParticipants;
        endTime = block.timestamp + (_durationInMinutes * 1 minutes);
        isOpen = true;
        
        emit LotteryInitialized(ticketPrice, _numberOfWinners, _minParticipants, endTime);
    }

    function enter(uint numberOfTickets) external payable whenOpen nonReentrant {
        require(block.timestamp < endTime, "Lottery has ended.");
        require(msg.value >= ticketPrice * numberOfTickets, "Insufficient payment.");

        uint totalCost = ticketPrice * numberOfTickets;
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }

        ticketCounts[msg.sender] += numberOfTickets;
        participantContributions[msg.sender] += totalCost;
        players.push(payable(msg.sender));

        emit ParticipantJoined(msg.sender, numberOfTickets);
    }

    function closeLotteryAndReset() external whenOpen nonReentrant {
        require(block.timestamp >= endTime, "Time not reached to close the lottery.");

        if (players.length >= minParticipants) {
            handleLotteryClosure();
        } else {
            refundParticipants();
            refundContributors();
            resetLottery();
        }
    }

    function handleLotteryClosure() private {
        isOpen = false;
        delete winners;

        if (players.length > 0) {
            shuffle(players);
            uint totalPrize = address(this).balance;
            lastWinnerShare = totalPrize / numberOfWinners;
            for (uint i = 0; i < numberOfWinners; i++) {
                winners.push(players[i]);
                winners[i].transfer(lastWinnerShare);
            }
            emit WinnersDrawn(winners, totalPrize);
        }

        emit LotteryClosed();
        resetLottery();
    }

    function refundParticipants() private {
        for (uint i = 0; i < players.length; i++) {
            uint refundAmount = participantContributions[players[i]];
            if (refundAmount > 0) {
                participantContributions[players[i]] = 0; // Sıfırlayarak tekrar ödeme yapmayı önler
                players[i].transfer(refundAmount);
            }
        }
    }

    function refundContributors() private {
        for (uint i = 0; i < contributors.length; i++) {
            uint refundAmount = prizePoolContributions[contributors[i]];
            if (refundAmount > 0) {
                prizePoolContributions[contributors[i]] = 0; // Sıfırlayarak tekrar ödeme yapmayı önler
                contributors[i].transfer(refundAmount);
            }
        }
    }

    function withdrawFunds() private nonReentrant {
        uint amount = address(this).balance;
        require(amount > 0, "No funds to withdraw.");
        payable(owner).transfer(amount);
        emit FundsWithdrawn(amount);
    }

    function resetLottery() private {
        delete players;
        delete contributors;
        ticketPrice = 0;
        numberOfWinners = 0;
        minParticipants = 0;
        endTime = 0;
        isOpen = false;
        emit LotteryClosedAndReset();
    }

    function shuffle(address payable[] storage array) private {
        uint n = array.length;
        for (uint i = 0; i < n; i++) {
            uint j = i + uint(keccak256(abi.encodePacked(blockhash(block.number - 1), i))) % (n - i);
            (array[i], array[j]) = (array[j], array[i]);
        }
    }

    function increasePrizePool() external payable whenOpen nonReentrant {
        require(block.timestamp < endTime, "Lottery has ended.");
        require(msg.value > 0, "Must send Ether to increase the prize pool.");

        if (prizePoolContributions[msg.sender] == 0) {
            contributors.push(payable(msg.sender));
        }

        prizePoolContributions[msg.sender] += msg.value;
        emit PrizePoolIncreased(msg.sender, msg.value);
    }

    function getWinners() external view returns (address payable[] memory, uint) {
        return (winners, lastWinnerShare);
    }

    function getTicketPrice() external view returns (uint) {
        return ticketPrice;
    }
}
