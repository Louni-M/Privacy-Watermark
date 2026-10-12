# watermark-cli Specification

## Purpose

Let users and scripts watermark local images and PDFs from the command line with the same settings, validation, naming and output safety as the app, without opening its window.

## Requirements

### Requirement: Command invocation and help
The `pwm` command SHALL accept the watermark text as its first positional argument, followed by one or more input file paths: `pwm TEXT FILE… [options]`. `--text TEXT` SHALL provide the text as an option instead, in which case every positional argument is an input file. Options MAY appear before, between or after positional arguments. `--` SHALL end option parsing so that paths beginning with `-` can be given. An empty TEXT SHALL be accepted, matching the app's blank-text behavior. `--help` and `-h` SHALL print usage and exit successfully without processing files. Usage SHALL list every option with its accepted values and default. `--version` SHALL print the version of the containing app release. An unknown option, a missing value, an invalid value, a missing TEXT or no input file SHALL print a specific error and a hint to use `--help`, process no file and exit with the usage error code.

#### Scenario: Show help
- **WHEN** the user runs `pwm --help`
- **THEN** usage, every option, accepted values and defaults are printed
- **AND** the command exits with code 0 without reading or writing any document

#### Scenario: Reject an invalid option value
- **WHEN** the user runs `pwm "COPY" scan.jpg --opacity 150`
- **THEN** an error names `--opacity` and its accepted range 0–100
- **AND** no output is written and the command exits with the usage error code

#### Scenario: Path beginning with a dash
- **WHEN** the user runs `pwm "COPY" -- -scan.pdf`
- **THEN** `-scan.pdf` is treated as an input file, not as an option

### Requirement: Settings match the app
The command SHALL expose the app's shared settings, with the app's defaults and ranges: `--date` (append today's date as a `DD-MM-YYYY` line, off by default; `--no-date` turns it off), `--opacity` 0–100 (default 30), `--size` 12–72 (default 36), `--spacing` 50–300 (default 150), `--color white|black|gray` (default black), `--direction up|down` (default up), `--format keep|pdf|jpg|png` (default keep), `--pdf-mode flattened|text` (default flattened) and `--dpi 300|450|600` (default 450). Keep original format SHALL map PDF to PDF, PNG to PNG and JPG/JPEG to JPG. Text line breaks given as real newlines or the two-character sequence `\n` SHALL become separate watermark lines. Text, including any date line, SHALL be at most 200 characters. Text that is longer SHALL be rejected with a usage error rather than silently shortened. For the same input and settings, the rendered output SHALL be equivalent to the app's export.

#### Scenario: Defaults equal the app
- **WHEN** the user runs `pwm "COPY" contract.pdf` with no appearance or format options
- **THEN** the output is a flattened 450-DPI PDF watermarked at 30% opacity, size 36, spacing 150, black, ascending

#### Scenario: Include today's date
- **WHEN** the user runs `pwm "For rental file" id.jpg --date` on 12 October 2026
- **THEN** the watermark contains the line `For rental file` followed by the line `12-10-2026`

#### Scenario: Text too long
- **WHEN** the text plus the requested date line exceeds 200 characters
- **THEN** the command reports the 200-character limit and the actual length, writes nothing and exits with the usage error code

### Requirement: Output placement and naming
Without `--out`, each copy SHALL be written in the folder containing its source. With `--out DIR`, every copy SHALL be written in DIR. DIR SHALL be an existing, writable directory; otherwise the command SHALL fail with a usage error before processing. Names SHALL follow the app's export contract: `<stem>_watermarked.<ext>`, then ` (2)`, ` (3)` and so on for names already used or reserved in the same run. A PDF exported as images SHALL produce a `<stem>_watermarked` folder containing `<stem>_page_001.<ext>` and subsequent pages. Inputs SHALL never be merged. Existing files, directories and any input of the run SHALL never be replaced or modified. Publication SHALL be atomic per input: an input either produces its complete output or none.

#### Scenario: Copy beside the original
- **WHEN** the user runs `pwm "COPY" ~/Documents/passport.jpg`
- **THEN** `~/Documents/passport_watermarked.jpg` is created and `passport.jpg` is byte-for-byte unchanged

#### Scenario: Name already used
- **WHEN** `passport_watermarked.jpg` already exists beside the source
- **THEN** the new copy is `passport_watermarked (2).jpg` and the existing file is unchanged

#### Scenario: Sources in several folders
- **WHEN** inputs come from two different folders and `--out` is absent
- **THEN** each copy is created beside its own source

#### Scenario: PDF to page images
- **WHEN** the user runs `pwm "COPY" lease.pdf --format png` on a 3-page PDF
- **THEN** a `lease_watermarked` folder is published containing `lease_page_001.png` through `lease_page_003.png`

### Requirement: Input validation and isolation
Inputs SHALL be validated with the app's rules: case-insensitive JPG, JPEG, PNG or PDF that the decoder accepts; at most 100 MiB; at most 50 PDF pages; at most 20,000 pixels per image side. Password-protected and empty PDFs SHALL be rejected. Directories SHALL NOT be traversed, and missing paths SHALL NOT be processed. Each of these inputs SHALL be reported as excluded with the app's readable reason. The same underlying file given more than once, including through links, SHALL be processed once. An input that fails during export SHALL be reported as failed and SHALL NOT prevent the remaining inputs from being attempted. A source that changes while it is being read SHALL fail rather than be partially exported.

#### Scenario: Mixed valid and invalid inputs
- **WHEN** the user runs `pwm "COPY" a.jpg notes.txt b.pdf` and `b.pdf` is password-protected
- **THEN** `a_watermarked.jpg` is saved
- **AND** `notes.txt` and `b.pdf` are reported as excluded with their reasons

#### Scenario: Duplicate argument
- **WHEN** the same file is passed twice, once directly and once through a symbolic link
- **THEN** exactly one watermarked copy is produced

### Requirement: Reporting and exit status
For each saved input, standard output SHALL contain the absolute path of its published file or page folder, one per line, and nothing else. Errors and the run summary SHALL go to standard error. The summary SHALL use the app's outcome categories, saved, failed, excluded and not processed, and these SHALL add up to the number of distinct inputs. The exit status SHALL be:
- 0 when every input was saved;
- 1 when at least one input was saved and at least one was failed, excluded or not processed;
- 2 when no input was saved;
- 64 for usage errors;
- 78 for an invalid preset file;
- 130 after interruption.

Messages SHALL NOT include watermark text. The command SHALL NOT write diagnostic log files.

#### Scenario: Partial success
- **WHEN** two inputs are saved and one is excluded
- **THEN** stdout lists the two output paths
- **AND** stderr ends with `2 saved · 0 failed · 1 excluded · 0 not processed`
- **AND** the exit status is 1

#### Scenario: Interrupted run
- **WHEN** the user presses Control-C during the second of three inputs
- **THEN** the first copy remains, no partial output or staging directory remains for the second
- **AND** the summary counts one saved and two not processed, and the exit status is 130

### Requirement: Named presets
`--preset NAME` SHALL load text and settings from the user's preset file. The file is located at `$XDG_CONFIG_HOME/pwm/presets.json`, or at `~/.config/pwm/presets.json` when `XDG_CONFIG_HOME` is unset. A preset MAY define any of text, date, opacity, size, spacing, color, direction, format, PDF mode and DPI. Explicit command-line options, including `--text`, `--date` and `--no-date`, SHALL override preset values. When a preset defines text, positional TEXT SHALL NOT be expected, and every positional argument is then an input file. `--list-presets` SHALL print the available preset names. An unknown preset name SHALL be a usage error. A missing file SHALL only be an error when a preset is requested. A malformed file or out-of-range preset value SHALL report the file and the problem and exit with the configuration error code. The command SHALL only read the preset file and SHALL never create or modify it.

#### Scenario: Use a preset
- **WHEN** the preset `rental` defines text `Rental application`, date true and opacity 40, and the user runs `pwm --preset rental id.jpg payslip.pdf`
- **THEN** both files are watermarked with that text, today's date line and 40% opacity

#### Scenario: Override a preset value
- **WHEN** the user runs `pwm --preset rental id.jpg --opacity 20 --text "Guarantor file"`
- **THEN** opacity 20 and the text `Guarantor file` are used, and the preset's other values are kept

#### Scenario: Malformed preset file
- **WHEN** `presets.json` is not valid JSON and the user requests a preset
- **THEN** the command names the file and the parse problem, writes nothing and exits with code 78

### Requirement: Metadata-only stripping
`--strip-only` SHALL produce copies of JPG/JPEG and PNG inputs, in the same format, without a watermark and without source EXIF, GPS, camera or timestamp metadata. The copies SHALL be named `<stem>_stripped.<ext>`, with the same suffix, placement and no-replacement rules as watermarked copies. Watermark text SHALL NOT be accepted with `--strip-only`, so every positional argument is an input file. Appearance, format, PDF and preset options SHALL be rejected with a usage error. PDF inputs SHALL be reported as excluded with a reason stating that PDF metadata stripping is not supported. Visible content and pixel dimensions SHALL be preserved. Transparency SHALL become opaque, as in image export.

#### Scenario: Strip a photo
- **WHEN** the user runs `pwm --strip-only IMG_0042.jpg` on a photo containing GPS coordinates
- **THEN** `IMG_0042_stripped.jpg` is created with the same pixel dimensions and no EXIF or GPS metadata
- **AND** the original is unchanged

#### Scenario: PDF with strip-only
- **WHEN** the user runs `pwm --strip-only report.pdf`
- **THEN** no output is written, the file is reported as excluded and the exit status is 2
