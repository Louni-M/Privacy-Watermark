# Track Spec: Hybrid PDF Watermarking (Vector vs Secure Raster)

## Problem
The current vector watermarking is high-quality but structurally insecure (easy to remove with PDF editors). Users need a "Secure Mode" that makes the watermark permanent through rasterization, while maintaining professional quality.

## Solution
Introduce a "Mode Sécurisé" (Secure Mode) that converts PDF pages into high-DPI images with the watermark "burnt-in".

## Requirements

### Functional
- **FR-1: Mode Toggle**: Add a Switch to the GUI to choose between "Vector" (Performance/Quality) and "Secure Raster" (Security).
- **FR-2: High-DPI Engine**: Implement a rasterization engine for PDFs supporting 300, 450, and 600 DPI.
- **FR-3: DPI Selection**: Add a `SegmentedButton` to select DPI levels (300, 450, 600) when Secure Mode is active.
- **FR-4: Permanent Watermark**: Ensure the watermark is applied such that it cannot be extracted as a separate object from the output PDF.

### Non-Functional
- **Quality**: Raster output must maintain >95% perceived quality (target 300-600 DPI).
- **UX**: The DPI selection should only be visible when Secure Mode is ON.
- **Performance**: High-DPI rendering should handle multi-page documents without crashing.

## Acceptance Criteria
- [ ] AC-1: UI Switch correctly toggles "Secure Mode".
- [ ] AC-2: SegmentedButton allows switching between 300, 450, and 600 DPI.
- [ ] AC-3: In "Secure Mode", the output PDF contains flat images where the watermark is part of the pixel data.
- [ ] AC-4: Text in "Secure Mode" output is NOT selectable (verification of rasterization).

## Out of Scope
- OCR (Optical Character Recognition) to restore text selectability in secure mode.
- Progressive rendering during rasterization (blocking operation is acceptable for now).
