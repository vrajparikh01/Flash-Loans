// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./FlashLoan.sol";
import "./Token.sol";

// borrower contract that takes out the loan
contract FlashLoanReceiver{
    FlashLoan private pool;
    address public owner;

    event LoanReceived(address token, uint amount);

    constructor(address _poolAddress){
        pool = FlashLoan(_poolAddress);
        owner = msg.sender;
    }

    // do whatever you want with money as long as you pay back
    function receiveTokens(address _tokenAddress, uint _amount) external{
        // console.log("tokenAddress: ",_tokenAddress, "amount: ", _amount);

        require(msg.sender == address(pool), "Sender must be pool");

        // Required funds received
        require(Token(_tokenAddress).balanceOf(address(this)) == _amount, "Failed to get the loan");

        // emit the event 
        emit LoanReceived(_tokenAddress, _amount);
        
        // Do stuff with the money
        // Here we can buy cryptos on one exchange and sell it on the other exchange

        // Return the funds to the pool
        require(Token(_tokenAddress).transfer(msg.sender, _amount),"Transfer of tokens failed");
    }

    function executeFlashLoan(uint _amount) external{
        require(msg.sender == owner, "Only owner can execute the fn");
        pool.flashLoan(_amount);
    }
}