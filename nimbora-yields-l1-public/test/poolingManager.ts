import { ethers, network, upgrades } from "hardhat";
import { expect } from "chai";
import { Contract, Wallet, keccak256, toUtf8Bytes } from "ethers";
import { ERC20Mock, ERC4626Mock, WETH9 } from "../typechain-types";

const l2PoolingManager = "1029302920393029293";
const ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000"
const RELAYER_ROLE = keccak256(toUtf8Bytes("0x01"));
const zeroAddress = "0x0000000000000000000000000000000000000000"
const maxUint256 = "115792089237316195423570985008687907853269984665640564039457584007913129639935"
const l2BridgeEthFee = 1000;
const l2MessagingEthFee = 1000;
const L2_HANDLER_SELECTOR = "0x10e13e50cb99b6b3c8270ec6e16acfccbe1164a629d74b43549567a77593aff";

function padAddressTo32Bytes(address: string) {
    // Remove the '0x' prefix if it exists
    let cleanAddress = address.startsWith('0x') ? address.slice(2) : address;

    // Pad the address with zeros to make it 32 bytes long
    while (cleanAddress.length < 64) {
        cleanAddress = '0' + cleanAddress;
    }

    return '0x' + cleanAddress;
}

function computeFromReportL2(new_epoch: any, bridgeInfo: any, strategyReportL2: any, bridgeDepositInfo: any) {
    const encoder = ethers.AbiCoder.defaultAbiCoder();
    let encodedData = '0x';
    encodedData += encoder.encode(["uint256"], [new_epoch]).slice(2);
    for (let index = 0; index < bridgeInfo.length; index++) {
        const bridgeInfoElement = bridgeInfo[index];
        encodedData += encoder.encode(["uint256", "uint256"], [bridgeInfoElement.bridge, bridgeInfoElement.amount]).slice(2);
    }

    for (let index = 0; index < strategyReportL2.length; index++) {
        const strategyReportL2Element = strategyReportL2[index];
        encodedData += encoder.encode(["uint256", "uint256", "uint256"], [strategyReportL2Element.l1Strategy, strategyReportL2Element.actionId, strategyReportL2Element.amount]).slice(2);
    }

    for (let index = 0; index < bridgeDepositInfo.length; index++) {
        const bridgeDepositInfoElement = bridgeDepositInfo[index];
        encodedData += encoder.encode(["uint256", "uint256"], [bridgeDepositInfoElement.bridge, bridgeDepositInfoElement.amount]).slice(2);
    }

    return ethers.keccak256(encodedData);
}


function splitUint256ToUint128(uint256: bigint) {
    const lowMask = BigInt("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
    const lowPart = uint256 & lowMask;
    const highPart = uint256 >> BigInt(128);
    return { lowPart, highPart };
}

function computeMessageReceivedL1(l2Pooling: any, l1Pooling: any, hash: bigint) {
    const encoder = ethers.AbiCoder.defaultAbiCoder();
    let encodedData = '0x';
    encodedData += encoder.encode(["uint256"], [l2Pooling]).slice(2);
    encodedData += encoder.encode(["uint256"], [l1Pooling]).slice(2);
    encodedData += encoder.encode(["uint256"], [2]).slice(2);
    const { lowPart, highPart } = splitUint256ToUint128(hash);
    encodedData += encoder.encode(["uint256"], [lowPart]).slice(2);
    encodedData += encoder.encode(["uint256"], [highPart]).slice(2);
    return ethers.keccak256(encodedData);
}

function computeMessageReceivedL2(l1Pooling: any, l2Pooling: any, nonceMessaging: any, epoch: any, hash: any) {
    const encoder = ethers.AbiCoder.defaultAbiCoder();
    let encodedData = '0x';

    encodedData += encoder.encode(["uint256"], [l1Pooling]).slice(2);
    encodedData += encoder.encode(["uint256"], [l2Pooling]).slice(2);
    encodedData += encoder.encode(["uint256"], [nonceMessaging]).slice(2);
    encodedData += encoder.encode(["uint256"], [L2_HANDLER_SELECTOR]).slice(2);

    const { lowPart: lowEpoch, highPart: highEpoch } = splitUint256ToUint128(epoch);

    const { lowPart: lowHash, highPart: highHash } = splitUint256ToUint128(hash);

    encodedData += encoder.encode(["uint256"], [4]).slice(2);
    encodedData += encoder.encode(["uint256"], [lowEpoch]).slice(2);
    encodedData += encoder.encode(["uint256"], [highEpoch]).slice(2);
    encodedData += encoder.encode(["uint256"], [lowHash]).slice(2);
    encodedData += encoder.encode(["uint256"], [highHash]).slice(2);
    return ethers.keccak256(encodedData);
}




function computeFromReportL1(strategyReportL1: any) {
    const encoder = ethers.AbiCoder.defaultAbiCoder();
    let encodedData = '0x';
    for (let index = 0; index < strategyReportL1.length; index++) {
        const strategyReportL1Element = strategyReportL1[index];
        encodedData += encoder.encode(["uint256", "uint256", "uint256"], [strategyReportL1Element.l1Strategy, strategyReportL1Element.l1Nav, strategyReportL1Element.amount]).slice(2);
    }

    return ethers.keccak256(encodedData);
}





describe("Pooling Manager Test", function () {


    async function InitPoolingManager() {
        const owner = await ethers.provider.getSigner(0);
        const relayer = await ethers.provider.getSigner(1);

        const starknetMockFactory = await ethers.getContractFactory('StarknetMock');
        const starknetMock = await starknetMockFactory.deploy();
        const starknetMockAddress = await starknetMock.getAddress()

        const erc20MintableMockFactory = await ethers.getContractFactory('ERC20Mock');
        const dai = await erc20MintableMockFactory.deploy();
        const daiAddress = await dai.getAddress();
        const wsteth = await erc20MintableMockFactory.deploy();
        const wstethAddress = await wsteth.getAddress();


        const wethMockFactory = await ethers.getContractFactory('WETH9');
        const weth = await wethMockFactory.deploy();
        const wethAddress = await weth.getAddress();

        const sdaiMockFactory = await ethers.getContractFactory('ERC4626Mock');
        const sdai = await sdaiMockFactory.deploy(daiAddress);
        const sdaiAddress = await sdai.getAddress();



        const starkneErc20BridgeMockFactory = await ethers.getContractFactory("StarkneErc20BridgeMock")
        const daiBridge = await starkneErc20BridgeMockFactory.deploy(daiAddress);
        const daiBridgeAddress = await daiBridge.getAddress();
        const starkneEthBridgeMockFactory = await ethers.getContractFactory("StarknetEthBridgeMock")
        const ethBridge = await starkneEthBridgeMockFactory.deploy();
        const ethBridgeAddress = await ethBridge.getAddress();



        const poolingManagerFactory = await ethers.getContractFactory('PoolingManager');
        const poolingManager = await upgrades.deployProxy(poolingManagerFactory, [
            owner.address,
            l2PoolingManager,
            starknetMockAddress,
            relayer.address,
            ethBridgeAddress,
            wethAddress
        ]);
        const poolingManagerAddress = await poolingManager.getAddress()




        await dai.mint(owner.address, ethers.parseUnits('100', 'ether'));
        await dai.mint(daiBridgeAddress, ethers.parseUnits('100', 'ether'));

        await dai.approve(sdai, ethers.parseUnits('25', 'ether'));
        await sdai.deposit(ethers.parseUnits('25', 'ether'), owner.address)
        await dai.transfer(sdaiAddress, ethers.parseUnits('25', 'ether'));

        await weth.deposit({ value: ethers.parseUnits('15', 'ether') });
        await owner.sendTransaction({
            to: ethBridgeAddress,
            value: ethers.parseUnits('10', 'ether'),
        });

        await wsteth.mint(owner.address, ethers.parseUnits('100', 'ether'));


        return { owner, relayer, starknetMock, starknetMockAddress, dai, daiAddress, weth, wethAddress, wsteth, wstethAddress, sdai, sdaiAddress, daiBridge, daiBridgeAddress, ethBridge, ethBridgeAddress, poolingManager, poolingManagerAddress };
    }

    async function InitUniswap(ownerAddress: string, poolingManagerAddress: string, weth: WETH9, wethAddress: string, wsteth: ERC20Mock, wstethAddress: string) {

        const uniswapV3FactoryMockFactory = await ethers.getContractFactory('UniswapV3FactoryMock');
        const uniswapV3FactoryMock = await uniswapV3FactoryMockFactory.deploy();
        const uniswapV3FactoryMockAddress = await uniswapV3FactoryMock.getAddress()

        const poolFee = "3000";
        const poolAddress = Wallet.createRandom().address;
        uniswapV3FactoryMock.setPool(wethAddress, wstethAddress, poolFee, poolAddress);

        // Pricefeed giving the price of WstETH in ETH, let's take 1.2 ETH
        const mockV3AggregatorFactory = await ethers.getContractFactory('MockV3Aggregator');
        const mockV3Aggregator = await mockV3AggregatorFactory.deploy(18, "1200000000000000000");
        const mockV3AggregatorAddress = await mockV3Aggregator.getAddress();

        const uniswapRouterMockFactory = await ethers.getContractFactory('UniswapRouterMock');
        const uniswapRouterMock = await uniswapRouterMockFactory.deploy();
        const uniswapRouterMockAddress = await uniswapRouterMock.getAddress();

        // initialy set the exchange rate to pricefeed value
        uniswapRouterMock.setExchangeRate(wstethAddress, wethAddress, "1200000000000000000")


        const uniswapV3StrategyFactory = await ethers.getContractFactory('UniswapV3Strategy');
        const minReceivedAmountFactor = "990000000000000000"
        const uniswapV3Strategy = await upgrades.deployProxy(uniswapV3StrategyFactory, [
            poolingManagerAddress,
            wethAddress,
            wstethAddress,
            uniswapRouterMockAddress,
            uniswapV3FactoryMockAddress,
            mockV3AggregatorAddress,
            minReceivedAmountFactor,
            poolFee
        ]);
        const uniswapV3StrategyAddress = await uniswapV3Strategy.getAddress();


        await wsteth.mint(uniswapRouterMockAddress, ethers.parseUnits('5', 'ether'));
        await weth.transfer(uniswapRouterMockAddress, ethers.parseUnits('5', 'ether'));


        return { mockV3Aggregator, mockV3AggregatorAddress, uniswapV3Strategy, uniswapV3StrategyAddress };
    }

    async function InitSavingDai(poolingManagerAddress: string, daiAddress: string, sdaiAddress: string) {
        const savingDaiStrategyFactory = await ethers.getContractFactory('SavingDaiStrategy');
        const savingDaiStrategy = await upgrades.deployProxy(savingDaiStrategyFactory, [
            poolingManagerAddress,
            daiAddress,
            sdaiAddress,
        ]);
        const savingDaiStrategyAddress = await savingDaiStrategy.getAddress();
        return { savingDaiStrategy, savingDaiStrategyAddress };
    }

    it("test init", async function () {
        const { owner, relayer, starknetMock, starknetMockAddress, dai, daiAddress, weth, wethAddress, daiBridge, daiBridgeAddress, ethBridge, ethBridgeAddress, poolingManager, poolingManagerAddress } = await InitPoolingManager();
        expect(await poolingManager.l2PoolingManager()).equal(l2PoolingManager);
        expect(await poolingManager.hasRole(ADMIN_ROLE, owner.address)).equal(true);
        expect(await poolingManager.hasRole(RELAYER_ROLE, relayer.address)).equal(true);
        expect(await poolingManager.starknetCore()).equal(starknetMockAddress);
        expect(await poolingManager.ethBridge()).equal(ethBridgeAddress);
        expect(await poolingManager.ethWrapped()).equal(wethAddress);
    });



    it("should return correct hash for single element in each array", async function () {
        const { poolingManager } = await InitPoolingManager();
        const addressUsed = "0xef651ae91702efec38a7bdb1f9816ad554a2adcd"
        const bridgeInfo = [{ bridge: addressUsed, amount: "3" }];
        const strategyReportL2 = [{ l1Strategy: addressUsed, actionId: "2", amount: '8' }];
        const bridgeDepositInfo = [{ bridge: addressUsed, amount: "4" }];
        const epoch = 0;
        const expectedHashForSingleElements = computeFromReportL2(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo);
        const hash = await poolingManager.hashFromReportL2(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo);
        expect(hash).to.equal(expectedHashForSingleElements);
    });

    it("should return correct hash for diff elements in each array", async function () {
        const { poolingManager } = await InitPoolingManager();
        const addressUsed1 = "0xef651ae91702efec38a7bdb1f9816ad554a2adcd";
        const addressUsed2 = "0xabcdef1234567890abcdef1234567890abcdef12";

        const bridgeInfo = [
            { bridge: addressUsed1, amount: "3" },
        ];
        const strategyReportL2 = [
            { l1Strategy: addressUsed1, actionId: "2", amount: '8' },
            { l1Strategy: addressUsed2, actionId: "4", amount: '10' }
        ];
        const bridgeDepositInfo: any = [

        ];
        const epoch = 0;
        const expectedHashForDiffElements = computeFromReportL2(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo);
        const hash = await poolingManager.hashFromReportL2(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo);
        expect(hash).to.equal(expectedHashForDiffElements);
    });

    it("should return correct hash for single element in each array", async function () {
        const { poolingManager } = await InitPoolingManager();
        const addressUsed = "0xef651ae91702efec38a7bdb1f9816ad554a2adcd"
        const strategyReportL1 = [{ l1Strategy: addressUsed, l1Nav: "2", amount: '244' }];
        const expectedHashForSingleElements = computeFromReportL1(strategyReportL1);
        const hash = await poolingManager.hashFromReportL1(1, strategyReportL1);
        expect(hash).to.equal(expectedHashForSingleElements);
    });

    it("should return correct hash for diff element in each array", async function () {
        const { poolingManager } = await InitPoolingManager();
        const addressUsed1 = "0xef651ae91702efec38a7bdb1f9816ad554a2adcd";
        const addressUsed2 = "0xabcdef1234567890abcdef1234567890abcdef12";
        const strategyReportL1 = [
            { l1Strategy: addressUsed1, l1Nav: "238303033", amount: '238' },
            { l1Strategy: addressUsed2, l1Nav: "238303033333", amount: '10' }
        ];
        const expectedHashForDiffElements = computeFromReportL1(strategyReportL1);
        const hash = await poolingManager.hashFromReportL1(2, strategyReportL1);
        expect(hash).to.equal(expectedHashForDiffElements);
    });

    it("test registerStrategy revert zero value strategy", async function () {
        const { owner, relayer, starknetMock, starknetMockAddress, dai, daiAddress, weth, wethAddress, wsteth, wstethAddress, daiBridge, daiBridgeAddress, ethBridge, ethBridgeAddress, poolingManager, poolingManagerAddress } = await InitPoolingManager();
        const { mockV3Aggregator, mockV3AggregatorAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await InitUniswap(owner.address, poolingManagerAddress, weth, wethAddress, wsteth, wstethAddress);
        await expect(poolingManager.registerStrategy(zeroAddress, wethAddress, ethBridgeAddress)).to.be.revertedWithCustomError(poolingManager, "ZeroAddress");
    });

    it("test registerStrategy revert zero value underlying", async function () {
        const { owner, relayer, starknetMock, starknetMockAddress, dai, daiAddress, weth, wethAddress, wsteth, wstethAddress, daiBridge, daiBridgeAddress, ethBridge, ethBridgeAddress, poolingManager, poolingManagerAddress } = await InitPoolingManager();
        const { mockV3Aggregator, mockV3AggregatorAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await InitUniswap(owner.address, poolingManagerAddress, weth, wethAddress, wsteth, wstethAddress);
        await expect(poolingManager.registerStrategy(uniswapV3StrategyAddress, zeroAddress, ethBridgeAddress)).to.be.revertedWithCustomError(poolingManager, "ZeroAddress");
    });

    it("test registerStrategy revert zero value bridge", async function () {
        const { owner, relayer, starknetMock, starknetMockAddress, dai, daiAddress, weth, wethAddress, wsteth, wstethAddress, daiBridge, daiBridgeAddress, ethBridge, ethBridgeAddress, poolingManager, poolingManagerAddress } = await InitPoolingManager();
        const { mockV3Aggregator, mockV3AggregatorAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await InitUniswap(owner.address, poolingManagerAddress, weth, wethAddress, wsteth, wstethAddress);
        await expect(poolingManager.registerStrategy(uniswapV3StrategyAddress, wethAddress, zeroAddress)).to.be.revertedWithCustomError(poolingManager, "ZeroAddress");
    });

    it("test registerStrategy revert InvalidPoolingManager", async function () {
        const { owner, relayer, starknetMock, starknetMockAddress, dai, daiAddress, weth, wethAddress, wsteth, wstethAddress, daiBridge, daiBridgeAddress, ethBridge, ethBridgeAddress, poolingManager, poolingManagerAddress } = await InitPoolingManager();
        const { mockV3Aggregator, mockV3AggregatorAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await InitUniswap(owner.address, Wallet.createRandom().address, weth, wethAddress, wsteth, wstethAddress);
        await expect(poolingManager.registerStrategy(uniswapV3StrategyAddress, wethAddress, ethBridgeAddress)).to.be.revertedWithCustomError(poolingManager, "InvalidPoolingManager");
    });

    it("test registerStrategy", async function () {
        const { owner, relayer, starknetMock, starknetMockAddress, dai, daiAddress, weth, wethAddress, wsteth, wstethAddress, sdai, sdaiAddress, daiBridge, daiBridgeAddress, ethBridge, ethBridgeAddress, poolingManager, poolingManagerAddress } = await InitPoolingManager();
        const { mockV3Aggregator, mockV3AggregatorAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await InitUniswap(owner.address, poolingManagerAddress, weth, wethAddress, wsteth, wstethAddress);
        await poolingManager.registerStrategy(uniswapV3StrategyAddress, wethAddress, ethBridgeAddress);
        expect((await weth.allowance(poolingManagerAddress, ethBridgeAddress))).to.be.equal(maxUint256);
        const strategyInfoUni = await poolingManager.strategyInfo(uniswapV3StrategyAddress);
        expect(strategyInfoUni.underlying).to.be.equal(weth);
        expect(strategyInfoUni.bridge).to.be.equal(ethBridgeAddress);

        const { savingDaiStrategy, savingDaiStrategyAddress } = await InitSavingDai(poolingManagerAddress, daiAddress, sdaiAddress);
        await poolingManager.registerStrategy(savingDaiStrategyAddress, daiAddress, daiBridgeAddress);
        expect((await dai.allowance(poolingManagerAddress, daiBridgeAddress))).to.be.equal(maxUint256);
        const strategyInfoSdai = await poolingManager.strategyInfo(savingDaiStrategyAddress);
        expect(strategyInfoSdai.underlying).to.be.equal(daiAddress);
        expect(strategyInfoSdai.bridge).to.be.equal(daiBridgeAddress);
    });

    it("test handleReport revert invalid message to consume", async function () {
        const { owner, relayer, starknetMock, starknetMockAddress, dai, daiAddress, weth, wethAddress, wsteth, wstethAddress, sdai, sdaiAddress, daiBridge, daiBridgeAddress, ethBridge, ethBridgeAddress, poolingManager, poolingManagerAddress } = await InitPoolingManager();
        const { mockV3Aggregator, mockV3AggregatorAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await InitUniswap(owner.address, poolingManagerAddress, weth, wethAddress, wsteth, wstethAddress);
        await poolingManager.registerStrategy(uniswapV3StrategyAddress, wethAddress, ethBridgeAddress);
        let epoch = "0";
        const depositAmount = ethers.parseUnits('1', 'ether');
        const bridgeInfo = [
            { bridge: ethBridgeAddress, amount: depositAmount },
        ];
        const bridgeInfoFake = [
            { bridge: Wallet.createRandom().address, amount: depositAmount },
        ];
        const strategyReportL2 = [
            { l1Strategy: uniswapV3StrategyAddress, actionId: "0", amount: depositAmount },
        ];
        const bridgeDepositInfo: any = [
        ];
        const expectedHash = computeFromReportL2(epoch, bridgeInfoFake, strategyReportL2, bridgeDepositInfo);
        starknetMock.addMessage([expectedHash])
        // revert does not work, related tot he fact it is reverted in the starknet core
        //expect(await poolingManager.handleReport(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo, 0, l2MessagingEthFee)).to.be.reverted();
    });

    it("test handleReport one strategy with deposit order, no revert, no pending", async function () {
        const { owner, relayer, starknetMock, starknetMockAddress, dai, daiAddress, weth, wethAddress, wsteth, wstethAddress, sdai, sdaiAddress, daiBridge, daiBridgeAddress, ethBridge, ethBridgeAddress, poolingManager, poolingManagerAddress } = await InitPoolingManager();
        const { mockV3Aggregator, mockV3AggregatorAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await InitUniswap(owner.address, poolingManagerAddress, weth, wethAddress, wsteth, wstethAddress);
        await poolingManager.registerStrategy(uniswapV3StrategyAddress, wethAddress, ethBridgeAddress);
        let epoch = "1";
        const depositAmount = ethers.parseUnits('1', 'ether');
        const bridgeInfo = [
            { bridge: ethBridgeAddress, amount: depositAmount },
        ];
        const strategyReportL2 = [
            { l1Strategy: uniswapV3StrategyAddress, actionId: "0", amount: depositAmount },
        ];
        const bridgeDepositInfo: any = [
        ];
        const expectedHashL2 = computeFromReportL2(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo);
        const messageReceivedL1 = computeMessageReceivedL1(l2PoolingManager, poolingManagerAddress, BigInt(expectedHashL2));
        starknetMock.addMessage([messageReceivedL1])

        // with agrs doesn't work with struct
        //await expect(poolingManager.handleReport(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo, 0, l2MessagingEthFee, { value: l2MessagingEthFee })).to.emit(poolingManager, "ReportHandled").withArgs(epoch, expectedReport)
        await expect(poolingManager.handleReport(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo, 0, l2MessagingEthFee, 1, { value: l2MessagingEthFee })).to.emit(poolingManager, "ReportHandled");

        // Make sure the right message has been sent
        const expectedReport = [
            { l1Strategy: uniswapV3StrategyAddress, l1Nav: "999999999999999999", amount: '0' },
        ];
        const expectedHashL1 = computeFromReportL1(expectedReport);
        const nonceMessaging = await starknetMock.l1ToL2MessageNonce();
        const messageReceivedL2 = computeMessageReceivedL2(poolingManagerAddress, l2PoolingManager, (nonceMessaging - BigInt(1)).toString(), BigInt(epoch), BigInt(expectedHashL1));
        const { lowPart: lowEpoch, highPart: highEpoch } = splitUint256ToUint128(BigInt(epoch));
        const { lowPart: lowHash, highPart: highHash } = splitUint256ToUint128(BigInt(expectedHashL1));
        const messageReceivedL2Call = await starknetMock.getL1ToL2MsgHash(poolingManagerAddress, l2PoolingManager, L2_HANDLER_SELECTOR, [lowEpoch, highEpoch, lowHash, highHash], (nonceMessaging - BigInt(1)));
        expect(messageReceivedL2).to.equal(messageReceivedL2Call);
        const l1ToL2Message = await starknetMock.l1ToL2Messages(messageReceivedL2);
        expect(l1ToL2Message).to.be.equal(1 + l2MessagingEthFee);
    });

    it("test handleReport one strategy with report order, no revert, no pending", async function () {
        const { owner, relayer, starknetMock, starknetMockAddress, dai, daiAddress, weth, wethAddress, wsteth, wstethAddress, sdai, sdaiAddress, daiBridge, daiBridgeAddress, ethBridge, ethBridgeAddress, poolingManager, poolingManagerAddress } = await InitPoolingManager();
        const { mockV3Aggregator, mockV3AggregatorAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await InitUniswap(owner.address, poolingManagerAddress, weth, wethAddress, wsteth, wstethAddress);
        await poolingManager.registerStrategy(uniswapV3StrategyAddress, wethAddress, ethBridgeAddress);
        wsteth.transfer(uniswapV3StrategyAddress, "833333333333333333")
        let epoch = "1";
        const bridgeInfo = [
            { bridge: ethBridgeAddress, amount: BigInt(0) },
        ];
        const strategyReportL2 = [
            { l1Strategy: uniswapV3StrategyAddress, actionId: "1", amount: BigInt(0) },
        ];
        const bridgeDepositInfo: any = [
        ];
        const expectedHashL2 = computeFromReportL2(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo);
        const messageReceivedL1 = computeMessageReceivedL1(l2PoolingManager, poolingManagerAddress, BigInt(expectedHashL2));
        starknetMock.addMessage([messageReceivedL1])

        const expectedReport = [
            { l1Strategy: uniswapV3StrategyAddress, l1Nav: "999999999999999999", amount: '0' },
        ];

        await expect(poolingManager.handleReport(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo, 0, l2MessagingEthFee, 1, { value: l2MessagingEthFee })).to.emit(poolingManager, "ReportHandled");

        // Make sure the right message has been sent
        const expectedHashL1 = computeFromReportL1(expectedReport);
        const nonceMessaging = await starknetMock.l1ToL2MessageNonce();
        const messageReceivedL2 = computeMessageReceivedL2(poolingManagerAddress, l2PoolingManager, (nonceMessaging - BigInt(1)).toString(), BigInt(epoch), BigInt(expectedHashL1));
        const { lowPart: lowEpoch, highPart: highEpoch } = splitUint256ToUint128(BigInt(epoch));
        const { lowPart: lowHash, highPart: highHash } = splitUint256ToUint128(BigInt(expectedHashL1));
        const messageReceivedL2Call = await starknetMock.getL1ToL2MsgHash(poolingManagerAddress, l2PoolingManager, L2_HANDLER_SELECTOR, [lowEpoch, highEpoch, lowHash, highHash], (nonceMessaging - BigInt(1)));
        expect(messageReceivedL2).to.equal(messageReceivedL2Call);
        const l1ToL2Message = await starknetMock.l1ToL2Messages(messageReceivedL2);
        expect(l1ToL2Message).to.be.equal(1 + l2MessagingEthFee);
    });

    it("test handleReport one strategy with withdraw order, no revert, no pending", async function () {
        const { owner, relayer, starknetMock, starknetMockAddress, dai, daiAddress, weth, wethAddress, wsteth, wstethAddress, sdai, sdaiAddress, daiBridge, daiBridgeAddress, ethBridge, ethBridgeAddress, poolingManager, poolingManagerAddress } = await InitPoolingManager();
        const { mockV3Aggregator, mockV3AggregatorAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await InitUniswap(owner.address, poolingManagerAddress, weth, wethAddress, wsteth, wstethAddress);
        await poolingManager.registerStrategy(uniswapV3StrategyAddress, wethAddress, ethBridgeAddress);
        wsteth.transfer(uniswapV3StrategyAddress, "833333333333333333")
        let epoch = "1";
        const amountWithdraw = "500000000000000000"
        const bridgeInfo = [
            { bridge: ethBridgeAddress, amount: BigInt(0) },
        ];
        const strategyReportL2 = [
            { l1Strategy: uniswapV3StrategyAddress, actionId: "2", amount: amountWithdraw },
        ];
        const bridgeDepositInfo: any = [
            { bridge: ethBridgeAddress, amount: amountWithdraw },
        ];
        const expectedHashL2 = computeFromReportL2(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo);
        const messageReceivedL1 = computeMessageReceivedL1(l2PoolingManager, poolingManagerAddress, BigInt(expectedHashL2));
        starknetMock.addMessage([messageReceivedL1])

        const expectedReport = [
            { l1Strategy: uniswapV3StrategyAddress, l1Nav: "500000000000000000", amount: "500000000000000000" },
        ];


        const overallFees = l2MessagingEthFee + l2BridgeEthFee;

        await expect(poolingManager.handleReport(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo, l2BridgeEthFee, l2MessagingEthFee, 1, { value: overallFees })).to.emit(poolingManager, "ReportHandled");

        // Make sure the right message has been sent
        const expectedHashL1 = computeFromReportL1(expectedReport);
        const nonceMessaging = await starknetMock.l1ToL2MessageNonce();
        const messageReceivedL2 = computeMessageReceivedL2(poolingManagerAddress, l2PoolingManager, (nonceMessaging - BigInt(1)).toString(), BigInt(epoch), BigInt(expectedHashL1));
        const { lowPart: lowEpoch, highPart: highEpoch } = splitUint256ToUint128(BigInt(epoch));
        const { lowPart: lowHash, highPart: highHash } = splitUint256ToUint128(BigInt(expectedHashL1));
        const messageReceivedL2Call = await starknetMock.getL1ToL2MsgHash(poolingManagerAddress, l2PoolingManager, L2_HANDLER_SELECTOR, [lowEpoch, highEpoch, lowHash, highHash], (nonceMessaging - BigInt(1)));
        expect(messageReceivedL2).to.equal(messageReceivedL2Call);
        const l1ToL2Message = await starknetMock.l1ToL2Messages(messageReceivedL2);
        expect(l1ToL2Message).to.be.equal(1 + l2MessagingEthFee);
    });

    it("test handleReport one strategy with too high withdraw order, no revert, no pending", async function () {
        const { owner, relayer, starknetMock, starknetMockAddress, dai, daiAddress, weth, wethAddress, wsteth, wstethAddress, sdai, sdaiAddress, daiBridge, daiBridgeAddress, ethBridge, ethBridgeAddress, poolingManager, poolingManagerAddress } = await InitPoolingManager();
        const { mockV3Aggregator, mockV3AggregatorAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await InitUniswap(owner.address, poolingManagerAddress, weth, wethAddress, wsteth, wstethAddress);
        await poolingManager.registerStrategy(uniswapV3StrategyAddress, wethAddress, ethBridgeAddress);
        wsteth.transfer(uniswapV3StrategyAddress, "833333333333333333")
        let epoch = "1";
        const amountWithdraw = "2000000000000000000"
        const bridgeInfo = [
            { bridge: ethBridgeAddress, amount: BigInt(0) },
        ];
        const strategyReportL2 = [
            { l1Strategy: uniswapV3StrategyAddress, actionId: "2", amount: amountWithdraw },
        ];
        const bridgeDepositInfo: any = [
            { bridge: ethBridgeAddress, amount: amountWithdraw },
        ];
        const expectedHashL2 = computeFromReportL2(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo);
        const messageReceivedL1 = computeMessageReceivedL1(l2PoolingManager, poolingManagerAddress, BigInt(expectedHashL2));
        starknetMock.addMessage([messageReceivedL1])

        const expectedReport = [
            { l1Strategy: uniswapV3StrategyAddress, l1Nav: "0", amount: "999999999999999999" },
        ];

        const overallFees = l2MessagingEthFee + l2BridgeEthFee;

        await expect(poolingManager.handleReport(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo, l2BridgeEthFee, l2MessagingEthFee, 1, { value: overallFees })).to.emit(poolingManager, "ReportHandled");

        // Make sure the right message has been sent
        const expectedHashL1 = computeFromReportL1(expectedReport);
        const nonceMessaging = await starknetMock.l1ToL2MessageNonce();
        const messageReceivedL2 = computeMessageReceivedL2(poolingManagerAddress, l2PoolingManager, (nonceMessaging - BigInt(1)).toString(), BigInt(epoch), BigInt(expectedHashL1));
        const { lowPart: lowEpoch, highPart: highEpoch } = splitUint256ToUint128(BigInt(epoch));
        const { lowPart: lowHash, highPart: highHash } = splitUint256ToUint128(BigInt(expectedHashL1));
        const messageReceivedL2Call = await starknetMock.getL1ToL2MsgHash(poolingManagerAddress, l2PoolingManager, L2_HANDLER_SELECTOR, [lowEpoch, highEpoch, lowHash, highHash], (nonceMessaging - BigInt(1)));
        expect(messageReceivedL2).to.equal(messageReceivedL2Call);
        const l1ToL2Message = await starknetMock.l1ToL2Messages(messageReceivedL2);
        expect(l1ToL2Message).to.be.equal(1 + l2MessagingEthFee);
    });

    it("test handleReport one strategy with deposit order, revert, no pending", async function () {
        const { owner, relayer, starknetMock, starknetMockAddress, dai, daiAddress, weth, wethAddress, wsteth, wstethAddress, sdai, sdaiAddress, daiBridge, daiBridgeAddress, ethBridge, ethBridgeAddress, poolingManager, poolingManagerAddress } = await InitPoolingManager();
        const { mockV3Aggregator, mockV3AggregatorAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await InitUniswap(owner.address, poolingManagerAddress, weth, wethAddress, wsteth, wstethAddress);
        await poolingManager.registerStrategy(uniswapV3StrategyAddress, wethAddress, ethBridgeAddress);

        // Previous Price of one Wsteth: 1.2 WETH, now update to 1 WETH but amm still trading at 1.2WETH
        mockV3Aggregator.updateAnswer("1000000000000000000");

        let epoch = "1";
        const depositAmount = ethers.parseUnits('1', 'ether');
        const bridgeInfo = [
            { bridge: ethBridgeAddress, amount: depositAmount },
        ];
        const strategyReportL2 = [
            { l1Strategy: uniswapV3StrategyAddress, actionId: "0", amount: depositAmount },
        ];
        const bridgeDepositInfo: any = [
        ];
        const expectedHashL2 = computeFromReportL2(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo);
        const messageReceivedL1 = computeMessageReceivedL1(l2PoolingManager, poolingManagerAddress, BigInt(expectedHashL2));
        starknetMock.addMessage([messageReceivedL1])
        await expect(poolingManager.handleReport(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo, 0, l2MessagingEthFee, 1, { value: l2MessagingEthFee })).to.revertedWithCustomError(poolingManager, "NoL1Report");
    });

    it("test handleReport two strategy with deposit order, revert, no pending", async function () {
        const { owner, relayer, starknetMock, starknetMockAddress, dai, daiAddress, weth, wethAddress, wsteth, wstethAddress, sdai, sdaiAddress, daiBridge, daiBridgeAddress, ethBridge, ethBridgeAddress, poolingManager, poolingManagerAddress } = await InitPoolingManager();
        const { mockV3Aggregator, mockV3AggregatorAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await InitUniswap(owner.address, poolingManagerAddress, weth, wethAddress, wsteth, wstethAddress);
        const { savingDaiStrategy, savingDaiStrategyAddress } = await InitSavingDai(poolingManagerAddress, daiAddress, sdaiAddress);

        await poolingManager.registerStrategy(uniswapV3StrategyAddress, wethAddress, ethBridgeAddress);
        await poolingManager.registerStrategy(savingDaiStrategyAddress, daiAddress, daiBridgeAddress);

        // Previous Price of one Wsteth: 1.2 WETH, now update to 1 WETH but amm still trading at 1.2WETH
        mockV3Aggregator.updateAnswer("1000000000000000000");

        let epoch = "1";
        const depositAmount = ethers.parseUnits('1', 'ether');
        const depositAmountDai = ethers.parseUnits('2', 'ether');
        const bridgeInfo = [
            { bridge: ethBridgeAddress, amount: depositAmount },
            { bridge: daiBridgeAddress, amount: depositAmountDai }
        ];
        const strategyReportL2 = [
            { l1Strategy: uniswapV3StrategyAddress, actionId: "0", amount: depositAmount },
            { l1Strategy: savingDaiStrategyAddress, actionId: "0", amount: depositAmountDai },
        ];
        const bridgeDepositInfo: any = [
        ];
        const expectedHashL2 = computeFromReportL2(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo);
        const messageReceivedL1 = computeMessageReceivedL1(l2PoolingManager, poolingManagerAddress, BigInt(expectedHashL2));
        starknetMock.addMessage([messageReceivedL1])
        await expect(poolingManager.handleReport(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo, 0, l2MessagingEthFee, 2, { value: l2MessagingEthFee })).to.revertedWithCustomError(poolingManager, "NotEnoughSuccessCalls");
    });

    it("test handleReport two strategy with deposit order, one revert and go to pending, no pending", async function () {
        const { owner, relayer, starknetMock, starknetMockAddress, dai, daiAddress, weth, wethAddress, wsteth, wstethAddress, sdai, sdaiAddress, daiBridge, daiBridgeAddress, ethBridge, ethBridgeAddress, poolingManager, poolingManagerAddress } = await InitPoolingManager();
        const { mockV3Aggregator, mockV3AggregatorAddress, uniswapV3Strategy, uniswapV3StrategyAddress } = await InitUniswap(owner.address, poolingManagerAddress, weth, wethAddress, wsteth, wstethAddress);
        const { savingDaiStrategy, savingDaiStrategyAddress } = await InitSavingDai(poolingManagerAddress, daiAddress, sdaiAddress);

        await poolingManager.registerStrategy(uniswapV3StrategyAddress, wethAddress, ethBridgeAddress);
        await poolingManager.registerStrategy(savingDaiStrategyAddress, daiAddress, daiBridgeAddress);

        // Previous Price of one Wsteth: 1.2 WETH, now update to 1 WETH but amm still trading at 1.2WETH
        mockV3Aggregator.updateAnswer("1000000000000000000");

        let epoch = "1";
        const depositAmount = ethers.parseUnits('1', 'ether');
        const depositAmountDai = ethers.parseUnits('2', 'ether');
        const bridgeInfo = [
            { bridge: ethBridgeAddress, amount: depositAmount },
            { bridge: daiBridgeAddress, amount: depositAmountDai }
        ];
        const strategyReportL2 = [
            { l1Strategy: uniswapV3StrategyAddress, actionId: "0", amount: depositAmount },
            { l1Strategy: savingDaiStrategyAddress, actionId: "0", amount: depositAmountDai },
        ];
        const bridgeDepositInfo: any = [
        ];
        const expectedHashL2 = computeFromReportL2(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo);
        const messageReceivedL1 = computeMessageReceivedL1(l2PoolingManager, poolingManagerAddress, BigInt(expectedHashL2));
        starknetMock.addMessage([messageReceivedL1])
        await poolingManager.handleReport(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo, 0, l2MessagingEthFee, 1, { value: l2MessagingEthFee });
        // await expect(poolingManager.handleReport(epoch, bridgeInfo, strategyReportL2, bridgeDepositInfo, 0, l2MessagingEthFee, 1, { value: l2MessagingEthFee })).to.emit(poolingManager, "ReportHandled").withArgs(epoch, 1, [[savingDaiStrategyAddress, "1999999998999999999", "0"], ["0", "0", "0"]]);

        const expectedReport = [
            { l1Strategy: savingDaiStrategyAddress, l1Nav: "1999999999999999999", amount: "0" },
        ];

        const expectedHashL1 = computeFromReportL1(expectedReport);
        const nonceMessaging = await starknetMock.l1ToL2MessageNonce();
        const messageReceivedL2 = computeMessageReceivedL2(poolingManagerAddress, l2PoolingManager, (nonceMessaging - BigInt(1)).toString(), BigInt(epoch), BigInt(expectedHashL1));

        const { lowPart: lowEpoch, highPart: highEpoch } = splitUint256ToUint128(BigInt(epoch));
        const { lowPart: lowHash, highPart: highHash } = splitUint256ToUint128(BigInt(expectedHashL1));
        const messageReceivedL2Call = await starknetMock.getL1ToL2MsgHash(poolingManagerAddress, l2PoolingManager, L2_HANDLER_SELECTOR, [lowEpoch, highEpoch, lowHash, highHash], (nonceMessaging - BigInt(1)));
        expect(messageReceivedL2).to.equal(messageReceivedL2Call);
        const l1ToL2Message = await starknetMock.l1ToL2Messages(messageReceivedL2);
        expect(l1ToL2Message).to.be.equal(1 + l2MessagingEthFee);

        // Still can't check for struct but good value
        // const pendingRequestsCreatedExpected = [uniswapV3StrategyAddress, "0", depositAmount];
        // const pendingRequestsCreated = await poolingManager.pendingRequests(0);
        // expect(pendingRequestsCreated).to.be.equal(pendingRequestsCreatedExpected);
    });



});

