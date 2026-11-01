#!/usr/bin/env bash
# Watch a Velero rollout: pod images, BSL phase, Argo state. usage: ssh ... 'bash -s -- v1.18.4' < velero-watch.sh
export KUBECONFIG=/etc/kubernetes/admin.conf
k() { sudo -E kubectl "$@"; }
TARGET="$1"
for i in $(seq 1 60); do
  img=$(k -n velero get pods -l '!batch.kubernetes.io/job-name' -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}' | sort | uniq -c | tr -s ' \n' ' ')
  bsl=$(k -n velero get bsl default -o jsonpath='{.status.phase}')
  argo=$(k -n argocd get app poketwo-velero -o jsonpath='{.status.sync.status}/{.status.health.status}/{.status.operationState.phase}')
  echo "$(date -u +%T) argo=$argo imgs=[$img] bsl=$bsl"
  if [ "$(echo "$img" | grep -o 'velero:v[0-9.]*' | sort -u)" = "velero:$TARGET" ] && [ "$bsl" = Available ]; then echo DONE; break; fi
  sleep 30
done
k -n velero get pods -l '!batch.kubernetes.io/job-name' --no-headers | awk '{print $1,$2,$3,$4}'
k -n velero get bsl default -o jsonpath='{.status.message}'; echo
