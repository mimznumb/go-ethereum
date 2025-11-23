# 📚 Documentation Index

Добре дошли в документацията на go-ethereum DevOps infrastructure!

## 🚀 Започнете тук

Ако сте нов в проекта, започнете с:

1. **[QUICKSTART.md](./QUICKSTART.md)** - 5-минутен бърз старт
2. **[DEPLOYMENT_FLOW.md](./DEPLOYMENT_FLOW.md)** - Подробен deployment flow
3. **[VISUAL_FLOW.md](./VISUAL_FLOW.md)** - Визуални диаграми и схеми

## 📖 Документи

### Основни

| Документ | Описание | Аудитория |
|----------|----------|-----------|
| [QUICKSTART.md](./QUICKSTART.md) | Бърз старт и често използвани команди | Всички |
| [OPTIMIZATION_SUMMARY.md](./OPTIMIZATION_SUMMARY.md) | Обобщение на всички оптимизации | Tech Leads, DevOps |

### Технически

| Документ | Описание | Аудитория |
|----------|----------|-----------|
| [DEPLOYMENT_FLOW.md](./DEPLOYMENT_FLOW.md) | Пълен deployment pipeline | DevOps, Developers |
| [VISUAL_FLOW.md](./VISUAL_FLOW.md) | Диаграми и troubleshooting | DevOps, Support |
| [../infrastructure_review.md](../infrastructure_review.md) | 54 препоръки за подобрения | DevOps, Architects |

## 🎯 Намерете бързо

### Искам да...

- **Build images локално** → [QUICKSTART.md#локално-тестване](./QUICKSTART.md)
- **Deploy към EKS** → [DEPLOYMENT_FLOW.md#workflow-3-helm-deploy](./DEPLOYMENT_FLOW.md)
- **Разбера flow-а** → [VISUAL_FLOW.md#quick-reference-diagram](./VISUAL_FLOW.md)
- **Fix проблем** → [VISUAL_FLOW.md#common-issues--solutions](./VISUAL_FLOW.md)
- **Видя какво е променено** → [OPTIMIZATION_SUMMARY.md](./OPTIMIZATION_SUMMARY.md)

### Често задавани въпроси

**Q: Как да build-на images?**  
A: `make build-all` или вижте [QUICKSTART.md](./QUICKSTART.md)

**Q: Къде се деплойват контрактите?**  
A: Вижте [DEPLOYMENT_FLOW.md - Smart Contracts](./DEPLOYMENT_FLOW.md#smart-contracts-deployment-tracking)

**Q: Защо build-ът е бавен?**  
A: Вижте [OPTIMIZATION_SUMMARY.md - Performance](./OPTIMIZATION_SUMMARY.md#performance-improvements)

**Q: Как работи CI/CD?**  
A: Вижте [VISUAL_FLOW.md - Complete Flow](./VISUAL_FLOW.md#quick-reference-diagram)

## 🔧 Инструменти

- **Makefile** - `make help` за всички команди
- **Docker** - Вижте `docker/` директория
- **Helm** - Вижте `helm/geth-devnet/`
- **Terraform** - Вижте `terraform/`

## 📊 Структура на проекта

```
go-ethereum/
├── docs/                          # ← Вие сте тук
│   ├── README.md                  # Този файл
│   ├── QUICKSTART.md              # Бърз старт
│   ├── DEPLOYMENT_FLOW.md         # Deployment flow
│   ├── VISUAL_FLOW.md             # Диаграми
│   └── OPTIMIZATION_SUMMARY.md    # Обобщение
├── docker/                        # Docker images
├── .github/workflows/             # CI/CD workflows
├── helm/                          # Kubernetes deployments
├── terraform/                     # Infrastructure
├── hardhat/                       # Smart contracts
└── Makefile                       # Automation
```

## 🎓 Learning Path

### Beginner (0-1 седмица)

1. Прочетете [QUICKSTART.md](./QUICKSTART.md)
2. Run `make build-all` локално
3. Експериментирайте с `make` командите
4. Deploy локално с `make deploy-local`

### Intermediate (1-2 седмици)

1. Прочетете [DEPLOYMENT_FLOW.md](./DEPLOYMENT_FLOW.md)
2. Разберете CI/CD workflows
3. Направете тест deployment към EKS
4. Review [infrastructure_review.md](../infrastructure_review.md)

### Advanced (2+ седмици)

1. Прочетете [VISUAL_FLOW.md](./VISUAL_FLOW.md)
2. Implement security improvements
3. Setup monitoring
4. Optimize Terraform

## 🔗 External Resources

- [Docker Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

## 📝 Contributing

Ако намерите грешки или искате да добавите документация:

1. Създайте issue в GitHub
2. Или направете PR с промени
3. Следвайте съществуващия формат

## 📞 Support

- **Документация**: Вижте файловете в тази папка
- **Issues**: GitHub Issues
- **Logs**: `make logs` или `kubectl logs`
- **Help**: `make help`

---

**Последна актуализация**: 2025-11-23  
**Версия**: 1.0
