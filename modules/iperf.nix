{ config, helpers, lib, ... }:

with lib;
let cfg = config.homeserver.iperf;
in {
  options.homeserver.iperf = {
    enable = mkEnableOption "Enable Iperf";

    version = mkOption {
      type = types.string;
      default = "latest";
      defaultText = "latest";
      description = "Version name to use for Iperf images";
    };

    subdomain = mkOption {
      type = types.string;
      default = "iperf";
      defaultText = "iperf";
      description = "Subdomain to use for Iperf";
    };

    port = mkOption {
      type = types.int;
      default = 5201;
      defaultText = "5201";
      description = "Port to use for Iperf";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers = {
      iperf = {
        image = "networkstatic/iperf3:${cfg.version}";
        ports = [ "${toString cfg.port}:5201" ];
        cmd = [ "-s" ];
      };
    };
  };
}

