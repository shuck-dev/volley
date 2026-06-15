# Web lag spikes investigation report (2026-06-15)

## Problem

Periodic lag spikes on the web build, visible as clustered 80-150ms frame drops lasting
~0.8-1s, recurring intermittently across a play session. Desktop unaffected.

## Evidence

Four Firefox profiles across three builds:

| build | threads | profiles | key finding |
|---|---|---|---|
| itch `WebNoThreads` | no | 10.45, 11.12, 11.20 | periodic CC pauses (JSStackFrame from audio postMessage) + sync getParameter IPC stalls |
| local `WebNoThreads` | no | -- (console logs) | confirmed same behaviour as itch |
| local `WebThreaded` | yes | 12.00 | CC/getParameter stalls eliminated; Firefox pthread starvation appears instead |

### No-threads root cause (confirmed)

Two families of main-thread stalls, inherent to the no-threads architecture:

1. **Cycle-collector pauses, ~4-6s cadence, up to ~30ms** (12 of 23 stalls in 120s capture).
   Freed objects: `JSStackFrame` / `SavedStacks` from the postMessage-based audio worklet
   path. Without SharedArrayBuffer, Godot's audio worklet communicates via `postMessage`,
   which creates JS allocations each callback. Firefox's CC sweeps them in visible pauses.
   Canonical Godot issue: godotengine/godot#87329.

2. **Synchronous WebGL `getParameter` IPC stalls, up to 30ms** (7 of 23 stalls).
   `glGet*` calls by the GL-compatibility renderer force a sync IPC round-trip on
   no-threads. `gl_compatibility` is the ONLY web renderer in Godot 4.

The itch no-threads build switched from threaded in PR #822 because itch did not
serve COOP/COEP headers. **itch has since added a native SharedArrayBuffer option**
that serves the required headers, making the threaded build viable.

### Threaded build findings

The `WebThreaded` preset (`thread_support=true`) was tested locally with COOP/COEP
headers served. Engine console confirmed "multi-threaded" and `[web] threads=true`.

**Chrome:** smooth, no visible stutter.

**Firefox:** the CC pauses and getParameter stalls are eliminated. However, Firefox
starves the Emscripten pthread worker in intermittent ~0.8-1s clusters, producing
80-150ms frame gaps. Engine logs during these gaps show Godot's `_process()` is not
running (`process=3.54ms` frozen across 4+ consecutive 100ms frames). Saves are fast
(1-2ms) and do not correlate with the gaps. Object counts are stable.

This is Firefox's thread scheduler deprioritising the Emscripten worker thread.
The game loop competes with the main thread for CPU and loses during compositor
cycles or browser housekeeping. The no-threads build masked this: the game loop
shared the main thread so it couldn't be starved (it WAS the main thread, just
paused for CC/getParameter).

## Metrics comparison

**No-threads (120s):** p50=1.42ms, p95=3.55ms, p99=5.75ms, max=30.6ms.
5-10ms: 310 (2.58/s), 10-30ms: 53 (0.44/s), 30ms+: 1.

**Threaded Firefox (74s):** p50=1.45ms, p95=3.01ms, p99=3.87ms, max=94.3ms.
5-10ms: 37 (0.50/s), 10-30ms: 2 (0.03/s), 30ms+: 3.

The threaded build dramatically reduced 5-10ms spikes (5x) and 10-30ms spikes (16x).
The 30ms+ spikes are one-time mmap/memfd_create allocations (WebGL IPC setup).
However, the frame-level logging that captures engine `_process(delta)` reveals the
80-150ms clusters that eventDelay doesn't measure (they happen on the worker thread).

## What was ruled out

- **Autosave / FileSaveStorage:** confirmed fast (1-2ms), no correlation with spike clusters.
- **Game code (JavaScriptBridge, try/catch, console.trace, push_error):** none in hot paths.
- **itch wrapper page:** reproduced identically on a bare local server.
- **Audio mix rate / file logging:** unrelated to the actual mechanism.
- **Object count / memory churn:** stable across spike clusters.

## Options

| option | Firefox | Chrome | desktop | complexity |
|---|---|---|---|---|
| Ship `WebThreaded` | pthread starvation (~80-150ms clusters, intermittent) | smooth | unaffected | CI flip + itch SAB toggle |
| Stay `WebNoThreads` | CC pauses (~22-30ms every ~5s) + getParameter stalls | same as Firefox | unaffected | no change |
| Hybrid: detect Firefox, use no-threads | CC pauses (~22-30ms) | threaded | unaffected | needs two exports + browser-sniff loader |
| Wait for Firefox fix | depends on Mozilla | -- | -- | out of our control |

### Firefox workarounds tested (none effective)

- **`emscripten_pool_size=2, godot_pool_size=2`:** no change. Firefox starves the worker
  thread irrespective of pool size.
- **Jolt Physics removed (`physics/3d/physics_engine=Dummy`):** no change. Eliminating
  Jolt's `JobSystemThreadPool` (~7 idle pthreads) had zero effect on the starvation
  clusters.
- **FPS cap:** irrelevant. The engine is not running during the gaps (`_process` frozen).

## Upstream context

Firefox's Emscripten pthread scheduling is known to produce worker starvation in
threaded Godot web builds. Mozilla is tracking related patterns:

- **[Bug 1939938](https://bugzilla.mozilla.org/show_bug.cgi?id=1939938):** Godot game
  spends ~4s on multiple background threads during WASM compilation (loading-time,
  not runtime). Demonstrates Mozilla awareness of Godot web thread pressure.
- **[Bug 1920115](https://bugzilla.mozilla.org/show_bug.cgi?id=1920115):** March 2025 fix
  (commit `bbc06f4`): TaskController allows high-priority tasks to run before timers.
  Relevant to Worker message scheduling.

These bugs do not track Volley's specific runtime starvation pattern. No Mozilla bug
currently tracks the intermittent worker starvation we observe. Volley is a candidate to
file a targeted report with our profile data.

## Why this is visible to us before others

- Most Godot web games ship single-threaded (default since 4.3). Threaded exports need
  COOP/COEP headers, which itch historically did not serve until its recent
  SharedArrayBuffer support.
- Firefox is a minority of browser share for gaming.

Note: the threaded build requires Firefox to open the game in a popup tab (itch
behaviour when serving COEP `credentialless` which Firefox stable does not ship).
Chrome embeds in-page normally.

## Recommendation

Ship `WebThreaded` with the itch SharedArrayBuffer toggle. Chrome gets the full fix,
Firefox exchanges one stutter family for another (30ms CC pauses replaced by 80-150ms
pthread starvation clusters). Neither is engine-tunable at our level.

A 120s+ Firefox threaded profile is needed to establish the long-run worst-case
frequency before declaring the tradeoff acceptable. The Firefox popup-tab UX cost
(itch's COEP-credentialless fallback) is a further factor.

The PR (#966) implements the publish change. The `3d/physics_engine=Dummy` change is
housekeeping (removes unused Jolt thread pool) and does not affect web lag.
