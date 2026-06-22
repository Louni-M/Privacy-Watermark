# Privacy Watermark

Domain language for the local image/PDF watermarking workflow.

## Language

**Sensitive document**:
A user-selected image or PDF that may contain private identity information and is being prepared for watermarking.
_Avoid_: Upload, asset

**Sensitive document intake**:
The decision that validates a selected **Sensitive document** and either rejects it or accepts it as loaded image bytes or a loaded PDF document with a page count.
_Avoid_: File load, file picker handling

## Relationships

- **Sensitive document intake** accepts exactly one selected **Sensitive document**.
- **Sensitive document intake** produces either loaded image bytes, a loaded PDF document with page count, or an intake rejection.

## Example Dialogue

> **Dev:** "Does **Sensitive document intake** update the preview controls?"
> **Domain expert:** "No. It ends once the selected **Sensitive document** is accepted or rejected; the app translates that result into UI state."

## Flagged Ambiguities

- "load" was used to mean both validating/opening a **Sensitive document** and mutating UI state. Resolved: **Sensitive document intake** owns validation/opening; the app owns UI translation.
