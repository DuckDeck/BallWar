# godot-ohos

[English](https://github.com/godothub/godot-ohos) | [中文文档](https://github.com/godothub/godot-ohos/blob/main/README-ZH.md)

OpenHarmony/HarmonyOS support for Godot, adapted for the latest stable version

## Installation

Download the plugin archive from the release page, then extract it into your Godot project's `addons` directory. The plugin directory must be named `godot-ohos`.

The project layout should look roughly like this:

```text
my_game/
|-- project.godot
`-- addons/
    `-- godot-ohos/
        |-- plugin.cfg
        `-- bin
```

## Setup

1. Open the project in Godot.
2. Go to `Project > Project Settings > Plugins`.
3. Enable `godot-ohos`.
4. Open `Editor > Editor Settings`.
5. Enable `Advanced Settings`.
6. Set `Export > Harmony > Deveco Home` to your DevEco Studio installation path.

You should be able to find directories such as `sdk` inside it. On macOS this is usually:

```text
/Applications/DevEco-Studio.app/Contents
```

The export template directory is configured by `Export > Harmony > Export Preset`. By default, the plugin points it to your project's plugin template directory:

```text
res://addons/godot-ohos/bin
```

You normally do not need to change it if you installed the release archive as-is.

## Export

1. Open `Project > Export`.
2. Add an `OpenHarmony` preset.
3. Configure `Package > Unique Name`.
4. Choose an OHOS project output directory.
5. Export the project.
6. Open the generated OHOS project in DevEco Studio, then sign, package, and run it there.

The default SDK version is `6.0.2(22)`, which supports more than 98% of HarmonyOS devices. Values below API 22 are normalized back to this default.
