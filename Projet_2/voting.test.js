const voting = artifacts.require("./voting.sol");
const { BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');



contract('Voting', accounts => {
    const owner = accounts[0];
    const second = accounts[1];
    const third = accounts[2];

    let VotingInstance;


    describe("states function", function(){
        beforeEach(async () => {
            VotingInstance = await voting.new({from:owner});
        })

        it("should be 'ProposalsRegistrationStarted' (1)", async () =>{
            await VotingInstance.startProposalsRegistering();
            const storedData = await VotingInstance.workflowStatus.call();
            expect(storedData).to.be.bignumber.equal(new BN(1));
        })

        it("should emit RegisteringVoters and ProposalsRegistrationStarted", async () => {
            const storedData = await VotingInstance.startProposalsRegistering();
            expectEvent(storedData, 'WorkflowStatusChange', {
                previousStatus : new BN(0),
                newStatus : new BN(1)
            });
        });
    });


    describe("addVoter function", function() {
        beforeEach(async function () {
            VotingInstance = await voting.new({from:owner});
            await VotingInstance.addVoter(owner, {from: owner});
            await VotingInstance.addVoter(second, {from: owner});
        });

        //objectif de la fonction 
        it("should add a voter", async () => { 
            const storedData = await VotingInstance.getVoter(second);
            expect(storedData.isRegistered).to.be.true;
        });

        //require
        it("is already registered", async () => {
            await expectRevert(VotingInstance.addVoter(second, {from: owner}), "Already registered");
        });

        //event
      it("should emit voterAddress", async () => {
            const storedData = await VotingInstance.addVoter(third);
            expectEvent(storedData, 'VoterRegistered', {
                voterAddress : third,
            });
        });
         
    });

    describe("addProposal function", function() {
        beforeEach(async function() {
            VotingInstance = await voting.new({from:owner});
            await VotingInstance.addVoter(owner);
            await VotingInstance.startProposalsRegistering({from:owner});
            await VotingInstance.addProposal("proposal", {from:owner});
        });

        //objectif de la fonction  
        it("should store proposal", async () => {
            const storedData = await VotingInstance.getOneProposal(0);
            expect(storedData.description).to.equal("proposal");
        }); 

        //require
        it("is an empty proposal", async () => {
            await expectRevert(VotingInstance.addProposal("", {from:owner}), "Vous ne pouvez pas ne rien proposer");
        });

        //require
        it("is not the time to register proposal", async () => {
            await VotingInstance.endProposalsRegistering({from:owner});
            await expectRevert(VotingInstance.addProposal("proposal", {from:owner}), "Proposals are not allowed yet");
        });

        //event
        it("should emit ProposalRegistered", async () => {
            const storedData = await VotingInstance.addProposal("proposal");
            expectEvent(storedData, 'ProposalRegistered', {
                proposalId : new BN(1),
            });
        });


    })

    describe("setVote function", function(){
        beforeEach(async function(){
            VotingInstance = await voting.new({from:owner});
            await VotingInstance.addVoter(owner);
            await VotingInstance.startProposalsRegistering({from:owner});
            await VotingInstance.addProposal("proposal", {from:owner});
            await VotingInstance.endProposalsRegistering({from:owner});
            await VotingInstance.startVotingSession({from:owner});
        })

        //objectif de la fonction n°1
        it("should set a vote", async () =>{
            await VotingInstance.setVote(0, {from:owner});
            const storedData = await VotingInstance.getOneProposal(0);
            expect(await new BN(storedData.voteCount)).to.be.bignumber.equal(new BN(1));
        })
        
        //objectif de la fonction n°2
         it("should as voted", async () =>{
            await VotingInstance.setVote(0, {from:owner});
            const storedData = await VotingInstance.getVoter(owner);
            expect(storedData.hasVoted).to.be.true;
        })

        //event
        it("should emit Voted", async () => {
            const storedData = await VotingInstance.setVote(0, {from:owner});
            expectEvent(storedData, 'Voted', {
                voter : owner,
                proposalId: new BN(0)
            });
        });

    })

    describe("tallyVotes function", function(){
        beforeEach(async function(){
            VotingInstance = await voting.new({from:owner});
            await VotingInstance.addVoter(owner);
            await VotingInstance.addVoter(second);
            await VotingInstance.addVoter(third);
            await VotingInstance.startProposalsRegistering({from:owner});
            await VotingInstance.addProposal("proposal1", {from:owner});
            await VotingInstance.addProposal("proposal2", {from:owner});
            await VotingInstance.endProposalsRegistering({from:owner});
            await VotingInstance.startVotingSession({from:owner});
            await VotingInstance.setVote(0, {from:owner});
            await VotingInstance.setVote(1, {from:second});
            
        })

        //objectif de la fonction n°1
        it("should be the second to win", async () =>{
            await VotingInstance.setVote(1, {from:third});
            await VotingInstance.endVotingSession({from:owner});
            await VotingInstance.tallyVotes({from:owner});
            expect(await VotingInstance.winningProposalID.call()).to.be.bignumber.equal(new BN(1));
        })

        //objectif de la fonction n°2
         it("should be the first to win", async() =>{
            await VotingInstance.endVotingSession({from:owner});
            await VotingInstance.tallyVotes({from:owner});
            expect(await VotingInstance.winningProposalID.call()).to.be.bignumber.equal(new BN(0));
        })

    
    })


});
