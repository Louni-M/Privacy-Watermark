# Plan: Fix Missing Secure Mode for PDFs

## Phase 1: Fix & Verify

- [x] Task: Fix Secure Mode Visibility Logic b477985
  - [x] Create a failing test case for `PassportFiligraneApp` logic (mocking `on_file_result` behavior) to confirm `secure_mode_switch` visibility is not updated.
  - [x] Modify `main.py` to explicitly set `secure_mode_switch.visible = True` when a PDF is loaded.
  - [x] Verify the test passes.

- [ ] Task: Conductor - User Manual Verification 'Phase 1' (Protocol in workflow.md)
