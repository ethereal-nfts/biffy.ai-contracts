pragma solidity 0.5.17;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";


contract BiffysLove is ERC20Mintable, ERC20Detailed, ERC20Burnable, Ownable {
    mapping (address => bool) public minters;

    function initialize(
        string memory name, string memory symbol, uint8 decimals, address biffysMind
    ) public initializer {
        Ownable.initialize(biffysMind);
        ERC20Detailed.initialize(name, symbol, decimals);
        ERC20Mintable.initialize(biffysMind);
    }
}
