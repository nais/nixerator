{ lib }:

let
  nlib = import ../lib { inherit lib; };
in
{
  app = nlib.mkApp {
    name = "hello";
    namespace = "default";
    image = "nginx:1.25";
    replicas = 2;
    env = { FOO = "bar"; };
    service = { port = 80; targetPort = 8080; };
    ingress = { host = "hello.local"; };
  };
}

