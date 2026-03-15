# Product Guidelines

## Prose Style
- **Clarity and Precision**: All UI text and documentation should be clear, concise, and professional.
- **Tone**: Professional, secure, and reassuring, reflecting the app's focus on privacy.
- **Vocabulary**: Use standard macOS terminology (e.g., "Export" instead of "Save As", "Finder" instead of "Explorer").

## Branding & UX Principles
- **Privacy-First**: Always inform the user of security actions (e.g., "Metadata stripped", "Secure rasterization applied").
- **Real-Time Feedback**: Ensure all interactive elements (sliders, inputs) provide immediate visual feedback in the preview.
- **macOS Integration**: Design the interface to feel native to macOS, following platform-appropriate layouts and spacing.
- **Safety**: Provide clear warnings for potentially destructive or large-file-size operations (e.g., very high DPI in Secure Mode).

## Design & UI Guidelines
- **Flet Framework**: Adhere to Flet's best practices for layout and state management.
- **Responsiveness**: Ensure the preview and controls scale gracefully with window resizing.
- **Simplicity**: Maintain a clean, uncluttered interface focused on the core task of watermarking.

## Security & Privacy Standards
- **Zero Metadata Leakage**: All exports must have EXIF and other metadata stripped.
- **Secure Logging**: Do not log sensitive user information or file paths; use path sanitization.
- **Resource Limits**: Enforce maximum file sizes and page counts to prevent resource exhaustion.
