# Jade Protected copy — acceptance record

Date: 2026-09-15. **5/5 tasks complete; ready to archive and sync.**

## Asset and size review

- Retained the concept-C jade tile, ivory folded document, and protective offset
  corner. Two image-generation edge-cleanup candidates retained visible fringe
  and were rejected. Following explicit user approval, an alpha-only inset mask
  removed the contaminated perimeter and isolated specks. Every RGB pixel is
  unchanged; the mask procedure is documented in `assets/icon/README.md`.
- Reviewed correctly composited [light](evidence/master-light.png) and
  [dark](evidence/master-dark.png) masters. Visible edges are smooth and free of
  green/cyan specks. Hidden RGB beneath zero alpha is deliberately preserved;
  an image viewer that ignores alpha can still display those hidden pixels.
- Regenerating the final ICNS from a temporary copy of the master and script
  produces byte-identical output.
- Extracted all ten ICNS representations: correct 16, 32, 128, 256, and 512 point
  1×/2× dimensions and zero alpha at every corner. Reviewed actual-pixel
  [16-/32-point samples on light/dark](evidence/small-sizes.png): document
  silhouette remains recognizable at 16; fold and offset corner are clear at 32.
  This was direct image analysis, not browser HTML rendering.

## Final package

- Built with `OUTPUT_DIR=dist/jade-icon-clean-verification scripts/build-app.sh`
  and `scripts/build-dmg.sh`. Universal arm64/x86_64 slices, strict ad-hoc
  signature, source/embedded ICNS equality, package checksum/UDZO format,
  Applications shortcut, installation resources, and saved Finder layout and
  background alias checks pass.
- Name: Privacy Watermark. Bundle ID: `com.lounim.privacywatermark`.
  Version 2.1.2 (build 1), minimum macOS 14.0, all unchanged.
- Final DMG: `dist/jade-icon-clean-verification/Privacy-Watermark.dmg`.
  SHA-256: `ce4d4c1f7d535a2406068cb3ec4a0458116d578cec6bd80771d51009c49c7533`.
- Mounted final DMG read-only. [Finder installer inspection](evidence/installer-final.png)
  shows jade icon, app/Applications arrow layout, and the complete Install.txt
  icon and label after enlarging the Finder window. The first capture clipped
  Install.txt at the bottom; this final capture replaces it. Finder presents the
  jade artwork on a dark rounded backing, distinct from the transparent source
  asset verified by the light/dark composites.
- Copied the mounted app into the isolated user Applications folder
  `~/Applications/Jade Icon Verification/Privacy Watermark.app`, verified its
  resource and signature, ejected the DMG, then launched the installed copy.
  [Installed app after eject](evidence/installed-final.png) shows the working
  sample-watermark preview. The existing `/Applications` installation was untouched.

## Synthetic workflow

- Resolved the earlier export blocker using the native chooser's **New Folder**
  action, then **Export here**. App reported **1 saved · 0 failed**.
  [Successful export UI](evidence/export.png) and the actual
  [watermarked JPG](evidence/photo_watermarked.jpg) are retained.
- Source was `tests/WatermarkCoreTests/Fixtures/photo.jpg`, a synthetic ID.
  Output is 1000 × 640 with the COPY watermark visually confirmed.
  SHA-256: `bcc7be9f81155af18f8f0040a6c65c32d748fe8e477699a50d2dd60bf9541b11`.
- The final installed build subsequently completed the same open-preview-export
  flow successfully: **1 saved, 0 failed**. See [final export UI](evidence/export-final.png)
  and [final output](evidence/photo-watermarked-final.jpg). Its output has the
  same SHA-256 above. The running executable was confirmed at
  `~/Applications/Jade Icon Verification/Privacy Watermark.app/Contents/MacOS/PrivacyWatermark`;
  installed ICNS matches the source and strict signature verification passes.

## Dock confirmation and coverage limits

- The user explicitly confirmed the running Dock icon looks correct at normal
  and enlarged sizes: jade tile, ivory folded document and protective offset
  corner, without stray colored specks or clipping. This closes task 2.2.
  Evidence source is the user's direct visual confirmation in this conversation,
  not an automated screenshot. The computer-use API could not select the
  windowless Dock; user-approved native capture was denied by macOS Screen
  Recording permissions. No system permission was changed.
- Earlier Finder [list](evidence/finder-list.png) and
  [icon](evidence/finder-icons.png) screenshots, and [installer](evidence/installer.png)
  screenshot, show the pre-cleanup jade resource; `installer-final.png` is the
  final resource. They are supporting history, not final-alpha evidence.
- The earlier browser file-URL denial was not bypassed. The blocked HTML review
  was not opened through another surface.
- Runtime exercised: Apple Silicon arm64, macOS 26.6.2 (25G83). Intel and macOS 14
  runtime checks were not performed; both executable slices were validated.
- No Swift runtime edits, version bump, publication, or historical demo changes.
  Unrelated pre-existing archival/spec/release-evidence changes remain untouched.
  Strict OpenSpec validation passes. No new runtime tests were needed for an
  alpha/resource-only change.
