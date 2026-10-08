# Protected copy icon

`master.png` is the production 1024 × 1024 RGBA master. It retains the jade
rounded square, ivory folded document, and protective offset corner of concept C.

## Provenance

Selected reference: `assets/icon-prototype/concepts.png` on local prototype
branch `codex/minimal-icon-prototype`, commit `3e4516b`. The reference is a
comparison board, not a production asset. On 2026-09-15, OpenAI image generation
rendered concept C as standalone artwork, removing captions, other concepts,
the Dock mockup, and the external presentation background. The generated
1254-pixel RGBA image was resized to 1024 pixels with macOS `sips`.

After two image-generation cleanup attempts retained edge artifacts, a user-approved
alpha-only cleanup preserved every RGB pixel of the selected master. A Pillow
8× mask used a rounded rectangle `(80, 102, 942, 935)` with radius `195`,
resized to 1024 × 1024 with Lanczos filtering; the final alpha is the per-pixel
minimum of the original alpha and mask. This removes isolated exterior specks
and the contaminated perimeter without changing the document artwork.
This was a one-time master cleanup; Pillow is not required to regenerate ICNS.

The master is retained so builds do not require image generation or the prototype
branch. Regeneration from this master uses only macOS tools:

```sh
bash assets/icon/generate.sh
```

The script creates 16, 32, 128, 256, and 512 point representations at both 1× and
2×, then writes `assets/app_icon.icns` using `iconutil`. Temporary iconset files
are removed on exit. Existing app and DMG packaging consume that stable path.
