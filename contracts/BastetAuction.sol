pragma solidity 0.5.17;

import "./BiffyLovePoints.sol";
//import "./mocks/MockUniswapFactory.vy";
//import "./mocks/MockUniswapExchange.vy";
import "./library/BasisPoints.sol";

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";


contract BastetAuction is Initializable {
    using BasisPoints for uint;
    using SafeMath for uint;

    //BiffyLovePoints private biffyLovePoints;
    //MockUniswapFactory private mockUniswapFactory;

    function initialize(
        //BiffyLovePoints _biffyLovePoints,
        //MockUniswapFactory _mockUniswapFactory
    ) public initializer {
        //biffyLovePoints = _biffyLovePoints;
        //mockUniswapFactory = _mockUniswapFactory;
    }
}
