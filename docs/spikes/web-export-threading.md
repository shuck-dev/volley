# Threaded Web Export

## Problem

Volley's web build stalls the main thread inside the graphics commit path. Gabbro's Firefox profile for SH-188 caught an 87ms block on `MessageChannel::WaitForSyncNotify` inside `PWebGLChild::SendGetNumber`, called from `_emscripten_webgl_do_commit_frame`. That is the single-threaded Emscripten WebGL backend doing a synchronous IPC round trip to the compositor on every frame commit, with the engine's simulation running on the same thread that has to wait for the reply. The local SH-188 work (PR #299) trimmed the simulation cost that sits in front of that wait, but the wait itself is structural: as long as simulation and the GL commit share a thread, long frames will keep showing up when the compositor is busy.

## Decision

Ship the web build with Godot 4.6.2's threaded export variant. Target Chrome first, hosted on itch.io. Keep a non-threaded preset alongside it as a secondary target for environments that cannot serve the cross-origin isolation headers SharedArrayBuffer requires.

## Why this fixes it

The threaded Emscripten runtime runs the engine main loop on a pthread worker. GL calls from the worker go through the `OFFSCREEN_FRAMEBUFFER=1` proxy, which marshals them to the page main thread for submission. Simulation no longer sits on the same thread as the sync IPC, so the 87ms stall stops gating the next frame's update. The page main thread still pays the compositor round trip, but that happens off the simulation's critical path. This is the sanctioned path: the Emscripten docs describe `OFFSCREEN_FRAMEBUFFER` as the mechanism for proxying GL from workers ([emscripten OffscreenCanvas docs](https://emscripten.org/docs/porting/multimedia_and_graphics/OpenGL-support.html#offscreen-framebuffer)), and Godot 4.6 formalised threaded web as a first-class option ([Godot 4.6 release notes](https://godotengine.org/article/godot-4-6-is-released/)).

## Hosting requirements

Threaded builds need `SharedArrayBuffer`, which browsers only expose under cross-origin isolation. The host must serve:

- `Cross-Origin-Opener-Policy: same-origin`
- `Cross-Origin-Embedder-Policy: credentialless` (or `require-corp` with correctly tagged subresources)

On itch.io this is the "SharedArrayBuffer support" toggle on the HTML5 upload, which has to be enabled per build ([itch community thread on SAB support](https://itch.io/t/2025976/sharedarraybuffer-support-for-html5-games)). Third-party embeds of the itch page break under these headers, which is fine for Volley since the primary surface is the itch page itself.

## Browser support matrix

| Browser | Behaviour |
|---|---|
| Chrome desktop | Runs directly in the itch page |
| Firefox desktop | Plays in-page while the itch Origin Trial for credentialless COEP is active; falls back to the itch popup player otherwise |
| Safari desktop | Popup player only (Safari requires `require-corp`, which itch's embed page does not currently satisfy) |
| Mobile Firefox | Unsupported; threaded web export does not run |
| Mobile Chrome / Safari | Popup player, same as desktop Safari |

## Operational changes

One thing has to move with this decision:

1. **Itch upload toggle.** Each new HTML5 upload to itch needs "SharedArrayBuffer support" re-enabled; the toggle does not persist across uploads. Add this to the release checklist.

CI template install is a non-issue: the threaded and non-threaded web templates ship together inside the standard `Godot_v${VERSION}-stable_export_templates.tpz` bundle, and both `release.yml` and `publish.yml` already download the full bundle. No separate install step is required.

Save paths are unaffected: threaded builds use the same `user://` IDBFS store as the single-threaded build, so existing player saves carry forward.

## Fallback

The export config keeps a second preset, `WebNoThreads`, as a fallback target for hosts that cannot serve the COOP/COEP pair. This is not shipped as the primary build; it exists so that if itch's SAB toggle regresses, or we stand up a mirror on a host without header control, we can produce a compatible bundle without reconfiguring the main preset.

## Follow-ups

- Flip the "SharedArrayBuffer support" toggle on the next itch upload that uses this preset.
- Playwright verification of the frame-time improvement lands under SH-189 once that ticket is scheduled.
