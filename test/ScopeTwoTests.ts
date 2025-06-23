import { expect } from "chai";
import { ethers } from "hardhat";
import { ignition } from "hardhat";
import { loadFixture, time } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import ScopeTwoTokenModule from "../ignition/modules/ScopeTwoTokenModule";
import { ScopeTwoToken__factory } from "../typechain-types";

describe("ScopeTwoToken", function () {
  async function deployScopeTwoToken() {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const { token } = await ignition.deploy(ScopeTwoTokenModule);

    const typedToken = ScopeTwoToken__factory.connect(await token.getAddress(), owner);

    await typedToken.setInitialPrice(100);

    return { token: typedToken, addr1, addr2 };
  }

  describe("Voting", function () {
    it("vote for start price voting", async function () {
      const { token, addr1, addr2 } = await loadFixture(deployScopeTwoToken);

      await token.connect(addr1)["vote(bool)"](true);

      await token.connect(addr2)["vote(bool)"](true);

      await expect(token.endVoting()).to.be.revertedWith("Voting is not active.");

      expect(await token.votingActive()).to.eq(false);

      await expect(token.startVoting()).to.emit(token, "VotingStarted").withArgs(1);

      await expect(token.endVoting()).to.be.revertedWith("Voting time is not over.");
    });

    it("startVoting sets voting start time, increments votingNumber, emits event", async function () {
      const { token, addr1, addr2 } = await loadFixture(deployScopeTwoToken);

      await token.connect(addr1)["vote(bool)"](true);
      await token.connect(addr2)["vote(bool)"](true);

      await expect(token.startVoting()).to.emit(token, "VotingStarted").withArgs(1);

      expect(await token.votingNumber()).to.equal(1);
      expect(await token.votingActive()).to.eq(true);
      const startTime = await token.votingStartTime();
      expect(startTime).to.be.greaterThan(0);
    });

    it("vote should fail if balance < minTokenAmount (0.05%)", async function () {
      const { token, addr1, addr2 } = await loadFixture(deployScopeTwoToken);

      await token.connect(addr1)["vote(bool)"](true);
      await token.connect(addr2)["vote(bool)"](true);

      await token.startVoting();

      await expect(token.connect(addr1)["vote(uint256)"](100)).to.be.revertedWith(
        "Price should be more than 0 and not be equal to the current one.",
      );

      await expect(token.connect(addr1)["vote(uint256)"](110)).to.be.revertedWith(
        "Total supply is zero. No voting allowed.",
      );

      await token.connect(addr2).buy({ value: ethers.parseEther("1") });
      await token.connect(addr2).buy({ value: ethers.parseEther("1") });
      await token.connect(addr2).buy({ value: ethers.parseEther("1") });

      await token.connect(addr1).buy({ value: ethers.parseEther("0.001") });

      console.log(
        "balance 1: ",
        ethers.formatEther(await token.connect(addr1).balanceOf(addr1)),
        "ETH",
      );
      console.log(
        "balance 2: ",
        ethers.formatEther(await token.connect(addr1).balanceOf(addr2)),
        "ETH",
      );

      expect(await token.connect(addr1).balanceOf(addr1)).to.be.greaterThan(0);

      await expect(token.connect(addr1)["vote(uint256)"](110)).to.be.revertedWith(
        "You cannot vote for token price as you dont have enough tokens.",
      );

      await token.connect(addr1).buy({ value: ethers.parseEther("1") });
      await token.connect(addr1)["vote(uint256)"](110);

      await expect(token.connect(addr1)["vote(uint256)"](110)).to.be.revertedWith(
        "You have already voted for price.",
      );

      await expect(token.connect(addr1)["vote(uint256)"](120)).to.be.revertedWith(
        "You have already voted for price.",
      );
    });

    it("token transfers are blocked for voters during voting to prevent double voting with token transfers", async function () {
      const { token, addr1, addr2 } = await loadFixture(deployScopeTwoToken);

      await token.connect(addr1)["vote(bool)"](true);
      await token.connect(addr2)["vote(bool)"](true);

      await token.startVoting();

      await token.connect(addr2).buy({ value: ethers.parseEther("1") });
      await token.connect(addr2).buy({ value: ethers.parseEther("1") });
      await token.connect(addr2).buy({ value: ethers.parseEther("1") });

      await token.connect(addr1).buy({ value: ethers.parseEther("1") });

      await token.connect(addr1)["vote(uint256)"](130);

      await expect(token.connect(addr1).transfer(addr2, 1)).to.be.revertedWith(
        "You cannot transfer as you participate in a voting.",
      );
    });

    it("endVoting should be callable only after timeToVote", async function () {
      const { token, addr1, addr2 } = await loadFixture(deployScopeTwoToken);

      await token.connect(addr1)["vote(bool)"](true);
      await token.connect(addr2)["vote(bool)"](true);

      await token.startVoting();

      await token.connect(addr2).buy({ value: ethers.parseEther("1") });
      await token.connect(addr2).buy({ value: ethers.parseEther("1") });
      await token.connect(addr2).buy({ value: ethers.parseEther("1") });

      await token.connect(addr1).buy({ value: ethers.parseEther("1") });

      await token.connect(addr1)["vote(uint256)"](130);

      await expect(token.connect(addr2).endVoting()).to.be.revertedWith("Voting time is not over.");

      await time.increase(3600);

      await expect(token.connect(addr2).endVoting()).to.not.revertedWith(
        "Voting time is not over.",
      );
    });
  });
});
