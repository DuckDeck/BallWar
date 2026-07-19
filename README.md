# Ball War

基于 **Godot 4.7 + GDScript** 的离线竖屏 2D 弹球消除原型。第一阶段已经完成：从顶部缺口向下发射单球、重力与反弹、六边形耐久障碍、得分、拖尾，以及底部托底回收至顶部发球点。

## 快速开始

1. 用 Godot 4.7 打开本目录。
2. 运行主场景：`res://scenes/main.tscn`。
3. 在顶部缺口下方点击或向下拖拽后松开，即可从缺口发球。

无头回归测试（PowerShell）：

```powershell
& 'D:\Program\Godot_v4.7\Godot_v4.7-stable_mono_win64_console.exe' --headless --path . -s res://tests/t1_smoke_test.gd
& 'D:\Program\Godot_v4.7\Godot_v4.7-stable_mono_win64_console.exe' --headless --path . -s res://tests/t1_gravity_test.gd
& 'D:\Program\Godot_v4.7\Godot_v4.7-stable_mono_win64_console.exe' --headless --path . -s res://tests/t1_bottom_recovery_test.gd
```

## 文档入口

- [项目概览](docs/00-项目概览.md)：运行方式、目录职责、第一阶段范围。
- [项目导览](docs/05-项目导览/README.md)：运行时对象、球的行为、配置和当前架构边界。
- [基础弹球闭环需求](docs/01-需求/01-01-基础弹球闭环/README.md)：已确认的玩法规则。
- [Godot 技术导航](docs/03-前端技术/godot/00-README.md)：当前实现与扩展规范。
- [任务总控](docs/00-任务总控/2026-06-30-Godot4跨平台2D弹球消除游戏/README.md)：阶段拆分与历史决策。

## 当前边界

当前实现是“单球 + 单个固定六边形障碍”的可验证闭环。多球下压、更多障碍形状、爆炸球、穿透球和大体积球尚未实现；进入这些玩法前请先阅读 [架构评审与扩展路线](docs/05-项目导览/03-架构评审与扩展路线.md)。
