### Shared VE
1. Deposit Multi to VEShare contract
2. Create shared VE
3. Withdraw Multi from VEShare
4. Withdraw shared VE

### VE share NFT
VE share NFT 由管理员创建，然后发给用户。三个参数：开始时间，结束时间，份额

开始时间、结束时间自动按天对齐

(UTC 2022/7/18/13:44, UTC 2022/8/18/13:44) -> (UTC 2022/7/18/00:00, UTC 2022/8/19/00:00)

VE share 延续时间不能超过 360 天

### Share 规则
每天所有用户的总份额不能超过 100
| Person | Day 1 | Day 2 | Day 3 | Day 4 | ... | Day 360 | Day 361 | Day 362 | Day 363 | ... | |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Alice | 50 | 50 | 50 | 50 | ... | 50 | 0 | 0 | 0 | ... |
| Bob | 0 | 40 | 40 | 40 | ... | 40 | 40 | 0 | 0 | ... |
| Total | 50 | 90 | 90 | 90 | ... | 90 | 40 | 0 | 0 | ... |
| New person 1 | 0 | 0 | 10 | 10 | ... | 10 | 10 | 10 | 0 | ... | ok |
| New person 2 | 0 | 0 | 20 | 20 | ... | 20 | 20 | 20 | 0 | ... | 不行，total share 超过 100 了 |

### Harvest 规则
VE share 持有者可以随时领取最新的奖励.

Harvest 结算范围是 $\lbrack settleStart, settleEnd \rbrack$，
$settleStart$ 是合约自动确定的，$settleEnd$ 默认等于 $block.timestamp$，可以手动设置为 $(settleStart, block.timestamp)$ 内的任意时间.

每个 epoch 可领取的奖励：
$$
claimableReward(epochId) = \frac{Length \lbrace \lbrack settleStart, settleEnd \rbrack \bigcap \lbrack epochStart(epochId), \widetilde{epochEnd}(epochId) \rbrack \rbrace}{\widetilde{epochEnd}(epochId) - epochStart(epochId)} \times epochReward(epochId) \times \frac{share}{100}
$$
$\widetilde{epochEnd} = min(epochEnd, block.timestamp)$

全部可领取的奖励：
$$
totalClaimable = \sum_{epochId} claimableReward(epochId).
$$

## 测试地址
- Multi 0x93bb21A55fa0598F28FF04117A8b683779D538E5
- USDC 0xFc3c911b420Bdf4F4812a6E1ddcE5abd0aF5824e
- VE 0x8a5967592A0EA779d189028e7f2ABe490081a438
- VEReward 0x7b6Ae47c8a1F83EF3AcbbD03f502808A29011d66
- VEShare 0x1C0b0cd3D4040b74Dc7D456b8D81d9634abCc977