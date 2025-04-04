// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CrowdFunding {

    // Structure to represent a fund withdrawal request
    struct Request {
        string description;                  // Why the funds are needed
        address payable recipient;           // Who will receive the funds
        uint value;                          // How much will be paid
        bool completed;                      // Has the request been fulfilled
        uint noOfVoters;                     // Number of contributors who voted for this request
        mapping(address => bool) voters;     // Tracks which contributors have voted
    }

    mapping(address => uint) public contributors;      // Keeps track of how much each contributor contributed
    mapping(uint => Request) public requests;          // Stores all the withdrawal requests
    uint public numRequests;                           // Number of requests created
    address public manager;                            // Creator of the campaign
    uint public minimumContribution;                   // Minimum amount required to become a contributor
    uint public deadline;                              // Time until which funding is allowed
    uint public target;                                // Total funding goal
    uint public noOfContributors;                      // Total unique contributors
    uint public raisedAmount;                          // Total amount raised

    // Modifier to restrict access to only the campaign creator
    modifier onlyOwner() {
        require(msg.sender == manager, "You don't have access to this function");
        _;
    }

    // Constructor to initialize target funding amount and deadline
    constructor(uint _target, uint _deadline) {
        target = _target;
        deadline = block.timestamp + _deadline;  // e.g., _deadline = 1 week in seconds
        minimumContribution = 10 wei;
        manager = msg.sender;
    }

    // Function to create a withdrawal request (only manager can call)
    function createRequest(
        address payable _recipient,
        string calldata _description,
        uint _value
    ) public onlyOwner {
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.value = _value;
        newRequest.recipient = _recipient;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    // Function to contribute funds to the contract
    function contribution() public payable {
        require(block.timestamp < deadline, "Deadline has passed!!");
        require(msg.value >= minimumContribution, "Minimum Contribution Required is 10 wei");

        // Count the contributor only once
        if (contributors[msg.sender] == 0) {
            noOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    // Function to check contract's current balance
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    // Function to refund contributors if target is not met after deadline
    function refund() public {
        require(block.timestamp > deadline && raisedAmount < target, "You are not eligible for refund!!");
        require(contributors[msg.sender] > 0, "You are not a contributor!");

        payable(msg.sender).transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;  // Prevent multiple refunds
    }

    // Function to vote for a specific fund request
    function voteRequest(uint _requestNo) public {
        require(contributors[msg.sender] > 0, "You are not eligible for voting.");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender] == false, "You have already voted!!");

        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    // Function to make payment if majority of contributors approve the request
    function makePayment(uint _requestNo) public onlyOwner {
        require(raisedAmount >= target, "Target not reached!!");

        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "The request is already completed");
        require(thisRequest.noOfVoters > noOfContributors / 2, "Majority does not support the request");

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}
