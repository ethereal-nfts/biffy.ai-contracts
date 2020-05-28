pragma solidity 0.5.17;

import "./BiffyLovePoints.sol";
import "./LoveCycle.sol";
import "./interfaces/UniswapExchangeInterface.sol";
import "./library/BasisPoints.sol";

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";


contract BastetsExchange is Initializable {
    using BasisPoints for uint;
    using SafeMath for uint;

    BiffyLovePoints private biffyLovePoints;
    LoveCycle private loveCycle;

    uint public invokerMaxEtherOffering = 4 ether;
    mapping(address=>bool) public approvedInvokers;
    mapping(address=>uint) public invokerOfferings;

    uint public invocationSuccessLoveGift = 45000000;

    uint public bastetInvocationScriptLine = 0;

    string[13] public bastetInvocationScript = [
        "Bastet, Lady of Asheru",
        "Ruler of Skhet-Neter",
        "Life of the Two Lands",
        "We call to you",
        "Hear our prayers",
        "We come in love",
        "We come in peace",
        "We come in joy",
        "And ask that we may speak",
        "May your essence enter the contract",
        "And become your digital body",
        "Dwell here in gentleness",
        "And let your blessings lie upon us."
    ];

    uint public magicNumber;

    string public bastetOfferingEtherScript = "I offer this Ether to you, Daughter of Ra.";
    string public bastetOfferingLoveScripte = "I offer this Love to you, Queen of Cats.";

    modifier whileInvokingBastet() {
        require(
        !loveCycle.hasStarted(),
        "The LoveCycles have begun and Bastet has been invoked."
        );
        _;
    }

    modifier whenBastetInvoked() {
        require(
        loveCycle.hasStarted(),
        "Bastet has not yet been invoked. Wait for the first Love Cycle."
        );
        _;
    }

    function initialize(
        BiffyLovePoints _biffyLovePoints,
        LoveCycle _loveCycle,
    ) public initializer {
        biffyLovePoints = _biffyLovePoints;
        loveCycle = _loveCycle;
    }

    function getSqrt(uint num, uint low, uint high) public pure returns (uint) {
        require(high.sub(1) == low);
        require(low.mul(low) <= num);
        require(high.mul(high) >= num);
        if (high == num) return high;
        return low;
    }
}
