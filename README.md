# Isaac FPS controls & performance patch

Private review package for the author of Isaac FPS Mod, based on **0.5.132**.
This is a patch to an existing mod, not a standalone replacement mod.

## Quick test (English)

1. Close Isaac and back up the six matching Lua files in your mod directory.
2. For the original **0.5.132** base only, copy the six `.lua` files from this repository into that directory.
3. Launch through REPENTOGON and continue normally. Do not delete your saves.
4. For a newer or locally modified version, review and merge `controls-performance.patch` instead of overwriting complete files. With Git, first run `git apply --check controls-performance.patch`, then `git apply controls-performance.patch`.
5. Restore your backed-up six files to undo the Lua changes.

All other original mod files and assets are still required. The existing sensitivity in a save is preserved; set it to **0.40 degrees per render pixel** if you want the same setting used in the local comparison.

## Included controls

- Mouse-look uses window cursor coordinates, projects cursor and origin in the same camera snapshot, then subtracts the origin and render midpoint.
- Centered tolerance reduced from 1 to 0.15 render pixels; one discarded centered sample replaces the 150ms + 3-sample startup wait.
- Default sensitivity 0.40 degrees/pixel; ADS sensitivity and pitch limits remain.
- F6 and the upper/forward thumb mouse button (Mouse5) toggle FPS mode, once per press.
- Hold LMB to repeat at the existing weapon cooldown; reload, ammo and charge/release behavior remain.
- Shooting/explosion camera shake and gun camera recoil removed; gun model animation remains.
- Gun rounds follow the aim pitch without the extra native falling-speed offset; native lobbed tears retain their fall behavior.

## Included rendering optimizations

- Pit geometry reuses bounded per-room faces, vertices and clipping scratch buffers, invalidating projection/shader caches when needed.
- Heart rendering caches up to 128 style recipes and merges adjacent identical-color rectangles.
- Duplicate native top-down NPC/bomb draws are suppressed under the existing opaque FPS-view flag; entity physics and damage are unchanged. Native rendering returns when that flag is off, including transitions/intros.

**No automatic room recording, archive writes, new diagnostic callbacks or experimental GPU triangle merging are included.** The mod's original manual F8 diagnostics remain as in the original base; this package does not turn them on. No saves, game executables, game assets, credentials or user profiles are shipped.

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

## Evidence and limits

See [PERFORMANCE.md](PERFORMANCE.md). Offline geometry/pixel/input regression checks passed against the packaged files. The individual changes were used in the local installed game; this freshly assembled distribution package still needs the author's own in-game compatibility/visual review. No claim of stable 144 FPS or a controlled combat benchmark is made.

## Credits and licensing

Original Isaac FPS Mod code and assets belong to their respective authors. Mouse method adapted from the user's local First Person v2.3 controls. Implementation and regression testing assisted by OpenAI Codex. Native High FPS belongs to hunchcldev/isaac-highfps contributors and is MIT-licensed.

No blanket license or relicensing of the original Lua mod is granted here. This private repository is for author review and testing; retain original credits and resolve original licensing before any public redistribution.

## По-русски

Это общий пакет улучшений управления и отрисовки для **Isaac FPS Mod 0.5.132**. Закройте игру, сохраните шесть исходных Lua-файлов и замените их файлами из репозитория. Для другой версии переносите изменения из патча, не заменяйте файлы целиком. Сохранения удалять не нужно. Чувствительность из существующего сохранения сохраняется.

Записи комнат здесь нет. Необязательный High FPS находится в отдельном архиве и подходит только указанной сборке REPENTOGON. Для возврата восстановите резервные копии файлов. Для скачивания всего пакета используйте **Code → Download ZIP**.
