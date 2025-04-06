1、require/revert/asset
- require 使用 if-revert 模式替代（简单条件判断，require中的提示字符串存在区块链上）
- revert 使用 自定义Error 模式替代（复杂逻辑判断，如可选参数检查）
- assert 断言模式（不退gas或只退部分gas，溢出检查，数据审计核对）
- revert+自定义Error更节省gas