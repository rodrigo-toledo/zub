# Zub

Zub is a Zig-based port of the popular Python library, Subliminal. The primary goal is to create a high-performance, single-binary, cross-platform command-line tool for automatically finding and downloading subtitles for video files.

## Building

To build the project, you will need to have Zig installed. You can find installation instructions on the [official Zig website](https://ziglang.org/learn/getting-started/).

### Standard Build

To build the project for your native platform, run the following command:

```sh
zig build
```

This will create an executable in the `zig-out/bin` directory.

### Cross-Compilation (Linux x86_64)

To cross-compile the project for 64-bit Linux, run the following command:

```sh
zig build -Dtarget=x86_64-linux-gnu
```

## Testing

To run the test suite, use the following command:

```sh
zig build test