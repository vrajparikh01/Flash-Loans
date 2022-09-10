// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./Token.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IReceiver{
    function receiveTokens(address tokenAddress, uint amount) external;
}

// Flash Loan/Liquidity Pool
contract FlashLoan is ReentrancyGuard{
    using SafeMath for uint;

    Token public token;
    uint public poolBalance;

    constructor(address _tokenAddress) {
        token = Token(_tokenAddress);
    }

    function depositTokens(uint _amt) external nonReentrant{
        require(_amt>0,"Must deposit more than 1 token");
        token.transferFrom(msg.sender, address(this), _amt);
        poolBalance = poolBalance.add(_amt);
    }

    function flashLoan(uint _borrowAmt) external nonReentrant{
        // console.log("Borrowed Amt: ", _borrowAmt);
        require(_borrowAmt > 0, "Must borrow at least 1 token");

        uint balanceBefore = token.balanceOf(address(this));
        require(balanceBefore >= _borrowAmt, "Not enough tokens in the pool");

        // ensrured by the protocol via depositTokens fn
        assert(poolBalance == balanceBefore);

        // send tokens to receiver
        token.transfer(msg.sender, _borrowAmt);

        // use loan, get paid back
        IReceiver(msg.sender).receiveTokens(address(token), _borrowAmt);

        // ensure the loan paid back
        uint balanceAfter = token.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Flash loan hasn't been paid back");
    }
}