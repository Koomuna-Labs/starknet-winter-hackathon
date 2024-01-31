import { ethers, network, upgrades } from "hardhat";
import { expect } from "chai";
import { Contract } from "ethers";

describe("StrategyBase Test", function () {

  async function loadFixture() {
    const owner = await ethers.provider.getSigner(0);

    const poolingManagerMockFactory = await ethers.getContractFactory('PoolingManagerMock');
    const poolingManager = await poolingManagerMockFactory.deploy();
    const poolingManagerAddress = await poolingManager.getAddress()

    const erc20MintableMockFactory = await ethers.getContractFactory('ERC20Mock');
    const underlyingToken = await erc20MintableMockFactory.deploy();
    const underlyingTokenAddress = await underlyingToken.getAddress()

    const yieldToken = await erc20MintableMockFactory.deploy();
    const yieldTokenAddress = await yieldToken.getAddress()
    const testStrategyBaseFactory = await ethers.getContractFactory('TestStrategyBase');
    const yield_factor = ethers.parseUnits('0.1', 'ether');
    const testStrategyBase = await upgrades.deployProxy(testStrategyBaseFactory, [
      poolingManagerAddress,
      underlyingTokenAddress,
      yieldTokenAddress,
      yield_factor
    ]);

    await yieldToken.mint(owner.address, ethers.parseUnits('100', 'ether'));
    await underlyingToken.mint(owner.address, ethers.parseUnits('100', 'ether'));



    const testStrategyBaseAddress = await testStrategyBase.getAddress();
    return { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, testStrategyBase, testStrategyBaseAddress };
  }

  it("test init", async function () {
    const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, testStrategyBase, testStrategyBaseAddress } = await loadFixture();
    expect(await testStrategyBase.poolingManager()).equal(poolingManagerAddress);
    expect(await testStrategyBase.underlyingToken()).equal(underlyingTokenAddress);
    expect(await testStrategyBase.yieldToken()).equal(yieldTokenAddress);
  });

  it("test yieldBalance", async function () {
    const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, testStrategyBase, testStrategyBaseAddress } = await loadFixture();
    const amount = ethers.parseUnits('1', 'ether');
    await yieldToken.transfer(testStrategyBaseAddress, amount)
    expect(await testStrategyBase.yieldBalance()).equal(amount);
  });

  it("test yieldToUnderlying", async function () {
    const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, testStrategyBase, testStrategyBaseAddress } = await loadFixture();
    const amount = ethers.parseUnits('1', 'ether');
    const underlyingTokens = await testStrategyBase.yieldToUnderlying(amount);
    const amountInUnderlying = ethers.parseUnits('10', 'ether');
    expect(underlyingTokens).equal(amountInUnderlying);
  });

  it("test underlyingToYield", async function () {
    const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, testStrategyBase, testStrategyBaseAddress } = await loadFixture();
    const amount = ethers.parseUnits('1', 'ether');
    const yieldTokens = await testStrategyBase.underlyingToYield(amount);
    const amountInYield = ethers.parseUnits('0.1', 'ether');
    expect(yieldTokens).equal(amountInYield);
  });

  it("test nav", async function () {
    const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, testStrategyBase, testStrategyBaseAddress } = await loadFixture();
    const amount = ethers.parseUnits('1', 'ether');
    await yieldToken.transfer(testStrategyBaseAddress, amount);
    const nav = await testStrategyBase.nav();
    const amountInUnderlying = ethers.parseUnits('10', 'ether');
    expect(nav).equal(amountInUnderlying);
  });

  it("test handleReport revert invalid caller", async function () {
    const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, testStrategyBase, testStrategyBaseAddress } = await loadFixture();
    const actionId = "0";
    const amount = ethers.parseUnits('1', 'ether');
    await underlyingToken.transfer(testStrategyBaseAddress, amount);
    await expect(testStrategyBase.handleReport(actionId, amount))
      .to.be.revertedWithCustomError(testStrategyBase, "InvalidCaller");
  });

  it("test handleReport action deposit", async function () {
    const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, testStrategyBase, testStrategyBaseAddress } = await loadFixture();
    const actionId = "0";
    const amount = ethers.parseUnits('1', 'ether');

    await underlyingToken.transfer(testStrategyBaseAddress, amount);
    await poolingManager.handleReport(testStrategyBaseAddress, actionId, amount);

    const lastNav = await poolingManager.lastNav();
    const lastWithdrawalAmount = await poolingManager.lastWithdrawalAmount();
    const nav = await testStrategyBase.nav();

    expect(lastNav).to.equal(amount);
    expect(lastNav).to.equal(nav);
    expect(lastWithdrawalAmount).to.equal(0);
  });

  it("test handleReport action report", async function () {
    const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, testStrategyBase, testStrategyBaseAddress } = await loadFixture();
    const amount = ethers.parseUnits('1', 'ether');

    await underlyingToken.transfer(testStrategyBaseAddress, amount);
    await poolingManager.handleReport(testStrategyBaseAddress, "0", amount);
    await poolingManager.handleReport(testStrategyBaseAddress, "1", amount);

    const lastNav = await poolingManager.lastNav();
    const lastWithdrawalAmount = await poolingManager.lastWithdrawalAmount();
    const nav = await testStrategyBase.nav();

    expect(lastNav).to.equal(amount);
    expect(lastNav).to.equal(nav);
    expect(lastWithdrawalAmount).to.equal(0);
  });

  it("test handleReport action withdraw", async function () {
    const { owner, poolingManager, poolingManagerAddress, underlyingToken, underlyingTokenAddress, yieldToken, yieldTokenAddress, testStrategyBase, testStrategyBaseAddress } = await loadFixture();
    const depositAmount = ethers.parseUnits('1', 'ether');
    const withdrawalAmount = ethers.parseUnits('0.5', 'ether');

    await underlyingToken.transfer(testStrategyBaseAddress, depositAmount);
    await poolingManager.handleReport(testStrategyBaseAddress, "0", depositAmount);
    await poolingManager.handleReport(testStrategyBaseAddress, "2", withdrawalAmount);

    const lastNav = await poolingManager.lastNav();
    const lastWithdrawalAmount = await poolingManager.lastWithdrawalAmount();
    const nav = await testStrategyBase.nav();

    const new_nav = ethers.parseUnits('0.5', 'ether');
    expect(lastNav).to.equal(new_nav);
    expect(lastNav).to.equal(nav);
    expect(lastWithdrawalAmount).to.equal(withdrawalAmount);
  });

});

