/**
 * Created on: 5/9/2020
 * @summary: Basis points math calculations.
 * @author: Ethereal
 */
pragma solidity 0.5.17;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";


library BasisPoints {
    using SafeMath for uint;

    uint constant private BASIS_POINTS = 10000;

/**
 * @dev : Calculates percentage of uint with basis points.
 * @param amt :  Amount to multiply by bp.
 * @param bp :  Basis Points to multiply with. 100 BP is 1%.
 * @return : Amount * BP / 10000.
 */
    function mulBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        return amt.mul(bp).div(BASIS_POINTS);
    }

    function addBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.add(mulBP(amt, bp));
    }

    function subBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.sub(mulBP(amt, bp));
    }
}
