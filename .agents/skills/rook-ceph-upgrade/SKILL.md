---
name: rook-ceph-upgrade
description: Rook operator and Ceph image upgrades in kubernetes/core/rook-ceph.nix (order constraints, breaking changes seen, CephX key rotation, ceph-csi-drivers chart, rollout watch scripts, CSI smoke test, known crash records). Use for any Rook, Ceph or ceph-csi change.
---

# Rook / Ceph upgrades

Storage under every PVC; the riskiest chain. Follow helm-chart-upgrade for the
PR loop and hfym-cluster-access for how to run `ceph`. State as of 2026-10-31:
Rook 1.20.9, Ceph 19.2.7 Squid (`quay.io/ceph/ceph:v19.2.7-20261009`),
ceph-csi-drivers chart 1.0.4, daemon CephX keys rotated to AES256K (gen 1),
CSI client keys still `aes`.

## Order constraints

- Rook: one minor per hop (1.14 -> 1.15 -> ... ). Each hop restarts the operator,
  then mons, mgrs, OSDs, MDS, RGW one at a time; ~10 min, no PVC downtime.
  The operator restarts all OSDs of one host together (3 on vaporeon), so
  expect ~35% degraded PGs for a minute with min_size 1 keeping I/O up.
- Ceph: one major per hop (Reef 18 -> Squid 19 -> Tentacle 20) and **cannot be
  downgraded**. A Ceph image hop restarts every daemon on the new image, ~13 min;
  verify `ceph versions` is uniform, `require_osd_release` and `min_mon_release`
  moved.
- Each Rook minor has a min/max Ceph and a Kubernetes range (chart README). Hit
  so far: Rook 1.18 refuses Ceph >= 19.2.6; Rook 1.19 requires Ceph >= 19.2.0;
  **Rook 1.21 requires Kubernetes >= 1.32** (so Rook parks at 1.20 until the first
  kube hop; 1.21.1 pins ceph-csi-operator 1.1.0 -> drivers chart 1.1.0).
- CVE-2025-30156 (CephX privilege escalation): the fixed Ceph (>= 19.2.6) needs
  Rook >= 1.19.10 and then a key rotation, so the sequence that worked was
  Rook 1.15 -> 1.16 -> 1.17 -> 1.18, Ceph 18.2.2 -> 19.2.5, Rook 1.19.12,
  Ceph 19.2.7 + daemon key rotation in one PR, Rook 1.20.9.

## Per-hop procedure

1. Pre-check: `ceph status` shows 617 active+clean, 7 OSDs up, quorum d,k,l,
   MDS 1 up + 1 hot standby, no new entries in `ceph crash ls-new`.
2. Read `Documentation/Upgrade/rook-upgrade.md` (branch `release-1.X`) "Breaking
   changes" and the chart `values.yaml` diff.
3. Bump `version`/`sha256` of `helmReleases.rook-ceph` (or
   `CephCluster.spec.cephVersion.image` for Ceph). Merge.
4. Watch: `ssh ... 'bash -s -- v1.20.9' < scripts/watch-rook.sh` (Rook hop,
   target with `v`) or `ssh ... 'bash -s -- 19.2.7' < scripts/watch-ceph.sh`
   (Ceph hop, target without `v`). Both print DONE when all 25 `rook_cluster`
   deployments carry the target label and Ceph is back to baseline.
5. After any hop that touches CSI: `scripts/csi-check.sh` (Driver CRs keep the
   NixOS mounts, plugin DaemonSets ready, 1 GiB RBD PVC write smoke test).
6. Check Argo: `poketwo-rook-ceph` Synced. Argo CD >= 3.3 maps Ceph HEALTH_WARN
   to app Degraded, so Degraded here means "read `ceph health detail`", not a
   sync problem.

## Breaking changes that applied

- **1.18**: `csi.rookUseCsiOperator` defaults true; the operator converts the
  `csi.csi*PluginVolume(Mount)` values into `Driver` CRs. Verified the `/nix` and
  kernel-module hostPaths survived.
- **1.20**: Rook stops managing CSI entirely. The separate `ceph-csi-drivers`
  chart (repo https://ceph.github.io/ceph-csi-operator, version = the
  `ceph-csi-operator` dependency in rook-ceph's Chart.yaml) is REQUIRED; without
  it the CSI pods fail for missing ServiceAccounts. rook-ceph.nix now has
  `helmReleases.ceph-csi-drivers` with Rook's recommended values
  (`deploy/charts/ceph-csi-drivers/values.yaml` in the rook tag), plus:
  - `drivers.{rbd,cephfs}.snapshotPolicy = "volumeSnapshot"` (chart default for
    rbd is `none`, which removes the csi-snapshotter Velero needs);
  - `nfs.enabled = false; nvmeof.enabled = false` (chart default true);
  - the NixOS node-plugin volumes (`lib-modules` from
    `/run/booted-system/kernel-modules/lib/modules/`, `host-nix` = `/nix` ro) under
    `drivers.*.nodePlugin.volumes` as `{ volume; mount }` entries; the operator
    merges them by name over its built-ins.
  The new chart's CRD group `csi.ceph.io` needed a `kube-openapi.json` refresh,
  and ~53 old CSI RBAC/ServiceAccount objects had to be pruned afterwards.
- **1.19**: `metadataServer.activeStandby = false` would now delete the standby
  MDS (we keep true).
- 1.15 holder pods, 1.16 Quincy drop, 1.17 S3 user credential purge / OBC config
  fields: nothing in this repo used them.

## CephX key rotation (done once, repeatable)

`CephCluster.spec.security.cephx.daemon = { keyRotationPolicy = "KeyGeneration"; keyGeneration = N; }`
rotates mon/mgr/osd/mds/rgw/admin keys on the next daemon restart, so put it in
the same PR as a Ceph image bump. Ceph is HEALTH_ERR until the last key rotates
(~10 min after the image rollout); `watch-ceph.sh` prints `status.cephx`.
Rook only rotates live daemons: a stale auth entity (osd.5, left over from a
March 2026 OSD replacement, absent from `ceph osd ls`) kept HEALTH_ERR until
`ceph auth rm osd.5`. Ask Oliver before removing credentials.
CSI client keys (`client.csi-*`, `rbd-mirror-peer`) stay `aes`: AES256K client
keys need kernel >= 7.0 on the nodes (6.18 today). The remaining
`AUTH_INSECURE_*` warnings are expected until then.

## Known warts

- osd.2 (jolteon) and osd.8 (flareon) have ~80 crash records from 2026-03 and
  osd.8 segfaulted once on shutdown during the 1.15 hop (`BlueStore::_txc_create`
  from `handle_watch_timeout`); came back in 30 s. Compare `crash ls-new` before
  and after each hop rather than reading the total.
- `MON_DISK_LOW` on mon d = vaporeon `/var` (ZFS `nixos/var`, 181 GB) filling
  with CRI-O images. `crictl rmi --prune` freed 28 GB once; a real fix is kubelet
  `imageGCHighThresholdPercent` in `modules/poketwo/kubernetes.nix`.
- Ceph 19 -> 20 Tentacle: Rook docs say disable the `rook` mgr module first.
