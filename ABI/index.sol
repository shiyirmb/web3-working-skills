/*
总结：
abi.encode()	           严格 ABI 编码，32 字节对齐，适用于合约调用、参数传递
abi.encodePacked()	       紧凑编码，不对齐，适用于 keccak256() 计算哈希
abi.decode()	           解析 abi.encode() 生成的数据，适用于数据恢复

selector	               获取函数前 4 字节的选择器，用于 call() 或 delegatecall()
abi.encodeWithSignature()  生成完整 calldata（函数选择器+参数），适用于动态调用合约
abi.encodeWithSelector()   通过选择器构造 calldata	适用于代理合约
keccak256()	               计算哈希值，适用于唯一 ID、事件索引、完整性验证
*/

// --------------------------------------------------------------------------------------


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 编码解码示例合约
contract EncodeExample {
    function encodeData() external pure returns (bytes memory, bytes memory) {
        return (
            abi.encode("a", uint256(123)),        // 32 字节对齐   
            abi.encodePacked("a", uint256(123))  // 紧凑编码
        );
        
    }

    function decodeData(bytes memory data) external pure returns (string memory, uint256) {
        return abi.decode(data, (string, uint256));
    }
}

/* encodeData返回结果解析：
    0x0000000000000000000000000000000000000000000000000000000000000040 // 偏移量 (指向字符串数据的存储位置，这里表示往后找64字节)
      0000000000000000000000000000000000000000000000000000000000000020 // 数据长度
      000000000000000000000000000000000000000000000000000000000000007b // 123
      0000000000000000000000000000000000000000000000000000000000000001 // 1个字节
      6100000000000000000000000000000000000000000000000000000000000000 // a
    ABI规则：字符串不是固定长度，所以放在最后存储，所以a在最后
    bytes为字节数组，数组存储格式：[数据长度][实际数据]

    0x61000000000000000000000000000000000000000000000000000000000000007b
*/
    
    
// --------------------------------------------------------------------------------------


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TargetExample {
    uint256 public value;

    function setValue(uint256 _value) external {
        value = _value;
    }

    // abi.encodeWithSignature示例，在外部合约中调用
    // 等同于下面CallerExample合约中的abi.encodeWithSelector(selector, num)
    function encodeWithSignatureExample() external pure returns (bytes memory) {
        // 相当于构建calldata，适用于代理合约，如delegatecall()
        return abi.encodeWithSignature("setValue(uint256)", 123);
    }
}

contract CallerExample {
    uint256 public value; // 需要与 TargetExample 的存储布局一致，否则 delegatecall 会出问题，仅用于演示

    address public target;

    constructor(address _targetAddress) {
        target = _targetAddress;
    }

    function callSetValue(address target, uint256 num) external {
        bytes4 selector = bytes4(keccak256("setValue(uint256)"));
        (bool success, ) = target.call(abi.encodeWithSelector(selector, num));
        require(success, "Call failed");
    }

    function delegateCallSetValue(address target, uint256 num) external {
        bytes4 selector = bytes4(keccak256("setValue(uint256)"));
        (bool success, ) = target.delegatecall(abi.encodeWithSelector(selector, num));
        require(success, "Delegatecall failed");
    }

}

// --------------------------------------------------------------------------------------


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 以太坊哈希函数，生成256位哈希值
// 用途：
//   唯一 ID 计算
//   签名验证 如keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", message.length, message))
//   存储数据完整性验证
contract keccak256Example {
    uint256 public a;
    event SetAValue(address indexed from, uint256 indexed a);

    // 比如event selector生成：keccak256("SetA(address,uint256)")
    function setA() external {
        a = 123;
        emit SetAValue(msg.sender, a);
    }

    // 用于比较上面的event topic是否匹配
    function getEventSelector() external pure returns (bytes32) {
        return keccak256("SetAValue(address,uint256)");
    }

    function hashFunc() external pure returns (bytes4, bytes4) {
        return (bytes4(keccak256("setA()")), this.setA.selector);  // 获取前 4 字节的函数选择器
    }

    // 对数据进行哈希
    function getHash(string memory data) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }
}