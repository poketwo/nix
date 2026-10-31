#!/usr/bin/env bash
# After a CSI-affecting hop: Driver CRs keep the NixOS mounts, plugin DaemonSets ready, 1 GiB RBD PVC smoke test.
# usage: ssh -i ~/.ssh/poketwo devin@turtwig.hfym.co 'bash -s' < csi-check.sh
export KUBECONFIG=/etc/kubernetes/admin.conf
k() { sudo -E kubectl "$@"; }
echo "== csi operator / drivers"
k -n rook-ceph get deploy | grep -iE 'csi' 
k -n rook-ceph get drivers.csi.ceph.io,operatorconfigs.csi.ceph.io,cephconnections.csi.ceph.io 2>&1 | head
echo "== driver CR nodePlugin volumes"
for d in $(k -n rook-ceph get drivers.csi.ceph.io -o name 2>/dev/null); do echo "$d:"; k -n rook-ceph get $d -o jsonpath='{range .spec.nodePlugin.volumes[*]}{.volume.name}{" "}{.volume.hostPath.path}{" mount="}{.mount.mountPath}{" ro="}{.mount.readOnly}{"\n"}{end}'; done
echo "== live plugin pod mounts (one per ds)"
for drv in rbd cephfs; do ds=rook-ceph.$drv.csi.ceph.com-nodeplugin; c=csi-${drv}plugin; P=$(k -n rook-ceph get pod -l app=$ds -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); echo "$ds/$P:"; k -n rook-ceph get pod $P -o jsonpath='{range .spec.volumes[*]}{.name}={.hostPath.path}{"\n"}{end}' | grep -E 'nix|lib-modules'; k -n rook-ceph get pod $P -o jsonpath="{range .spec.containers[?(@.name=='$c')].volumeMounts[*]}{.name}:{.mountPath}:{.readOnly}{\"\n\"}{end}" | grep -E 'nix|lib-modules'; done
echo "== ds status"; k -n rook-ceph get ds
echo "== PVC mount smoke test"
k -n rook-ceph delete pod csi-smoke --ignore-not-found >/dev/null 2>&1; k -n rook-ceph delete pvc csi-smoke --ignore-not-found >/dev/null 2>&1
SC=rbd-nvme  # reclaimPolicy Delete, so the smoke PV does not linger (rbd-nvme-retain would)
cat <<Y | k apply -f - >/dev/null
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: csi-smoke, namespace: rook-ceph}
spec: {accessModes: [ReadWriteOnce], storageClassName: $SC, resources: {requests: {storage: 1Gi}}}
---
apiVersion: v1
kind: Pod
metadata: {name: csi-smoke, namespace: rook-ceph}
spec:
  restartPolicy: Never
  containers: [{name: t, image: busybox, command: ["sh","-c","echo ok > /d/f && cat /d/f"], volumeMounts: [{name: d, mountPath: /d}]}]
  volumes: [{name: d, persistentVolumeClaim: {claimName: csi-smoke}}]
Y
if k -n rook-ceph wait --for=jsonpath='{.status.phase}'=Succeeded pod/csi-smoke --timeout=180s && [ "$(k -n rook-ceph logs csi-smoke)" = ok ]; then RC=0; echo "SMOKE OK"; else RC=1; echo "SMOKE FAILED"; k -n rook-ceph describe pod csi-smoke | tail -15; fi
k -n rook-ceph delete pod/csi-smoke pvc/csi-smoke --wait=false >/dev/null
exit $RC
