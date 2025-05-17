# 背景
常见的solidity合约漏洞，在前人的基础上学习和提升

# 参考链接
- [常见漏洞第1篇](https://learnblockchain.cn/article/5853)
- [常见漏洞第2篇](https://learnblockchain.cn/article/5860)
- [常见漏洞第3篇](https://learnblockchain.cn/article/5867)
- [常见漏洞第4篇](https://learnblockchain.cn/article/5873)
- [2023年常见合约漏洞](https://learnblockchain.cn/article/6310)

# 详细分类

## 重入攻击
- 当eth被转账时，接受合约的回退或者接受函数被调用，增额时候就把控制权交给了对方合约
- 一些代币协议通过调用一个预先确定的函数来提醒对方（接收方的智能合约）收到了代币，这就把控制流交给了接受函数
- 当攻击合约收到控制权时，它不一定会调用对应的函数，而是通过再次调用受害者（sender）合约中的不同函数（跨函数重入），甚至是不同合约（跨合约重入）
- 只读重入发生在合约处于中间状态时访问一个视图函数。
- [示例代码](xxx)

## 不适当的访问控制
- 没有按预期控制住非法访问
- 常见场景1: 身份校验的modifier函数没有写，或者写了之后没有异常抛出的语句
- 常见场景2: 校验是否已经访问过了，但是实际没有在每个用户访问后写入合约存储，导致校验结果永远为true
- [示例代码](xxx)

## 不正确的输入验证
- 比如常见的withdraw接口，允许从任何人的地址提款的漏洞
- [示例代码](xxx)

## 过多的函数限制
- 可能导致资金锁死在合约中，因为设计漏洞导致没有任何人能从合约中提取资金
- [示例代码](xxx)

## 投票相关 - 双重投票或者msg.sender
- 如果拥有一个token代表有对应的投票权，那么用户可以将这个token在地址A中投票完成后，转移到地址B再次投票
- 应该使用erc20 snapshot 或者 erc20 votes
- [示例代码](xxx)

## 闪电贷治理攻击
- 黑客通过闪电贷获取到足够多的治理token，投票完成后即退回，影响投票的结果（按黑客的预期）
- [示例代码](xxx)

## 闪电贷价格攻击
- 黑客通过闪电贷短期内获取足够多的资金，token交易对的价格会随着买卖压力的变化而变化，会产生巨大的买卖压力，最终导致黑客使用小部分资金撬动了大量资金
- [链上top10闪电贷攻击分析](https://www.immunebytes.com/blog/top-10-flash-loan-attacks/)
- [示例代码](xxx)

## 绕过“是否是合约”的检查
- 如果合约中对某个地址是否是合约有检查，那么黑客可以绕过
- 方案1是在黑客部署合约地址的constructor函数中访问，此时新合约的runtimeCode还没有被写入
- 方案2是使用create2函数提前计算合约地址，在没有实际部署合约之前，这个地址表现得就是一个普通的eoa
- [示例代码](xxx)

## tx.origin问题
- 不要使用tx.origin来标记和识别发起人，黑客可能诱骗用户签署一个恶意合约的call，然后在恶意合约中去访问受害者合约（比如token转账等）
- [示例代码](xxx)

## gas拒绝服务攻击（griefing attack)
- 通过恶意消耗完交易中的gas导致某个合约无法正常提供服务
- 方案1: 在fallback函数里死循环while
- 方案2: 在方法中返回大量的字节（导致caller的gas会被用完）
- 方案3: 删除一个大量数据的list结构
- [示例代码](xxx)

## 不安全的随机数
- 目前无法使用区块链上的单一交易安全地产生随机数
- 只要随机数是在区块链上由合约产生的，那就是可以完全遇见和复制的。
- [示例代码](xxx)

## 错误使用chainlink随机数oracle
- 常规来说，chainlink来完成安全随机数的获取，这样的话攻击者无法预测实际的随机数。
  - 步骤1: 智能合约向预言机合约发起一个随机数请求。
  - 步骤2: 一段时间后，预言机合约会返回一个随机数。
- 但是可能会存在如下的错误使用预言机的风险：
  - 链上可能发生reorg，尤其是polygon这种侧链，上层应用和底层数据都可能发生reorg
  - 请求随机数的智能合约必须在随机数返回之前不做任何事情，否则可能被攻击者监视到返回随机数的预言机mempool，然后就能提前知道随机数的值。
- [示例代码](xxx)

## 价格oracle中获取陈旧的数据
- 如果链上较为繁忙，可能导致合约获取到老旧的价格数据，引起资金亏损。
- **需要明确什么时间范围的价格是可以接受的，以及价格本身波动的范围是否可信**。
- [示例代码](xxx)

## 只依赖一个预言机
- 如果只依赖一个预言机，那攻击成功的可能性会很大，对此的防御措施是使用多个独立的预言机。
- **一个好的智能合约架构在可能的情况下会完全避免使用预言机。**
- [示例代码](xxx)

## 混合计算
- 外部合约可能通过selfdestruct方法强制发送eth余额给受害者合约地址，导致受害者合约内部的记账不再准确
- erc20就属于特定场景构造，尽可能统一资金的收支方法（不要又记账，又从外部合约中读区）
- [示例代码](xxx)

## 把加密证明当作密码一样对待
- 看接下来一段代码
```
contract InsecureMerkleRoot {
    bytes32 merkleRoot;
    function airdrop(bytes[] calldata proof, bytes32 leaf) external {

        require(MerkleProof.verifyCalldata(proof, merkleRoot, leaf), "not verified");
        require(!alreadyClaimed[leaf], "already claimed airdrop");
        alreadyClaimed[leaf] = true;

        mint(msg.sender, AIRDROP_AMOUNT);
    }
}
```
- 示例代码中，有3个风险
  - 任何人都能监听链上事件，并本地重构merkleTree，创建出正确额merkleProof
  - 叶子以明文方式写入，攻击者也可以构造一个明文来完成功能
  - 如果有人提交了有效的证明，也可能被抢跑
    - 任何人都可以在内存池中截留该数据，然后将收款地址替换成自己
- 也就是说，加密的证明（merkleTree，签名等）需要与msg.sender绑定，让恶意攻击者无法拿到对应的msg.sender，以及构造正确的签名。
- [示例代码](xxx)

## 数值溢出问题
- uint256 a = uint8(b) + 1
  - 如果此时b是2^8-1, 那么a的值不会变成256， 而是会直接revert, 因为超过了uint8的上限。
  - 
- [示例代码](./PrimitiveOverflow/PrimitiveOverflow.sol)

## solidity截断问题
- solidity0.8以前，uint256可能存在溢出问题，需要使用对应的safeCast库来进行安全加减乘除
- 如下代码中，代码不会revert，但会overflow变成0
```function test(int256 value) public pure returns (int8) {
	return int8(value + 1); // overflows and does not revert
} 

```
- [示例代码](xxx)

## 对存储指针的写入不会保存新数据
- 还是如下代码，实际上并不会修改myArray里的对应值。
  - 这个原理跟C一样，指针和对象，需要分清
```contract DoesNotWrite {
    struct Foo {
        uint256 bar;
    }
    Foo[] public myArray;

    function moveToSlot0() external {
        Foo storage foo = myArray[0];
        foo = myArray[1]; // myArray[0] 不会改变
        // we do this to make the function a state 
        // changing operation
        // and silence the compiler warning
        myArray[1] = Foo({bar: 100});
    }
}
```
- [示例代码](xxx)

## 删除包含动态数据类型的结构并不会删除实际的数据
- 比如mapping和list的场景下，如果某个slot包含对其他slot的引用，那么这些slot不会被删除（会遗留下来）
- 给出这段代码，问题点比较明确
```contract NestedDelete {

    mapping(uint256 => Foo) buzz;

    struct Foo {
        mapping(uint256 => uint256) bar;
    }

    Foo foo;

    function addToFoo(uint256 i) external {
        buzz[i].bar[5] = 6;
    }

    function getFromFoo(uint256 i) external view returns (uint256) {
        return buzz[i].bar[5];
    }

    function deleteFoo(uint256 i) external {
        // internal map still holds the data in the 
        // mapping and array
        delete buzz[i];
    }
}
```
- [示例代码](xxx)


## erc20代币问题 - 转账扣费
- 不应该预期某个token的transfer方法新增100之后，余额会实际新增100
  - 考虑手续费场景
- [示例代码](xxx)

## erc20代币问题 - rebase代币
- 当一个代币的所有余额rebase时，总发行量会发生变化，所有人的余额会被按总发行量变更的方向进行同步rebase
- 最好是不要在外部存储某个token的余额，如果要，使用的时候要看一下实际的余额是否符合预期。
- [示例代码](xxx)

## erc777 等代币转账钩子可能引起重入问题
- 最后openzeppelin废弃了erc777库一样
- [示例代码](xxx)

## erc20 不是所有的erc20代币转账都会返回true
- 规范是说，如果不符合预期就应该返回false，但是tether等并没有严格遵守这个要求，而是在余额不足的场景下直接revert了交易
- [示例代码](xxx)

## erc20的地址投毒（0金额代币转账）
- 实际可以允许模拟A发送资金给B（0金额的形式）
  - 比如transferFrom（A， B， 0）
- [示例代码](xxx)

## 未检查的返回值
- 如果使用call或者assembly时，一定要显示检查返回值，因为如果发生了revert，caller是不会自动revert的
- [示例代码](xxx)

## 在循环中使用msg.value
- 因为循环过程中有可能会消耗该msg.value，所以一定需要动态判定（而不是使用一开始的一个）
- 最直接的问题就是双花。

## 合约中私有变量的定义
- 实际上合约里不存在任何私有变量，所有变量都可以通过contract storage在链外读取

## 不安全的delegatecall调用
- 比如调用的函数里包括selfdestruct

## 合约升级的问题
- logic合约升级时，多个父类的storage会排列和对齐，可能导致变量之间相互覆盖（gap结构）




## 减少过大的管理员权限
- 避免权限丢失后导致大范围影响，应该仔细设计和限制权限

## 避免owner权限转移失败（使用ownable2Step进行权限转移）
- 避免因为地址填写错误等导致权限丢失

## 四舍五入的问题
- 看这段代码，最终daiToTake一定会是0
  ```contract Exchange {

    uint256 private constant CONVERSION = 1e12;

    function swapDAIForUSDC(uint256 usdcAmount) external pure returns (uint256 a) {
        uint256 daiToTake = usdcAmount / CONVERSION;
        conductSwap(daiToTake, usdcAmount);
    }
}```
- [示例代码](xxx)

## 抢跑 - 不受限制的提款
- 任何交易都有可能有被其他人在内存池子里监听到的风险，
- 所以尽量设计完善的安全认证流程，以及尽量将交易聚合成一笔使用事务的特性
- [示例代码](xxx)

## 抢跑 - erc4626通膨攻击
- 结合了四舍五入问题和抢跑问题
- 给定以下这段代码，存钱进去，然后获取一定的share股权
```function getShares(...) external {
    // code
    shares_received = assets_contributed / total_assets;
    // more code
}
```
- 如果有人存入20，本来预期有一定的资产获取，但是你通过抢跑提前存入200，就能稀释受害者的share，并且因为四舍五入变成存了钱，但是只拿到0share
- [示例代码](xxx)

## 抢跑 - erc20授权
- A准备授权给B 100的代币权限，构造交易1
- A后悔了，A只准备给50.构造交易2
- 当交易2在mempool里时，B先发送交易3 transferFrom（A， 100），
- 即交易顺序为 1 - 3 - 2
- 最终A损失了150的代币
- [示例代码](xxx)

## 抢跑 - 三明治攻击
- 常见于大量购买某个token时，可能引起该token价格上升。
- 攻击者可以在受害者购买交易之前插入自己的交易1（提前购买一部分该token），同时在受害者购买交易之后插入自己的交易2（卖出该token），从而获得利差，让受害者额外多付出资金
- 需要在eth client层面配合，确保攻击者的交易2能提交
- [示例代码](xxx)

## 签名相关 - ecrecover()函数不通过，返回0，但传入的用来比较的address也是0
- ecrecover函数如果不通过并不会revert，而是返回address(0)，如果此时的校验也是address(0)则能绕过校验
- 代码如下
```contract InsecureContract {

    address signer; 
    // defaults to address(0)
    // who lets us give the beneficiary the airdrop without them// spending gas
    function airdrop(address who, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {

        // 如果签名无效，ecrecover 会返回 address(0) 
        require(signer == ecrecover(keccak256(abi.encode(who, amount)), v, r, s), "invalid signature");

        mint(msg.sender, AIRDROP_AMOUNT);
    }
}
```
- [示例代码](xxx)


## 签名相关 - 签名重放
- 即一个签名被反复多次拿来验证，最终导致异常风险。
- 有几个重要的点：
  - 签名信息构成里需要包括source用户地址信息（防止抢跑），链id（防止跨链重放），有效时间段，nonce（防止双花），签名的信息在链上构造

## 签名相关 - 多个签名验证绕过问题（for循环）
- 如果签名验证逻辑写在for循环里，for循环检查完毕后执行逻辑。
- 如果输入的list长度直接为0，则可以绕过，给定如下代码
- [示例代码](xxx)

## 签名相关 - 签名的可塑性问题
- 即ecdsa签名可能出现2个有效的s，v只是用于决定取哪一个。
  - 用曲线的阶减去原来的s，就是新的s，然后v取另一个值。
- 比如使用eddsa等签名方案就从源头规避了签名可塑性问题。
- 同时也需要确保签名的重放问题，给出nullifer记录，同时要将交易的核心信息都打包到签名中，哪怕有恶意攻击者抢跑也无法修改交易的既定结果。

## 极端场景 - compound奖励计算错误问题
- 可以进一步查看这个事件原理并重现




