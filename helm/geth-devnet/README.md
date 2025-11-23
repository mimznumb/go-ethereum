# Geth Devnet Helm Chart

Helm chart за deployment на Geth devnet в Kubernetes с пълна production-ready конфигурация.

## 🚀 Quick Start

```bash
# Install chart
helm install geth-devnet ./helm/geth-devnet \
  --namespace devnet \
  --create-namespace

# Upgrade existing release
helm upgrade geth-devnet ./helm/geth-devnet \
  --namespace devnet

# Uninstall
helm uninstall geth-devnet --namespace devnet
```

## 📋 Features

- ✅ **Security**: Non-root user, security context, network policies
- ✅ **High Availability**: Pod disruption budgets, anti-affinity rules
- ✅ **Persistence**: Optional PVC for data retention
- ✅ **Autoscaling**: HPA based on CPU/memory
- ✅ **Monitoring**: Health checks (liveness/readiness probes)
- ✅ **Networking**: LoadBalancer, Ingress, NetworkPolicy support
- ✅ **IRSA**: AWS IAM Roles for Service Accounts integration

## 📦 Resources Created

| Resource | Purpose | Optional |
|----------|---------|----------|
| Deployment | Geth pod(s) | Required |
| Service | LoadBalancer/ClusterIP | Required |
| ServiceAccount | IRSA integration | Required |
| PersistentVolumeClaim | Data persistence | Optional |
| ConfigMap | Geth configuration | Optional |
| HorizontalPodAutoscaler | Auto-scaling | Optional |
| PodDisruptionBudget | HA during updates | Optional (>1 replica) |
| Ingress | External HTTP access | Optional |
| NetworkPolicy | Network isolation | Optional |

## ⚙️ Configuration

### Basic Configuration

```yaml
# values.yaml
replicaCount: 1

image:
  repository: your-registry/geth-devnet
  tag: latest
  pullPolicy: Always

resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 1Gi
```

### Enable Persistence

```yaml
persistence:
  enabled: true
  size: 20Gi
  storageClass: gp3  # AWS EBS gp3
```

### Enable Autoscaling

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 70
```

### Enable Ingress

```yaml
ingress:
  enabled: true
  className: alb
  host: geth.example.com
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
  tls: true
  tlsSecret: geth-tls-cert
```

### Enable Network Policy

```yaml
networkPolicy:
  enabled: true
  allowExternal: true
  allowAllEgress: true
```

### Custom Geth Arguments

```yaml
geth:
  networkId: 1337
  maxPeers: 50
  noDiscovery: false
  extraArgs:
    - --verbosity=4
    - --metrics
    - --metrics.addr=0.0.0.0
```

## 🔧 Advanced Configuration

### IRSA (IAM Roles for Service Accounts)

```yaml
serviceAccount:
  create: true
  name: geth-devnet-sa
  roleArn: "arn:aws:iam::123456789012:role/geth-devnet-role"
```

### Node Selection

```yaml
nodeSelector:
  node.kubernetes.io/instance-type: t3.medium
  topology.kubernetes.io/zone: eu-central-1a

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                  - geth-devnet
          topologyKey: kubernetes.io/hostname

tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "geth"
    effect: "NoSchedule"
```

### Environment Variables

```yaml
env:
  LOG_LEVEL: "debug"
  CUSTOM_VAR: "value"
```

## 📊 Monitoring

### Health Checks

The chart includes both liveness and readiness probes:

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 8545
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /
    port: 8545
  initialDelaySeconds: 10
  periodSeconds: 5
```

### Metrics (Optional)

Enable Prometheus metrics:

```yaml
geth:
  extraArgs:
    - --metrics
    - --metrics.addr=0.0.0.0
    - --metrics.port=6060
```

## 🔍 Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n devnet
kubectl describe pod <pod-name> -n devnet
kubectl logs <pod-name> -n devnet -f
```

### Check Service

```bash
kubectl get svc -n devnet
kubectl describe svc geth-devnet -n devnet
```

### Check PVC

```bash
kubectl get pvc -n devnet
kubectl describe pvc geth-devnet-data -n devnet
```

### Test RPC Connection

```bash
# Port forward
kubectl port-forward -n devnet svc/geth-devnet 8545:8545

# Test RPC
curl -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"web3_clientVersion","params":[]}' \
  http://localhost:8545
```

## 📝 Examples

### Development Setup

```yaml
# values-dev.yaml
replicaCount: 1
persistence:
  enabled: false
autoscaling:
  enabled: false
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 250m
    memory: 512Mi
```

```bash
helm install geth-devnet ./helm/geth-devnet \
  -f helm/geth-devnet/values-dev.yaml \
  --namespace devnet
```

### Production Setup

```yaml
# values-prod.yaml
replicaCount: 3
persistence:
  enabled: true
  size: 100Gi
  storageClass: gp3
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
resources:
  requests:
    cpu: 1000m
    memory: 2Gi
  limits:
    cpu: 2000m
    memory: 4Gi
ingress:
  enabled: true
  className: alb
  host: geth-prod.example.com
  tls: true
networkPolicy:
  enabled: true
```

```bash
helm install geth-devnet ./helm/geth-devnet \
  -f helm/geth-devnet/values-prod.yaml \
  --namespace production
```

## 🔐 Security Best Practices

1. **Non-root user**: Pods run as user 1000
2. **Security context**: Drop all capabilities
3. **Network policies**: Restrict ingress/egress
4. **IRSA**: Use IAM roles instead of access keys
5. **TLS**: Enable for Ingress
6. **Resource limits**: Prevent resource exhaustion

## 📚 Related Documentation

- [Deployment Flow](../../docs/DEPLOYMENT_FLOW.md)
- [Quick Start Guide](../../docs/QUICKSTART.md)
- [Optimization Summary](../../docs/OPTIMIZATION_SUMMARY.md)

## 🆘 Support

For issues or questions:
- Check logs: `kubectl logs -n devnet <pod-name>`
- Check events: `kubectl get events -n devnet`
- Review documentation in `docs/` folder

## 📄 License

Same as parent project.
