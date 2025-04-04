// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Vote {
    struct Voter {
        string name;
        uint age;
        uint voterId;
        Gender gender;
        uint voteCandidateId;
        address voterAddress;
    }

    struct Candidate {
        string name;
        string party;
        uint age;
        Gender gender;
        uint candidateId;
        address candidateAddress;
        uint votes;
    }

    address public electionCommission;

    address public winner;

    uint nextVoterId = 1;
    uint nextCandidateId = 1;

    uint startTime;
    uint endTime;
    bool stopVoting;

    mapping(uint => Voter) voterDetails;
    mapping(uint => Candidate) candidateDetails;

    enum VotingStatus {
        NotStarted,
        InProgress,
        Ended
    }
    enum Gender {
        NotSpecified,
        Male,
        Female,
        Other
    }

    constructor() {
        electionCommission = msg.sender;
    }

    modifier onlyAdult(uint _age) {
        require(_age >= 18, "You are below 18 years");
        _;
    }
    modifier isVotingOver() {
        require(
            block.timestamp <= endTime && stopVoting == false,
            "Voting time is Over"
        );
        _;
    }

    modifier onlyCommissioner() {
        require(msg.sender == electionCommission, "Not Authorized");
        _;
    }

    function registerCandidate(
        string calldata _name,
        string calldata _party,
        uint _age,
        Gender _gender
    ) external onlyAdult(_age) {
        require(
            isCandidateNotRegistered(msg.sender),
            "You are already registered"
        );
        require(nextCandidateId < 3, "Candidate Registraion is Full");
        require(msg.sender != electionCommission, "You are not permitted");
        candidateDetails[nextCandidateId] = Candidate({
            name: _name,
            party: _party,
            age: _age,
            gender: _gender,
            candidateId: nextCandidateId,
            candidateAddress: msg.sender,
            votes: 0
        });
        nextCandidateId++;
    }

    function addElectionCommission(address _person) external onlyCommissioner {
        electionCommission = _person;
    }

    function isCandidateNotRegistered(
        address _person
    ) internal view returns (bool) {
        for (uint i = 1; i < nextCandidateId; i++) {
            if (candidateDetails[i].candidateAddress == _person) {
                return false;
            }
        }
        return true;
    }

    function getCandidateList() public view returns (Candidate[] memory) {
        Candidate[] memory storeCandidateList = new Candidate[](
            nextCandidateId - 1
        );
        for (uint i = 0; i < storeCandidateList.length; i++) {
            storeCandidateList[i] = candidateDetails[i + 1];
        }
        return storeCandidateList;
    }

    function isVoterNotRegistered(
        address _person
    ) internal view returns (bool) {
        for (uint i = 1; i < nextVoterId; i++) {
            if (voterDetails[i].voterAddress == _person) {
                return false;
            }
        }
        return true;
    }

    function registerVoter(
        string calldata _name,
        uint _age,
        Gender _gender
    ) external onlyAdult(_age) {
        require(isVoterNotRegistered(msg.sender), "You are already registered");

        voterDetails[nextVoterId] = Voter({
            name: _name,
            age: _age,
            voterId: nextVoterId,
            gender: _gender,
            voteCandidateId: 0,
            voterAddress: msg.sender
        });
        nextVoterId++;
    }

    function getVoterList() public view returns (Voter[] memory) {
        Voter[] memory storeVoterList = new Voter[](nextVoterId - 1);
        for (uint i = 0; i < storeVoterList.length; i++) {
            storeVoterList[i] = voterDetails[i + 1];
        }
        return storeVoterList;
    }

    function castVote(uint _voterId, uint _candidateId) external {
        require(
            _candidateId > 0 && _candidateId < nextCandidateId,
            "Invalid candidate id"
        );
        require(nextVoterId > _voterId, "Invalid voter id");
        require(
            voterDetails[_voterId].voterAddress == msg.sender,
            "You are not authorized"
        );
        require(
            voterDetails[_voterId].voteCandidateId == 0,
            "You have already voted"
        );
        voterDetails[_voterId].voteCandidateId = _candidateId;
        candidateDetails[_candidateId].votes++;
    }

    function setVotingPeriod(
        uint _startTime,
        uint _endTime
    ) external onlyCommissioner {
        require(_startTime < _endTime, "Invalid Time Period");
        require(
            _endTime > 3600,
            "End Time Duration must be greater than 1 hour"
        );
        startTime = block.timestamp + _startTime;
        endTime = startTime + _endTime;
    }

    function getVotingStatus() public view returns (VotingStatus) {
        if (startTime == 0) {
            return VotingStatus.NotStarted;
        } else if (endTime > block.timestamp && stopVoting == false) {
            return VotingStatus.InProgress;
        } else {
            return VotingStatus.Ended;
        }
    }

    function announceVotingResult() external onlyCommissioner {
        //    require(getVotingStatus() == VotingStatus.Ended,"Cannot announce result until the voting is over");
        uint maxVotes = 0;
        for (uint i = 1; i < nextCandidateId; i++) {
            if (candidateDetails[i].votes > maxVotes) {
                winner = candidateDetails[i].candidateAddress;
                maxVotes = candidateDetails[i].votes;
            }
        }
    }

    function emergencyStopVoting() public onlyCommissioner {
        stopVoting = true;
    }
}
