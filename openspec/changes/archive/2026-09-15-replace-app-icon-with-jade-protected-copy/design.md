## Context

See [proposal.md](proposal.md) for motivation and the approved concept reference. The repository currently retains only `assets/app_icon.icns`. The app build copies that resource, the bundle metadata names it, and the DMG settings reuse it. A short design is useful because the generated comparison board must become a clean, repeatable production asset.

## Goals / Non-Goals

**Goals:** preserve the selected design while producing a clean master, complete macOS representations, and consistent packaging through the existing resource path.

**Non-Goals:** redesigning the concept, introducing theme variants, changing Swift views, renaming the product or bundle, bumping the version, or publishing another release. Existing release videos remain historical evidence.

## Decisions

1. **Create a standalone 1024 × 1024 RGBA master in `assets/icon/`.** Use concept C as the visual reference, retaining jade, ivory, the folded document corner, and the offset protective corner. Remove board captions, surrounding mockup, and external background; leave transparent pixels outside the rounded square. Refine small details only for legibility. A whole-board crop alone is unsuitable as production artwork because it may retain presentation elements or insufficient source resolution. Review the standalone result beside concept C before conversion.
2. **Keep the stable `assets/app_icon.icns` integration.** Derive standard iconset entries for 16, 32, 128, 256, and 512 points at 1× and 2×, up to 1024 pixels, using macOS image tools and `iconutil`. Retain concise, executable generation instructions beside the master. Do not add a new asset-catalog/build system when the existing path already serves the app and disk image.
3. **Verify the actual packaged resource and presentation.** Inspect ICNS representations and alpha edges, confirm that the app resource matches the source ICNS, and use the existing universal app and local DMG build/verification scripts. Open the built app and mounted local DMG in Finder, then inspect its running Dock entry at small and large sizes. Record which OS/architecture was actually exercised; a universal binary is not evidence of runtime testing on both processors.

## Risks / Trade-offs

- [Fine strokes disappear when reduced] → Review 16- and 32-point sizes on light and dark surroundings and simplify fine details without changing the chosen silhouette.
- [Generated artwork drifts from concept C] → Compare the standalone master directly with the selected reference and retain the master and provenance in the repository.
- [Finder or Dock caches the old icon] → Relaunch the built copy from a fresh local output path and verify the embedded resource before treating a cached display as an asset failure; preserve unrelated running sessions.
- [Reference exists only on a local prototype branch] → Keep that branch until the implementation retains the standalone master and its provenance; the implementation does not depend on the preview HTTP server.

## Migration Plan

After an explicit apply request, create and review the master, generate the ICNS, build locally, and record package and visual verification in this change's acceptance record. The existing published release remains unchanged. Rollback restores the previous ICNS and removes newly introduced source assets; no user data or settings migration is needed.
