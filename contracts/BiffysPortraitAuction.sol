pragma solidity 0.5.17;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./library/BasisPoints.sol";


contract BiffysPortraitAuction is Initializable, Ownable {
    using SafeMath for uint;
    using BasisPoints for uint;
    using Address for address;

    struct Auction {
      uint portraitId;
      uint startingBid;
      uint minIncreaseBP;
      uint artistComissionBP;
      uint timerSeconds;
      uint startTime;
      address artist;
    }

    ERC20Burnable lovePoints;
    IERC721 biffysPortraits;

    uint public auctionNonce;

    mapping(address => uint) public loveBalances;

    mapping(uint => uint) public auctionEndTime;
    mapping(uint => address) public auctionLastBidder;
    mapping(uint => uint) public auctionLastBid;
    mapping(uint => bool) public auctionIsClaimed;
    mapping(uint => Auction) public auctions;


    function initialize(
        ERC20Burnable _lovePoints,
        IERC721 _biffysPortraits,
        address _owner
    ) external initializer {
        Ownable.initialize(_owner);
        lovePoints = _lovePoints;
        biffysPortraits = _biffysPortraits;
    }

    function startAuction(
      uint _portraitId,
      uint _startingBid,
      uint _minIncreaseBP,
      uint _artistComissionBP,
      uint _timerSeconds,
      uint _startTime,
      address _artist
    ) external onlyOwner {
      biffysPortraits.transferFrom(msg.sender,address(this), _portraitId);
      auctions[auctionNonce] = Auction(
        _portraitId,
        _startingBid,
        _minIncreaseBP,
        _artistComissionBP,
        _timerSeconds,
        _startTime,
        _artist
      );
      auctionEndTime[auctionNonce] = _startTime.add(_timerSeconds);
      auctionNonce = auctionNonce.add(1);
    }

    function claimPortrait(uint auctionId) external {
      Auction memory auction = auctions[auctionId];
      require(now > auctionEndTime[auctionId], "Auction not ended");
      require(now > auction.startTime && auction.startTime != 0, "Auction not started");
      require(auctionLastBidder[auctionId] != address(0x0), "No winner");
      require(auctionIsClaimed[auctionId] == false, "Already claimed");

      auctionIsClaimed[auctionId] == true;
      uint bid = auctionLastBid[auctionId];
      if(auction.artist != address(0x0)) {
        uint comission = bid.mulBP(auction.artistComissionBP);
        require(lovePoints.transfer(auction.artist,comission),"Transfer failed.");
        lovePoints.burn(bid.sub(comission));
      } else {
        lovePoints.burn(bid);
      }

      biffysPortraits.transferFrom(address(this),auctionLastBidder[auctionId],auction.portraitId);
    }

    function depositAndBid(uint auctionId, uint amount) external {
      if(amount > loveBalances[msg.sender]){
        deposit(amount.sub(loveBalances[msg.sender]));
      }
      bid(auctionId,amount);
    }

    function bid(uint auctionId, uint amount) public {
      Auction memory auction = auctions[auctionId];
      require(now < auctionEndTime[auctionId], "Auction ended");
      require(now > auction.startTime && auction.startTime != 0, "Auction not started");
      require(amount >= auctionLastBid[auctionId].addBP(auction.minIncreaseBP), "Bid too low");
      require(amount >= auction.startingBid, "Bid below starting bid");
      require(loveBalances[msg.sender] >= amount, "Love balance too low");
      require(msg.sender != auctionLastBidder[auctionId]);
      address lastBidder = auctionLastBidder[auctionId];
      if(auctionLastBid[auctionId] != 0) {
        loveBalances[lastBidder] = loveBalances[lastBidder].add(auctionLastBid[auctionId]);
      }
      loveBalances[msg.sender] = loveBalances[msg.sender].sub(amount);
      auctionLastBid[auctionId] = amount;
      auctionLastBidder[auctionId] = msg.sender;
      auctionEndTime[auctionId] = now.add(auction.timerSeconds);
    }

    function deposit(uint amount) public {
      require(lovePoints.transferFrom(msg.sender, address(this), amount),"Transfer failed");
      loveBalances[msg.sender] = loveBalances[msg.sender].add(amount);
    }

    function withdrawAll() external {
      withdraw(loveBalances[msg.sender], msg.sender);
    }

    function withdraw(uint amount, address to) public {
      require(loveBalances[msg.sender] >= amount, "Cannot withdraw more than balance");
      require(amount > 0, "Must withdraw at least 1 wei of Love");
      loveBalances[msg.sender] = loveBalances[msg.sender].sub(amount);
      uint toBurn = amount.mulBP(500); //5% burn on withdraw
      lovePoints.burn(toBurn); 
      require(lovePoints.transfer(to, amount.sub(toBurn)),"Transfer Failed");
    }

    function getAuction(uint auctionId) external view returns(
      uint portraitId,
      uint startingBid,
      uint minIncreaseBP,
      uint artistComissionBP,
      uint timerSeconds,
      uint startTime,
      address artist,
      uint endTime,
      address lastBidder,
      uint lastBid,
      bool isClaimed
    ) {
      Auction memory auction = auctions[auctionId];
      portraitId = auction.portraitId;
      startingBid = auction.startingBid;
      minIncreaseBP = auction.minIncreaseBP;
      artistComissionBP = auction.artistComissionBP;
      timerSeconds = auction.timerSeconds;
      startTime = auction.startTime;
      artist = auction.artist;
      endTime = auctionEndTime[auctionId];
      lastBidder = auctionLastBidder[auctionId];
      lastBid = auctionLastBid[auctionId];
      isClaimed = auctionIsClaimed[auctionId];
    }
}
