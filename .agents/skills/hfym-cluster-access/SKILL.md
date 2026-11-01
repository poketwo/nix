---
name: hfym-cluster-access
description: How to run kubectl and ceph against the live hfym-ds cluster from a dev box (SSH to turtwig, admin kubeconfig, ceph via the Rook operator pod, Vault writes). Use before any live check, rollout watch or cleanup in this repo.
---

# Live access to the hfym-ds cluster

## kubectl

There is no kubeconfig on the dev box. Run kubectl on a control-plane node over SSH:

```bash
ssh -o StrictHostKeyChecking=accept-new -i ~/.ssh/poketwo devin@turtwig.hfym.co \
  'sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl get nodes'
```

For anything longer than one command, write a script locally and pipe it in. The
hosts' login shell is zsh, so always run it through bash:

```bash
cat > /tmp/check.sh <<'EOF2'
export KUBECONFIG=/etc/kubernetes/admin.conf
k() { sudo -E kubectl "$@"; }
k -n argocd get app
EOF2
ssh -i ~/.ssh/poketwo devin@turtwig.hfym.co 'bash -s -- arg1' < /tmp/check.sh
```

Hosts: turtwig, chimchar, piplup (control plane, Linode), vaporeon, jolteon,
flareon, glaceon, sylveon (workers). All reachable as `<host>.hfym.co`, `devin`
has passwordless sudo. turtwig has no python3; do text processing locally.

Gotchas:
- `kubectl get backup` resolves to CNPG's `backups.postgresql.cnpg.io`. Velero
  objects need the full name: `kubectl -n velero get backups.velero.io`.
- `kubectl` short names for Argo apps work (`get app -n argocd`).

## Argo CD

Every app comes from `applicationset.yaml` with `automated: {}`: auto-sync ON,
prune OFF, selfHeal OFF. Consequences:
- A merge to `main` rolls out on its own ~3 min after CI pushes `cluster`.
- Objects a chart stops rendering stay live. Delete them by hand, one plain
  `kubectl delete <kind> <name>` each. A one-off prune of a whole app is
  `kubectl -n argocd patch app <app> --type merge -p '{"operation":{"sync":{"prune":true,"syncOptions":["CreateNamespace=true","ServerSideApply=true"]}}}'`;
  `syncOptions` in the operation REPLACES the app's own, and omitting
  `ServerSideApply=true` falls back to client-side apply, which fails on big CRDs
  and re-applies CRs (it rolled the CSI pods once). Always copy them in.
- Server-side apply does not remove list items (e.g. a Deployment initContainer)
  still owned by an older `kubectl-client-side-apply` manager. If a removed item
  survives a sync, check `--show-managed-fields` and `kubectl patch --type=json` it out.
- Fields set live but not rendered (a Schedule's `paused`) are never reverted.

## Ceph CLI

There is no rook-ceph-tools pod. Use the operator pod with the explicit config:

```bash
kubectl -n rook-ceph exec deploy/rook-ceph-operator -- ceph \
  --conf=/var/lib/rook/rook-ceph/rook-ceph.config \
  --keyring=/var/lib/rook/rook-ceph/client.admin.keyring status
```

Useful: `status`, `health detail`, `versions`, `osd dump | grep require_osd_release`,
`crash ls-new`, `fs subvolume ls cephfs-nvme csi`, `fs clone status cephfs-nvme <clone> --group_name csi`.

Baseline when healthy: 3 mons (quorum d,k,l), 7 OSDs up (ids 0 2 3 4 6 7 8 on
vaporeon/jolteon/flareon), MDS `1/1 daemons up, 1 hot standby`, 617 PGs
active+clean. Pools are size 2 / min_size 1, so one OSD restarting keeps I/O
flowing with one copy live.

Known warnings that are not incidents: `AUTH_INSECURE_*` (CSI client keys are
still `aes`; AES256K CSI keys need kernel 7.0), old osd.2/osd.8 crash records
(`ceph crash archive-all` clears RECENT_CRASH), `MON_DISK_LOW` on mon d means
vaporeon's `/var` ZFS dataset (181 GB, CRI-O images) is filling.

## Vault secrets

Kubernetes Secrets rendered by the repo become VaultStaticSecrets at
`hfym-ds/<namespace>/<secret-name>` (see `kubernetes/extras/vault-secrets.nix`).
A new secret only needs an empty `resources.v1.Secret.<name>` in the nix file
plus the value written to Vault with curl (Python urllib gets 403):

```bash
curl -sS -H "X-Vault-Token: $VAULT_TOKEN" -X POST \
  https://vault.hfym.co/v1/hfym-ds/data/<ns>/<name> -d '{"data":{"<key>":"..."}}'
```

Vault is single-node raft and needs a manual unseal from Oliver after every pod
restart (node reboots); a sealed Vault shows up as ingress 503s.
