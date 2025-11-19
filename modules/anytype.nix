{ config, helpers, lib, ... }:

with lib;
let cfg = config.control.anytype;
in {
  options.control.anytype = 
    (helpers.webServiceDefaults {
      name = "Anytype";
      version = "latest";
      subdomain = "anytype";
      port = 10008;
    })
    // {

    paths = {
      default = helpers.mkInheritedPathOption {
        parentName = "home server global default path";
        parent = config.control.defaultPath;
        defaultSubpath = "anytype";
        description = "Default path for any-sync data";
      };
      mongo = helpers.mkInheritedPathOption {
        parentName = "paths.default";
        parent = cfg.paths.default;
        defaultSubpath = "mongo";
        description = "Path for any-sync MongoDB data.";
      };
      redis = helpers.mkInheritedPathOption {
        parentName = "paths.default";
        parent = cfg.paths.default;
        defaultSubpath = "redis";
        description = "Path for any-sync Redis data.";
      };
      minio = helpers.mkInheritedPathOption {
        parentName = "paths.default";
        parent = cfg.paths.default;
        defaultSubpath = "minio";
        description = "Path for any-sync Minio data.";
      };
      etc = helpers.mkInheritedPathOption {
        parentName = "paths.default";
        parent = cfg.paths.default;
        defaultSubpath = "etc";
        description = "Path for any-sync configuration files.";
      };
    };
  };

  config = mkIf cfg.enable {

    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers = {
      any-sync-mongo = {
        image = "mongo:6.0";
        volumes = [ "${cfg.paths.mongo}:/data/db" ];
        extraOptions = [
          "--network=anytype-net"
          "--pull=always"
        ];
        cmd = [ "--replSet" "rs0" ];
      };

      any-sync-redis = {
        image = "redis/redis-stack-server:latest";
        volumes = [ "${cfg.paths.redis}:/data" ];
        extraOptions = [
          "--network=anytype-net"
          "--pull=always"
        ];
      };

      any-sync-minio = {
        image = "minio/minio:latest";
        volumes = [ "${cfg.paths.minio}:/data" ];
        environment = {
          MINIO_ROOT_USER = "minio";
          MINIO_ROOT_PASSWORD = "miniopassword";
        };
        cmd = [ "server" "/data" "--console-address" ":9001" ];
        extraOptions = [
          "--network=anytype-net"
          "--pull=always"
        ];
      };

      any-sync-coordinator = {
        image = "ghcr.io/anyproto/any-sync-coordinator:${cfg.version}";
        volumes = [ "${cfg.paths.etc}/any-sync-coordinator:/etc/any-sync-coordinator" ];
        ports = [
          helpers.webServicePort config cfg 443
          "${helpers.webServicePort config cfg 443}/udp"
        ];
        extraOptions = [
          "--network=anytype-net"
          "--pull=always"
        ];
      };

      any-sync-filenode = {
        image = "ghcr.io/anyproto/any-sync-filenode:${cfg.version}";
        volumes = [
          "${cfg.paths.etc}/any-sync-filenode:/etc/any-sync-filenode"
          "${cfg.paths.etc}/.aws:/root/.aws:ro"
        ];
        extraOptions = [
          "--network=anytype-net"
          "--pull=always"
        ];
      };

      any-sync-node-1 = {
        image = "ghcr.io/anyproto/any-sync-node:${cfg.version}";
        volumes = [
          "${cfg.paths.etc}/any-sync-node-1:/etc/any-sync-node"
          "${cfg.paths.etc}/.aws:/root/.aws:ro"
          "${cfg.paths.default}/any-sync-node-1:/storage"
        ];
        extraOptions = [
          "--network=anytype-net"
          "--pull=always"
        ];
      };

      any-sync-node-2 = {
        image = "ghcr.io/anyproto/any-sync-node:${cfg.version}";
        volumes = [
          "${cfg.paths.etc}/any-sync-node-2:/etc/any-sync-node"
          "${cfg.paths.etc}/.aws:/root/.aws:ro"
          "${cfg.paths.default}/any-sync-node-2:/storage"
        ];
        extraOptions = [
          "--network=anytype-net"
          "--pull=always"
        ];
      };

      any-sync-node-3 = {
        image = "ghcr.io/anyproto/any-sync-node:${cfg.version}";
        volumes = [
          "${cfg.paths.etc}/any-sync-node-3:/etc/any-sync-node"
          "${cfg.paths.etc}/.aws:/root/.aws:ro"
          "${cfg.paths.default}/any-sync-node-3:/storage"
        ];
        extraOptions = [
          "--network=anytype-net"
          "--pull=always"
        ];
      };

      any-sync-consensusnode = {
        image = "ghcr.io/anyproto/any-sync-consensusnode:${cfg.version}";
        volumes = [ "${cfg.paths.etc}/any-sync-consensusnode:/etc/any-sync-consensusnode" ];
        extraOptions = [
          "--network=anytype-net"
          "--pull=always"
        ];
      };
    };

    systemd.services = helpers.mkDockerNetworkService {
      networkName = "anytype-net";
      dockerCli = "${config.virtualisation.docker.package}/bin/docker";
    };
  };
}