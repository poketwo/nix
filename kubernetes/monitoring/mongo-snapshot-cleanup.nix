{ lib, ... }:

let
  # One-shot cleanup of sanoid snapshots on the mongo/mongo zvol, run in the
  # host's root via chroot like zfs-exporter. Safe to re-run: it only prunes
  # hourlies beyond the newest 12 (the new sanoid retention, applied before
  # the hosts are redeployed) and, where set, the oldest daily dated on or
  # before `oldestDailyUpTo`, so a re-run after that daily is gone is a no-op.
  script = { oldestDailyUpTo ? null }: ''
    set -euo pipefail
    ds=mongo/mongo

    echo "before:"
    zfs list -o name,used,avail,usedbysnapshots "$ds"
    zfs list -t snapshot -o name,creation,used -s creation "$ds"

    mapfile -t hourlies < <(zfs list -H -t snapshot -o name -s creation "$ds" | grep '_hourly$' || true)
    extra=$(( ''${#hourlies[@]} - 12 ))
    for (( i = 0; i < extra; i++ )); do
      zfs destroy -v "''${hourlies[i]}"
    done
  '' + lib.optionalString (oldestDailyUpTo != null) ''
    oldest=$(zfs list -H -t snapshot -o name -s creation "$ds" | grep '_daily$' | head -n 1 || true)
    day=''${oldest#*@autosnap_}
    day=''${day:0:10}
    if [[ -n "$oldest" && ! "$day" > "${oldestDailyUpTo}" ]]; then
      zfs destroy -v "$oldest"
    else
      echo "oldest daily ''${oldest:-none} is newer than ${oldestDailyUpTo}, keeping it"
    fi
  '' + ''

    echo "after:"
    zfs list -o name,used,avail,usedbysnapshots "$ds"
  '';

  job = node: args: {
    backoffLimit = 0;
    template.spec = {
      nodeName = node;
      hostPID = true;
      restartPolicy = "Never";

      containers.cleanup = {
        image = "busybox:1.37";
        command = [
          "chroot"
          "/host"
          "/run/current-system/sw/bin/bash"
          "-c"
          ("export PATH=/run/current-system/sw/bin\n" + script args)
        ];
        securityContext.privileged = true;
        volumeMounts = [{ name = "host-root"; mountPath = "/host"; }];
      };

      volumes = [{
        name = "host-root";
        hostPath.path = "/";
      }];
    };
  };
in
{
  namespaces.prometheus.resources."batch/v1".Job = {
    mongo-snapshot-cleanup-vaporeon.spec = job "vaporeon" { oldestDailyUpTo = "2026-11-03"; };
    mongo-snapshot-cleanup-jolteon.spec = job "jolteon" { };
  };
}
