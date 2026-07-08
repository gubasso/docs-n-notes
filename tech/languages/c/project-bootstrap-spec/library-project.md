# C library project — implementation-kind additions

What a **library** project adds on top of the general recipe and the C binding: a public header API,
shared/static build targets, install/export rules, and ABI hygiene. This file owns only the
**bootstrap-time ordering**.

## Prerequisites

- The [general runbook](../../../programming/project-bootstrap/runbook.md) and the C
  [binding runbook](runbook.md) are done — a buildable, gated project exists.

## Add these, in this order

1. **Public header API.** Place the consumer-facing headers under `include/<project>/`; keep
   implementation-private declarations out of them. Wrap headers in include guards (or
   `#pragma once`) and `extern "C"` so C++ callers link cleanly. →
   [00 — Toolchain & layout](00-toolchain-and-layout.md).

2. **Library build target.** Add a shared and/or static target (CMake
   `add_library(... SHARED|STATIC)`, Meson `library()`/`shared_library()`/`static_library()`).
   Decide up front which you ship.

3. **Symbol visibility.** Default to hidden visibility (`-fvisibility=hidden`) and mark the public
   API with an export macro, so only intended symbols are part of the ABI.

4. **Install & export rules.** Install headers plus the library, and generate a discovery file — a
   `pkg-config` `.pc` and/or a CMake package config — so downstream projects can find and link it.

5. **ABI hygiene.** For a shared library, plan a `soname`/version early; keep the public header
   changes additive within a major version.

## Versioning & publishing (later phase)

SemVer policy, `soname` bumps on ABI breaks, and packaging/distribution are release-phase concerns,
not bootstrap. Bootstrap stops at a buildable, installable, gated library with a defined public API.
