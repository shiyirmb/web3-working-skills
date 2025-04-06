// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    知识点：演示fallback+delegatecall实现合约升级模式
        1、fallback函数：当调用不存在的函数时触发，将所有调用委托给目标合约
        2、delegatecall：在fallback函数中使用delegatecall，将调用委托给目标合约
        3、存储布局：目标合约和调用者合约的存储布局必须匹配，否则会导致调用失败

    更完整的参考：https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Proxy.sol
*/

/**
 * @title DelegateCall示例合约
 * @dev 这个合约展示了delegatecall的特性和使用方法
 */

// 目标合约 - 包含将被delegatecall调用的函数
contract TargetContract {
    // 状态变量 - 在delegatecall时不会被使用
    uint256 public value;
    address public sender;
    uint256 public timestamp;
    
    // 事件 - 记录函数调用
    event TargetFunctionCalled(address caller, uint256 value, uint256 time);
    
    /**
     * @dev 设置值函数 - 将被delegatecall调用
     * @param _value 要设置的值
     */
    function setValue(uint256 _value) public {
        value = _value;
        sender = msg.sender;
        timestamp = block.timestamp;
        
        emit TargetFunctionCalled(msg.sender, _value, block.timestamp);
    }
    
    /**
     * @dev 获取状态函数
     * @return 当前值、发送者地址和时间戳
     */
    function getState() public view returns (uint256, address, uint256) {
        return (value, sender, timestamp);
    }
}

// 调用者合约 - 使用fallback+delegatecall实现代理模式（合约升级的核心机制）
contract CallerContract {
    // 状态变量 - 与目标合约的布局必须匹配！
    uint256 public value;
    address public sender;
    uint256 public timestamp;
    
    // 目标合约地址 - 用于fallback函数中的delegatecall
    address public targetContract;
    
    /**
     * @dev 设置目标合约地址 - 用于fallback函数中的delegatecall
     * @param _targetContract 目标合约地址
     */
    function setTargetContract(address _targetContract) public {
        require(_targetContract != address(0), "Invalid target contract address");
        targetContract = _targetContract;
    }
    
    /**
     * @dev 内部函数，执行delegatecall到目标合约
     * 参考了OpenZeppelin的Proxy合约实现
     */
    function _delegate() internal {
        address _targetContract = targetContract;
        require(_targetContract != address(0), "Target contract not set");
        
        // 使用内联汇编执行delegatecall
        assembly {
            // 复制调用数据
            calldatacopy(0, 0, calldatasize())
            
            // 执行delegatecall
            let result := delegatecall(gas(), _targetContract, 0, calldatasize(), 0, 0)
            
            // 复制返回数据
            returndatacopy(0, 0, returndatasize())
            
            // 根据调用结果返回或回滚
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    /**
     * @dev fallback函数 - 当调用不存在的函数时触发
     * 将所有调用委托给目标合约
     */
    fallback() external payable {
        _delegate();
    }
    
    /**
     * @dev receive函数 - 接收以太币时触发
     * 将调用委托给目标合约
     */
    receive() external payable {
        _delegate();
    }
}