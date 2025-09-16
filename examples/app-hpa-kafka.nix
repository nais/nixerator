{ lib, ... }:
{
  app = {
    name = "hpa-kafka";
    namespace = "default";
    image = "nginx:1.25";

    service.enable = true;
    service.port = 80;
    service.targetPort = 8080;

    hpa = {
      enable = true;
      minReplicas = 3;
      maxReplicas = 6;
      kafka = {
        topic = "default.mytopic";
        consumerGroup = "myconsumergroup";
        threshold = 100;
      };
    };
  };
}

