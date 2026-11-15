# Operational checks

| Task | Check | Expected evidence |
|---|---|---|
| Check Cargo resolution | `cargo metadata --locked --format-version 1` | Machine-readable graph or a lockfile/resolution error |
| Check GitLab configuration | CI Lint and merged YAML, followed by a sandbox run for the intended event | Resolved includes, intended job set and DAG |
| Check the Windows service | `Get-Service gitlab-runner` and `Get-CimInstance Win32_Service -Filter "Name='gitlab-runner'"` | Service state and configured account |
| Check installed runner connectivity | `gitlab-runner verify` against the service's config | Registered runner can reach GitLab; pair with a scheduled probe to prove service execution |
| Check tool resolution in a job | `whoami`, `Get-Command git,cargo,rustc,pwsh`, `rustc -vV` | Effective identity, executable paths and Rust host triple |
| Check an outbound route | `Test-NetConnection <host> -Port 443` from the service context | TCP reachability; follow with a client-specific HTTPS probe for TLS and auth |
