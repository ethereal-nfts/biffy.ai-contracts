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

    modifier isAnyLobbyActive() {
        require(
        loveCycle.hasStarted(),
        "The first Sacrifice starts at the begining of the LoveCycle."
        );
        require(
        loveCycle.daysSinceCycleStart() < lobbyCount,
        "Final Sacrifice has ended."
        )
    }

    function initialize(
        BiffyLovePoints _biffyLovePoints,
        UniswapExchangeInterface _uniswapExchange,
        LoveCYcle _loveCycle,
        uint _lobbySize,
        uint _lobbyTime,
        uint _lobbyCount,
        uint _unclaimedDecayBP
    ) public initializer {
        biffyLovePoints = _biffyLovePoints;
        uniswapExchange = _uniswapExchange;
        loveCycle = _loveCycle;
        lobbySize = _lobbySize;
        lobbyTime = _lobbyTime;
        lobbyCount = _lobbyCount;
        unclaimedDecayBP = _unclaimedDecayBP;
    }

    function sacrificeForLove() public payable isAnyLobbyActive {
        require(msg.value > 0, "Sacrifice Ether to earn Love.");
        uint currentSacrifice = loveCycle.daysSinceCycleStart();
        participantSacrificeEther[msg.sender][currentSacrifice] =
            participantSacrificeEther[msg.sender][currentSacrifice].add(msg.value);
        sacrificeEther[currentSacrifice] =
            sacrificeEther[currentSacrifice].add(msg.value);
    }

    
}
