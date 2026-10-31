#!/usr/bin/env bash
# One-off backup of a namespace, following its DataUploads to completion and checking nothing is left behind.
# usage: ssh -i ~/.ssh/poketwo devin@turtwig.hfym.co 'bash -s -- <namespace>' < velero-test-backup.sh
export KUBECONFIG=/etc/kubernetes/admin.conf
k() { sudo -E kubectl "$@"; }
NS="$1"; NAME="test-$NS-$(date -u +%m%d%H%M)"
k apply -f - <<Y
apiVersion: velero.io/v1
kind: Backup
metadata: {name: $NAME, namespace: velero}
spec: {includedNamespaces: [$NS], snapshotMoveData: true, ttl: 24h, storageLocation: default}
Y
T0=$(date +%s)
for i in $(seq 1 240); do
  sleep 30
  P=$(k -n velero get backups.velero.io $NAME -o jsonpath='{.status.phase}')
  echo "t+$(( $(date +%s)-T0 ))s backup=$P | $(k -n velero get dataupload -l velero.io/backup-name=$NAME -o custom-columns=PVC:.spec.sourcePVC,PHASE:.status.phase,DONE:.status.progress.bytesDone,TOTAL:.status.progress.totalBytes --no-headers 2>/dev/null | tr -s ' ' | tr '\n' ';')"
  case "$P" in Completed|PartiallyFailed|Failed) break;; esac
done
k -n velero get backups.velero.io $NAME -o jsonpath='errors={.status.errors} warnings={.status.warnings} items={.status.progress.itemsBackedUp}/{.status.progress.totalItems}{"\n"}'
k -n velero get dataupload -l velero.io/backup-name=$NAME -o jsonpath='{range .items[*]}{.spec.sourcePVC} {.status.phase} {.status.message}{"\n"}{end}'
echo "leftover backup PVCs: $(k -n velero get pvc --no-headers 2>/dev/null | wc -l), VolumeSnapshots: $(k get volumesnapshot -A --no-headers 2>/dev/null | wc -l)"
