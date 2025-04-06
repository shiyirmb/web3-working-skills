// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/* 
    总结：
    storage/memory/calldata/transient storage(Solidity 0.8.13+)
    持久性: storage（永久） > transient（交易内） > memory/calldata（函数调用内）
    成本: storage（最贵） > transient > memory > calldata（最便宜）
    可变性: storage/memory/transient（可变） vs calldata（只读）
*/

// 演示不使用Transient时的gas消耗情况
contract WithoutTransient {

    // 使用 storage 变量时，需要实实在在地写入区块链
    // 对应着EVM操作码： SSTORE， 操作消耗大量 gas（设置为非零值约 20,000 gas，修改现有值约 5,000 gas）
    bool private _locked; 

    mapping(address => uint256) public balances;
    
    modifier nonReentrant() {
        // 检查锁定状态
        require(!_locked, "ReentrancyGuard: reentrant call");
        
        // 锁定合约
        _locked = true;
        
        // 执行函数
        _;
        
        // 解锁合约
        _locked = false;
    }
    
    function withdraw() external payable nonReentrant { // 以防止重入攻击为例
        // uint256[] memory a = new uint256[](10);
        uint256 amount = balances[msg.sender];
        if (amount > 0) {
            balances[msg.sender] = 0;
            
            // 外部调用可能导致重入
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed");
        }
    }
    
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
}


// 演示使用Transient时的gas消耗情况
contract WithTransient {
    // 使用 transient 变量，仅临时存储，在合约间调用中共享，一旦交易完成就丢弃，不会永久存储到链上
    // 对应着EVM操作码： TSTORE / TLOAD
    // transient 变量写入成本远低于正常 storage 变量（约 100 gas vs 5,000-20,000 gas）
    // 锁在交易结束时自动清除，不需要担心锁定状态意外持续到下一个交易
    bool transient _locked;

    mapping(address => uint256) public balances;
    
    modifier nonReentrant() {
        // 检查锁定状态
        require(!_locked, "ReentrancyGuard: reentrant call");
        
        // 锁定合约
        _locked = true;
        
        // 执行函数
        _;
        
        // 解锁合约
        _locked = false;
    }
    
    function withdraw() external payable nonReentrant { // 以防止重入攻击为例
        uint256 amount = balances[msg.sender];
        if (amount > 0) {
            balances[msg.sender] = 0;
            
            // 外部调用可能导致重入
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed");
        }
    }
    
    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }
}