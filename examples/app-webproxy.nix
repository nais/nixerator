{ lib, ... }:
{
  app = {
    name = "webproxy";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    webproxy.enable = true;
    webproxy.httpProxy = "http://proxy.nav.no:8088";
    webproxy.noProxy = [ "localhost" ".local" ];
  };
}

