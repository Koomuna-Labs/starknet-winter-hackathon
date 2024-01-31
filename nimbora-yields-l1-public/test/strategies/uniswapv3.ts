import { ethers, network, upgrades } from "hardhat";
import { expect } from "chai";
import { Contract, Wallet } from "ethers";

const maxUint256 = "115792089237316195423570985008687907853269984665640564039457584007913129639935"
describe("Strategy UniswapV3 Test", function () {

    async function loadFixture() {
        const owner = await ethers.provider.getSigner(0);

        const poolingManagerMockFactory = await ethers.getContractFactory('PoolingManagerMock');
        const poolingManager = await poolingManagerMockFactory.deploy();
        const poolingManagerAddress = await poolingManager.getAddress()

        const uniswapV3FactoryMockFactory = await ethers.getContractFactory('UniswapV3FactoryMock');
        const uniswapV3FactoryMock = await uniswapV3FactoryMockFactory.deploy();
        const uniswapV3FactoryMockAddress = await uniswapV3FactoryMock.getAddress()

        const erc20MintableMockFactory = await ethers.getContractFactory('ERC20Mock');
        const underlyingToken = await erc20MintableMockFactory.deploy();
        const underlyingTokenAddress = await underlyingToken.getAddress()
        const yieldToken = await erc20MintableMockFactory.deploy();
        const yieldTokenAddress = await yieldToken.getAddress();

        const poolFee = "3000";
        const poolAddress = Wallet.createRandom().address;
        uniswapV3FactoryMock.setPool(underlyingTokenAddress, yieldTokenAddress, poolFee, poolAddress);

        // Pricefeed giving the price of WstETH in ETH, let's take 1.2 ETH
        const mockV3AggregatorFactory = await ethers.getContractFactory('MockV3Aggregator');
        const mockV3Aggregator = await mockV3AggregatorFactory.deploy(18, "1200000000000000000");
        const mockV3AggregatorAddress = await mockV3Aggregator.getAddress();


        const uniswapRouterMockFactory = await ethers.getContractFactory('UniswapRouterMock');
        const uniswapRouterMock = await uniswapRouterMockFactory.deploy();
        const uniswapRouterMockAddress = await uniswapRouterMock.getAddress();

        // initialy set the exchange rate to pricefeed value
        uniswapRouterMock.setExchangeRate(yieldTokenAddress, underlyingTokenAddress, "1200000000000000000")


        const uniswapV3StrategyFactory = await ethers.getContractFactory('UniswapV3Strategy');
        const minReceivedAmountFactor = "990000000000000000"
        const uniswapV3Strategy = await upgrades.deployProxy(uniswapV3StrategyFactory, [
            poolingManagerAddress,
            underlyingTokenAddress,
            yieldTokenAddress,
            uniswapRouterMockAddress,
            uniswapV3FactoryMockAddress,
            mockV3AggregatorAddress,
            minReceivedAmountFactor,
            poolFee
        ]);
        const uniswapV3StrategyAddress = await uniswapV3Strategy.getAddress();


        await yieldToken.mint(owner.address, ethers.parseUnits('100', 'ether'));
        await underlyingToken.mint(owner.address, ethers.parseUnits('100', 'ether'));
        await yieldToken.mint(uniswapRouterMockAddress, ethers.parseUnits('100', 'ether'));
        await underlyingToken.mint(uniswapRouterMockAddress, ethers.parseUnits('100', 'ether'));


        return { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress };
    }

    it("test init", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await loadFixture();
        expect(await uniswapV3Strategy.uniswapRouter()).equal(uniswapRouterMockAddress);
        expect(await uniswapV3Strategy.chainlinkPricefeed()).equal(mockV3AggregatorAddress);
        expect(await uniswapV3Strategy.pricefeedPrecision()).equal("1000000000000000000");
        expect(await uniswapV3Strategy.minReceivedAmountFactor()).equal("990000000000000000");
        expect(await uniswapV3Strategy.poolFee()).equal("3000");
        expect(await underlyingToken.allowance(uniswapV3StrategyAddress, uniswapRouterMockAddress)).equal(maxUint256);
        expect(await yieldToken.allowance(uniswapV3StrategyAddress, uniswapRouterMockAddress)).equal(maxUint256);
    });

    it("test setMinReceivedAmountFactor invalid caller", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await loadFixture();
        const randomAddress = Wallet.createRandom().address;
        await owner.sendTransaction({
            to: randomAddress,
            value: ethers.parseUnits('1', 'ether'),
        });

        await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [randomAddress],
        });
        const impersonatedSigner = await ethers.getSigner(randomAddress);
        const uniswapV3StrategyConnected = uniswapV3Strategy.connect(impersonatedSigner) as Contract;
        await expect(uniswapV3StrategyConnected.setMinReceivedAmountFactor("980000000000000000"))
            .to.be.revertedWithCustomError(uniswapV3Strategy, "InvalidCaller");
        await network.provider.request({
            method: "hardhat_stopImpersonatingAccount",
            params: [randomAddress],
        });
    });

    it("test setMinReceivedAmountFactor invalid slippage", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await loadFixture();
        await expect(uniswapV3Strategy.setMinReceivedAmountFactor("1010000000000000000"))
            .to.be.revertedWith("Invalid slippage");
    });

    it("test setMinReceivedAmountFactor invalid slippage", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await loadFixture();
        await expect(uniswapV3Strategy.setMinReceivedAmountFactor("1010000000000000000"))
            .to.be.revertedWith("Invalid slippage");
    });

    it("test setMinReceivedAmountFactor ", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await loadFixture();
        await uniswapV3Strategy.setMinReceivedAmountFactor("980000000000000000");
        expect(await uniswapV3Strategy.minReceivedAmountFactor()).equal("980000000000000000");
    });

    it("test chainlinkLatestAnswer ", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await loadFixture();
        const value = await uniswapV3Strategy.chainlinkLatestAnswer();
        expect(value).equal("1200000000000000000");
    });

    it("test underlyingToYield ", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await loadFixture();
        const amount = ethers.parseUnits('10', 'ether');
        const yieldAmount = await uniswapV3Strategy.underlyingToYield(amount);
        const expectedAmount = "8333333333333333333";
        expect(yieldAmount).equal(expectedAmount);
    });

    it("test yieldToUnderlying ", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await loadFixture();
        const amount = ethers.parseUnits('10', 'ether');
        const yieldAmount = await uniswapV3Strategy.yieldToUnderlying(amount);
        const expectedAmount = ethers.parseUnits('12', 'ether');
        expect(yieldAmount).equal(expectedAmount);
    });

    it("test applySlippageDepositExactInputSingle ", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await loadFixture();
        const yieldAmount = ethers.parseUnits('10', 'ether');
        const amountOutMinimum = await uniswapV3Strategy.applySlippageDepositExactInputSingle(yieldAmount);
        const expectedAmount = ethers.parseUnits('9.9', 'ether');
        expect(amountOutMinimum).equal(expectedAmount);
    });

    it("test applySlippageDepositExactInputSingle ", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await loadFixture();
        const yieldAmount = ethers.parseUnits('10', 'ether');
        const amountOutMinimum = await uniswapV3Strategy.applySlippageWithdrawExactOutputSingle(yieldAmount);
        const expectedAmount = "10101010101010101010"
        expect(amountOutMinimum).equal(expectedAmount);
    });

    it("test handle report 0 deposit ", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await loadFixture();
        const underlyingAmount = ethers.parseUnits('10', 'ether');
        underlyingToken.transfer(uniswapV3StrategyAddress, underlyingAmount);
        await poolingManager.handleReport(uniswapV3StrategyAddress, '0', underlyingAmount);

        const lastNav = await poolingManager.lastNav();
        const lastWithdrawalAmount = await poolingManager.lastWithdrawalAmount();
        const nav = await uniswapV3Strategy.nav();

        const expectedBalance = "8333333333333333330"
        const yieldBalance = await yieldToken.balanceOf(uniswapV3StrategyAddress);
        expect(yieldBalance).to.equal(expectedBalance);

        const expectedNav = "9999999999999999996"

        expect(lastNav).to.equal(expectedNav);
        expect(lastNav).to.equal(nav);
        expect(lastWithdrawalAmount).to.equal(0);
    });

    it("test handle report 0 deposit revert Insufficient output amount ", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await loadFixture();
        const underlyingAmount = ethers.parseUnits('10', 'ether');
        mockV3Aggregator.updateAnswer("1000000000000000000");
        underlyingToken.transfer(uniswapV3StrategyAddress, underlyingAmount);
        await expect(poolingManager.handleReport(uniswapV3StrategyAddress, '0', underlyingAmount)).to.be.revertedWith("Insufficient output amount")
    });

    it("test handle report 1 report ", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await loadFixture();
        const underlyingAmount = ethers.parseUnits('10', 'ether');
        underlyingToken.transfer(uniswapV3StrategyAddress, underlyingAmount);
        await poolingManager.handleReport(uniswapV3StrategyAddress, '0', underlyingAmount);
        yieldToken.transfer(uniswapV3StrategyAddress, underlyingAmount);
        await poolingManager.handleReport(uniswapV3StrategyAddress, '1', 0);

        const lastNav = await poolingManager.lastNav();
        const lastWithdrawalAmount = await poolingManager.lastWithdrawalAmount();
        const nav = await uniswapV3Strategy.nav();

        const expectedBalance = "18333333333333333330"
        const yieldBalance = await yieldToken.balanceOf(uniswapV3StrategyAddress);
        expect(yieldBalance).to.equal(expectedBalance);

        const expectedNav = "21999999999999999996"

        expect(lastNav).to.equal(expectedNav);
        expect(lastNav).to.equal(nav);
        expect(lastWithdrawalAmount).to.equal(0);
    });

    it("test handle report 2 withdraw amountInMaximum below yield balance", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await loadFixture();

        const yieldAmount = ethers.parseUnits('10', 'ether');
        yieldToken.transfer(uniswapV3StrategyAddress, yieldAmount);

        const withdrawalAmount = ethers.parseUnits('6', 'ether');
        await poolingManager.handleReport(uniswapV3StrategyAddress, '2', withdrawalAmount);

        const lastNav = await poolingManager.lastNav();
        const lastWithdrawalAmount = await poolingManager.lastWithdrawalAmount();
        const nav = await uniswapV3Strategy.nav();

        const expectedWithdraw = ethers.parseUnits('6', 'ether');
        const underlyingBalance = await underlyingToken.balanceOf(poolingManagerAddress);
        expect(underlyingBalance).to.equal(expectedWithdraw);

        const expectedNav = "6000000000000000000"
        expect(lastNav).to.equal(expectedNav);
        expect(lastNav).to.equal(nav);
        expect(lastWithdrawalAmount).to.equal(expectedWithdraw);

    });

    it("test handle report 2 withdraw amountInMaximum below yield balance revert slippage", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await loadFixture();
        mockV3Aggregator.updateAnswer("2000000000000000000");
        const yieldAmount = ethers.parseUnits('10', 'ether');
        yieldToken.transfer(uniswapV3StrategyAddress, yieldAmount);
        const withdrawalAmount = ethers.parseUnits('6', 'ether');
        await expect(poolingManager.handleReport(uniswapV3StrategyAddress, '2', withdrawalAmount)).to.be.revertedWith("Excessive input amount")
    });

    it("test handle report 2 withdraw amountInMaximum above yield balance", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await loadFixture();
        const yieldAmount = ethers.parseUnits('5', 'ether');
        yieldToken.transfer(uniswapV3StrategyAddress, yieldAmount);

        const withdrawalAmount = ethers.parseUnits('10', 'ether');
        await poolingManager.handleReport(uniswapV3StrategyAddress, '2', withdrawalAmount);

        const lastNav = await poolingManager.lastNav();
        const lastWithdrawalAmount = await poolingManager.lastWithdrawalAmount();
        const nav = await uniswapV3Strategy.nav();

        const expectedWithdraw = ethers.parseUnits('6', 'ether');
        const underlyingBalance = await underlyingToken.balanceOf(poolingManagerAddress);
        expect(underlyingBalance).to.equal(expectedWithdraw);
        expect(lastNav).to.equal(0);
        expect(lastNav).to.equal(nav);
        expect(lastWithdrawalAmount).to.equal(expectedWithdraw);
    });

    it("test handle report 2 withdraw amountInMaximum above yield balance revert slippage", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, mockV3Aggregator, mockV3AggregatorAddress, uniswapRouterMock, uniswapRouterMockAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await loadFixture();
        const yieldAmount = ethers.parseUnits('5', 'ether');
        yieldToken.transfer(uniswapV3StrategyAddress, yieldAmount);
        const withdrawalAmount = ethers.parseUnits('10', 'ether');
        mockV3Aggregator.updateAnswer("2000000000000000000");
        await expect(poolingManager.handleReport(uniswapV3StrategyAddress, '2', withdrawalAmount)).to.be.revertedWith("Insufficient output amount")
    });

});

