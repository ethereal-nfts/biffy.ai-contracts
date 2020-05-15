pragma solidity 0.5.17;

import "./BiffyLovePoints.sol";
import "./interfaces/UniswapExchangeInterface.sol";
import "./library/BasisPoints.sol";

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";


contract BastetAuction is Initializable {
    using BasisPoints for uint;
    using SafeMath for uint;

    BiffyLovePoints private biffyLovePoints;
    UniswapExchangeInterface private uniswapExchange;

    function initialize(
        BiffyLovePoints _biffyLovePoints,
        UniswapExchangeInterface _uniswapExchange
    ) public initializer {
        biffyLovePoints = _biffyLovePoints;
        uniswapExchange = _uniswapExchange;
    }
}
