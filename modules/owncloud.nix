{ config, helpers, lib, ... }:

with lib;
let cfg = config.homeserver.owncloud; # (gets the config values the user has set)
in {
  options.homeserver.owncloud = {
    enable = mkEnableOption "Enable ownCloud container";

    dbPasswordFile = mkOption {
      type = types.path;
      description = ''
        Path of Postgres password file for ownCloud.
      '';
    };

    version = mkOption {
      type = types.string;
      default = "release";
      defaultText = "release";
      description = "Version name to use for ownCloud images";
    };

    port = mkOption {
      type = types.int;
      default = 10001;
      defaultText = "10001";
      description = "Port to use for ownCloud";
    };

    paths = {
      default = mkOption {
        type = types.path;
        description = "Default path for ownCloud data (required)";
      };

      database = helpers.mkInheritedPathOption {
        parentName = "paths.default";
        parent = cfg.paths.default;
        defaultSubpath = "db";
        description = "Path for ownCloud database.";
      };

      uploads = helpers.mkInheritedPathOption {
        parentName = "paths.default";
        parent = cfg.paths.default;
        defaultSubpath = "pictures";
        description = "Path for ownCloud uploads (pictures).";
      };

      machineLearning = helpers.mkInheritedPathOption {
        parentName = "paths.default";
        parent = cfg.paths.default;
        defaultSubpath = "machine_learning";
        description = "Path for ownCloud appdata (machine learning model cache).";
      };
    };
  };

  config = mkIf cfg.enable {

    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers = {
      owncloud = {
        image = "owncloud/server:${cfg.version}";
        ports = [ "${toString cfg.port}:8080" ];
        environment = {
          OWNCLOUD_DOMAIN=cfg.domain;
          OWNCLOUD_TRUSTED_DOMAINS=${OWNCLOUD_TRUSTED_DOMAINS};
          OWNCLOUD_DB_TYPE=mysql;
          OWNCLOUD_DB_NAME=owncloud;
          OWNCLOUD_DB_USERNAME=owncloud;
          OWNCLOUD_DB_PASSWORD=owncloud;
          OWNCLOUD_DB_HOST=mariadb;
          OWNCLOUD_ADMIN_USERNAME=${ADMIN_USERNAME};
          OWNCLOUD_ADMIN_PASSWORD=${ADMIN_PASSWORD};
          OWNCLOUD_MYSQL_UTF8MB4=true;
          OWNCLOUD_REDIS_ENABLED=true;
          OWNCLOUD_REDIS_HOST=redis;
        };
        volumes = [
          "${cfg.paths.uploads}:/usr/src/app/upload"
          "/etc/localtime:/etc/localtime:ro"
          "${cfg.dbPasswordFile}:/run/secrets/owncloud-db-password:ro"
        ];
        extraOptions = [ "--network=owncloud-net" ];
      };

      immich_machine_learning = {
        image =
          "ghcr.io/owncloud-app/owncloud-machine-learning:${toString cfg.version}";
        environment = { IMMICH_VERSION = toString cfg.version; };
        volumes = [ "${cfg.paths.machineLearning}/model-cache:/cache" ];
        extraOptions = [ "--network=owncloud-net" ];
      };

      immich_redis = {
        image =
          "redis:6.2-alpine@sha256:905c4ee67b8e0aa955331960d2aa745781e6bd89afc44a8584bfd13bc890f0ae";
        extraOptions = [ "--network=owncloud-net" ];
      };

      immich_postgres = {
        image =
          "tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0";
        environment = {
          POSTGRES_PASSWORD_FILE = "/run/secrets/owncloud-db-password";
          POSTGRES_USER = "owncloud";
          POSTGRES_DB = "owncloud";
        };
        volumes = [
          "${cfg.paths.database}:/var/lib/postgresql/data"
          "${cfg.dbPasswordFile}:/run/secrets/owncloud-db-password:ro"
        ];
        extraOptions = [ "--network=owncloud-net" ];
      };
    };

    systemd.services = helpers.mkDockerNetworkService {
      networkName = "owncloud-net";
      dockerCli = "${config.virtualisation.docker.package}/bin/docker";
    };
  };
}
