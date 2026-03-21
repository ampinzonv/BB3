# Changelog

All notable changes to the BioBash (BB3) project will be documented in this file.

## [Unreleased] - 2026-03-21

### Added
- **Universal CLI Dispatcher (`biobash`)**: A new centralized entry point was created. Now all commands are accessible via `biobash <command>` without needing to `source` the library into the active terminal session.
- **Dynamic Module Loading**: The dispatcher automatically resolves cross-dependencies (like `bb_guess_sequence_type` inside `blast.sh` commands) by securely loading all required core modules into memory dynamically at runtime.

### Changed
- **Installation Script (`biobash_install.sh`)**: 
  - Restructured to add the project path to the system's `$PATH` instead of dynamically sourcing `.sh` modules inside user profile files.
  - Added native compatibility for macOS devices with `zsh` support (edits `.zshrc`, `.bashrc`, or `.bash_profile` dynamically based on `$SHELL` inference).
  - Changed the default installation directory to `~/.biobash`, removing the friction and dependence on root/`sudo` access.
- **Uninstallation Script (`biobash_uninstall.sh`)**: 
  - Overhauled cleanup mechanisms to iteratively scan all potential user configuration files (`.bashrc`, `.bash_profile`, `.zshrc`, `.profile`).
  - Improved safety of configuration file redaction preventing accidental modification of non-Biobash environment lines.

### Removed
- Legacy requirement to use `source load_biobash.sh` for standard interactive CLI usage.
