// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
回顾：
1、require = if-revert模式
   常用于简单的条件判断，编译器会转换为if (!condition) { revert(message); }
2、revert = 自定义error模式
   适合复杂的条件判断，如对可选参数进行格式检查等
3、assert = 断言模式
   不退gas，一般用于溢出检查、数据审计核对场景，如defi项目中核对用户可提取收益总和是否与池子中的余额是否一致，避免不够支付。
*/ 
contract Example1 {
    mapping(address => uint256) public balances; // 记录用户余额
    uint256 public totalDeposited; // 记录所有用户的存款总额
    address public owner; // 记录合约管理员地址 

    constructor() {
        owner = msg.sender;
    }

    // 自定义error
    error DepositZeroAmount();
    error InsufficientBalance(address user, uint256 balance, uint256 requestedAmount);
    error WithdrawZeroAmount();
    error WithdrawFailed();
    error NotOwner(address caller);
    error NoFundsAvailable();
    error EmergencyWithdrawalFailed();
    error InvalidBValue(uint256 providedValue);

    /// @notice 用户存款
    function deposit() external payable {
        // require(msg.value > 0, "Deposit amount must be greater than 0");
        if (msg.value == 0) revert DepositZeroAmount(); // 使用if-revert模式替代require，更省gas

        balances[msg.sender] += msg.value;
        totalDeposited += msg.value;

        // 确保总存款金额与合约余额一致
        assert(totalDeposited == address(this).balance);
    }

    /// @notice 用户取款
    function withdraw(uint256 amount) external {
        // require(amount > 0, "Withdraw amount must be greater than 0");
        if (amount == 0) revert WithdrawZeroAmount();
        
        // require(balances[msg.sender] >= amount, "Insufficient balance");
        if (balances[msg.sender] < amount) revert InsufficientBalance(msg.sender, balances[msg.sender], amount);

        balances[msg.sender] -= amount;
        totalDeposited -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            // revert("Withdraw failed");
            revert WithdrawFailed();
        }

        // 确保总存款金额与合约余额一致
        assert(totalDeposited == address(this).balance);
    }

    /// @notice 只有合约所有者才能提取所有余额（紧急提现）
    function emergencyWithdraw(uint256 _amount) external {
        // require(msg.sender == owner, "Only owner can withdraw all funds");
        if (msg.sender != owner) revert NotOwner(msg.sender);
        
        // require(address(this).balance > 0, "No funds available");
        if (address(this).balance == 0) revert NoFundsAvailable();
        
        uint256 amount = address(this).balance;
        if (_amount > 0 && _amount < amount) {
            amount = _amount;
        }

        totalDeposited -= amount; // 归零总存款记录

        (bool success, ) = payable(owner).call{value: amount}("");
        if (!success) {
            // revert("Emergency withdrawal failed");
            revert EmergencyWithdrawalFailed();
        }

    }

    // 仅为了示例对可选参数的检查 
    function revertExample(uint256 a, uint256 b) public pure {
        if (b > 0) { // 当b是可选参数时
            if (b != 10 && b != 20) {
                // revert("b must be 10 or 20");
                revert InvalidBValue(b);
            }
        }
        // ......
    }

    /// @notice 获取合约当前余额
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

}