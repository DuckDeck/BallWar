# godot-ohos

[English](https://github.com/godothub/godot-ohos) | [中文文档](https://github.com/godothub/godot-ohos/blob/main/README-ZH.md)

Godot 的 OpenHarmony/HarmonyOS 支持，支持 Godot 最新稳定版

## 安装

从 release 页面下载插件压缩包，然后解压到 Godot 项目的 `addons` 目录。插件目录名需要保持为 `godot-ohos`。

目录结构大致如下：

```text
my_game/
├── project.godot
└── addons/
    └── godot-ohos/
        ├── plugin.cfg
        └── bin
```

## 配置

1. 用 Godot 打开项目。
2. 打开 `项目 > 项目设置 > 插件`。
3. 启用 `godot-ohos` 插件。
4. 打开 `编辑器 > 编辑器设置`。
5. 打开 `高级设置`。
6. 配置 `导出 > Harmony > Deveco Home`，指向 DevEco Studio 的安装目录。

该目录里可以看到sdk等目录。macOS 上通常是：

```text
/Applications/DevEco-Studio.app/Contents
```

导出模板目录由 `导出 > Harmony > Export Preset` 配置。默认会指向当前项目里的鸿蒙插件模板目录：

```text
res://addons/godot-ohos/bin
```

如果是直接解压 release 压缩包安装，通常不需要修改这个模板目录。

## 导出

1. 打开 `项目 > 导出`。
2. 添加 `OpenHarmony` 预设。
3. 配置 `包 > 唯一名称`。
4. 选择 OHOS 工程输出目录。
5. 执行导出。
6. 用 DevEco Studio 打开导出的 OHOS 工程，自行完成签名、打包和运行。

默认 SDK 版本是 `6.0.2(22)`，可以支持超过98%的鸿蒙设备，低于 API 22 的值会自动恢复到这个默认版本。
