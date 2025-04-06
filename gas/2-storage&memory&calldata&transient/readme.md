transient更节省gas-0.8.13后新增加（写入成本约100gas，远低于storage的5000-20000gas）
- 持久性：storage-永久>transient-交易内>memory/calldata-函数调用内
- 成本：storage-最贵>transient>memory>calldata-最便宜
- 可变性：storage/memory/transient-可变 calldata-不可变