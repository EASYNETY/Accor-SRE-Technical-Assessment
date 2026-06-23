resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = "monitoring"
  create_namespace = true
  wait       = false

  values = [yamlencode({
    server = {
      persistentVolume = {
        enabled = false
      }
      global = {
        scrape_interval = "15s"
      }
      service = {
        type = "ClusterIP"
      }
      resources = {
        requests = {
          cpu    = "50m"
          memory = "128Mi"
        }
      }
    }
    "kube-state-metrics" = {
      resources = {
        requests = {
          cpu    = "10m"
          memory = "32Mi"
        }
      }
    }
    "prometheus-pushgateway" = {
      enabled = false
    }
    alertmanager = {
      enabled = false
    }
    pushgateway = {
      enabled = false
    }
  })]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = "monitoring"
  create_namespace = true

  values = [yamlencode({
    adminUser     = "admin"
    adminPassword = "redemption123!"
    service = {
      type = "ClusterIP"
    }
    ingress = {
      enabled = false
    }
  })]
}
