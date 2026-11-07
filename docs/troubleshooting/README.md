# Troubleshooting index

| Symptom | First discriminating check | Recovery evidence |
|---|---|---|
| Pipeline absent or job missing | Inspect merged YAML, source and ref against workflow and job rules | Intended event creates the expected graph |
| Pending job | Compare job tags and protected-ref status against online, eligible runners and available slots | A tagged probe runs on the intended runner |
| Windows command missing | Compare service identity, PATH and tool locations with the interactive session | The same job resolves and runs the approved executable |
| TLS or proxy failure | Separate DNS, TCP, TLS chain and HTTP auth using the failing client under the job identity | Approved CA and proxy configuration permits authenticated requests |
| Cold or stale cache | Compare computed key, protection suffix, backend and platform/toolchain | A cold run succeeds and the next run restores the intended cache |
| Missing artifact | Identify producer, commit, expiration and the consumer's transfer declaration | Consumer receives the exact commit-stamped file |
| Scanner failure | Separate command startup, report/compute completion and policy decision | Logs correlate the commit, input and verdict, including outage handling |
