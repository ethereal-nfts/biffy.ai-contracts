pragma solidity 0.5.17;

import "./BiffyLovePoints.sol";
import "./LoveCycle.sol";
import "./interfaces/UniswapExchangeInterface.sol";
import "./library/BasisPoints.sol";

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";


contract BastetRitual is Initializable {
    using BasisPoints for uint;
    using SafeMath for uint;

    BiffyLovePoints private biffyLovePoints;
    UniswapExchangeInterface private uniswapExchange;
    LoveCycle private loveCycle;

    uint public sacrificeSize;    //Total Love available in each sacrifice
    uint public sacrificeTime;    //duration of each sacrifice
    uint public sacrificeCount;   //maximum number of sacrifices
    uint public unclaimedDecayBP; //Decay per day for unclaimed Love

    mapping(address => mapping(uint => uint)) public participantSacrificeEther;
    mapping(uint => uint) public sacrificeEther;

    modifier isAnySacrificeActive() {
        require(
        loveCycle.hasStarted(),
        "The first Sacrifice starts at the begining of the LoveCycle."
        );
        require(
        loveCycle.daysSinceCycleStart() < sacrificeCount,
        "Final Sacrifice has ended."
        );
        _;
    }

    function initialize(
        BiffyLovePoints _biffyLovePoints,
        UniswapExchangeInterface _uniswapExchange,
        LoveCycle _loveCycle,
        uint _sacrificeSize,
        uint _sacrificeTime,
        uint _sacrificeCount,
        uint _unclaimedDecayBP
    ) public initializer {
        biffyLovePoints = _biffyLovePoints;
        uniswapExchange = _uniswapExchange;
        loveCycle = _loveCycle;
        sacrificeSize = _sacrificeSize;
        sacrificeTime = _sacrificeTime;
        sacrificeCount = _sacrificeCount;
        unclaimedDecayBP = _unclaimedDecayBP;
    }

    function sacrificeForLove() public payable isAnySacrificeActive {
        require(msg.value > 0, "Sacrifice Ether to earn Love.");
        uint currentSacrifice = loveCycle.daysSinceCycleStart();
        participantSacrificeEther[msg.sender][currentSacrifice] =
            participantSacrificeEther[msg.sender][currentSacrifice].add(msg.value);
        sacrificeEther[currentSacrifice] =
            sacrificeEther[currentSacrifice].add(msg.value);
    }
}
