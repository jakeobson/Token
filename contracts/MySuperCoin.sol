pragma solidity 0.4.23;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";

contract MySuperCoin is MintableToken {
    
    string public name = "Ojooo Coin";
    string public symbol = "OJX";
    uint8 public decimals = 18;
}