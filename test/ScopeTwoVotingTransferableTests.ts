import { expect } from "chai";
import { ethers } from "hardhat";
import { ignition } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ScopeTwoVotingTransferable__factory } from "../typechain-types";
import ScopeTwoVotingTransferableModule from "../ignition/modules/ScopeTwoVotingTransferableModule";

describe("ScopeTwoVotingTransferable", function () {
  async function deployScopeTwoVotingTransferableToken() {
    const [owner, ...others] = await ethers.getSigners();

    const { token } = await ignition.deploy(ScopeTwoVotingTransferableModule);

    const typedToken = ScopeTwoVotingTransferable__factory.connect(await token.getAddress(), owner);

    await typedToken.setInitialPrice(100);

    return { token: typedToken, owner, others };
  }

  describe("Voting", function () {
    it("vote for start price voting", async function () {
      const { token, owner, others } = await loadFixture(deployScopeTwoVotingTransferableToken);

      await token.connect(others[0]).buy({ value: ethers.parseEther("1") });
      await token.connect(others[1]).buy({ value: ethers.parseEther("1") });
      await token.connect(others[2]).buy({ value: ethers.parseEther("1") });

      console.log("TOTAL SUPPLY", ethers.formatEther(await token.totalSupply()), "ETH");

      await token.connect(others[0])["vote(bool)"](true);

      await token.connect(others[1])["vote(bool)"](true);

      await expect(token.endVoting()).to.be.revertedWith("Voting is not active.");

      expect(await token.votingActive()).to.eq(false);

      await expect(token.startVoting()).to.emit(token, "VotingStarted").withArgs(1);

      await expect(token.endVoting()).to.be.revertedWith("Voting time is not over.");

      await token.connect(others[0])["vote(uint256)"](120);
      await token.connect(others[1])["vote(uint256)"](120);
      await token.connect(others[2])["vote(uint256)"](220);

      const info1 = await token._votingInfo(others[0]);
      const info2 = await token._votingInfo(others[1]);
      const info3 = await token._votingInfo(others[2]);
      console.log("1 voting info ", info1);
      console.log("2 voting info ", info2);
      console.log("3 voting info ", info3);

      await token.connect(others[0]).transfer(others[2], ethers.parseEther("1"));

      console.log("balance of 1: ", await token.balanceOf(others[0]));
      console.log("balance of 3: ", await token.balanceOf(others[2]));
      const weight1 = await token._votingInfo(others[0]);
      const weight3 = await token._votingInfo(others[2]);
      console.log("voting weight of 1: ", weight1[1], "-", weight1[0]);
      console.log("voting weight of 3: ", weight3[1], "-", weight3[0]);

      expect(weight3[0]).to.eq(ethers.parseEther("2"));

      console.log(
        "before cleanup and refund: ",
        ethers.formatEther(await ethers.provider.getBalance(owner)),
        "ETH",
      );

      await token.connect(owner).clearAll();

      console.log(
        "after cleanup and refund: ",
        ethers.formatEther(await ethers.provider.getBalance(owner)),
        "ETH",
      );
    });
  });
});
