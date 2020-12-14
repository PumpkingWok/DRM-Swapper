
const DRMSwapper = artifacts.require("DRMSwapper.sol");
const ERC1155 = artifacts.require("ERC1155PresetMinterPauser.sol");
const truffleAssert = require('truffle-assertions');

contract('Contract -- deployement of DRMSwapper contract', function(accounts) {

    it('Deploy DRMSwapper', async function() {
        token0 = await ERC1155.new("T");
        await truffleAssert.passes(
            DRMSwapper.new(token0.address),
            "Token ERC1155 Compliant"
        );
    });
});