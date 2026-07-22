# 续局存档与 HUD 自动化测试

> 版本归属：V0.4 | 生命周期状态：已审核

| 测试资产 | 覆盖内容 |
|---|---|
| `tests/t4_hud_test.gd#_initialize` | **T4-HUD-AUTO-01** HUD 为独立场景，且被主场景实例化后仍能解析自身控件；在常用/紧凑竖屏画布中保持顶部安全区与左右分区；**T4-HUD-AUTO-02** 分数、计时、挑战倒计时和暂停信号通过 HUD 组件工作。 |
| `tests/t4_session_restore_test.gd#_initialize` | **T4-SV-AUTO-01** 经典模式只恢复最近稳定检查点；**T4-SV-AUTO-02** 新进入挑战模式不建档，首次发射后保存并恢复为当前棋盘、库存与计时的 `READY` 状态且清空活动球；**T4-SV-AUTO-03** 两模式存档独立。 |
| `tests/t4_pause_test.gd#_initialize` | **T4-SV-AUTO-04** 暂停菜单保存退出后回到模式选择；模式选择不显示独立继续按钮，点击有存档的模式会显示续局确认弹窗。 |
| `tests/t4_progress_dialog_test.gd#_initialize` | **T4-SV-AUTO-05** 续局确认弹窗显示原始存档分数；继续恢复该分数的 `READY` 对局，不继续清除旧进度并开始零分新局。 |
