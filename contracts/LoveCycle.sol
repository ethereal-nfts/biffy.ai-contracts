pragma solidity 0.5.17;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";


contract LoveCycle is Initializable {
    using SafeMath for uint;

    uint constant public CYCLE_LENGTH = 30 days;

    uint public startTime;

    function initialize(
        uint _startTime
    )
    public initializer {
        startTime = _startTime;
    }

    function hasStarted() public view returns (bool) {
        return now > startTime;
    }

    function currentCycle() public view returns (uint) {
        if (now < startTime) return 0;
        return now.sub(startTime).div(CYCLE_LENGTH).add(1);
    }

    function daysSinceCycleStart() public view returns (uint) {
        require(hasStarted(), "Must be in cycle 1 or higher.");
        return now.sub(startTime).div(86400).mod(30); //days since cycle start, rounded down.
    }
}
