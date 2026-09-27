# Contributing

Single maintainer, best-effort. Issues and pull requests are read; response time is not guaranteed.

## Before you open a pull request

Run the gate the way CI does:

```bash
opa test policies/ -v
opa fmt --list --fail policies/
./scripts/card-gate.sh
```

The [Quickstart](README.md#quickstart) lists the tools the gate needs.

## Licensing of contributions

This repository carries two licenses, split by path.

| Paths | License |
|-------|---------|
| `schemas/`, `policies/`, `scripts/`, `.github/` | Apache-2.0 ([LICENSE](LICENSE)) |
| `README.md`, `CONTRIBUTING.md`, `docs/`, `examples/` | CC BY 4.0 ([LICENSE-CONTENT](LICENSES/CC-BY-4.0.txt)) |

Anything not listed falls under Apache-2.0. By opening a pull request you agree that your contribution is licensed under the license that covers the path you changed.

## Referencing frameworks: IDs and your own words

A Card maps an agent to controls in published frameworks. Some of those frameworks are open. Some are copyrighted and sold.

**ISO/IEC 42001 is copyrighted.** Nothing in this repository reproduces its text. That covers clause text, Annex A control text, and Annex B implementation guidance. The same rule applies to any other ISO/IEC standard, and to any framework whose terms do not allow redistribution.

What a Card, example, schema, or doc may contain for a copyrighted framework:

- The framework name and edition, for example `ISO/IEC 42001:2023`.
- The identifier of the clause or control, for example `8.3` or `A.6.2.4`.
- Your own commentary: how this agent meets the control, in words you wrote about your system.

What it may not contain:

- The control or clause text, quoted or closely paraphrased.
- Tables, notes, or guidance copied from the standard.

In a control mapping, `control_id` carries the identifier and `statement` carries your commentary. A `statement` describes the agent. It never restates the requirement. A reader who needs the requirement itself gets it from their own licensed copy.

Openly published frameworks set their own terms, so read them before you quote. When you are unsure about a framework, use the identifier and your own words. That form is always safe.

A pull request that adds framework text will be asked to remove it before review.
