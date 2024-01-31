import { ethers, network, upgrades } from "hardhat";
import { expect } from "chai";
import { Contract, Wallet } from "ethers";

describe("Strategy SavingDai Test", function () {

    async function loadFixture() {
        const owner = await ethers.provider.getSigner(0);


        const poolingManagerMockFactory = await ethers.getContractFactory('PoolingManagerMock');
        const poolingManager = await poolingManagerMockFactory.deploy();
        const poolingManagerAddress = await poolingManager.getAddress()

        const erc20MintableMockFactory = await ethers.getContractFactory('ERC20Mock');
        const underlyingToken = await erc20MintableMockFactory.deploy();
        const underlyingTokenAddress = await underlyingToken.getAddress()

        const erc4626MintableMockFactory = await ethers.getContractFactory('ERC4626Mock');
        const yieldToken = await erc4626MintableMockFactory.deploy(underlyingTokenAddress);
        const yieldTokenAddress = await yieldToken.getAddress();

        const savingDaiStrategyFactory = await ethers.getContractFactory('SavingDaiStrategy');
        const savingDaiStrategy = await upgrades.deployProxy(savingDaiStrategyFactory, [
            poolingManagerAddress,
            underlyingTokenAddress,
            yieldTokenAddress,
        ]);


        await underlyingToken.mint(owner.address, ethers.parseUnits('200', 'ether'));
        await underlyingToken.approve(yieldTokenAddress, ethers.parseUnits('50', 'ether'));
        await yieldToken.deposit(ethers.parseUnits('50', 'ether'), owner.address)
        await underlyingToken.transfer(yieldTokenAddress, ethers.parseUnits('50', 'ether'));
        return { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, savingDaiStrategy };
    }


    it("test init ", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, savingDaiStrategy } = await loadFixture();
        const randomAddress = Wallet.createRandom().address;
        await owner.sendTransaction({
            to: randomAddress,
            value: ethers.parseUnits('1', 'ether'),
        });

        const totalAssets = await yieldToken.totalAssets();
        expect(totalAssets == ethers.parseUnits('100', 'ether'));
        const totalSupply = await yieldToken.totalSupply();
        expect(totalSupply == ethers.parseUnits('50', 'ether'));
    });


    it("test underlyingToYield ", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, savingDaiStrategy } = await loadFixture();
        const amount = ethers.parseUnits('10', 'ether');
        const yieldAmount = await savingDaiStrategy.underlyingToYield(amount);
        const expectedAmount = ethers.parseUnits('5', 'ether');
        expect(yieldAmount).equal(expectedAmount);
    });

    it("test yieldToUnderlying ", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, savingDaiStrategy } = await loadFixture();
        const amount = ethers.parseUnits('10', 'ether');
        const yieldAmount = await savingDaiStrategy.yieldToUnderlying(amount);
        const expectedAmount = "19999999999999999999";
        expect(yieldAmount).equal(expectedAmount);
    });


    it("test handle report 0 deposit ", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, savingDaiStrategy } = await loadFixture();
        const underlyingAmount = ethers.parseUnits('10', 'ether');
        underlyingToken.transfer(savingDaiStrategy, underlyingAmount);
        await poolingManager.handleReport(savingDaiStrategy, '0', underlyingAmount);

        const lastNav = await poolingManager.lastNav();
        const lastWithdrawalAmount = await poolingManager.lastWithdrawalAmount();
        const nav = await savingDaiStrategy.nav();

        const expectedBalance = "5000000000000000000"
        const yieldBalance = await yieldToken.balanceOf(savingDaiStrategy);
        expect(yieldBalance).to.equal(expectedBalance);

        const expectedNav = "9999999999999999999"
        expect(lastNav).to.equal(expectedNav);
        expect(lastNav).to.equal(nav);
        expect(lastWithdrawalAmount).to.equal(0);
    });

    it("test handle report 1 report ", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, savingDaiStrategy } = await loadFixture();
        const underlyingAmount = ethers.parseUnits('10', 'ether');
        underlyingToken.transfer(savingDaiStrategy, underlyingAmount);
        await poolingManager.handleReport(savingDaiStrategy, '0', underlyingAmount);
        await poolingManager.handleReport(savingDaiStrategy, '1', underlyingAmount);

        const lastNav = await poolingManager.lastNav();
        const lastWithdrawalAmount = await poolingManager.lastWithdrawalAmount();
        const nav = await savingDaiStrategy.nav();

        const expectedBalance = "5000000000000000000"
        const yieldBalance = await yieldToken.balanceOf(savingDaiStrategy);
        expect(yieldBalance).to.equal(expectedBalance);

        const expectedNav = "9999999999999999999"
        expect(lastNav).to.equal(expectedNav);
        expect(lastNav).to.equal(nav);
        expect(lastWithdrawalAmount).to.equal(0);
    });

    it("test handle report 2 withdraw enought yield balance", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, savingDaiStrategy } = await loadFixture();
        const yieldAmount = ethers.parseUnits('10', 'ether');
        yieldToken.transfer(savingDaiStrategy, yieldAmount);

        const withdrawalAmount = ethers.parseUnits('6', 'ether');


        await poolingManager.handleReport(savingDaiStrategy, '2', withdrawalAmount);

        const lastNav = await poolingManager.lastNav();
        const lastWithdrawalAmount = await poolingManager.lastWithdrawalAmount();
        const nav = await savingDaiStrategy.nav();

        const expectedWithdraw = ethers.parseUnits('6', 'ether');
        const underlyingBalance = await underlyingToken.balanceOf(poolingManagerAddress);
        expect(underlyingBalance).to.equal(expectedWithdraw);

        const expectedNav = "13999999999999999998"
        expect(lastNav).to.equal(expectedNav);
        expect(lastNav).to.equal(nav);
        expect(lastWithdrawalAmount).to.equal(expectedWithdraw);

    });


    it("test handle report 2 withdraw not enought yield balance", async function () {
        const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, savingDaiStrategy } = await loadFixture();
        const yieldAmount = ethers.parseUnits('10', 'ether');
        yieldToken.transfer(savingDaiStrategy, yieldAmount);

        const withdrawalAmount = ethers.parseUnits('23', 'ether');
        await poolingManager.handleReport(savingDaiStrategy, '2', withdrawalAmount);

        const lastNav = await poolingManager.lastNav();
        const lastWithdrawalAmount = await poolingManager.lastWithdrawalAmount();
        const nav = await savingDaiStrategy.nav();

        const expectedWithdraw = "19999999999999999999";
        const underlyingBalance = await underlyingToken.balanceOf(poolingManagerAddress);
        expect(underlyingBalance).to.equal(expectedWithdraw);

        const expectedNav = "0"
        expect(lastNav).to.equal(expectedNav);
        expect(lastNav).to.equal(nav);
        expect(lastWithdrawalAmount).to.equal(expectedWithdraw);

    });

});

