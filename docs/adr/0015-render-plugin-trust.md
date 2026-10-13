# ADR 0015: Trust repository render scripts

## Context

The Argo CD render sidecar runs scripts from this repository while it holds the SOPS
age key. Anyone who can push code to `main` can use those scripts to read that key.

## Decision

I accept this risk for a single-maintainer repository. I protect `main`, require merge
requests, and allow only the promotion bot token to push directly.

## Tradeoff

Repository write access remains security-sensitive. A later change should bake the
renderer into a pinned image instead of running repository scripts beside the key.
