{ config, helpers, lib, ... }:

with lib;
let cfg = config.control.anytype;
in {
  options.control.anytype = {
    enable = mkEnableOption "Enable any-sync containers";

    versions = {
      any-sync-coordinator = mkOption {
        type = types.str;
        default = "latest";
        description = "Version for any-sync-coordinator image.";
      };
      any-sync-filenode = mkOption {
        type = types.str;
        default = "latest";
        description = "Version for any-sync-filenode image.";
      };
      any-sync-node = mkOption {
        type = types.str;
        default = "latest";
        description = "Version for any-sync-node image.";
      };
      any-sync-consensusnode = mkOption {
        type = types.str;
        default = "latest";
        description = "Version for any-sync-consensusnode image.";
      };
    };

    ports = {
      coordinator = mkOption {
        type = types.int;
        default = 443;
        description = "Port for any-sync-coordinator.";
      };
      filenode = mkOption {
        type = types.int;
        default = 4100;
        description = "Port for any-sync-filenode.";
      };
      node1 = mkOption {
        type = types.int;
        default = 4800;
        description = "Port for any-sync-node-1.";
      };
      node2 = mkOption {
        type = types.int;
        default = 4801;
        description = "Port for any-sync-node-2.";
      };
      node3 = mkOption {
        type = types.int;
        default = 4802;
        description = "Port for any-sync-node-3.";
      };
      consensusnode = mkOption {
        type = types.int;
        default = 4700;
        description = "Port for any-sync-consensusnode.";
      };
    };

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
        ports = [ "127.0.0.1:27017:27017" ];
        volumes = [ "${cfg.paths.mongo}:/data/db" ];
        extraOptions = [
          "--network=anytype-net"
          "--pull=always"
        ];
        cmd = [ "--replSet" "rs0" ];
      };

      any-sync-redis = {
        image = "redis/redis-stack-server:latest";
        ports = [ "127.0.0.1:6379:6379" ];
        volumes = [ "${cfg.paths.redis}:/data" ];
        extraOptions = [
          "--network=anytype-net"
          "--pull=always"
        ];
      };

      any-sync-minio = {
        image = "minio/minio:latest";
        ports = [ "127.0.0.1:9000:9000" "127.0.0.1:9001:9001" ];
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
        image = "ghcr.io/anyproto/any-sync-coordinator:${cfg.versions.any-sync-coordinator}";
        ports = [
          "${toString cfg.ports.coordinator}:${toString cfg.ports.coordinator}"
          "${toString cfg.ports.coordinator}:${toString cfg.ports.coordinator}/udp"
        ];
        volumes = [ "${cfg.paths.etc}/any-sync-coordinator:/etc/any-sync-coordinator" ];
        extraOptions = [
          "--network=anytype-net"
          "--pull=always"
        ];
      };

      any-sync-filenode = {
        image = "ghcr.io/anyproto/any-sync-filenode:${cfg.versions.any-sync-filenode}";
        ports = [
          "${toString cfg.ports.filenode}:${toString cfg.ports.filenode}"
          "${toString cfg.ports.filenode}:${toString cfg.ports.filenode}/udp"
        ];
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
        image = "ghcr.io/anyproto/any-sync-node:${cfg.versions.any-sync-node}";
        ports = [
          "${toString cfg.ports.node1}:${toString cfg.ports.node1}"
          "${toString cfg.ports.node1}:${toString cfg.ports.node1}/udp"
        ];
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
        image = "ghcr.io/anyproto/any-sync-node:${cfg.versions.any-sync-node}";
        ports = [
          "${toString cfg.ports.node2}:${toString cfg.ports.node2}"
          "${toString cfg.ports.node2}:${toString cfg.ports.node2}/udp"
        ];
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
        image = "ghcr.io/anyproto/any-sync-node:${cfg.versions.any-sync-node}";
        ports = [
          "${toString cfg.ports.node3}:${toString cfg.ports.node3}"
          "${toString cfg.ports.node3}:${toString cfg.ports.node3}/udp"
        ];
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
        image = "ghcr.io/anyproto/any-sync-consensusnode:${cfg.versions.any-sync-consensusnode}";
        ports = [
          "${toString cfg.ports.consensusnode}:${toString cfg.ports.consensusnode}"
          "${toString cfg.ports.consensusnode}:${toString cfg.ports.consensusnode}/udp"
        ];
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