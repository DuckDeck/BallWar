# 多球与棋盘波次手工验证场景

> 所属功能域：多球顺序弹射、方块波次与危险线
> 版本归属：v0.3 | 生命周期状态：已审校

## 执行环境

- Godot 4.7，启动 `res://scenes/main.tscn`。
- 使用 `resources/game_config.tres`；需要验证上限时，可暂时将 `initial_ball_count` 调为 10。

## 用例

### T2-MAN-01：顶部槽位与顺序发射

- 来源层引用：L1-MB-01、L1-MB-02、L1-MB-03、L1-MB-05、L1-MB-06。
- execution_ref：`tests/t2_t3_architecture_test.gd#_initialize`。
- 操作步骤：将起始球数临时设为 10，从顶部缺口向下方拖拽并发射，观察至所有球回收。
- 期望结果：首球立即从缺口离开；其余彩球留在两条斜线形成的顶部槽内，按短间隔沿同一瞄准角度依次发射；球与其拖尾 RGB 一致；球之间不相撞；最后一球回收后才恢复发射。

### T3-MAN-01：安全波次推进

- 来源层引用：L1-WB-01、L1-WB-02、L1-WB-03、L1-WB-04。
- execution_ref：`tests/t2_t3_architecture_test.gd#_initialize`。
- 操作步骤：完成一个未触及危险线的球批次。
- 期望结果：旧方块整体上移一个逻辑格，底部只生成一行且至少一块；下一安全回合的球数和方块数字不降低。

### T3-MAN-02：危险线结束

- 来源层引用：L1-WB-05、L1-WB-06、L1-WB-07。
- execution_ref：`tests/t2_t3_architecture_test.gd#_initialize`。
- 操作步骤：连续完成安全批次，直至任意方块上边缘触及顶部虚线。
- 期望结果：进入 `GAME_OVER`，发射器禁用，累计分数冻结；该失败回合不再生成底行或增加下一批球数。
