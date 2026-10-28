# Validation and performance notes

## Offline checks against the packaged Lua code

- 240 pit-geometry comparisons: identical vertices/attributes across layouts, eye positions, clipping and map revisions.
- Synthetic pit calculation: allocations **1532.1 -> 255.8 KiB/call**, about **83% lower**. One packaging-run timing was **4.20 -> 2.68 ms/call**; synthetic timings vary and are not game FPS.
- 300 heart-style raster comparisons: identical pixels, including half/ghost/broken/gold/eternal styles and blink colors. **9157 -> 7303 rectangle draws**, about **20% fewer**.
- 84 mouse comparisons over four window scales and three camera offsets.
- Held-fire checks: cooldown, magazine reload/resume, release/pause clearing and charged shot behavior.
- 48 gun/native-tear pitch/falling cases.
- F6/Mouse5 press edges, held buttons and simultaneous presses.
- Lua 5.4 syntax checks.

## Earlier local gameplay samples

In a large, almost empty 102-pit-cell room, before/after window averages were approximately: scene/frame 13.97 -> 12.88ms, pit work 1.76 -> 1.31ms, GC-tail work 1.14 -> 0.66ms. These were not matched camera paths and NPC/effect counts differed; treat them as indicative, not a controlled benchmark or combat guarantee.

A later run after removing the profiling archive contained 19 normal room transitions and 389 native moving-world stat windows: median render-loop rate 126/s, range of window rates 69-144/s. Those window rates are not instantaneous minimum FPS. Short stalls remained. The first bounded ordinary transition traces were 66-157ms. A 3.2s trace belonged to a floor/stage transition. No Lua errors were found in that run.

## Recording-related regression excluded from this package

An experimental room recorder had stored a ~223KB archive in the same JSON document that gun autosave reads every room. The game's bundled JSON decoder took 7.31s to decode it in reproduction, versus less than 0.1ms for the document without the archive. Removing the archive fixed the repeated 7-8s door stalls in the subsequent local run.

That recorder and its archive handling are NOT shipped. Existing installations that previously used the experimental recorder may still require one-time archive cleanup: back up the save, remove only the `IsaacFPSRoomProfiles` JSON key using a proper JSON editor, preserve every other key/value. This is unnecessary for an untouched original mod. This package does not automatically modify saves.

## Remaining limits

The heart cache and native duplicate-draw suppression have output/logic checks and local use, but no isolated combat FPS improvement measurement. Native rendering residual timings include waits/pacing and cannot be interpreted as GPU-only time. The optional native DLL targets a specific executable. Review visual compatibility with other mods, especially hooks into native NPC/bomb rendering.
