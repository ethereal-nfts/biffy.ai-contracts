pragma solidity 0.5.17;

import "./BiffyLovePoints.sol";
import "./LoveCycle.sol";
import "./interfaces/UniswapExchangeInterface.sol";
import "./library/BasisPoints.sol";

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/roles/WhitelistedRole.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";

contract BastetsExchange is Initializable, WhitelistedRole, Ownable {
    using BasisPoints for uint;
    using SafeMath for uint;

    BiffyLovePoints private biffyLovePoints;
    LoveCycle private loveCycle;

    uint public invokerMaxEtherOffering;
    uint public invocationLove;
    bool public isRitualSetUp;
    uint public totalInvocationOffering;
    mapping(address=>uint) public invokerOffering;

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

    event BastetInvocation(address invoker, string message);
    event BastetInvocationEtherOffering(address supplicant, string message, uint ether);
    event BastetInvocationLoveClaim(address supplicant, uint love);
    event BastetEtherOffering(address suplicant, string message, uint ether);
    event BastetLoveOffering(address supplicant, string message, uint love);

    modifier whileInvokingBastet() {
        require(
        !loveCycle.hasStarted(),
        "The LoveCycles have begun and Bastet has been invoked."
        );
        require(
            isRitualSetUp,
            "Awaiting ritual set up."
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
        LoveCycle _loveCycle
    ) public initializer {
        WhitelistedRole.initialize(msg.sender);
        Ownable.initialize(msg.sender);
        biffyLovePoints = _biffyLovePoints;
        loveCycle = _loveCycle;
    }

    function bastetRitualSetUp(_invokerMaxEtherOffering, _invocationLove) public onlyOwner {
        require(!isRitualSetUp, "Bastet ritual already set up.");
        invokerMaxEtherOffering = _invokerMaxEtherOffering;
        invocationLove = _invocationLove;
        isRitualSetUp = true;
        biffyLovePoints.mint(address(this), invocationLove);
    }

    function invokeBastet() public payable onlyWhitelisted whileInvokingBastet {
        require(invokerOffering[msg.sender].add(msg.value) <= invokerMaxEtherOffering, "Maximum offering exceeded.");
        invokerOffering[msg.sender] = invokerOffering[msg.sender].add(msg.value);
        totalInvocationOffering += msg.value;
        if (bastetInvocationScriptLine < 13) {
            emit BastetInvocation(msg.sender, bastetInvocationScript[bastetInvocationScriptLine]);
            bastetInvocationScriptLine++;
        }
        emit BastetInvocationEtherOffering(msg.sender, bastetOfferingEtherScript, msg.value);
    }

    function claimInvocationLove() public onlyWhitelisted whenBastetInvoked {
        require(invokerOffering[msg.sender] > 0, "Invoker has no Love claim remaining.");
        uint loveClaim = totalOffered.mul(invocationLove).div(invokerOffering[msg.sender]);
        invokerOffering[msg.sender] = 0;
        biffyLovePoints.transfer(msg.sender, loveClaim);
        emit BastetInvocationLoveClaim(msg.sender, loveClaim);
    }

    function getEtherLoveRate() public pure returns (uint) {
        return magicNumber.mul(sqrt(biffyLovePoints.totalSupply()))
    }

    function amtEtherFromLoveSacrifice(uint loveAmount) public pure returns (uint) {
        uint loveSupply = biffyLovePoints.totalSupply();
        uint loveSupplyFinal = loveSupply.sub(loveAmount);
        return magicNumber.mul(2).div(3).mul(
            loveSupply.mul(sqrt(loveSupply)).sub(
                loveSupplyFinal.mul(sqrt(loveSupplyFinal))
            )
        );
    }

    function amtEtherToEarnLove(uint loveAmount) public pure returns (uint) {
        uint loveSupply = biffyLovePoints.totalSupply();
        uint loveSupplyFinal = loveSupply.add(loveAmount);
        return magicNumber.mul(2).div(3).mul(
            loveSupplyFinal.mul(sqrt(loveSupplyFinal)).sub(
                loveSupply.mul(sqrt(loveSupply))
            )
        );
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _updateMagicNumber() internal {
        uint loveSupply = biffyLovePoints.totalSupply();
        magicNumber = address(this).balance.mul(3).div(2).div(
            loveSupply.mul(sqrt(loveSupply))
        );
    }
}
