// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IPancakeRouter02 {
    function WETH() external view returns (address);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

contract BuyToken is Ownable {
    address private constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E; 
    address private TOKEN_TO_BUY;
    uint256 private constant SLIPPAGE_TOLERANCE = 15; 

    IPancakeRouter02 public pancakeRouter;
    address public feeRecipient;
    uint256 public feePercentage;
    uint256 public randomVar;

    constructor(address _tokenAddress, address _owner) Ownable(_owner) {
        pancakeRouter = IPancakeRouter02(PANCAKE_ROUTER);
        TOKEN_TO_BUY = _tokenAddress;
        feePercentage = 100; 
    }

    receive() external payable {
        uint256 amountToSwap = msg.value;
        uint256 fee = (amountToSwap * feePercentage) / 10000; 

        buyToken(amountToSwap - fee, msg.sender);

        payable(feeRecipient).transfer(fee);
    }

    function buyToken(uint256 amountIn, address recipient) internal {
        uint256 amountOutMin = getAmountOutMin(amountIn);
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH(); 
        path[1] = TOKEN_TO_BUY;
        uint256 deadline = block.timestamp + 15 minutes; 

        pancakeRouter.swapExactETHForTokens{value: amountIn}(amountOutMin, path, recipient, deadline);
    }

    function getAmountOutMin(uint256 amountIn) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = TOKEN_TO_BUY;
        uint256[] memory amountsOut = pancakeRouter.getAmountsOut(amountIn, path);
        uint256 amountOutMin = (amountsOut[1] * (100 - SLIPPAGE_TOLERANCE)) / 100;
        return amountOutMin;
    }

    function returnTokensSentByMistake(address token, address to, uint256 amount) external onlyOwner {
    require(token != address(0), "Invalid token address");
    require(to != address(0), "Invalid recipient address");
    require(amount > 0, "Invalid amount");

    IERC20(token).transfer(to, amount);
}

    function withdrawTokens(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function withdrawBNB(address payable to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        feePercentage = _feePercentage;
    }

    function approveToken(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).approve(PANCAKE_ROUTER, amount);
    }
}