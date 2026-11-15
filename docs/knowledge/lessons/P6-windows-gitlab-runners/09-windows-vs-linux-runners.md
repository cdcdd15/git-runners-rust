# Windows versus Linux runners: meaningful differences

## The operating system changes more than syntax

A GitLab job is logically the same unit on either platform, but shell behavior, path conventions, installed toolchains, permissions and isolation options differ. Windows runners are often required for native MSVC builds, Windows-only SDKs or enterprise scanners installed as Windows executables.

## Comparison

| Dimension | Windows Shell runner | Linux container runner |
|---|---|---|
| Execution | Host PowerShell processes | Processes inside container |
| Filesystem | NTFS, drive letters, Windows ACLs | Container filesystem and mounted volumes |
| Tools | Host-installed Git, Rust, scanners | Usually image-defined tools |
| Isolation | Low; shared service account/host | Better process/filesystem isolation, not absolute |
| Paths | `C:\...`, `Join-Path` | `/builds/...`, POSIX paths |
| Secrets risk | Host-accessible credentials | Container/runtime-specific exposure |
| Reproducibility | Requires disciplined host provisioning | Image pinning can improve consistency |

The comparison is intentionally between **Windows Shell** and **Linux container** runners, not Windows versus Linux in every possible executor combination. Windows container runners also exist, and Linux Shell runners share many Shell risks.

## Rust target triples

A Rust project may build for `x86_64-pc-windows-msvc`, `x86_64-pc-windows-gnu` or Linux targets. Target choice affects compiler/linker requirements, binary format and dependencies. A Linux build cannot be assumed equivalent to a Windows MSVC build even if the Rust source is identical.

## YAML portability

```yaml
windows_check:
  tags: [windows, rust]
  script:
    - '$env:RUST_BACKTRACE = "1"'
    - 'cargo check --locked'

linux_check:
  tags: [linux, docker]
  image: rust:stable
  script:
    - export RUST_BACKTRACE=1
    - cargo check --locked
```

These are illustrative jobs. The image tag is not pinned to an immutable digest and would require governance review for production reproducibility.

## Caching and artifacts

Cargo registry data can be cached on both platforms, but compiler outputs under `target/` should not be assumed portable. Use platform-aware cache keys. Artifacts containing native executables are inherently platform-specific; consumers must run on a compatible OS or use an appropriate cross-compilation strategy.

## Operational tradeoff

Windows Shell is straightforward when a legacy enterprise toolchain must be installed on a host. Its cost is lower isolation and greater configuration drift. Linux containers make toolchain versions easier to declare but require compatible build dependencies and container infrastructure.

## Decision framework

Choose based on required target binary, SDK availability, scanner support, trust level, reproducibility requirements and operations capacity. Avoid selecting Windows merely because the development team uses Windows desktops.

**Conclusion:** The executor and toolchain define portability and security more strongly than the YAML filename.
