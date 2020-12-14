const DRMSwapper = artifacts.require("DRMSwapper.sol");
const ERC1155 = artifacts.require("ERC1155PresetMinterPauser.sol");
const truffleAssert = require('truffle-assertions');

contract('Contract -- propose a swap', function(accounts) {

    before(async () => {
        token0 = await ERC1155.new("");
        factory = await DRMSwapper.new(token0.address);
        await token0.mintBatch(accounts[0], [0,1,2,3], [10,10,10,10], []);
        await token0.mintBatch(accounts[1], [4,5,6,7], [10,10,10,10], []);
        await token0.setApprovalForAll(factory.address, true, {from: accounts[0]});
        await token0.setApprovalForAll(factory.address, true, {from: accounts[1]});

    });

    it('Propose a swap with only one tokenId', async function() {

        const fromTokenId = [1]
        const fromAmount = [1]
        const toTokenId = [6]
        const toAmount = [1]
        const tx = await factory.proposeSwap(fromTokenId, fromAmount, toTokenId, toAmount, {from: accounts[0]});
        truffleAssert.eventEmitted(tx, 'ProposeSwap', (ev) => {
            return true;
        });
        const swap = await factory.getSwap(1)
        assert.equal(swap.creator, accounts[0])
        assert.equal(fromTokenId, parseInt(swap.fromTokensId))
        assert.equal(fromAmount, parseInt(swap.fromAmounts))
        assert.equal(toTokenId, parseInt(swap.toTokensId))
        assert.equal(toAmount, parseInt(swap.toAmounts))
    });

    it('Accept a swap not reserved', async function() {
        const tx = await factory.acceptSwap(1, {from: accounts[1]})
        truffleAssert.eventEmitted(tx, 'AcceptSwap', (ev) => {
            return true;
        });
    });

    it('Propose a reserved swap with only one tokenId', async function() {
        const fromTokenId = [2]
        const fromAmount = [2]
        const toTokenId = [7]
        const toAmount = [3]
        const reservedFor = accounts[1]
        const tx = await factory.proposeSwapReserved(fromTokenId, fromAmount, toTokenId, toAmount, reservedFor);
        truffleAssert.eventEmitted(tx, 'ProposeSwap', (ev) => {
            return true;
        });
    });

    it('Accept a swap reserved', async function() {
        const tx = await factory.acceptSwap(2, {from: accounts[1]})
        truffleAssert.eventEmitted(tx, 'AcceptSwap', (ev) => {
            return true;
        });
    });
});