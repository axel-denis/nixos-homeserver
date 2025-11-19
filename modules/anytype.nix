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
    quic = true; # enables quic protocol for the routing module

    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers = {
      anytype = {
        image = "ghcr.io/grishy/any-sync-bundle:${cfg.version}";
        ports = [
          (helpers.webServicePort config cfg 33010)
          "${helpers.webServicePort config cfg 33020}/udp"
        ];
        environment = { # FIXME - will not work on lan only, as lan only require server ip here:
          ANY_SYNC_BUNDLE_INIT_EXTERNAL_ADDRS = "${cfg.subdomain}.${config.control.routing.domain}";
        };
        extraOptions = [ "--pull=always" ];
        volumes = [
          "${cfg.paths.default}:/data"
        ];
      };
    };
  };
}
