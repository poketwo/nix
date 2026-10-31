#!/usr/bin/env bash
# Watch a cert-manager hop, then run a self-signed Certificate smoke test.
# usage: ssh -i ~/.ssh/poketwo devin@turtwig.hfym.co 'bash -s -- v1.19.6' < watch-cert-manager.sh
export KUBECONFIG=/etc/kubernetes/admin.conf
k() { sudo -E kubectl "$@"; }
TARGET="$1"
for i in $(seq 1 30); do
  SY=$(k -n argocd get app poketwo-cert-manager -o jsonpath='{.status.sync.status}/{.status.health.status}/{.status.operationState.phase}')
  IMGS=$(k -n cert-manager get pod -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}' | grep cert-manager | sed 's|.*:||' | sort | uniq -c | tr -s ' \n' ' ')
  BAD=$(k -n cert-manager get pod -o jsonpath='{range .items[*]}{.metadata.name} {.status.phase} {range .status.containerStatuses[*]}{.ready}{end}{"\n"}{end}' | awk '!($2=="Running" && $3 ~ /^(true)+$/) && $2!="Succeeded" {print $1":"$2":"$3}' | tr '\n' ' ')
  NR=$(k get certificate -A -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' | grep -c -v True)
  ISS=$(k get clusterissuer -o jsonpath='{range .items[*]}{.metadata.name}={.status.conditions[?(@.type=="Ready")].status}{" "}{end}')
  NOTREADY_ISS=$(echo "$ISS" | tr ' ' '\n' | grep -v '^$' | grep -vc '=True$')
  echo "$(date -u +%H:%M:%S) argo=$SY imgs=[$IMGS] notReadyCerts=$NR issuers=$ISS pods=[$BAD]"
  if [ "$IMGS" = " 3 $TARGET " ] && [ -z "$BAD" ] && [ -n "$ISS" ] && [ "$NOTREADY_ISS" = 0 ]; then echo DONE; break; fi
  sleep 30
done
echo "--- smoke: selfsigned cert"
cat <<'Y' | k apply -f - >/dev/null
apiVersion: cert-manager.io/v1
kind: Certificate
metadata: { name: devin-smoke, namespace: default }
spec: { secretName: devin-smoke-tls, commonName: devin-smoke.test, issuerRef: { name: selfsigned, kind: ClusterIssuer } }
Y
for i in $(seq 1 20); do R=$(k -n default get certificate devin-smoke -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'); [ "$R" = True ] && break; sleep 3; done
echo "smoke cert ready=$R"; k -n default delete certificate devin-smoke >/dev/null; k -n default delete secret devin-smoke-tls >/dev/null 2>&1
k get certificate -A -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name} {.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' | grep -v True$ || echo "all certs Ready"
