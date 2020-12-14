
const DRMSwapper = artifacts.require("DRMSwapper.sol");
const truffleAssert = require('truffle-assertions');

contract('Contract -- deployement of DRMSwapper contract', function(accounts) {
    let swappers;
    const drmA = '0x44d6E8933F8271abcF253C72f9eD7e0e4C0323B3'

    it('Deploy DRMSwapper', async function() {
        swappers = await DRMSwapper.new(drmA);
    });
});