# Device Channels

Concrete, device-specific channel plugins for the **Generic Channel** factory framework (LabVIEW 2021, Actor Framework).

This is the third and most specific layer of the Factory Pattern demo:

| Layer | Folder | Provides |
|---|---|---|
| 1. Framework | `..\Generic Channel` | Abstract `Channel` / `Configuration` classes, the factory API (`Load Class From Config`, plugin discovery), and the `ChannelsManager` / `ChannelManagerUI` actors. Shipped as `Channel.lvlibp`. |
| 2. Channel types | `..\Channels` | Signal-type plugins `AIO-Channel` (analog I/O) and `DIO-Channel` (digital I/O), plus the `Channels Template`. They add the `Get_Input` / `Set_Output` API and the shared settings (`Direction`, `Units`). Shipped as `AIO-Channel.lvlibp` and `DIO-Channel.lvlibp`. |
| **3. Devices** | **this folder** | Implementations of those channel types for specific backends: **DAQmx** (real NI hardware) and the **Simulator** (no hardware, with an on-screen panel). |

The application only knows about `Channel`. At runtime the factory reads a channel's `PluginPath` from the configuration file, loads that class, and calls `Connect`, `Get_Input` and so on through dynamic dispatch. Adding a new device therefore needs no change to layers 1 or 2.

---

## Getting started: install the dependencies

This project builds against packed libraries from the two lower layers, which are not built here. `Install_Dependencies.bat` downloads them from GitHub releases into `Dependencies\`. **Run it once before opening `Devices.lvproj`**, and again whenever a dependency version changes.

### Prerequisites

- **GitHub CLI (`gh`)**, installed and signed in. Run `gh auth login` once, and check with `gh auth status`. Your account needs read access to both repositories below.
- **Windows 10 (1803) or later.** The script unzips with the built-in `tar`.
- **LabVIEW closed** (or at least this project). Packed libraries are locked while loaded and can't be overwritten.

### Run

Double-click `Install_Dependencies.bat`, or run it from a terminal:

```bat
cd "<path>\Factory Pattern\Device Channels"
Install_Dependencies.bat
```

It ends with `All dependencies downloaded successfully!`, or with `ERROR: Dependency installation failed!` and a non-zero exit code.

### What it downloads

| Dependency | GitHub repository | Release | Asset | Result in `Dependencies\` |
|---|---|---|---|---|
| Generic Channel (layer 1) | `Andergongar/Generic-Channel` | `v1.0.0` | `LV2021x64.zip` | `Channel.lvlibp` |
| Abstraction Channels (layer 2, the `..\Channels` project) | `Andergongar/Abstraction-Channels` | `v1.0.0` | `LV2021x64.zip` | `AIO-Channel.lvlibp`, `DIO-Channel.lvlibp`, `ExcludeLoad.Plugin` |

For each dependency, in that order, the script:
1. Creates `Dependencies\` (and an empty `Release\`) if missing.
2. Downloads the release assets into `Dependencies\` with `gh release download`.
3. Extracts every `.zip` there, overwriting existing files, then deletes the zip.

`ExcludeLoad.Plugin` comes with the layer-2 release. Leave it in `Dependencies\`.

### Changing versions

Edit the configuration block at the top of the script:

```bat
set "GENERIC_CH_VERSION=v1.0.0"
set "GENERIC_CH_REPO=Andergongar/Generic-Channel"

set "ABSTRACTION_CH_VERSION=v1.0.0"
set "ABSTRACTION_CH_REPO=Andergongar/Abstraction-Channels"
```

> **Keep the two versions compatible.** The Abstraction-Channels release must have been built against the same Generic-Channel version you install here. Otherwise `AIO_Channel` and `DIO_Channel` point to a different `Channel` class, and the parent links break.

After changing a version, re-run the script and rebuild this project (see [Building](#building)).

### Troubleshooting

| Symptom | Fix |
|---|---|
| `'gh' is not recognized…` | Install the GitHub CLI and open a new terminal |
| `release not found` / `HTTP 404` | Wrong tag, or no access to the repository: check `gh auth status` |
| `ERROR: Failed to extract …` | A file in `Dependencies\` is locked. Close LabVIEW and run the script again. |
| Classes show broken parents in LabVIEW | A `.lvlibp` is missing or the versions don't match. Fix the versions and re-run the script. |

---

## Folder layout

```
Device Channels\
├── Devices.lvproj              LabVIEW project for this layer
├── Install_Dependencies.bat    downloads Dependencies\ from GitHub releases
├── Dependencies\               Packed libraries from the lower layers (installed by the script)
│   ├── Channel.lvlibp          from Generic Channel
│   ├── AIO-Channel.lvlibp      from Channels
│   └── DIO-Channel.lvlibp      from Channels
├── DAQmx\                      DAQmx.lvlib - real hardware
│   ├── AIO_Channel_class\      + AIO-Configuration_class\
│   ├── DIO_Channel_class\      + DIO-Configuration_class\
│   ├── Support\                Get_AIO_Devices.vi, Get_DIO_Devices.vi
│   └── DAQmx_AIO_Specificer.vi, DAQmx_DIO_Specificer.vi
├── Simulator\
│   ├── Channels\DIO-Channel\   Simulator-Channel.lvlib - simulated AIO + DIO channels
│   └── Panel\                  DIO_Panel.lvlib (actor), Create AIO/DIO Panel.vi
├── AIO_Panel\                  AIO_Panel.lvlib (actor) - simulator panel for analog channels
└── Builds\                     Output packed libraries
    ├── DAQ_mx.lvlibp
    └── Simulated_CHs.lvlibp
```

---

## Class hierarchy

```
Channel.lvlibp:Channel
├── AIO-Channel.lvlibp:AIO_Channel
│   ├── DAQmx.lvlib:AIO_Channel              (real analog I/O)
│   └── Simulator-Channel.lvlib:AIO_Channel  (simulated analog I/O)
└── DIO-Channel.lvlibp:DIO_Channel
    ├── DAQmx.lvlib:DIO_Channel              (real digital I/O)
    └── Simulator-Channel.lvlib:DIO_Channel  (simulated digital I/O)

Channel.lvlibp:Configuration
├── AIO-Channel.lvlibp:AIO-Configuration
│   └── DAQmx.lvlib:AIO-Configuration
└── DIO-Channel.lvlibp:DIO-Configuration
    └── DAQmx.lvlib:DIO-Configuration
```

The classes have the same file names in both backends (`AIO_Channel.lvclass` and so on). There is no conflict because LabVIEW qualifies each class by its owning library (`DAQmx.lvlib:AIO_Channel` vs `Simulator-Channel.lvlib:AIO_Channel`).

---

## DAQmx plugins (`DAQmx.lvlib` → `DAQ_mx.lvlibp`)

These drive real NI-DAQmx hardware.

**Channel classes** (`AIO_Channel`, `DIO_Channel`) override:

| Method | Role |
|---|---|
| `Connect` / `Disconnect` | Create/clear the DAQmx task for the configured physical channel |
| `GetConnectionStatus` | Report whether the task is valid/running |
| `Get_Input` / `Set_Output` | Read or write the channel value |
| `GetConfigurationType` | Return the DAQmx configuration class, so the factory pairs the channel with the right settings |
| `Get-AIO-DAQmx-Cfg` / `Get-DIO-DAQmx-Cfg` | Typed access to the DAQmx configuration |

**Configuration classes** (`AIO-Configuration`, `DIO-Configuration`) extend the layer-2 settings with DAQmx data (for example the physical channel, `DAQ_Line = "Dev2/port0/line0"`):

| Method | Role |
|---|---|
| `LoadCFG` / `SaveCFG` | Read/write the DAQmx keys in the channel's INI section |
| `AIO-DAQ-Panel` / `DIO-DAQ-Panel` + `GetPanelUI` | Settings panel shown inside the Channel Manager UI |
| `CreateAIO_DAQ_CFG` / `CreateDIO_DAQ_CFG` | Build a configuration object |
| `Read…/Write…DAQ_Data` | Accessors for the DAQmx `Data.ctl` typedef |

**Support VIs.** `Get_AIO_Devices.vi` and `Get_DIO_Devices.vi` list the physical channels available on the installed DAQ devices, for use in the settings panels.

**Requirements:** the NI-DAQmx driver, and a real or NI MAX-simulated DAQ device.

---

## Simulator plugins (`Simulator-Channel.lvlib` → `Simulated_CHs.lvlibp`)

These behave like real channels but need no hardware. Each simulated channel appears on a **simulator panel** where you can watch outputs and set inputs by hand.

**Channel classes** (`AIO_Channel`, `DIO_Channel`) override `Connect`, `Disconnect`, `GetConnectionStatus`, `Get_Input` and `Set_Output`, and add `CreateSimulated.vi`.
- The simulated `AIO_Channel` does **not** override `GetConfigurationType`, so it uses the layer-2 `AIO-Configuration` unchanged.
- The simulated `DIO_Channel` does override it.

**Simulator panels** are Actor Framework actors:

| Library | Actor | Messages |
|---|---|---|
| `Simulator\Panel\DIO_Panel.lvlib` | `DIO_Panel` | `Create Channel`, `Remove Channel`, `Set Output`, `Get Input`, `Update Inputs` |
| `AIO_Panel\AIO_Panel.lvlib` | `AIO_Panel` | same set |

`Create AIO Panel.vi` and `Create DIO Panel.vi` launch the panels. `G_Variables.vi` is a global that holds shared state, most likely the panel's enqueuer.

Expected flow (based on the method and message names):

```
Connect     → Send Create Channel  → the channel appears on the panel
Set_Output  → Send Set Output      → the panel shows the value
Get_Input   → Send Get Input       → returns the value set on the panel
Disconnect  → Send Remove Channel  → the channel is removed from the panel
```

---

## Configuration file

Each channel is one INI section. `PluginPath` tells the factory which class to load, and the other keys are written by that plugin's `SaveCFG`. Example (from `..\Channels\Files\Test.ini`):

```ini
[DIO_1]
Direction = "Input"
DAQ_Line = "Dev2/port0/line0"
PluginPath = "Device Channels\\DAQmx\\DIO_Channel_class\\DIO_Channel.lvclass"

[DIO_2]
Direction = "Input"
PluginPath = "Device Channels\\Simulator\\Channels\\DIO-Channel\\DIO_Channel_class\\DIO_Channel.lvclass"
```

`PluginPath` is relative to the **plugins folder** set with `Set Plugins Folder.vi`. In this example that is the `Factory Pattern` folder.

---

## Building

All builds are in `Devices.lvproj` → **Build Specifications** and output to `Builds\`:

| Build spec | Source | Output |
|---|---|---|
| `DAQ_mx` | `DAQmx.lvlib` | `Builds\DAQ_mx.lvlibp` |
| `Simulated_CHs` | `Simulator-Channel.lvlib` (includes both panel libraries) | `Builds\Simulated_CHs.lvlibp` |

Build order across the demo:

1. `Generic Channel` → `Channel.lvlibp`, published as a release of `Andergongar/Generic-Channel`
2. `Channels` → `AIO-Channel.lvlibp`, `DIO-Channel.lvlibp`, published as a release of `Andergongar/Abstraction-Channels`
3. `Install_Dependencies.bat` here installs both into `Dependencies\`. For unreleased local builds, copy the three `.lvlibp` files by hand instead.
4. `Device Channels` → `DAQ_mx.lvlibp`, `Simulated_CHs.lvlibp`

> **Important:** when a lower layer gets a new release, update its version in `Install_Dependencies.bat`, re-run the script, and rebuild this layer. The classes inherit from the classes *inside* those packed libraries, so a stale or duplicated copy breaks inheritance and the factory fails to load the plugin.

---

## Adding a new device backend

For example a VISA or Modbus backend:

1. Create a library such as `MyDevice.lvlib` in a new folder, and add it to `Devices.lvproj`.
2. For each signal type you support, create:
   - a channel class inheriting from `AIO-Channel.lvlibp:AIO_Channel` or `DIO-Channel.lvlibp:DIO_Channel`
   - optionally, a configuration class inheriting from the matching `…-Configuration`, if the device needs extra settings
3. Override `Connect`, `Disconnect`, `GetConnectionStatus`, `Get_Input` and `Set_Output`.
4. If you added a configuration class, override `GetConfigurationType`, plus `LoadCFG`, `SaveCFG`, `GetPanelUI` and a panel VI on that class.
5. Add a Packed Library build spec (copy `DAQ_mx`), output to `Builds\`, with *Exclude dependent packed libraries* enabled.
6. Build, and place the result under the plugins folder. **Load Plugins** in the Channel Manager UI will list it.

---

## Housekeeping notes

Found while documenting the folder. None of these stops the build.

- `Simulator\Channels\DIO-Channel\DIO-Configuration_class\` is not part of any library. Its parent points to the **source** `..\Channels\DIO-Channel\DIO-Configuration.lvclass` instead of `DIO-Channel.lvlibp`. It looks like a leftover. Check what the simulated `DIO_Channel.GetConfigurationType` returns before deleting it.
- `G_Variables.vi` (used by `Simulator-Channel.lvlib`) lives outside this folder, in `..\Channels\DIO-Channel\Private\`. Consider moving it into `Simulator\`.
- `Simulator-Channel.lvlib` holds both AIO and DIO channels but sits in a folder named `DIO-Channel`.
- The AIO panel's messages folder is named `AIO_Panel\DIO_Panel Messages\`, probably a copy-paste leftover.
- Leftover items: an empty `DIO_Panel\tdef\` folder at the root, and `Simulator\Device Channels\DAQmx\DIO-Configuration_class\tdef\Direction.ctl`.
- The `Simulated_CHs` build spec also lists `DAQmx.lvlib` as a (non top-level) source. Check that this is intended.
