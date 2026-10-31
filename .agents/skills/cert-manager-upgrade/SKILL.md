---
name: cert-manager-upgrade
description: cert-manager chart upgrades in kubernetes/core/cert-manager.nix, one minor per PR, with the rollout/issuer/certificate watch and self-signed smoke test. Use for any cert-manager version change.
---

# cert-manager upgrades

Upstream requires one minor per hop. Done 1.14.5 -> 1.15.5 -> 1.16.5 -> 1.17.4
-> 1.18.6 -> 1.19.6 in Oct 2026, ~8 min each. **1.19 is the last minor that
supports Kubernetes 1.31; 1.20 needs 1.32**, so the next hop waits for the kube
upgrade. Follow helm-chart-upgrade for the PR loop.

- Chart repo https://charts.jetstack.io, tarballs `cert-manager-v1.X.Y.tgz`.
- Values used: `installCRDs = true` (still accepted through 1.19; new name is
  `crds.enabled`), `global.leaderElection.namespace`, `prometheus.enabled`.
  1.16 added values schema validation; these keys pass.
- Three ClusterIssuers (`letsencrypt`, staging, `selfsigned`) use DNS-01 via the
  Cloudflare token secret.
- Watch + smoke test: `ssh ... 'bash -s -- v1.19.6' < scripts/watch-cert-manager.sh`
  prints DONE when the 3 pods run the target, issuers are Ready and no pod is
  unhealthy, then issues and deletes a self-signed Certificate and lists any
  Certificate not Ready.
- Pre-existing, not an upgrade regression: `bmt/constellation-tls` is not Ready
  because it references a non-existent issuer `letsencrypt-prod`; the Argo app
  was already OutOfSync on 4 Deployments + 2 webhooks (drift, not prune).
