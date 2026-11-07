# P1.2 · Review a failing Rust change

**Access** — Offline. Allow 35–45 minutes. Use the [P1.1 parser and CLI](p1-1-read-a-rust-library-and-cli.md) as the baseline. All patches, diagnostics and test results below are illustrative and unexecuted.

## Change request

Ledger Gateway operations wants a debug message with the byte count of the routing file after validation. Count the original file contents, including any trailing line ending, and keep existing parsing, error variants and CLI exit behavior. The helper runs synchronously and needs only the length. A debug message should go to stderr so the CLI's normal stdout remains usable by callers. The examples show the helper body without the surrounding debug flag.

## Proposed patch

```diff
+fn report_validated_bytes(text: String) {
+    eprintln!("validated route file: {} bytes", text.len());
+}
+
 fn run() -> Result<(), CliError> {
     // Existing argument validation omitted.
     let text = fs::read_to_string(path).map_err(CliError::Read)?;
     let route = parse_route(&text).map_err(CliError::InvalidRoute)?;
+    report_validated_bytes(text);
     println!("{} -> {}", route.tenant, route.destination);
     Ok(())
 }
```

Before reading the answer, mark the owner of the file buffer, where the borrow starts, and the last use of the borrowed data. Then predict the error and propose a diff that preserves the message and the order of the calls.

## Worked review

```text
error[E0505]: cannot move out of `text` because it is borrowed
    let route = parse_route(&text)...;
                            ----- borrow of `text` occurs here
    report_validated_bytes(text);
                           ^^^^ move out of `text` occurs here
    println!("{} -> {}", route.tenant, route.destination);
                         ------------ borrow later used here
```

The diagnostic excerpt abbreviates the source. Exact formatting can vary with the compiler version. `run` owns the `String`. `parse_route(&text)` returns a `Route` with slices into that string, and the subsequent print still uses those slices. The helper's by-value signature requires moving the buffer while the borrow is active. This is a compile-time failure, so the test harness cannot run tests for the affected CLI target. [Rust E0505](https://doc.rust-lang.org/error_codes/E0505.html)

```diff
-fn report_validated_bytes(text: String) {
+fn report_validated_bytes(text: &str) {
     eprintln!("validated route file: {} bytes", text.len());
 }
@@
-    report_validated_bytes(text);
+    report_validated_bytes(&text);
```

The helper needs shared access for the duration of its call. `&String` coerces to `&str` here, and the new shared borrow can coexist with the parser's shared borrow. The buffer stays owned by `run`, and the helper accepts both borrowed `String` values and string slices. Another valid interface would pass only `text.len()` as a `usize`. That is appropriate if the helper's contract is to format a precomputed count. [Rust borrowing](https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html), [String deref behavior](https://doc.rust-lang.org/std/string/struct.String.html#deref)

Java would copy the reference when passing a `String` to a helper. With Rust's owned `String`, a by-value call transfers ownership. A shared borrow is the appropriate signature when the helper only reads synchronously. Cloning the original buffer would also avoid moving it, at the cost of duplicating the text. Independent ownership would make sense if a separate background task needed to keep the contents after `run` returned and `run` also still needed the original. Even then, if the task needs only a byte count, pass the count.

## Predict the tests and diagnostics

1. **Identify the boundary.** Would a build that includes the broken CLI reach its test assertions? What could passing library-only tests establish?
2. **Review a different patch.** Suppose the call is moved after the route is printed. The helper still accepts `String`, and the next line now attempts to read `text.len()`. What diagnostic should the reviewer expect?
3. **Review the behavioral change.** After the borrowing fix, predict the debug-enabled CLI's stdout, stderr and success or failure for each input in the table. Why does the valid CRLF file have a different count from the LF file?
4. **Keep the tests at the right boundary.** Where should the team assert the parse error variant, the output channel and the exit status?

### Answer key

1. A build of the broken CLI fails during compilation. Passing library-only tests would support the parser's behavior, while the changed binary would still need to compile. Read the failing target before interpreting a green test summary.
2. The last use of the borrowed route is now before the move. Moving the string into the helper is legal at that point, but reading it again produces **E0382**, a use after move. Follow the move location and the later use in the diagnostic. [Rust E0382](https://doc.rust-lang.org/error_codes/E0382.html)
3. The repaired implementation counts the original UTF-8 buffer. With ASCII inputs, CRLF takes two bytes and LF one. The helper comes after successful parsing, so invalid input skips it when `?` returns early.

| Input | Expected stdout | Expected stderr | Status |
|---|---|---|---|
| `north=settlement\n` | `north -> settlement` | `validated route file: 17 bytes` | Success |
| `north=settlement\r\n` | `north -> settlement` | `validated route file: 18 bytes` | Success |
| `north=\n` | Empty | `invalid routing file: EmptyDestination` | Failure |
| Unreadable file | Empty | Read error with OS-dependent detail | Failure |

4. Assert the exact `ParseError` in a library unit test. Assert stdout, stderr and success or failure in CLI boundary tests, using a controlled input file. Avoid comparing the entire OS-dependent read error message. Existing library tests should retain their expected outcomes because the patch changes only the CLI helper. [Rust test assertions](https://doc.rust-lang.org/book/ch11-01-writing-tests.html)

## Troubleshooting and acceptance

| First evidence | Next check |
|---|---|
| E0505 | Find the active borrow and its last use. Inspect the receiving parameter for an unnecessary move. |
| E0382 | Find the earlier move and decide whether the consumer needs ownership or only a borrow. |
| Wrong byte count | Check the untrimmed buffer, line endings and any non-ASCII characters before changing the parser. |
| Correct diagnostic appears on stdout | Inspect the output macro and check whether the CLI's machine-readable output contract changed. |

Pass the offline review when you can identify both diagnostics and their triggering lines, justify the borrowed interface, and predict all four CLI outcomes. Explain one situation where an independent owned value is justified and which tests would distinguish a compile failure from a behavior regression. Runtime practice remains in the [future labs](../../FUTURE-LABS.md).
