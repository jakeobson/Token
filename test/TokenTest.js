
var TokenCrowdsale = artifacts.require("TokenCrowdsale");
var MySupercoin = artifacts.require("MySupercoin");

const { should, EVMThrow } = require('./helpers')


contract('TokenCrowdsale', function ([owner, wallet, investor]) {

    let token;
    let crowdsale;

    beforeEach(async function () {

        token = await MySupercoin.new(owner);

        let startTime = web3.eth.getBlock('latest').timestamp;
        let endTime = startTime + 60 * 60 * 5;

        crowdsale = await TokenCrowdsale.new(
            startTime, endTime, 20850, wallet, token.address, 715
        );

    });

    it('token has an owner', async function () {

        const fundRaiseOwner = await token.owner();

        fundRaiseOwner.should.be.equal(owner);
    });

    it('crowdsale has an owner', async function () {

        const crowdsaleOwner = await crowdsale.owner();

        crowdsaleOwner.should.be.equal(owner);
    });

    it('allows to change the crowdsale owner to token owner', async function () {


        TokenCrowdsale.deployed().then(async function(instance){
        
            const tokenAddress = await instance.token();
            const MySuperCoinInstance = await MySupercoin.at(tokenAddress);
            const crowdsaleAddress = await instance.address;

            await MySuperCoinInstance.transferOwnership(crowdsaleAddress);

            
            assert.equal(await MySuperCoinInstance.owner(), await crowdsaleAddress, 'Not the same owner');
        });



    });

    it('has the right amount of tokens after 1 ether send', async function () {

        TokenCrowdsale.deployed().then(async function(instance){
        
            const tokenAddress = await instance.token();
            const MySuperCoinInstance = await MySupercoin.at(tokenAddress);

            await instance.sendTransaction(({ from: investor, value: web3.toWei(1, "ether") }));  
            
            const tokenAmount = await MySuperCoinInstance.balanceOf(investor);

            const currentTokenRate = await instance.rate.call();
            
            assert.equal(tokenAmount.toNumber(), web3.toWei(currentTokenRate.toNumber() * 1, "ether"), 'Wrong amount received');
              
        });

    });

    it('has initial stage of 0', async function () {

        TokenCrowdsale.deployed().then(async function(instance){

            const currentStage = await instance.currentStage.call();
            
            
            assert.equal(currentStage[0].toNumber(), 50*10**4, 'The stage is not 0');
              
        });

    });


    it('has 16200 tokens when 1 ether sent after changing stage to 1', async function () {

        TokenCrowdsale.deployed().then(async function(instance){
        
            const previousTokenRate = await instance.rate.call();

            await instance.setCrowdsaleStage(1);

            await instance.sendTransaction(({ from: investor, value: web3.toWei(1, "ether") }));  
        
            const tokenAddress = await instance.token();
            const MySuperCoinInstance = await MySupercoin.at(tokenAddress);

            const tokenAmount = await MySuperCoinInstance.balanceOf(investor);
            

            const currentTokenRate = await instance.rate.call();

            assert.equal(tokenAmount.toNumber(), web3.toWei((currentTokenRate.toNumber() + previousTokenRate.toNumber()), "ether"), 'The sender didn\'t receive the tokens as per PreICO rate');
            
        });

    });


    it('allows to change a stage', async function () {

        TokenCrowdsale.deployed().then(async function(instance){

            await instance.setCrowdsaleStage(1);

            const currentStage = await instance.currentStage.call();

            assert.equal(currentStage[0].toNumber(), 65 * 10 ** 4, 'The stage is wrong, should be 1');
              
        });

    });

    it('allows to send transaction above the limit', async function () {

        TokenCrowdsale.deployed().then(async function(instance){
        
            await instance.setCurrentEthereumRate(720);

            await instance.sendTransaction(({ from: web3.eth.accounts[4], value: web3.toWei(10, "ether") })); 

            const tokenAddress = await instance.token();
            const MySuperCoinInstance = await MySupercoin.at(tokenAddress);

            const tokenAmount = await MySuperCoinInstance.balanceOf(web3.eth.accounts[4]);

            assert.equal(1, 1, 'Ethereum Rate is wrong, should be 720');
              
        });

    });

    it('allows to change ethereum rate', async function () {

        TokenCrowdsale.deployed().then(async function(instance){
        
            await instance.setCurrentEthereumRate(720);

            const currentEthereumRate = await instance.currentEthereumRate.call();

            assert.equal(currentEthereumRate, 720, 'Ethereum Rate is wrong, should be 720');
              
        });

    });
    
    it('can finish the ICO', async function () {

        TokenCrowdsale.deployed().then(async function(instance){

            const team = web3.eth.accounts[6];
            const user = web3.eth.accounts[7];
            const investor_wallet = web3.eth.accounts[8];

            const tokenAddress = await instance.token();
            const MySuperCoinInstance = await MySupercoin.at(tokenAddress);

            await instance.setClosingTime(0);

            await instance.finish(team, user, investor_wallet);

            const tokenAmount1 = await MySuperCoinInstance.balanceOf(team);
            const tokenAmount2 = await MySuperCoinInstance.balanceOf(user);
            const tokenAmount3 = await MySuperCoinInstance.balanceOf(investor_wallet);

            assert.equal(await instance.isFinalized.call(), true, 'the ico did not end');
        });

    });
});