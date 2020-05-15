pragma solidity 0.5.17;


import "../interfaces/UniswapExchangeInterface.sol";

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";


//This mock is for testing adding liquidity only.
//An actual exchange will need to be launched by the official UniswapFactory contract first.
contract MockUniswapExchange is UniswapExchangeInterface, Initializable {
    using SafeMath for uint;

    IERC20 token;

    // Invest liquidity and receive market shares
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline)
    external payable returns (uint256)
    {
        require(deadline > now);
        require(max_tokens > 0);
        require(msg.value > 0);
        require(min_liquidity > 0);
        uint eth_reserve = address(this).balance.sub(msg.value);
        uint token_reserve = token.balanceOf(address(this));
        uint token_amount = msg.value.mul(token_reserve).div(eth_reserve);
        require(max_tokens > token_amount);
        token.transferFrom(msg.sender, address(this), token_amount);
        return 0;
    }

    function getEthToTokenInputPrice(uint256 eth_sold)
    external view returns (uint256 tokens_bought)
    {
        uint input_amount = eth_sold;
        uint input_reserve = address(this).balance;
        uint output_reserve = token.balanceOf(address(this));

        uint input_amount_with_fee = input_amount.mul(997);
        uint numerator = input_amount_with_fee.mul(output_reserve);
        uint denominator = input_reserve.mul(1000).add(input_amount_with_fee);
        return numerator.div(denominator);
    }

    function initialize(IERC20 _token, uint tokensToTransfer) public initializer payable {
        token = _token;
        token.transferFrom(msg.sender, address(this), tokensToTransfer);
    }
}
