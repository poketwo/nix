---
name: helm-chart-upgrade
description: Procedure for upgrading any Helm chart declared with transpire.fetchFromHelm under kubernetes/ (one minor per PR, local NAR hash, upstream notes, merge, Argo rollout watch, leftover cleanup). Use for any version bump of a component in this repo; the rook-ceph, argocd, cert-manager and velero skills add component specifics on top of this.
---

# Upgrading a Helm chart in this repo

How 28 hops (Rook, Ceph, cert-manager, Velero, Argo CD) were done in Oct 2026.
Each hop is one small PR; the whole loop is ~15 min including CI.

## Rules

- **One minor version per PR**, verified live before the next PR is opened.
  Rook, cert-manager and Argo CD all document per-minor upgrades, and a
  one-minor diff is small enough to read. Exception: a component that is
  completely broken and holds no state worth keeping (Velero after its bucket
  died) may jump straight to latest.
- Components whose Kubernetes support ends before the target Kubernetes version
  are upgraded **before** Kubernetes, not after.
- Before each hop read the upstream upgrade notes / breaking changes for that
  minor and say which ones apply to this repo's values. Diff the chart's
  `values.yaml` against the previous version (`diff cA/values.yaml cB/values.yaml | grep '^[<>]' | grep -v '#'`)
  to catch renamed or defaulted keys.
- Keep `values = { ... };` attribute-set blocks; do not collapse a single
  setting into `values.x.y = ...;`. Keep the diff minimal.
- Never edit the `cluster` branch; never force-push `main`.

## Steps

1. **Find the version.** Chart repos publish `index.yaml`; the latest entry of a
   given minor is the hop target (`curl -s <repo>/index.yaml | yq '.entries.<chart>[].version'`).
   Chart versions and app versions differ (argo-cd chart 10.11.6 = Argo CD 3.5.6).
   Rook's index names tarballs with a `v` (`rook-ceph-v1.20.9.tgz`) but
   `version = "1.20.9"` is what fetchFromHelm wants.
2. **Compute the hash locally** instead of pushing an empty hash:
   ```bash
   curl -sO <repo>/<chart>-<ver>.tgz && mkdir c && tar xzf <chart>-<ver>.tgz -C c
   python3 .agents/skills/helm-chart-upgrade/scripts/narhash.py c/<chart>
   ```
   Sanity check once per chart: the script reproduces the hash already in the
   nix file for the current version.
3. **Edit** `version` and `sha256` (and `image.tag`/plugin images if the file pins
   them) in `kubernetes/<ns>/<component>.nix`. Commit as
   `<component>: upgrade X -> Y (chart A -> B)`.
4. **New CRD groups** make CI fail with `option ... does not exist`: transpire
   type-checks rendered objects against `kube-openapi.json`. Refresh it from the
   live cluster (`kubectl get --raw /openapi/v2 > kube-openapi.json` on turtwig,
   or the flake app `update-kube-openapi`) and commit that separately. Re-apply
   the hand patch `Container.automountServiceAccountToken: {}` the file carries
   for the bitnami mongodb chart.
5. **Open the PR**, wait for CI (`build`, `check-flake`, the 8 host builds) and
   Devin Review. Merge with `command gh pr merge <n> --merge` when green and
   the pre-check below is clean. CI then rebuilds `cluster`; Argo syncs it ~3 min
   later (`kubectl -n argocd get app poketwo-<component>`).
6. **Pre-check / watch / verify** with the component's script (see the other
   skills). Report: versions on every pod/deployment, Argo `Synced/Healthy`,
   workload-specific smoke test, and anything new in logs or health.
7. **Clean up what Argo will not prune.** Objects that the new chart no longer
   renders (old DaemonSets, RBAC, Schedules, Secrets, a VSL) stay live and leave
   the app `OutOfSync` with `requiresPruning`. Confirm nothing uses them, then
   delete them by hand or do a one-off prune sync with the app's own
   syncOptions (see hfym-cluster-access).

## Chart-specific traps already hit

- A chart whose default for a list is a one-element placeholder (Velero's
  `configuration.volumeSnapshotLocation`) renders an invalid object when our
  override is removed; set it to `[ ]` explicitly.
- `autodetect`-style values that look at cluster capabilities are evaluated by
  `helm template` with no cluster, so monitors/CRDs behind them never render.
- `helm template` also means hooks run as Argo PreSync jobs (Velero
  `upgrade-crds`), which is fine.
- A chart dropping a subcomponent into a second chart (Rook 1.20 -> ceph-csi-drivers)
  means a second `helmReleases.<name>` in the same nix file, pinned to the
  version the first chart expects.
