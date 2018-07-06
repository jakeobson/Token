pragma solidity ^0.4.23;

import "./MySuperCoin.sol";

import "../node_modules/openzeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol";
import "../node_modules/openzeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol";

contract TokenCrowdsale is MintedCrowdsale, FinalizableCrowdsale {
    
    using SafeMath for uint256;

    // uint8 public decimals = 18;
    uint8 public currentStageNumber = 0;
    

    // ICO STAGE
    // ==============================

    struct Stage {
        uint256 percentage;
        uint256 limit;
        uint256 totalTokens;
        uint256 totalWei;
    }

    Stage[] stages;

    Stage public currentStage;

    // =============================


    // Token Distribution
    // =============================

    // uint256 public constant TOTAL_SUPPLY = 400000000 * (10 ** uint256(decimals));
    uint256 public constant TOTAL_SUPPLY = 400000000 ether;
    // uint256 public constant TOTAL_FOR_SALE = 240000000 * (10 ** uint256(decimals));
    uint256 public constant TOTAL_FOR_SALE = 240000000 ether;
    // uint256 public constant TOKENS_FOR_TEAM = 100000000 * (10 ** uint256(decimals));
    uint256 public constant TOKENS_FOR_TEAM = 100000000 ether;
    // uint256 public constant TOKENS_FOR_PARTNERS = 20000000 * (10 ** uint256(decimals));
    uint256 public constant TOKENS_FOR_PARTNERS = 20000000 ether;
    // uint256 public constant TOKENS_FOR_CUSTOMERS = 40000000 * (10 ** uint256(decimals));
    uint256 public constant TOKENS_FOR_CUSTOMERS = 40000000 ether;

    // ==============================
  
    uint256 public currentEthereumRate;

    uint256 public tokenBasePrice = 7 * 10 ** 4; // it's 0.07 so we have to divide by 100 (added 4 zeroes for a better calculating)

    // Events
    event EthTransferred(string text);
    event EthRefunded(string text);

    constructor(
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _rate,
        address _wallet,
        MintableToken _token,
        uint256 _currentEthereumRate
    )
    Crowdsale(_rate, _wallet, _token) 
    TimedCrowdsale(_openingTime, _closingTime)
    public {
        currentEthereumRate = _currentEthereumRate;

        //Presale One - 50% discount
        // stages.push(Stage(50 * 10 ** 4, 60000000 * (10 ** uint256(decimals)), 0, 0));
        stages.push(Stage(50 * 10 ** 4, 60000000 ether, 0, 0));

        //Presale Two - 35% discount
        stages.push(Stage(65 * 10 ** 4, 80000000 ether, 0, 0));

        //ICO - 0% discount
        stages.push(Stage(100 * 10 ** 4, 100000000 ether, 0, 0));

        currentStage = stages[0];

        _setCurrentTokenRate();
    }

    // Token Deployment
    // =================
    function createTokenContract() internal returns (MintableToken) {
        return new MySuperCoin(); // Deploys the ERC20 token. Automatically called when crowdsale contract is deployed
    }

    function setClosingTime(uint256 _closingTime) public onlyOwner {
        closingTime = _closingTime;
    }

    // Crowdsale Stage Management
    // =========================================================

    // Change Crowdsale Stage. Available Options: PresaleOne, PresaleTwo, ICO
    function setCrowdsaleStage(uint8 _stage) public onlyOwner onlyWhileOpen {

        require(_stage > 0 && _stage <= 2);

        currentStageNumber = _stage;

        currentStage = stages[_stage];

        _setCurrentTokenRate();
    }

    //setCurrent Ethereum Rate

    function setCurrentEthereumRate(uint256 _rate) public onlyOwner onlyWhileOpen {
        require(rate > 0);

        currentEthereumRate = _rate;

        _setCurrentTokenRate();
    }

    function setWallet(address _wallet) public onlyOwner onlyWhileOpen {
        require(wallet != _wallet);
        require(_wallet != address(0));
        
        wallet = _wallet;
    }

    function _setCurrentTokenRate() private {

        uint256 currentTokenBasePrice = (tokenBasePrice.div(100)).mul((currentStage.percentage).div(100));
        uint256 _rate = uint256((currentEthereumRate.mul(10**8)).div((currentTokenBasePrice)));
        
        rate = _rate;
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {

        super._preValidatePurchase(_beneficiary, _weiAmount);

        require(_weiAmount >= 0.001 ether);

        uint256 totalTokensAfterMinting = currentStage.totalTokens.add(_weiAmount.mul(rate));

        if(totalTokensAfterMinting > currentStage.limit){

            msg.sender.transfer(_weiAmount);
            emit EthRefunded("The Limit was hit, refunded");
            return;
        }

    }

    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal{
        currentStage.totalWei = currentStage.totalWei.add(_weiAmount);
        currentStage.totalTokens = currentStage.totalTokens.add(_weiAmount.mul(rate));
    }

    function finish(address _teamVault, address _usersVault, address _investorVault) public onlyOwner{

        finalize();

        uint256 alreadyMinted = token.totalSupply();

        require(alreadyMinted < TOTAL_FOR_SALE);

        uint256 unsoldTokens = TOTAL_FOR_SALE.sub(alreadyMinted);
        
        MintableToken(token).mint(_teamVault, TOKENS_FOR_TEAM.add(unsoldTokens));
        MintableToken(token).mint(_usersVault, TOKENS_FOR_CUSTOMERS);
        MintableToken(token).mint(_investorVault, TOKENS_FOR_PARTNERS);
        
    }
}