const {ethers} = require('hardhat');
const {expect} = require('chai');

const tokens = (n)=>{
    return ethers.utils.parseUnits(n.toString(),'ether');
}
const ether = tokens;

describe('Flash Loans', ()=>{
    let token, flashLoan, flashLoanReceiver

    beforeEach(async ()=>{
        // setup accounts
        accounts = await ethers.getSigners();
        deployer = accounts[0];

        // Load contracts
        const FlashLoan = await ethers.getContractFactory('FlashLoan');
        const FlashLoanReceiver = await ethers.getContractFactory('FlashLoanReceiver');
        const Token = await ethers.getContractFactory('Token');

        // Deploy token
        token = await Token.deploy('Dapp Token', 'DAPP', '1000000');
        // Deploy flash loan pool
        flashLoan = await FlashLoan.deploy(token.address);
        // deploy the borrower contract
        flashLoanReceiver = await FlashLoanReceiver.deploy(flashLoan.address);

        // approve tokens before calling transferFrom fn
        let transaction = await token.connect(deployer).approve(flashLoan.address, ether(1000000));
        await transaction.wait();

        // deposit tokens into the pool
        transaction = await flashLoan.connect(deployer).depositTokens(ether(1000000));
        await transaction.wait();
    })

    describe('Deployment', ()=>{
        it('send token to flash loan pool contract', async()=>{
            expect(await token.balanceOf(flashLoan.address)).to.equal(ether(1000000));
        })
    })

    describe('Borrowing funds', ()=>{
        it('borrows funds from the pool', async()=>{
            let amount = ether(100);
            transaction = await flashLoanReceiver.connect(deployer).executeFlashLoan(amount);
            await transaction.wait();

            await expect(transaction).to.emit(flashLoanReceiver, 'LoanReceived')
                .withArgs(token.address, amount)
        })
    })
})