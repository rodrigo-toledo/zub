# Tech Stack: Zub

## Core Language

*   **Zig**: The project is a port of a Python library to Zig, leveraging Zig's performance, safety, and cross-compilation capabilities.

## Build System

*   **Zig Build System**: The project uses the native Zig build system (`build.zig`) for compiling, testing, and managing the project.

## Key Dependencies & Libraries

*   **Zig Standard Library**: Used for core functionalities like file system access, HTTP client (via `std.ChildProcess` and `curl`), JSON parsing, and testing.

## Development Tools

*   **Git**: For version control.

## Target Platforms

*   **Cross-platform**: The goal is to support Windows, macOS, and Linux from a single codebase. However, initial development will prioritize Linux to ensure all features are stable before focusing on cross-platform compatibility.
