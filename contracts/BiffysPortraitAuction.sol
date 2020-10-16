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
      deposit(amount);
      bid(auctionId,amount);
    }

    function bid(uint auctionId, uint amount) public {
      Auction memory auction = auctions[auctionId];
      require(now < auctionEndTime[auctionId], "Auction ended");
      require(now > auction.startTime && auction.startTime != 0, "Auction not started");
      require(amount >= auctionLastBid[auctionId].addBP(auction.minIncreaseBP), "Bid too low");
      require(amount >= auction.startingBid, "Bid below starting bid");
      require(loveBalances[msg.sender] >= amount, "Love balance too low");
      if(auctionLastBid[auctionId] != 0) {
        loveBalances[auctionLastBidder[auctionId]] = loveBalances[auctionLastBidder[auctionId]].add(auctionLastBid[auctionId]);
      }
      loveBalances[msg.sender] = loveBalances[msg.sender].sub(amount);
      auctionLastBid[auctionId] = amount;
      auctionLastBidder[auctionId] = msg.sender;
      auctionEndTime[auctionId] = now.add(auction.timerSeconds);
    }

    function deposit(uint amount) public {
      lovePoints.transferFrom(msg.sender, address(this), amount);
      loveBalances[msg.sender] = loveBalances[msg.sender].add(amount);
    }

    function withdraw(uint amount, address to) external {
      require(loveBalances[msg.sender] >= amount, "Cannot withdraw more than balance");
      loveBalances[msg.sender] = loveBalances[msg.sender].sub(amount);
      uint toBurn = amount.mulBP(500); //5% burn on withdraw
      lovePoints.burn(toBurn); 
      lovePoints.transfer(to, amount.sub(toBurn));
    }
}
