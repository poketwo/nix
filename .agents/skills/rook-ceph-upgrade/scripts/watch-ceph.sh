#!/usr/bin/env bash
# Watch a Ceph image hop (and CephX daemon key rotation) until every daemon runs the target.
# usage: ssh -i ~/.ssh/poketwo devin@turtwig.hfym.co 'bash -s -- 19.2.7' < watch-ceph.sh   (no leading v)
T=$1
export KUBECONFIG=/etc/kubernetes/admin.conf
k() { sudo -E kubectl "$@"; }
C="--conf=/var/lib/rook/rook-ceph/rook-ceph.config --keyring=/var/lib/rook/rook-ceph/client.admin.keyring"
for i in $(seq 1 80); do
  POD=$(k -n rook-ceph get pod -l app=rook-ceph-operator --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  img=$(k -n rook-ceph get cephcluster rook-ceph -o jsonpath='{.spec.cephVersion.image}' | sed 's#.*:##')
  cv=$(k -n rook-ceph get deploy -l rook_cluster=rook-ceph -o jsonpath='{range .items[*]}{.metadata.labels.ceph-version}{"\n"}{end}' | sed 's/-.*//' | sort | uniq -c | tr -s ' \n' ' ')
  st=$(k -n rook-ceph exec $POD -- ceph $C status 2>/dev/null | grep -E 'health:|mon:|mds:|osd:|pgs:' | tr -s ' ' | tr '\n' '|')
  cx=$(k -n rook-ceph get cephcluster rook-ceph -o jsonpath='{.status.cephx.mon.keyGeneration}/{.status.cephx.mon.keyType} osd={.status.cephx.osd.keyGeneration}/{.status.cephx.osd.keyType} mgr={.status.cephx.mgr.keyGeneration}/{.status.cephx.mgr.keyType} admin={.status.cephx.admin.keyGeneration}/{.status.cephx.admin.keyType}')
  fs=$(k -n rook-ceph get cephfilesystem cephfs-nvme -o jsonpath='{.status.cephx.daemon.keyGeneration}/{.status.cephx.daemon.keyType}')
  rgw=$(k -n rook-ceph get cephobjectstore rgw-nvme -o jsonpath='{.status.cephx.daemon.keyGeneration}/{.status.cephx.daemon.keyType}')
  ph=$(k -n rook-ceph get cephcluster rook-ceph -o jsonpath='{.status.phase}/{.status.message}')
  pods=$(k -n rook-ceph get pods --no-headers 2>/dev/null | grep -vE 'Running|Completed' | awk '{print $1":"$3}' | tr '\n' ' ')
  echo "$(date +%T) img=$img cv=[$cv] $st cephx mon=$cx fs=$fs rgw=$rgw pods=[$pods] $ph"
  if [[ "$cv" == " 25 $T " && "$st" == *"617 active+clean"* && "$st" == *"7 up"* && "$st" == *"quorum d,k,l"* && "$st" == *"hot standby"* && "$cx" == 1/aes256k* && "$fs" == 1/aes256k && "$ph" == Ready* ]]; then echo DONE; break; fi
  sleep 45
done
k -n rook-ceph exec $POD -- ceph $C health detail 2>/dev/null | head -20
k -n rook-ceph exec $POD -- ceph $C versions 2>/dev/null | grep -A1 overall
k -n rook-ceph exec $POD -- ceph $C crash ls-new 2>/dev/null | tail -3
k -n rook-ceph get cephcluster rook-ceph -o jsonpath='{.status.cephx}{"\n"}'
