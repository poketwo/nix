{ ... }:

let
  # GitHub's SSH host keys, from https://api.github.com/meta
  githubKnownHosts = ''
    github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
    github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
    github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
  '';
in
{
  # Feature flags: flagd serving flags.yaml from github.com/poketwo/flags. A git-sync
  # sidecar pulls the repo every 5 s and flagd picks up the new file on its own.
  # Clients stream the flag set from the sync port (8015) and evaluate in-process.
  namespaces.poketwo = {
    resources."apps/v1".Deployment.flagd.spec = {
      replicas = 3;
      selector.matchLabels.app = "flagd";
      template = {
        metadata.labels.app = "flagd";
        spec = {
          initContainers.git-sync = {
            image = "registry.k8s.io/git-sync/git-sync:v4.8.0";
            # native sidecar: flagd starts once the first sync has passed the startup probe
            restartPolicy = "Always";
            args = [
              "--repo=git@github.com:poketwo/flags.git"
              "--ref=main"
              "--root=/git"
              "--link=flags"
              "--period=5s"
              "--depth=1"
              "--max-failures=-1"
              "--ssh-key-file=/etc/git-secret/ssh"
              "--ssh-known-hosts-file=/etc/git-known-hosts/known_hosts"
              "--http-bind=:8080"
              "--http-metrics"
              # /git is the emptyDir root, owned by root rather than git-sync's 65533
              "--git-config=safe.directory:/git"
            ];
            ports = [{ name = "http-monitoring"; containerPort = 8080; }];
            startupProbe = {
              httpGet = { path = "/"; port = "http-monitoring"; };
              periodSeconds = 2;
              failureThreshold = 60;
            };
            resources = {
              requests = { memory = "32Mi"; cpu = "10m"; };
              limits = { memory = "256Mi"; };
            };
            volumeMounts = [
              { name = "flags"; mountPath = "/git"; }
              { name = "git-secret"; mountPath = "/etc/git-secret"; readOnly = true; }
              { name = "git-known-hosts"; mountPath = "/etc/git-known-hosts"; readOnly = true; }
            ];
          };
          containers.flagd = {
            image = "ghcr.io/open-feature/flagd:v0.18.2";
            args = [ "start" "--uri" "file:/git/flags/flags.yaml" "--log-format" "json" ];
            ports = [
              { name = "flagd"; containerPort = 8013; }
              { name = "metrics"; containerPort = 8014; }
              { name = "sync"; containerPort = 8015; }
              { name = "ofrep"; containerPort = 8016; }
            ];
            livenessProbe = {
              httpGet = { path = "/healthz"; port = "metrics"; };
              periodSeconds = 10;
            };
            readinessProbe = {
              httpGet = { path = "/readyz"; port = "metrics"; };
              periodSeconds = 5;
            };
            resources = {
              requests = { memory = "32Mi"; cpu = "50m"; };
              limits = { memory = "256Mi"; };
            };
            volumeMounts = [{ name = "flags"; mountPath = "/git"; readOnly = true; }];
          };
          volumes = {
            flags.emptyDir = { };
            git-secret.secret = { secretName = "flagd"; defaultMode = 288; }; # 0440
            git-known-hosts.configMap.name = "flagd-known-hosts";
          };
          # git-sync runs as 65533 and needs the deploy key and /git to be group-accessible
          securityContext.fsGroup = 65533;
          # one replica per node, so losing a node never takes out more than one
          affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution = [{
            labelSelector.matchLabels.app = "flagd";
            topologyKey = "kubernetes.io/hostname";
          }];
        };
      };
    };

    resources."policy/v1".PodDisruptionBudget.flagd.spec = {
      maxUnavailable = 1;
      selector.matchLabels.app = "flagd";
    };

    resources.v1.Service.flagd.spec = {
      selector.app = "flagd";
      ports = [
        { name = "flagd"; port = 8013; targetPort = "flagd"; }
        { name = "sync"; port = 8015; targetPort = "sync"; }
        { name = "ofrep"; port = 8016; targetPort = "ofrep"; }
      ];
    };

    resources.v1.ConfigMap.flagd-known-hosts.data.known_hosts = githubKnownHosts;

    # Read-only deploy key for github.com/poketwo/flags
    resources.v1.Secret.flagd.stringData = {
      ssh = "";
    };
  };
}
