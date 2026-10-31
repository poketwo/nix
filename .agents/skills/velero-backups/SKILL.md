---
name: velero-backups
description: How PVC backups work on hfym-ds (Velero 1.18 + CSI snapshots + Kopia data mover to Cloudflare R2), how to verify a backup, run a one-off backup or restore, upgrade Velero, and why CephFS uses read-only snapshot-backed PVCs. Use for anything about backups, Velero, DataUploads, R2 or CephFS snapshots.
---

# Velero backups

Config: `kubernetes/core/velero.nix` (vmware-tanzu chart 12.2.2, Velero 1.18.4,
`velero-plugin-for-aws` 1.14.4, `EnableCSI`, kopia uploader, node-agent on the
5 workers). Rebuilt in Oct 2026 after the Backblaze bucket disappeared and
backups had silently failed for a week.

## How a backup runs

1. Schedule `daily` (04:30 UTC, ttl 168h, `snapshotMoveData`) backs up every
   namespace except velero, kube-system, cilium, rook-ceph, argocd, cert-manager.
   PVCs labelled `velero.io/exclude-from-backup=true` are skipped (label must be
   on the PVC itself; poketwo's prod MongoDB has it, its protection is sanoid ZFS
   snapshots on the host).
2. Per PVC Velero takes a CSI VolumeSnapshot, then creates an intermediate
   "backup PVC" from it in the `velero` namespace and a DataUpload; the
   node-agent mounts it and Kopia uploads deduplicated, encrypted chunks to R2
   bucket `hfym-ds-backups` (one Kopia repo per namespace). Snapshot and temp PVC
   are deleted afterwards, so a healthy cluster has 0 VolumeSnapshots between runs.
3. ~103 PVCs; the run is dominated by guiduck's 3 x 190 GB MongoDB members
   (~1.5 h). Everything else finishes in minutes.

R2: BSL `default`, `s3Url = https://<account>.r2.cloudflarestorage.com`,
`region = "auto"`, `checksumAlgorithm = ""` (R2 rejects AWS CRC32 trailers).
Credential is the R2 "Account API Token" scoped Object Read & Write to the
bucket, stored in Vault `hfym-ds/velero/r2-credentials` key `aws-config`
(S3 secret key = SHA-256 of the raw Cloudflare token). ~$5-15/month.

## CephFS: read-only backup PVCs, not clones

RBD snapshot -> PVC is a copy-on-write clone (instant). CephFS snapshot -> a
ReadWriteOnce PVC is a full subvolume clone done by the Ceph mgr in Python, one
file at a time (`bulk_copy` in `mgr/volumes/fs/async_cloner.py`), measured at
3.6 MB/s: 38 GB took ~3 h and blew Velero's 30 min prepare timeout.
ceph-csi treats a **ReadOnlyMany** PVC from a snapshot as "snapshot-backed": it
bind-mounts the `.snap` directory, no clone, binds in 0 s. Velero exposes that
per source storage class through the node-agent configmap:

```nix
nodeAgent.extraArgs = [ "--node-agent-configmap=velero-node-agent" ];
resources.v1.ConfigMap.velero-node-agent.data.config = builtins.toJSON {
  backupPVC = { cephfs-nvme.readOnly = true; cephfs-nvme-retain.readOnly = true; };
};
```

With it the 38 GB `atomicgrader/ag-assets` uploads in ~4 min (~150 MB/s).
Do not "fix" CephFS with a longer `dataMoverPrepareTimeout` or with `fs-backup`
(reads the live mount, loses point-in-time consistency).

An abandoned CephFS clone (Velero timed out and deleted its temp PVC) keeps
running in the mgr and ends as an orphan `csi-vol-*` subvolume that pins the
snapshot ("snapshot has pending clones", VolumeSnapshots stuck Deleting; 153 of
them from 2024 were cleaned up this way):

```bash
ceph fs subvolume ls cephfs-nvme csi            # compare with kubectl get pv subvolumeName
ceph fs clone status cephfs-nvme <csi-vol> --group_name csi
ceph fs clone cancel cephfs-nvme <csi-vol> --group_name csi   # EINVAL if already complete, fine
ceph fs subvolume rm cephfs-nvme <csi-vol> --group_name csi --force
```

If `snapshot rm` still returns EAGAIN, dangling entries remain in
`/volumes/_index/clone/` and the `[clone snaps]` section of the source
subvolume's `.meta`; mount the fs root from a cephfs nodeplugin pod with the
`csi-cephfs-node` key to remove them.

## Checking backups

```bash
k -n velero get bsl default                                   # Available
k -n velero get backups.velero.io                             # plain "backups" is CNPG's
k -n velero get backups.velero.io <name> -o jsonpath='{.status.phase} {.status.errors} {.status.progress}'
k -n velero get dataupload -l velero.io/backup-name=<name> -o custom-columns=PVC:.spec.sourcePVC,PHASE:.status.phase,DONE:.status.progress.bytesDone,TOTAL:.status.progress.totalBytes
k get volumesnapshot -A; k -n velero get pvc                  # both empty when idle
```

`Completed` is the only good phase; `PartiallyFailed` means at least one PVC is
not in R2. Nothing alerts on failure yet (no PrometheusRule consumer; Alloy's
pod scrape already collects `velero_backup_last_status`, so an alert would be a
Grafana-managed rule). `scripts/velero-watch.sh` prints image versions, BSL
phase and Argo state during a rollout; `scripts/velero-test-backup.sh <ns>`
runs a one-off backup of a namespace and follows its DataUploads.

Kopia maintenance Jobs (`*-kopia-maintain-job-*`) run after backups; Velero keeps
the last 3 per repo. Failed ones right after a repo delete are harmless.

## Restore

Velero never writes into an existing PVC. In-place restore of a corrupted PVC:
scale the workload to 0, delete the PVC, apply a Restore limited to that
namespace/PVC, Velero recreates the PVC with the same name and the node-agent
fills it from R2 (DataDownload), then scale up. Resources that already exist are
skipped, so delete what must be replaced first. Tested: 1 GiB RBD PVC in 45 s.

```yaml
apiVersion: velero.io/v1
kind: Restore
metadata: { name: r1, namespace: velero }
spec: { backupName: daily-2026..., includedNamespaces: [ns], includedResources: [persistentvolumeclaims, persistentvolumes] }
```

## Upgrading Velero

Chart repo https://vmware-tanzu.github.io/helm-charts; the chart pins an
`image.tag`, the aws plugin is an initContainer we pin too. 1.13 -> 1.17 -> 1.18
was done directly because nothing in the old backups was recoverable; otherwise
read the per-minor upgrade notes. Traps hit:
- `configuration.volumeSnapshotLocation` must be `[ ]`; the chart default
  renders a VSL with an empty provider and the manifest build fails.
- `metrics.serviceMonitor/nodeAgentPodMonitor` need `autodetect = false` to
  render under `helm template`; they were then removed again because Alloy's
  generic pod scrape already had the metrics and they doubled the series.
- `credentials.useSecret = false`; the BSL has its own `credential` ref.
- The live Deployment kept a removed initContainer owned by an old
  client-side-apply manager; patch it out (see hfym-cluster-access).
- Argo never prunes: delete old Schedules, VSLs, Secrets and their Vault paths
  by hand after a config change removes them.
