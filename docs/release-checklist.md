# Release Checklist — Runtime-Adaptive FPGA Video LUT Reconfiguration

## Purpose

This checklist defines the minimum steps required before publishing a formal GitHub release or DOI archive for the Runtime-Adaptive FPGA Video LUT Reconfiguration project.

## Documentation Readiness

- [ ] README reflects the correct repository title and technical purpose.
- [ ] LICENSE file is present.
- [ ] Technical overview is complete.
- [ ] Invention summary is complete.
- [ ] System architecture is complete.
- [ ] Register map is complete.
- [ ] LUT reconfiguration flow is complete.
- [ ] Diagnostic readback document is complete.
- [ ] Implementation plan is complete.
- [ ] Validation plan is complete.
- [ ] Technical white paper draft is complete.
- [ ] Patent-style disclosure draft is reviewed before wider public release.

## Repository Structure

- [ ] `docs/` contains architecture and validation documentation.
- [ ] `papers/` contains publication drafts.
- [ ] `images/` contains diagrams or diagram placeholders.
- [ ] `rtl/` contains RTL placeholder or source files.
- [ ] `src/` contains host-control placeholder or software files.
- [ ] `testbench/` contains verification placeholder or simulation files.

## Technical Review

- [ ] Confirm terminology is consistent across all documents.
- [ ] Confirm LUT, shadow buffer, active bank, and diagnostic readback descriptions match.
- [ ] Confirm register names match between register map and diagnostic documents.
- [ ] Confirm claims in the patent-style disclosure do not overstate implemented hardware.
- [ ] Confirm all future-work sections are clearly labeled as planned work.

## Publication Review

- [ ] Decide whether patent review is needed before additional public disclosure.
- [ ] Create a GitHub release tag such as `v0.1-docs-foundation`.
- [ ] Export white paper to PDF if needed.
- [ ] Upload release package to Zenodo if DOI archival is desired.
- [ ] Add DOI badge to README after Zenodo publication.

## Suggested Version Tags

| Version | Meaning |
|---|---|
| `v0.1-docs-foundation` | Initial documentation foundation |
| `v0.2-architecture-package` | Architecture, register map, and validation plan complete |
| `v0.3-paper-draft` | White paper and patent-style disclosure draft complete |
| `v1.0-public-technical-release` | Public release with diagrams, docs, and implementation evidence |

## Status

Initial release checklist for future GitHub release and DOI publication preparation.
