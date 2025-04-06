// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Receive和Fallback函数示例合约
 * @dev 这个合约展示了receive和fallback函数的区别和触发条件
 */
contract ReceiveFallbackExample {
    // 事件记录，用于跟踪函数调用
    event ReceivedEther(address sender, uint256 amount, string message);
    event FallbackCalled(address sender, uint256 amount, bytes data);
    
    // 记录合约收到的以太币总量
    uint256 public totalReceived;
    
    /**
     * @dev receive函数 - 当合约接收以太币但没有调用数据时触发
     * 条件：msg.data为空，且转账金额大于0
     */
    receive() external payable {
        totalReceived += msg.value;
        emit ReceivedEther(msg.sender, msg.value, "receive() was called");
    }
    
    /**
     * @dev fallback函数 - 当调用的函数不存在或发送了调用数据时触发
     * 条件1：msg.data不为空（调用了不存在的函数）
     * 条件2：msg.data为空但receive不存在，且转账金额大于0
     */
    fallback() external payable {
        totalReceived += msg.value;
        emit FallbackCalled(msg.sender, msg.value, msg.data);
    }
    
    /**
     * @dev 获取合约余额
     * @return 合约当前的以太币余额
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
}