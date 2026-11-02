# Grafana-provisioned infra alerts, routed to a Discord webhook kept in the
# grafana-alerts secret. Rules are file-provisioned, so they are read-only in
# the UI; edit them here.
{ lib, ... }:

let
  # Provisioned datasources without a uid get one derived from their name.
  mimir = "PAE45454D0EDB9216";
  receiver = "Infra alerts";

  # kube-state-metrics is scraped as a pod, so the object's namespace lands in
  # exported_namespace. Only alert on namespaces we run.
  ourNamespaces = lib.concatStringsSep "|" [
    "alloy"
    "argocd"
    "cert-manager"
    "cilium"
    "cloudnative-pg"
    "external-dns"
    "grafana"
    "guiduck"
    "ingress-nginx"
    "keycloak"
    "kube-system"
    "loki"
    "metallb"
    "metrics-server"
    "mimir"
    "mongodb-operator"
    "outline"
    "poketwo"
    "prometheus"
    "rabbitmq-operator"
    "rook-ceph"
    "snapshot-controller"
    "tailscale"
    "vault"
    "vault-secrets-operator"
    "velero"
  ];

  rule = { uid, title, expr, op ? "gt", threshold ? 0, for ? "5m", summary, severity ? "warning" }: {
    inherit uid title for;
    condition = "B";
    data = [
      {
        refId = "A";
        relativeTimeRange = { from = 600; to = 0; };
        datasourceUid = mimir;
        model = { refId = "A"; inherit expr; instant = true; };
      }
      {
        refId = "B";
        datasourceUid = "__expr__";
        model = {
          refId = "B";
          type = "threshold";
          expression = "A";
          conditions = [{ evaluator = { type = op; params = [ threshold ]; }; }];
        };
      }
    ];
    noDataState = "OK";
    execErrState = "Error";
    labels.severity = severity;
    # The chart runs these values through tpl; a raw string keeps Grafana's {{ }} intact.
    annotations.summary = "{{`" + summary + "`}}";
    notification_settings.receiver = receiver;
  };
in
{
  namespaces.grafana.helmReleases.grafana.values.alerting = {
    "contactpoints.yaml" = {
      apiVersion = 1;
      contactPoints = [{
        orgId = 1;
        name = receiver;
        receivers = [{
          uid = "infra-discord";
          type = "discord";
          settings = {
            url = "$__env{DISCORD_ALERTS_WEBHOOK_URL}";
            use_discord_username = true;
          };
        }];
      }];
    };

    "rules.yaml" = {
      apiVersion = 1;
      groups = [{
        orgId = 1;
        name = "infra";
        folder = "Infra";
        interval = "1m";
        rules = [
          (rule {
            uid = "infra-node-not-ready";
            title = "Node not ready";
            expr = ''1 - max by (node) (kube_node_status_condition{condition="Ready",status="true"})'';
            summary = "{{ $labels.node }} has been NotReady for 5m";
            severity = "critical";
          })
          (rule {
            uid = "infra-reachability";
            title = "Reachability probe failing";
            # Majority of probers failing = the target/path is down, not one node.
            expr = ''1 - avg by (job) (probe_success{job=~"integrations/blackbox/.*"})'';
            threshold = 0.5;
            for = "2m";
            summary = "{{ $labels.job }} is failing from most probers";
            severity = "critical";
          })
          (rule {
            uid = "infra-crashloop";
            title = "Container crashlooping";
            expr = ''max by (exported_namespace, exported_pod, exported_container) (kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff",exported_namespace=~"${ourNamespaces}"})'';
            for = "15m";
            summary = "{{ $labels.exported_namespace }}/{{ $labels.exported_pod }} ({{ $labels.exported_container }}) is in CrashLoopBackOff";
          })
          (rule {
            uid = "infra-deployment-unavailable";
            title = "Deployment replicas unavailable";
            expr = ''max by (exported_namespace, deployment) (kube_deployment_status_replicas_unavailable{exported_namespace=~"${ourNamespaces}"})'';
            for = "30m";
            summary = "{{ $labels.exported_namespace }}/{{ $labels.deployment }} has {{ $values.A }} unavailable replicas";
          })
          (rule {
            uid = "infra-host-disk";
            title = "Host filesystem almost full";
            expr = ''1 - max by (node, mountpoint) (node_filesystem_avail_bytes{fstype!~"tmpfs|overlay|squashfs|ramfs|nsfs"} / node_filesystem_size_bytes)'';
            threshold = 0.9;
            for = "15m";
            summary = "{{ $labels.node }}:{{ $labels.mountpoint }} is over 90% full";
          })
          (rule {
            uid = "infra-ceph-health";
            title = "Ceph HEALTH_ERR";
            # 0 = OK, 1 = WARN, 2 = ERR. WARN is common enough to be noise.
            expr = "max(ceph_health_status)";
            threshold = 1;
            summary = "Ceph reports HEALTH_ERR";
            severity = "critical";
          })
          (rule {
            uid = "infra-cert-expiry";
            title = "Certificate expiring";
            # Already-expired certs (renewal given up on) are excluded, else they page forever.
            expr = "min by (namespace, name) (certmanager_certificate_expiration_timestamp_seconds - time()) / 86400 > 0";
            op = "lt";
            threshold = 14;
            for = "1h";
            summary = "{{ $labels.name }} expires in {{ humanize $values.A }} days; cert-manager isn't renewing it";
          })
          (rule {
            uid = "infra-mongo-lag";
            title = "Mongo replication lag";
            # Arbiters report a bogus lag (a timestamp).
            expr = ''max by (set, name) (mongodb_mongod_replset_member_replication_lag{state!="ARBITER"})'';
            threshold = 60;
            for = "10m";
            summary = "{{ $labels.name }} is {{ $values.A }}s behind in {{ $labels.set }}";
          })
          (rule {
            uid = "infra-mongo-member";
            title = "Mongo replica set member unhealthy";
            expr = "1 - min(mongodb_rs_members_health)";
            summary = "A member of the poketwo replica set is unhealthy";
            severity = "critical";
          })
          (rule {
            uid = "infra-object-store";
            title = "Object storage (B2) errors";
            expr = "sum by (namespace, operation) (rate(thanos_objstore_bucket_operation_failures_total[10m]))";
            for = "30m";
            summary = "{{ $labels.namespace }} bucket {{ $labels.operation }} calls failing for 30m";
          })
        ];
      }];
    };
  };
}
