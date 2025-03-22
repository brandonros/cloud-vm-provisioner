terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.36.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.17.0"
    }
  }
}

provider "kubernetes" {
  config_path = "${path.module}/../../server-files/kubeconfig"
}

provider "helm" {
  kubernetes {
    config_path = "${path.module}/../../server-files/kubeconfig"
  }
}

resource "kubernetes_manifest" "letsencrypt_prod_issuer" {
  manifest = yamldecode(<<YAML
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-prod-issuer
  namespace: traefik
spec:
  acme:
    email: test@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
    - http01:
        gatewayHTTPRoute:
          parentRefs:
            - name: gateway
              namespace: traefik
              kind: Gateway
YAML
  )
}
