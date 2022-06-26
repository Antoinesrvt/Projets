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
            expect(new BN(VotingInstance.WorkflowStatus)).to.be.bignumber.equal(new BN(1));
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

        // Getter testé en meme temps que la fonction  
        it("should add a voter", async () => { 
            const storedData = await VotingInstance.getVoter(second);
            expect(storedData.isRegistered).to.be.true;
        });

        it("is already registered", async () => {
            await expectRevert(VotingInstance.addVoter(second, {from: owner}), "Already registered");
        });
         
    });

    describe("addProposal function", function() {
        beforeEach(async function() {
            VotingInstance = await voting.new({from:owner});
            await VotingInstance.addVoter(owner);
            await VotingInstance.startProposalsRegistering({from:owner});
            await VotingInstance.addProposal("proposal", {from:owner});
        });

        // Getter testé en meme temps que la fonction  
        it("should store proposal", async () => {
            const storedData = await VotingInstance.getOneProposal(0);
            expect(storedData.description).to.equal("proposal");
        }); 

        it("is your max proposal", async () => {
            await expectRevert(VotingInstance.addProposal("", {from:owner}), "Vous ne pouvez pas ne rien proposer");
        });

        it("is not the time to register proposal", async () => {
            await VotingInstance.endProposalsRegistering({from:owner});
            await expectRevert(VotingInstance.addProposal("proposal", {from:owner}), "Proposals are not allowed yet");
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

        it("should set a vote", async () =>{
            await VotingInstance.setVote(0, {from:owner});
            const storedData = VotingInstance.getOneProposal(0);
            expect(new BN(storedData.voteCount)).to.be.bignumber.equal(new BN(1));
        })

         it("should as voted", async () =>{
            await VotingInstance.setVote(0, {from:owner});
            const storedData = await VotingInstance.getVoter(owner);
            expect(storedData.hasVoted).to.be.true;
        })

    })

    describe("tallyVotes function", function(){
        beforeEach(async function(){
            VotingInstance = await voting.new({from:owner});
        })
    })


});