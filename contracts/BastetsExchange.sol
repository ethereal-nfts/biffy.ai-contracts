pragma solidity 0.5.17;

import "./BiffyLovePoints.sol";
import "./LoveCycle.sol";
import "./interfaces/UniswapExchangeInterface.sol";

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/roles/WhitelistedRole.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";


contract BastetsExchange is Initializable, WhitelistedRole, Ownable, ReentrancyGuard {
    using SafeMath for uint;

    BiffyLovePoints private biffyLovePoints;

    uint public invokerMaxEtherOffering;
    uint public invocationLove;
    bool public isRitualSetUp;
    uint public totalInvocationOffering;
    mapping(address=>uint) public invokerOffering;

    uint public invocationEndTime;

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
    uint public magicNumberDivisor = 1 ether;

    uint public lastMagicNumberUpdateEther;
    uint public lastMagicNumberUpdateLove;

    string public bastetOfferingEtherScript = "I offer this Ether to you, Daughter of Ra.";
    string public bastetOfferingLoveScript = "I offer this Love to you, Queen of Cats.";

    event BastetInvocation(address invoker, string message);
    event BastetInvocationEtherOffering(address supplicant, string message, uint eth);
    event BastetInvocationLoveClaim(address supplicant, uint love);
    event BastetEtherOffering(address suplicant, string message, uint eth, uint love);
    event BastetLoveOffering(address supplicant, string message, uint eth, uint love);

    modifier whileInvokingBastet() {
        require(
        now <= invocationEndTime,
        "Bastets Invocation is complete."
        );
        _;
    }

    modifier whenBastetInvoked() {
        require(
        now > invocationEndTime,
        "Bastets Invocation has not yet finished."
        );
        _;
    }

    function initialize(
        BiffyLovePoints _biffyLovePoints,
        uint _invokerMaxEtherOffering,
        uint _invocationLove,
        uint _invocationEndTime
    ) public initializer {
        WhitelistedRole.initialize(msg.sender);
        Ownable.initialize(msg.sender);
        ReentrancyGuard.initialize();

        biffyLovePoints = _biffyLovePoints;

        invokerMaxEtherOffering = _invokerMaxEtherOffering;
        invocationLove = _invocationLove;
        invocationEndTime = _invocationEndTime;

        biffyLovePoints.mint(address(this), invocationLove);
    }

    function invokeBastet() public payable onlyWhitelisted whileInvokingBastet {
        require(invokerOffering[msg.sender].add(msg.value) <= invokerMaxEtherOffering, "Maximum offering exceeded.");
        require(msg.value > 0, "Must send at least 1 wei.");
        updateMagicNumber();
        invokerOffering[msg.sender] = invokerOffering[msg.sender].add(msg.value);
        totalInvocationOffering += msg.value;
        if (bastetInvocationScriptLine < 13 && invokerOffering[msg.sender] == 0) {
            emit BastetInvocation(msg.sender, bastetInvocationScript[bastetInvocationScriptLine]);
            bastetInvocationScriptLine++;
        }
        emit BastetInvocationEtherOffering(msg.sender, bastetOfferingEtherScript, msg.value);
    }

    function claimInvocationLove() public onlyWhitelisted whenBastetInvoked {
        require(invokerOffering[msg.sender] > 0, "Invoker has no Love claim remaining.");
        uint loveClaim = totalInvocationOffering.mul(invocationLove).div(invokerOffering[msg.sender]);
        invokerOffering[msg.sender] = 0;
        biffyLovePoints.transfer(msg.sender, loveClaim);
        emit BastetInvocationLoveClaim(msg.sender, loveClaim);
    }

    function sacrificeEtherForLove(uint loveAmount) public payable nonReentrant returns (uint) {
        uint etherAmount = amtEtherToEarnLove(loveAmount);
        require(msg.value >= etherAmount, "Must sacrifice enough Ether.");
        biffyLovePoints.mint(msg.sender, loveAmount);
        if (msg.value > etherAmount) msg.sender.transfer(msg.value.sub(etherAmount));
        emit BastetEtherOffering(msg.sender, bastetOfferingEtherScript, etherAmount, loveAmount);
        return etherAmount;
    }

    function sacrificeLoveForEther(uint loveAmount) public payable nonReentrant returns (uint) {
        uint etherAmount = amtEtherFromLoveSacrifice(loveAmount);
        require(biffyLovePoints.balanceOf(msg.sender) >= loveAmount);
        biffyLovePoints.burnFrom(msg.sender, loveAmount);
        emit BastetLoveOffering(msg.sender, bastetOfferingLoveScript, etherAmount, loveAmount);
        msg.sender.transfer(etherAmount);
    }

    function getEtherLoveRate() public view returns (uint) {
        return magicNumber.mul(sqrt(biffyLovePoints.totalSupply()));
    }

    function amtEtherFromLoveSacrifice(uint loveAmount) public view returns (uint) {
        uint loveSupply = biffyLovePoints.totalSupply();
        uint loveSupplyFinal = loveSupply.sub(loveAmount);
        return magicNumber.mul(2).div(3).mul(
            loveSupply.mul(sqrt(loveSupply)).sub(
                loveSupplyFinal.mul(sqrt(loveSupplyFinal))
            )
        );
    }

    function amtEtherToEarnLove(uint loveAmount) public view returns (uint) {
        uint loveSupply = biffyLovePoints.totalSupply();
        uint loveSupplyFinal = loveSupply.add(loveAmount);
        return magicNumber.mul(2).div(3).mul(
            loveSupplyFinal.mul(sqrt(loveSupplyFinal)).sub(
                loveSupply.mul(sqrt(loveSupply))
            )
        );
    }

    function updateMagicNumber() public {
        uint loveSupply = biffyLovePoints.totalSupply();
        if (
            lastMagicNumberUpdateEther == address(this).balance &&
            lastMagicNumberUpdateLove == loveSupply
        )   return;
        if (address(this).balance == 0) magicNumber = 1;
        magicNumber = address(this).balance.mul(magicNumberDivisor).mul(3).div(2).div(
            loveSupply.mul(sqrt(loveSupply))
        );
    }

    function addMultipleWhitelisted(address[] memory accounts) public onlyWhitelistAdmin {
        for (uint i = 0; i < accounts.length; i++) {
            addWhitelisted(accounts[i]);
        }
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

}
