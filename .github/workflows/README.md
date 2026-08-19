# GitHub Actions

Upstream Google Cloud workflows were removed on purpose.

They authenticated to a GCP project you do not own (`online-boutique-ci`),
validated Helm/Kustomize/Terraform trees that no longer exist in this fork, and
would have burned your free Actions minutes failing.

**Day 2 of [the 4-day sprint](../../docs/4-day-roadmap.md) is where you write
`.github/workflows/ci.yaml` yourself** — lint/test first, then a matrix build
that publishes all service images to GHCR tagged with the git SHA.

Do not copy the old Google workflows back. They teach the wrong cloud, the
wrong identity model, and they hide the pipeline behind Workload Identity
Federation you cannot reproduce.
