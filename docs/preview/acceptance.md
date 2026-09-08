# Preview and relative watermark acceptance

Recorded 2026-09-08 on Apple Silicon, macOS 26.6.2 (25G83).
Implementation and acceptance are complete. The user confirmed that the app works and requested finalization, spec synchronization and archival on 2026-09-08 (tasks 6.3 and 6.5).

## Intentional behavior change

The entire watermark pattern now scales by the displayed shorter side divided by
`210 / 25.4 * 72`. A4 retains its previous numerical size and spacing. Images and
non-A4 PDFs intentionally have different proportions from older exports. Source
files, output dimensions, raster DPI, metadata removal, and opacity semantics are
unchanged. Standard PDFs retain selectable source/watermark text; flattened PDFs
retain raster text. Standard PDF opacity remains stronger than raster opacity at
the same setting; geometry is standardized, not compositing.

## Fixtures and reproducible commands

All documents are synthetic. `RelativeWatermarkTests` generates equivalent blank
A4 PDFs and JPG/PNG images at 1× and 3× resolution, tests the complete pattern at
0.5×/1×/2×/8×, and checks both directions, boundary size/spacing, invisible text,
and region/export parity. The existing `document.pdf` includes mixed displayed
geometry, crop/rotation and PDF content/annotation semantics.

The optional native acceptance mode generates a 4200×5940 photo with a long
Latin/non-Latin filename and a 50-page PDF containing A4, smaller, rotated and
cropped pages. Generated documents and exports stay in `.build/preview-acceptance`;
only screenshots and reports are retained here.

```sh
scripts/test.sh
scripts/build-app.sh
PASSPORT_SMOKE_OUTPUT=.build/preview-smoke scripts/smoke-test.sh
PASSPORT_PREVIEW_ACCEPTANCE=1 PASSPORT_SMOKE_OUTPUT=.build/preview-acceptance scripts/smoke-test.sh
openspec validate improve-preview-and-watermark-scaling --strict
```

The native acceptance window must be freely resizable. AeroSpace initially tiled
it back to 854 points tall, causing the minimum-size assertion to fail. For the
passing run, only the window titled `Passport Filigrane — Native smoke test` was
switched to floating with `aerospace layout --window-id <test-window-id> floating`.
No user window or global window-manager setting was changed. The final photo-fit
capture is 1720×1200 pixels at 2× backing scale: 860×600 points.

## Observed results

- [47 tests in 13 suites passed](tests.txt). Coverage includes output conversions,
  source identity/replacement, validation, metadata removal, local-only processing,
  source preservation, cancellation, export snapshots, and PDF semantics.
- [Universal arm64/x86_64 build, ad-hoc signing and verification passed](build.txt).
  Both architectures compiled; this session's runtime checks used arm64.
- The ordinary native smoke run passed panel cancellation, mixed-file import,
  selection/removal, zoom/navigation, export/reopen and failure/cancellation checks.
- [Native acceptance passed](native-acceptance.json): fitted photo below 25%,
  intermediate animated zoom scales, a continuous 1.2 zoom step, return to Fit,
  50-page navigation/settings stress, rapid high-resolution photo/PDF replacements,
  injected preview failure and recovery, and successful independent exports/reopen.
- [Measurements](measurement.json): sampled retained preview peak 14,486,110 bytes
  (13.8 MiB) against 100,663,296 bytes (96 MiB); largest synchronous navigation
  acknowledgement 0.010164 seconds. This measures navigation plus synchronous
  layout, not end-to-end detailed render latency. Cache cost and displayed image
  cost each have a 48 MiB allowance. Source snapshots and transient rendering
  scratch are outside the retained-preview measurement; this is not process RSS.
- Individual core preview renders retain the 16-million-pixel ceiling; the session
  requests at most 8 million pixels divided among visible pages. Tests cover
  eviction, superseded requests and recovery. Full-document strip rasters are not
  allocated. Immediate neighbors receive bounded overviews only.
- Screenshot review found consistent relative text size, spacing and phase between
  the synthetic photo and A4 page, and matching geometry in reopened exports.
  Standard PDF exports visibly retain the intentional stronger vector opacity.
  A fractional tile clipping seam found during review was fixed, with a uniform
  synthetic-image regression test. Final fitted captures have no white tile seams.
- The filename wraps to two lines and truncates without covering controls at
  860×600. Full-name hover and accessibility text are bound to the complete selected
  filename. Selection/removal state updates are covered by session tests.

## Captures

- [Photo fit and minimum-size filename](photo-fit.png)
- [Photo after animated zoom](photo-zoom.png)
- [Continuous PDF fit](pdf-fit.png)
- [PDF after stress settles](pdf-stress-settled.png)
- [Reopened photo export](photo-reopened.png)
- [Reopened standard PDF export](pdf-reopened.png)

## User acceptance and final sign-off

On 2026-09-08, after the implementation and remaining physical checks were
reported, the user confirmed: “it all works amazing. please finalize this,
archive and sync specs”. This is the user acceptance for the remaining interaction
checks and final sign-off, closing tasks 6.3 and 6.5.

Hardware model, individual gesture observations, and a new screen recording were
not supplied. The agent did not perform physical input checks. The original
measurement JSON preserves the pending-at-capture hardware status; the user's
subsequent acceptance is recorded here rather than rewriting that historical
measurement or claiming additional automated coverage.
