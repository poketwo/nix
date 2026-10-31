---
name: argocd-upgrade
description: Argo CD upgrades via the argo-cd chart in kubernetes/core/argocd.nix (chart-to-app version map, redis-ha and haproxy rollout traps, schema ComparisonError, 3.x breaking changes checked, health-check side effects). Use for any Argo CD or argo-helm change.
---

# Argo CD upgrades

Argo upgrades itself: the `poketwo-argocd` app syncs the new chart ~3 min after
`cluster` rebuilds, full rollout ~9 min (redis-ha-server pods are slowest).
Follow helm-chart-upgrade for the loop. State: chart 10.11.6 = Argo CD 3.5.6
(Oct 2026), `global.networkPolicy.create = false`, redis-ha on, 2 server replicas.

## Hops done, with the one thing each needed

| Chart | Argo CD | Note |
|---|---|---|
| 7.6.12 | 2.12.6 | diff schema is from Argo's own k8s libs (0.29), so apps using newer fields (`appArmorProfile` on cilium) show `ComparisonError: field not declared in schema`. Fix = next minor, not config. |
| 7.7.23 | 2.13.4 | clears the above. |
| 7.9.1 | 2.14.11 | **redis 7.4 -> 7.2 downgrade**: first replica to roll syncs the master's newer RDB and crash-loops (`Can't handle RDB format version`). Delete all three `argocd-redis-ha-server` pods (emptyDir cache); ~1 min of NOREPLICAS logs, then fine. |
| 8.2.7 | 3.0.12 | tracking label -> annotation (resources get it on next sync; no prune, so the orphan edge case is moot). Checked n/a: RBAC policy changes, Dex, repo creds, applyNestedSelectors, `argocd_app_*` metric renames. |
| 9.0.6 | 3.1.9 | chart drops `applicationsetcontroller.policy` default; live config still `sync`, no behavior change. |
| 9.3.7 | 3.2.6 | redis-ha 4.34 adds `component: haproxy` to the haproxy Deployment's **immutable selector** -> sync fails on that one object. `kubectl -n argocd delete deploy argocd-redis-ha-haproxy`; Argo recreates it, but only after the redis StatefulSet (7.2 -> 8.2 here) is healthy, so haproxy was gone ~4 min and controllers logged redis timeouts. |
| 9.5.11 | 3.3.9 | ships a CephCluster health check: `poketwo-rook-ceph` shows Degraded whenever Ceph is HEALTH_WARN. |
| 10.2.2 | 3.4.6 | chart 10 creates NetworkPolicies by default; set `global.networkPolicy.create = false` to keep the namespace as it was (Cilium enforces them; Alloy scrapes from another namespace). |
| 10.11.6 | 3.5.6 | clean. |

## Verify after each hop

```bash
k -n argocd get pods -o jsonpath='{range .items[*]}{.metadata.name} {range .spec.containers[*]}{.image} {end}{"\n"}{end}'
k -n argocd get sts argocd-redis-ha-server -o jsonpath='ready={.status.readyReplicas} updated={.status.updatedReplicas}'
k -n argocd get app -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status | sort | uniq -c -f1
```

Check every container image, not `containers[0]` (the redis trap hid there).
Compare the Synced/OutOfSync counts before and after; better diffing in newer
Argo lowers chronic OutOfSync (26 -> 10 at 2.12, 9 -> 6 at 3.0) but a rise
means something. Known Degraded apps unrelated to Argo: `oliver-ni-bmt-auth`,
`oliver-ni-icmt-discord-bot`, `poketwo-rook-ceph` (Ceph warnings).

## Drift Argo surfaced

Immutable fields that differ between source and live make an app fail to sync
forever (mimir's StatefulSet `volumeClaimTemplates` 500Mi/2Gi in nix vs 20Gi/50Gi
live since 2024). Fix the source to match live rather than recreating the
StatefulSet.
