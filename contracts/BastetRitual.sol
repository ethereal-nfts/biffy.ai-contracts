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
    uint public sacrificeCount;   //maximum number of sacrifices
    uint public rewardDecayBP; //Decay per day for unclaimed Love

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
        uint _sacrificeCount,
        uint _rewardDecayBP
    ) public initializer {
        biffyLovePoints = _biffyLovePoints;
        uniswapExchange = _uniswapExchange;
        loveCycle = _loveCycle;
        sacrificeSize = _sacrificeSize;
        sacrificeCount = _sacrificeCount;
        rewardDecayBP = _rewardDecayBP;
    }

    function sacrificeForLove() public payable isAnySacrificeActive {
        require(msg.value > 0, "Sacrifice Ether to earn Love.");
        uint sacrifice = loveCycle.daysSinceCycleStart();
        participantSacrificeEther[msg.sender][sacrifice] =
            participantSacrificeEther[msg.sender][sacrifice].add(msg.value);
        sacrificeEther[sacrifice] =
            sacrificeEther[sacrifice].add(msg.value);
    }

    function claimReward(uint sacrifice) public {
        uint amount = calculateReward(msg.sender, sacrifice);
        participantSacrificeEther[msg.sender][sacrifice] = 0;
        biffyLovePoints.mint(msg.sender, amount);
    }

    function calculateReward(address participant, uint sacrifice) public view returns (uint) {
        uint currentDay = loveCycle.daysSinceCycleStart();
        require(sacrifice < currentDay, "Sacrifice must have already occured.");
        require(sacrifice < sacrificeCount, "Must be a valid sacrifice.");
        uint daysSinceSacrificeEnd = sacrifice.sub(currentDay).sub(1);
        uint base = participantSacrificeEther[participant][sacrifice]
            .mul(sacrificeSize)
            .div(sacrificeEther[sacrifice]);
        if (daysSinceSacrificeEnd == 0) return base;
        if (daysSinceSacrificeEnd >= 20) return 0;
        return base.sub(base.mulBP(rewardDecayBP.mul(daysSinceSacrificeEnd)));
    }
}
