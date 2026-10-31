---
name: kubernetes-upgrade
description: Plan and constraints for upgrading Kubernetes itself on hfym-ds (kubeadm on NixOS, nixpkgs-k8s pin, control-plane then worker rounds, per-minor gotchas 1.32-1.35, component support matrix). Use when bumping kubernetesVersion / nixpkgs-k8s or planning a kube minor hop. Status: planned, not yet executed; update this file as hops land.
---

# Kubernetes upgrade (1.31.2 -> 1.35)

Status 2026-10-31: all 8 nodes kubeadm/kubelet/CRI-O 1.31.2, etcd 3.5.15.
Prerequisite component upgrades are done; Rook 1.21 and cert-manager 1.20 are
waiting on Kubernetes 1.32. **No kube hop has been executed yet**; this is the
researched plan. Ask Oliver before the first deploy and record what actually
happened here.

## Where the version lives

- `flake.nix` input `nixpkgs-k8s` pins the nixpkgs commit that provides
  kubernetes and cri-o. They do not always move together, so pick commits where
  both match (verified 2026-10-31 by reading `version =` at each commit;
  kubernetes moved to `pkgs/by-name/ku/kubernetes/package.nix` in 2025-07, cri-o
  stayed at `pkgs/applications/virtualization/cri-o/default.nix` until 2026-05):

  | Hop | nixpkgs commit | kubernetes | cri-o |
  |---|---|---|---|
  | current | `882842d2a908700540d206baa79efb922ac1c33d` | 1.31.2 | 1.31.2 |
  | 1.32 | `550b72055340` | 1.32.3 | 1.32.0 |
  | 1.33 | `4acc7f1d238d` | 1.33.4 | 1.33.3 |
  | 1.34 | `e9258e24d7ba` | 1.34.3 | 1.34.3 |
  | 1.35 | `4aba42448195` (or `917a7562e399` for 1.35.4) | 1.35.2 | 1.35.0 |

  `gh api 'repos/NixOS/nixpkgs/commits?path=<file>&per_page=60'` lists the bump
  commits per path if these need refreshing.
- `modules/poketwo/kubernetes.nix`: kubeadm config (still `kubeadm.k8s.io/v1beta3`;
  move to `v1beta4`, where extraArgs become `[{name, value}]` lists), kubelet
  config, CRI-O, firewall ports.
- One PR per minor: bump the pin (and `flake.lock`), `kubernetesVersion`, and
  anything the minor requires below.

## Order per hop

1. Control plane first, turtwig: run the new kubeadm from the nix store
   (`kubeadm upgrade plan`, `kubeadm upgrade apply vX.Y.Z`), then chimchar and
   piplup (`kubeadm upgrade node`). `upgrade apply` also renews the control-plane
   certs (expire 2027-03-25).
2. Deploy the hosts with the new kubelet/CRI-O. **Build on the dev box, never on
   a control plane**: turtwig/chimchar/piplup are 4 GB / 2 CPU Linodes and just
   evaluating the flake there hung turtwig for 35 min (kubelet NotReady, sshd
   dead, etcd member down) on 2026-10-31. Instead:
   ```bash
   # dev box (Determinate Nix: curl -sSfL https://install.determinate.systems/nix | sh -s -- install linux --no-confirm --init none)
   OUT=$(nix build --no-link --print-out-paths .#nixosConfigurations.<host>.config.system.build.toplevel)   # ~1 min from cache
   nix copy --to ssh://devin@<host>.hfym.co "$OUT"
   ssh devin@<host>.hfym.co "sudo $OUT/bin/switch-to-configuration switch && sudo nix-env -p /nix/var/nix/profiles/system --set $OUT"
   ```
   Activate first, set the system profile only after `switch` succeeded: a
   refused switch (kernel/dbus change) must not leave an untested generation as
   the boot default. For a reboot deploy do it the other way round, like
   `nixos-rebuild boot`: `nix-env --set` first, then
   `switch-to-configuration boot` (the bootloader installer reads the profile),
   verify the default entry (`bootctl list` on the systemd-boot workers,
   `grep -m1 menuentry /boot/grub/grub.cfg` on the GRUB control planes), reboot.
   After a control-plane reboot, if the node stays NotReady for >2 min with
   `lookup ds.hfym.co: Temporary failure in name resolution` in the kubelet log
   and no IPv6 reachability from inet0, `sudo networkctl reconfigure inet0`
   brought piplup back immediately (2026-10-31; chimchar and turtwig did not
   need it).
   `switch` restarts kubelet and CRI-O and both keep containers running, so a
   hop should need no drain. Try it on one worker first; if the CRI-O restart
   misbehaves, fall back to the cordon/drain/reboot procedure in AGENTS.md
   "Rolling a worker" (one worker at a time; prod Mongo local volumes and
   single-instance CNPG PDBs need the special handling described there).
3. Kubelets may lag the API server by up to 3 minors, so workers can skip hops:
   control plane 1.32 -> 1.33 -> 1.34 with workers on 1.31, roll workers to 1.34,
   then 1.35 everywhere. Simpler and safer is to deploy every node every hop.
4. All three control planes were reboot-deployed on 2026-10-31 (kernel 6.18,
   ~3.5 min each, etcd at 2/3 meanwhile, all API endpoints back within a
   minute of Ready). When a control plane needs a reboot deploy, use the same
   local build + `nix copy` + `switch-to-configuration boot` from step 2; do
   not run `nixos-rebuild --build-host <control-plane>` on them.
5. Verify: `kubectl get nodes` versions, `kubectl -n kube-system get pods`,
   Cilium `cilium status` on a node, Ceph baseline, Argo apps Synced, a PVC smoke
   test (rook-ceph-upgrade `csi-check.sh`).

## Per-minor gotchas that apply here

- **1.32**: `flowcontrol.apiserver.k8s.io/v1beta3` gone (only kubeadm-default
  FlowSchemas exist). Kubelet systemd watchdog available.
- **1.33**: `ReduceDefaultCrashLoopBackOffDecay` gate worth enabling for bot pods.
- **1.34**: kubeadm moves etcd to 3.6, which requires every member on
  >= 3.5.32 first (kubeadm 1.33 only brings 3.5.24): pin `etcd.local.imageTag`
  to 3.5.32+ during the 1.33 hop, or run `etcdutl check v2store` before 1.34.
  API-server metric labels change (`type` -> `group`/`resource`): Grafana
  dashboards need edits. `cgroupDriver` can leave KubeletConfiguration.
- **1.35**: kubelet flag `--pod-infra-container-image` is removed, and
  `/var/lib/kubelet/kubeadm-flags.env` on every node still carries it (kubeadm
  only writes that file on init/join). Delete it from the file on all 8 nodes
  before the 1.35 kubelet starts or kubelet will not start. cgroup v1 refused
  (nodes are cgroup2). `KubeletEnsureSecretPulledImages` on by default: pods
  pulling private ghcr images with `IfNotPresent` now need the pull secret even
  when cached.
- Nothing else deprecated is in use: no kube-proxy (Cilium KPR), IPv6-only,
  swap off, only `cilium.io/v2alpha1` on the deprecated-API list.

## Component support for the target

Cilium 1.19 (k8s 1.32-1.35), Rook 1.20 (1.31-1.36) -> 1.21 after 1.32,
cert-manager 1.19 (<= 1.31) -> 1.20 after 1.32, Velero 1.18 (1.33-1.35 tested),
Argo CD 3.5, MetalLB 0.14, CNPG 0.21 (old; upgrade separately). Cilium 1.20
is needed before any 1.36. ingress-nginx is archived upstream and needs a
replacement decision independent of this.
