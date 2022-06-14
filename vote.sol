//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable{

    uint public winningProposalId;
    address owner;
    mapping(address => Voter) voterState;
    Proposal[] public proposals;

    //Etat du voteur (j'ai rajouté un bool pour qu'un voteur puisse proposer qu'une seule variable au vote)
    struct Voter {
        bool isRegistered;
        bool hasProposed;
        bool hasVoted;
        uint votedProposalId;
    }

    // Propositions de vote
    struct Proposal {
        string description;
        uint voteCount;
        address author; 
    }

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


    constructor(){
        owner = msg.sender;
        proposals.push(Proposal("vote blanc", 0, address(0)));
         voterState[msg.sender].isRegistered = true;
    }


    //Changer l'etat du vote et le finir
    function setStatus() public onlyOwner{
        emit WorkflowStatusChange( status, WorkflowStatus(uint(status) + 1));
        status = WorkflowStatus(uint(status) + 1);
        
        if(status == WorkflowStatus.VotingSessionEnded){
            winningProposalId = reveal();
            status = WorkflowStatus.VotesTallied;
        }
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


    //Comptage des votes
    function reveal()internal view returns(uint max){
        for(uint i = 0; i < proposals.length; i++){
            if(proposals[i].voteCount > max){
                max = i;
            }
        }
        return(max);
    }

    //fonction pour savoir la proposition accepté
    function getWinner() public view returns(string memory){
        require(status == WorkflowStatus.VotesTallied, "Tallied not finished"); 
        return string("vote de", abi.encodePacked(proposals[winningProposalId].author, abi.encodePacked(proposals[winningProposalId].description, " confirme avec",proposals[winningProposalId].voteCount," voix"));
    }


} 