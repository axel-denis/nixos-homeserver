# LINK - https://github.com/grishy/any-sync-bundle

{ config, helpers, lib, ... }:

with lib;
let cfg = config.control.anytype;
in {
  options.control.anytype = (helpers.webServiceDefaults {
    name = "Anytype";
    version = "latest"; # 1.1.2-2025-10-24
    subdomain = "anytype";
    port = 10008;
  }) // {
    paths = {
      default = helpers.mkInheritedPathOption {
        parentName = "home server global default path";
        parent = config.control.defaultPath;
        defaultSubpath = "anytype";
        description = "Root path for Anytype appdata";
      };
    };
  };

  config = mkIf cfg.enable {
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers = {
      anytype-traefik = {
        image = "docker.io/traefik:v3.5.3";
        ports = [
          (helpers.webServicePort config cfg 33010)
          "${helpers.webServicePort config cfg 33020}/udp"
        ];
        cmd = [
          "--providers.docker=true"
          "--providers.docker.exposedbydefault=false"
          "--entrypoints.any-sync-tcp.address=:33010"
          "--entrypoints.any-sync-udp.address=:33020/udp"
        ];
        environment = { # FIXME - will not work on lan only, as lan only require server ip here:
          ANY_SYNC_BUNDLE_INIT_EXTERNAL_ADDRS = "${cfg.subdomain}.${config.control.routing.domain}";
        };
        extraOptions = [ "--network=anytypenet" "--pull=always" ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];
      };

      anytype = {
        image = "ghcr.io/grishy/any-sync-bundle:${cfg.version}";
        environment = { # FIXME - will not work on lan only, as lan only require server ip here:
          ANY_SYNC_BUNDLE_INIT_EXTERNAL_ADDRS = "${cfg.subdomain}.${config.control.routing.domain}";
        };
        extraOptions = [ "--network=anytypenet" "--pull=always" ];
        volumes = [
          "${cfg.paths.default}:/data"
        ];
        labels = {
          # Enable Traefik for this service
          "traefik.enable" = "true";
          # TCP Router Configuration
          # Routes all TCP traffic on port 33010 to any-sync-bundle
          "traefik.tcp.routers.any-sync-tcp.rule" = "HostSNI(`*`)";
          "traefik.tcp.routers.any-sync-tcp.entrypoints" = "any-sync-tcp";
          "traefik.tcp.routers.any-sync-tcp.service" = "any-sync-tcp-service";
          "traefik.tcp.routers.any-sync-tcp.tls.passthrough" = "true";
          # Try TLS passthrough
          "traefik.tcp.services.any-sync-tcp-service.loadbalancer.server.port" = "33010";
          # UDP Router Configuration
          # Routes all UDP traffic on port 33020 to any-sync-bundle
          "traefik.udp.routers.any-sync-udp.entrypoints" = "any-sync-udp";
          "traefik.udp.routers.any-sync-udp.service" = "any-sync-udp-service";
          "traefik.udp.services.any-sync-udp-service.loadbalancer.server.port" = "33020";
        };
      };
    };

    systemd.services = helpers.mkDockerNetworkService {
      networkName = "anytypenet";
      dockerCli = "${config.virtualisation.docker.package}/bin/docker";
    };
  };
}
