const { accounts, contract, web3 } = require("@openzeppelin/test-environment")
const { expectRevert, time, BN, constants, ether, balance } = require("@openzeppelin/test-helpers")
const {expect} = require("chai")

const Love = contract.fromArtifact("BiffysLove")
const Portraits = contract.fromArtifact("BiffysPortraits")
const Auction = contract.fromArtifact("BiffysPortraitAuction")

const zeroAddress = "0x0000000000000000000000000000000000000000"
const ethereal = accounts[0] //admin
const bidders = [
  accounts[1],
  accounts[2],
]
const artists = [
  accounts[6],
  accounts[7]
]
const noLoveHolders = [
  accounts[8],
  accounts[9]
]

describe("BiffysPortraitAuction",function() {
  before(async function () {
    this.love = await Love.new()
    await this.love.initialize("Biffys Love", "LOVE", 18, ethereal)
    await Promise.all([

    ])
    await this.love.mint(bidders[0],ether("1000"),{from:ethereal})
    await this.love.mint(bidders[1],ether("1000"),{from:ethereal})
    
    this.portraits = await Portraits.new()
    await this.portraits.initialize("Biffys Portraits", "BPRT", [ethereal], [ethereal])
    await Promise.all([
      this.portraits.mintWithTokenURI(ethereal, "1", "", {from: ethereal}),
      this.portraits.mintWithTokenURI(ethereal, "2", "", {from: ethereal}),
      this.portraits.mintWithTokenURI(ethereal, "3", "", {from: ethereal})
    ])
    
    this.auction = await Auction.new()
    await this.auction.initialize(
        this.love.address,
        this.portraits.address,
        ethereal
    )

    await this.portraits.setApprovalForAll(this.auction.address,true, {from: ethereal})
  })

  describe("First Auction",function(){
    describe("startAuction",function(){
      it("Should revert if sender not ethereal", async function(){
        const latest = await time.latest()
        await expectRevert(
          this.auction.startAuction(
            "1",
            ether("1"),
            "1500",
            "2000",
            "86400",
            latest.toNumber() - 60,
            ethereal
          ),
          "Ownable: caller is not the owner"
        )
      })
      it("Should revert if token does not exist", async function(){
        const latest = await time.latest()
        await expectRevert(
          this.auction.startAuction(
            "4",
            ether("1"),
            "1500",
            "2000",
            "86400",
            latest.toNumber() - 60,
            ethereal,
            {from:ethereal}
          ),
          "ERC721: operator query for nonexistent token"
        )
      })
      describe("On Success", function() {
        before(async function() {
          const latest = await time.latest()
          await this.auction.startAuction(
            "1",
            ether("1"),
            "1500",
            "2000",
            "86400",
            latest.toNumber() - 60,
            zeroAddress,
            {from:ethereal}
          )
        })
        it("Should increment nonce", async function(){
          const nonce = await this.auction.auctionNonce()
          expect(nonce.toNumber()).to.equal(1)
        })
        it("Should create auction", async function(){
          const {
            portraitId,
            startingBid,
            minIncreaseBP,
            artistComissionBP,
            timerSeconds,
            startTime,
            artist,
            endTime,
            lastBidder,
            lastBid,
            isClaimed
          } = await this.auction.getAuction(0)
          expect(portraitId.toNumber()).to.equal(1)
          expect(startingBid.toString()).to.equal(ether("1").toString())
          expect(minIncreaseBP.toNumber()).to.equal(1500)
          expect(artistComissionBP.toNumber()).to.equal(2000)
          expect(timerSeconds.toNumber()).to.equal(86400)
          //expect(startTime.toNumber()).to.equal(1)
          expect(artist).to.equal(zeroAddress)
          expect(endTime.toNumber()).to.equal(startTime.toNumber()+86400)
          expect(lastBidder).to.equal(zeroAddress)
          expect(lastBid.toNumber()).to.equal(0)
          expect(isClaimed).to.equal(false)
        })
        it("Should revert if called again for same token", async function(){
          const latest = await time.latest()
          await expectRevert(
            this.auction.startAuction(
              "1",
              ether("1"),
              "1500",
              "2000",
              "86400",
              latest.toNumber() - 60,
              ethereal,
              {from:ethereal}
            ),
            "ERC721: transfer of token that is not own"
          )
        })
      })
    })
    describe("depositAndBid", function(){
      it("Should revert if no love held by account",async function(){
        await expectRevert(
          this.auction.depositAndBid(
            0,
            ether("1"),
            {from:noLoveHolders[0]}
          ),
          "ERC20: transfer amount exceeds balance"
        )
      })
      it("Should revert if no love held by account",async function(){
        await expectRevert(
          this.auction.depositAndBid(
            0,
            ether("1"),
            {from:noLoveHolders[0]}
          ),
          "ERC20: transfer amount exceeds balance"
        )
      })
      it("Should revert if not approved",async function(){
        await expectRevert(
          this.auction.depositAndBid(
            0,
            ether("1"),
            {from:bidders[0]}
          ),
          "ERC20: transfer amount exceeds allowance"
        )
      })
      it("Should revert if exceeds balance",async function(){
        await expectRevert(
          this.auction.depositAndBid(
            0,
            ether("1001"),
            {from:bidders[0]}
          ),
          "ERC20: transfer amount exceeds balance"
        )
      })
      it("Should revert if less than starting bid",async function(){
        await this.love.approve(
          this.auction.address,
          constants.MAX_UINT256,
          {from: bidders[0]}
        )
        await expectRevert(
          this.auction.depositAndBid(
            0,
            1,
            {from:bidders[0]}
          ),
          "Bid below starting bid"
        )
      })
      describe("On Successful First Bid", async function(){
        before(async function(){
          await this.auction.depositAndBid(
            0,
            ether("1"),
            {from:bidders[0]}
          )
        })
        it("Should set a bid", async function(){
          const lastBidder = await this.auction.auctionLastBidder(0)
          const lastBid = await this.auction.auctionLastBid(0)
          expect(lastBidder).to.equal(bidders[0])
          expect(lastBid.toString()).to.equal(ether("1").toString())
        })
        it("Decrease bidder's loveBalance", async function(){
          const loveBalance = await this.auction.loveBalances(bidders[0])
          expect(loveBalance.toNumber()).to.equal(0)
        })
        it("should revert if bid too low", async function(){
          expectRevert(
            this.auction.depositAndBid(
              0,
              ether("1"),
              {from:bidders[1]}
            ),
            "Bid too low"
          )
        })
      })
      describe("On Successful Second Bid", async function(){
        before(async function(){
          await this.love.approve(
            this.auction.address,
            constants.MAX_UINT256,
            {from: bidders[1]}
          )
          await this.auction.depositAndBid(
            0,
            ether("2"),
            {from:bidders[1]}
          )
        })
        it("Should set a bid", async function(){
          const lastBidder = await this.auction.auctionLastBidder(0)
          const lastBid = await this.auction.auctionLastBid(0)
          expect(lastBidder).to.equal(bidders[1])
          expect(lastBid.toString()).to.equal(ether("2").toString())
        })
        it("Decrease bidder's loveBalance", async function(){
          const loveBalance = await this.auction.loveBalances(bidders[1])
          expect(loveBalance.toNumber()).to.equal(0)
        })
        it("Increase last bidder's loveBalance", async function(){
          const loveBalance = await this.auction.loveBalances(bidders[0])
          expect(loveBalance.toString()).to.equal(ether("1").toString())
        })
      })
    })
    describe("withdrawAll", async function(){
      it("Should revert if balance is zero", async function(){
        await expectRevert(
          this.auction.withdrawAll({from:bidders[1]}),
          "Must withdraw at least 1 wei of Love"
        )
      })
      describe("On success", async function(){
        before(async function(){
          this.auction.withdrawAll({from:bidders[0]})
        })
        it("Should return amount minus burn to withdrawer", async function(){
          const balance = await this.love.balanceOf(bidders[0])
          expect(balance.add(ether("0.05")).toString()).to.equal(ether("1000").toString())
        })
        it("Should decrease total supply of Love", async function(){
          const supply = await this.love.totalSupply()
          expect(supply.add(ether("0.05")).toString()).to.equal(ether("2000").toString())
        })
      })
    })
  })
})
