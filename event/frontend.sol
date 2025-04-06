// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EventExample合约
 * @dev 这个合约展示了event indexed/非indexed的前端数据展示
 */
contract EventExample {

    // indexed数据项会出现在topics中，而非indexed不会出现，需要使用ABI解析
    event BoughtToken(address indexed buyer, address indexed token, uint256 amount, uint256 cost);

    function buyToken() public payable  {

        emit BoughtToken(msg.sender, 0xCCF807B5207DC23Bc05fD547c55582B1C2E1F186, 1000, 2000);
    }

    function getEventSig() public pure returns (bytes32) {
        return keccak256("BoughtToken(address,address,uint256,uint256)");
    }

}