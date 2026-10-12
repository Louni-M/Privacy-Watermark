# Spec Delta

## Purpose

Let users watermark one or more selected images and PDFs directly from the Finder context menu in a few seconds, with copies saved beside the originals and without opening the app window.

## ADDED Requirements

### Requirement: Finder Quick Action availability
Once installed, a Quick Action named **Watermark** SHALL appear under Quick Actions in the Finder context menu and in the Finder Preview pane when every selected item is a JPG/JPEG, PNG or PDF file. It SHALL accept one or several selected files. Finder SHALL NOT offer it for a selection that includes another file type or a folder, so unsupported files are never passed to it; inputs that `pwm` still rejects, such as a password-protected PDF, SHALL be reported as excluded without blocking the others. Folders SHALL NOT be traversed. The Quick Action SHALL run without opening the Privacy Watermark window or adding a Dock icon for the app.

#### Scenario: Several files selected
- **WHEN** the user selects `id.jpg` and `payslip.pdf`, Control-clicks and chooses Quick Actions → Watermark
- **THEN** after the text prompt, `id_watermarked.jpg` and `payslip_watermarked.pdf` appear beside the originals
- **AND** both originals are byte-for-byte unchanged

### Requirement: Watermark text prompt
Before processing, the Quick Action SHALL ask for the watermark text in a dialog. The text field SHALL start empty. The dialog SHALL offer **Cancel**, **Without date** and **With date**. **With date** SHALL be the default button and SHALL append today's `DD-MM-YYYY` line. Accented and non-Latin characters SHALL be preserved exactly. When the user's preset file defines presets, a list SHALL first offer those presets and **Custom text…**. Choosing a preset SHALL use its text and settings without the text dialog. Cancel at any step SHALL write nothing and show no error. Text that exceeds the 200-character limit SHALL be reported, and the user SHALL be able to enter it again. Other settings SHALL use the app's defaults, except where a chosen preset defines them, including keeping each file's format.

#### Scenario: Accented text with date
- **WHEN** the user types `Dossier location — Agence Hôtel-de-Ville` and clicks With date
- **THEN** the copies show exactly that text, with the accents and dash unchanged, followed by today's date line

#### Scenario: Cancel
- **WHEN** the user clicks Cancel in the text dialog
- **THEN** no file or staging directory is created and no error is shown

#### Scenario: Choose a preset
- **WHEN** presets exist and the user chooses `rental` from the list
- **THEN** the files are watermarked with the `rental` preset without asking for text

### Requirement: Completion feedback
The Quick Action SHALL report completion. When every file is saved, it SHALL post a notification with the number of saved copies. When any file failed or was excluded, it SHALL show an alert listing each affected file name with its reason and the saved / failed / excluded counts. When at least one copy was saved, the alert SHALL offer **Reveal in Finder**, which selects the saved copies. Feedback SHALL NOT include the watermark text.

#### Scenario: All saved
- **WHEN** three files are watermarked successfully
- **THEN** a notification reports 3 saved copies and no dialog requires dismissal

#### Scenario: Partial failure
- **WHEN** one of two selected files is a password-protected PDF
- **THEN** an alert names that file with the protected-PDF reason and reports 1 saved · 0 failed · 1 excluded
- **AND** Reveal in Finder selects the saved copy

### Requirement: Locating the command
The Quick Action SHALL find `pwm` without relying on the login shell's `PATH`. It SHALL try the path recorded at installation first, then `/Applications/Privacy Watermark.app` and `~/Applications/Privacy Watermark.app`. If no usable `pwm` is found, it SHALL show an alert explaining that Privacy Watermark must be installed and the Quick Action reinstalled, and write nothing.

#### Scenario: App moved after installation
- **WHEN** the recorded path no longer exists but the app is in `/Applications`
- **THEN** the Quick Action uses the `pwm` inside that app bundle

#### Scenario: App removed
- **WHEN** no `pwm` executable can be found
- **THEN** an alert explains how to restore it and no file is processed

### Requirement: Installation and removal
A provided install command SHALL install the Quick Action for the current user only, in `~/Library/Services`, without administrator rights. It SHALL record the absolute path of the `pwm` it was installed from. On request, it SHALL also link `pwm` into a user-writable command directory (default `~/.local/bin`). If that directory is not on `PATH`, it SHALL say how to add it. Reinstallation SHALL replace only the previously installed Watermark Quick Action. An uninstall command SHALL remove the Quick Action and any link it created, and SHALL NOT touch the app, presets or user documents. Installation and removal SHALL NOT change system security settings, Gatekeeper or quarantine attributes.

#### Scenario: Install
- **WHEN** the user runs the install command from a checkout or from the installed app
- **THEN** Watermark becomes available in Finder Quick Actions without restarting the Mac
- **AND** no administrator password is requested

#### Scenario: Uninstall
- **WHEN** the user runs the uninstall command
- **THEN** Watermark no longer appears in Finder Quick Actions and the `pwm` link it created is removed
