{ lib, ... }:
{
  app = {
    name = "ingress-grpc";
    namespace = "default";
    image = "nginx:1.25";

    service = {
      enable = true;
      port = 80;
      targetPort = 8080;
      protocol = "grpc";
    };

    ingress = {
      enable = true;
      host = "grpc.example.local";
    };
  };
}

