#!/usr/bin/env bash
# Watch a Rook operator hop until all 25 rook_cluster deployments run the target.
# usage: ssh -i ~/.ssh/poketwo devin@turtwig.hfym.co 'bash -s -- v1.20.9' < watch-rook.sh
export KUBECONFIG=/etc/kubernetes/admin.conf
k() { sudo -E kubectl "$@"; }
C="--conf=/var/lib/rook/rook-ceph/rook-ceph.config --keyring=/var/lib/rook/rook-ceph/client.admin.keyring"
TARGET="$1"
for i in $(seq 1 40)  # ~30 min; do
  REV=$(k -n argocd get app poketwo-rook-ceph -o jsonpath='{.status.sync.status}/{.status.operationState.phase}')
  OP=$(k -n rook-ceph get deploy rook-ceph-operator -o jsonpath='{.spec.template.spec.containers[0].image}' | sed 's|.*:||')
  VERS=$(k -n rook-ceph get deploy -l rook_cluster=rook-ceph -o jsonpath='{range .items[*]}{.metadata.labels.rook-version}{"\n"}{end}' | sort | uniq -c | tr -s ' \n' ' ')
  POD=$(k -n rook-ceph get pod -l app=rook-ceph-operator --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  ST=$(k -n rook-ceph exec $POD -- ceph $C status 2>/dev/null | grep -E 'health:|osd:|pgs:' | sed 's/^ *//; s/  */ /g' | tr '\n' '|')
  BAD=$(k -n rook-ceph get pods --no-headers | grep -v -E 'Running|Completed' | awk '{print $1":"$3}' | tr '\n' ' ')
  echo "$(date -u +%H:%M:%S) argo=$REV op=$OP vers=[$VERS] $ST pods=[$BAD]"
  k -n rook-ceph exec $POD -- ceph $C health detail 2>/dev/null | grep '^\[' | grep -vE 'MON_DISK_LOW|RECENT_CRASH|PG_DEGRADED|OSD_DOWN|OSD_HOST_DOWN|MDS_INSUFFICIENT_STANDBY'
  if [ "$VERS" = " 25 $TARGET " ] && echo "$ST" | grep -q '617 active+clean' && echo "$ST" | grep -q '7 up'; then echo DONE; break; fi
  sleep 45
done
k -n rook-ceph exec $POD -- ceph $C health detail 2>/dev/null
k -n rook-ceph exec $POD -- ceph $C crash ls-new 2>/dev/null | tail -2
