//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable{

    uint16 public winningProposalId;
    uint16 public sessionId;
    address owner;

    //Etat du voteur (j'ai rajouté un bool pour qu'un voteur puisse proposer qu'une seule variable au vote)
    struct Voter {
        bool isRegistered;
        bool hasProposed;
        bool hasVoted;
        uint votedProposalId; 
    }
    mapping(address => Voter) voterState;

    // Propositions de vote
    struct Proposal {
        string description;
        uint voteCount;
        address author; 
    }
    Proposal[] public proposals;

    // Pour faire plusieurs sessions de vote
    struct Session { 
        string winningProposalName;
        uint16 nbVotes;
        uint16 totalVotes;
    }
    Session[] public sessions;

    // Les status du vote
    enum WorkflowStatus{
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public status;
    //public pour avoir un getter


    // All events
    event VoterRegistered(address voterAddress); 
    event VoterUnregistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event ProposalUnregistered(uint proposalId);
    event Voted (address voter, uint proposalId);
    event SessionRestart(uint sessionId);


    constructor(){
        owner = msg.sender;
        sessionId=0;
        sessions.push(Session('None',0,0));
        proposals.push(Proposal("vote blanc", 0, address(0)));
        voterState[msg.sender].isRegistered = true;
        status = WorkflowStatus.RegisteringVoters;
    }


    //Changer l'etat du vote
    function setStatus() public onlyOwner{
        emit WorkflowStatusChange( status, WorkflowStatus(uint(status) + 1));
        status = WorkflowStatus(uint(status) + 1);
    }


    // 1ere etape: whitelist un utilisateur 
    function whitelist(address _address) public onlyOwner{
        voterState[_address].isRegistered = true;
        emit VoterRegistered(_address);
    }

    function unWhitelist(address _address) public onlyOwner{
        voterState[_address].isRegistered = false;
        emit VoterUnregistered(_address);
    }


    // 2nd etape: register le vote
    function register(string memory _info) public {
        require(voterState[msg.sender].isRegistered == true, "Vous n'etes pas enregistre");
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "vous ne pouvez pas enregistrer de vote");
        require(voterState[msg.sender].hasProposed == false, "Vous avez deja propose un vote");
        proposals.push(Proposal(_info, 0, msg.sender));
        voterState[msg.sender].hasProposed = true;
    }

    function unRegister(uint _Id) public onlyOwner{
        require(voterState[msg.sender].isRegistered == true, "Vous n'etes pas enregistre");
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "vous ne pouvez pas enregistrer de vote");
        delete proposals[_Id];
    }


    // 3e etape: voter
    function voter(uint _vote) public{
        require(voterState[msg.sender].isRegistered == true, "Vous n'etes pas enregistre");
        require(status == WorkflowStatus.VotingSessionStarted, "la session de vote n'a pas demarree");
        require(_vote < proposals.length, "ce vote n'existe pas");
        //incrémenter un vote grace a l'id du vote dans la liste, changer l'etat du voteur
        proposals[_vote].voteCount ++;
        voterState[msg.sender].hasVoted = true;
        voterState[msg.sender].votedProposalId = _vote;
        emit Voted(msg.sender, _vote);
    }


//Fin du vote

     function votesTallied() external onlyOwner {
        require(status == WorkflowStatus.VotingSessionEnded, "Session is still ongoing");
        
        (uint16 win, uint16 voteWin, uint16 total) = reveal();
        winningProposalId = win;
        sessions[sessionId].winningProposalName = proposals[win].description;
        sessions[sessionId].nbVotes = voteWin;
        sessions[sessionId].totalVotes = total;       

        status = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }

    //Comptage des votes
    function reveal()internal view returns(uint16 max, uint16 totalVotes, uint16 nbVotesWinner){
        for(uint16 i = 0; i < proposals.length; i++){
            if(proposals[i].voteCount > max){
                max = i;
                nbVotesWinner = uint16(proposals[i].voteCount);
            }
            totalVotes += uint16(proposals[i].voteCount);
        }
        return(max, nbVotesWinner, totalVotes);
    }

    //fonction pour savoir la proposition accepté
    function getWinner() public view returns(string memory){
        require(status == WorkflowStatus.VotesTallied, "Tallied not finished"); 
        return string(abi.encodePacked("vote de", proposals[winningProposalId].author, proposals[winningProposalId].description, " confirme avec", proposals[winningProposalId].voteCount," voix"));
    }

//

} 