# Isaac FPS Performance

Rendering optimizations and optional native High FPS for **Isaac FPS Mod 0.5.132**. Controls are maintained separately in [isaac-fps-controls](https://github.com/bishoptype/isaac-fps-controls).

## Changes

- Reuse bounded per-room pit faces, vertices and clipping scratch buffers, invalidating derived geometry/projection caches when needed.
- Cache up to 128 heart-style draw recipes and merge adjacent identical-color rectangles.
- Suppress duplicate native top-down NPC/bomb draws while the existing opaque FPS-view flag is active; entity logic, collision and damage remain. Native rendering returns outside that flag, including transitions/intros.

## Files and validation

`main.lua`, `fps_holes.lua`, `fps_health.lua` are ready-to-test replacements for the exact base. `performance.patch` contains only these performance changes. **No mouse, firing, recoil or gun-aim changes are included.**

240 pit-geometry cases and 300 heart-style raster comparisons passed. Pit allocations fell about 83% in the synthetic check; heart rectangle draws fell about 20%. These are isolated checks, not a guarantee of 144 FPS. See [PERFORMANCE.md](PERFORMANCE.md) for evidence and limitations. Both split patches reproduce the previously tested combined code byte for byte when applied together.

## Optional native High FPS


The Lua changes above work without installing this component. `optional-highfps-repentogon.zip` contains a separately built MIT-licensed proxy DLL, its source/build scripts and a ready configuration.

- Upstream: [hunchcldev/isaac-highfps — repentogon-support](https://github.com/hunchcldev/isaac-highfps/tree/repentogon-support).
- Exact locally tested executable: **REPENTOGON Isaac 1.9.7.12**, PE timestamp **0x68154D8D**, REPENTOGON 1.1.3.
- Do not install it blindly for a different runtime or over another `winmm.dll` proxy.
- Close the game, back up existing `Repentogon/winmm.dll` and `isaac-highfps.ini`, then copy the contents of the archive's `install/Repentogon` into that same executable directory. This is the REPENTOGON runtime directory, not the Lua mod folder.
- Configuration: 144 FPS cap, interpolation enabled, `LuaVanillaCadence=0`, `LuaOverlay=0`, `Profile=0`, `Diag=0`, `Log=0`. Set `VSync=0` in game options for the uncapped rendering path. Back up the previous value if changing it.
- Local native change: `native-pacing.patch` schedules the next deadline from the actual current time, avoiding catch-up bursts after an over-budget frame.
- Physics/gameplay tick rate is unchanged. A stable 144 FPS is not guaranteed; a heavy Lua-rendered room can still fall below the cap.
- Build from `source/build.bat` with Visual Studio C++ x86 Build Tools. Upstream MIT license is included in the archive.
- Rollback: restore backed-up native files and VSync value; if those files were absent before installation, remove only the two installed native files.


The native High FPS source and binary are credited to hunchcldev/isaac-highfps contributors under the MIT license included in the archive.

## Base version and installation

Requires the original **Isaac FPS Mod 0.5.132** and its REPENTOGON runtime/assets. This repository is a patch set, not a standalone mod.

For the exact original base: close the game, back up the matching files, and replace only the `.lua` files from this repository. For a newer or locally modified base, merge the diff instead of overwriting files. Restore your backups to undo the changes. Do not delete saves.

**Using both repositories:** both patches apply independently to the original 0.5.132 code, and both application orders have been checked. Apply `controls.patch` and `performance.patch` with `git apply --check` followed by `git apply` for each patch. Do not copy both replacement `main.lua` files on top of each other: the second would overwrite the first repository's changes.

No automatic room recording, recording archives, new diagnostic callbacks, or experimental GPU triangle merging are included. The original mod's manual diagnostics are not enabled by these patches. No saves, game executables or game assets are shipped.

## Credits and licensing

Original Isaac FPS Mod code belongs to its respective authors. Implementation and regression testing assisted by OpenAI Codex. No blanket license or relicensing of the original Lua mod is granted here. This private author-review package retains original ownership; resolve original licensing before any public redistribution.
