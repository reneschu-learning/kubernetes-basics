# Helm Package Manager
Helm is a package manager for Kubernetes that allows you to define, install, and upgrade even the most complex Kubernetes applications. Helm uses a packaging format called charts. A chart is a collection of files that describe a related set of Kubernetes resources. Helm charts can be used to deploy applications, services, and other resources to a Kubernetes cluster. Unlike Deployments, which can only manage updates and rollbacks of Pods, Helm charts keep track of the versions of all the resources they manage, making it easy to roll back to previous versions if needed.

Helm charts follow a simple structure:

```
my-chart/
├── Chart.yaml          # Chart metadata (name, version, description)
├── values.yaml         # Default configuration values
├── charts/             # Dependencies (sub-charts)
├── templates/          # Kubernetes manifest templates
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── _helpers.tpl    # Template helpers and partials
│   └── NOTES.txt       # Post-install instructions
└── .helmignore         # Files to ignore when packaging
```

Remember our full application deployment from the configuration and volumes lab (see [deployment-full.yaml](../03_config-and-volumes/deployment-full.yaml))? We put everything into a single manifest file, which is fine for small applications, but as your application grows, it can become difficult to manage. Helm charts allow you to break your application into smaller, reusable components, making it easier to manage and deploy. Inspect the [gallery-chart](./gallery-chart) directory for an example of a Helm chart that deploys our sample application.

You can deploy the full application using Helm with the following command:

```bash
helm install gallery ./gallery-chart
```

Check the cluster state in `k9s`. You can see that with a single command, Helm has created all the resources needed to deploy the application. You can also check the status of the release with:

```bash
helm status gallery
```

Since Helm uses a template engine, you can customize the deployment by providing your own values. Our chart uses the release name as a prefix for all resources, so you can deploy multiple instances of the application with different configurations. For example, you can deploy a second instance of the application with a different release name and custom values:

```bash
helm install gallery2 ./gallery-chart --set frontend.replicaCount=1 --set frontend.publicPort=8090 --set backend.replicaCount=1 --set backend.internalPort=9100
```

Check `k9s` again. You will see additional Pods and Services for the second instance of the application, all configured with the custom values you provided.

For now, let's clean up the cluster by uninstalling the Helm releases:

```bash
helm uninstall gallery
helm uninstall gallery2
```

If you want to learn more about Helm, you can check out the [official Helm documentation](https://helm.sh/docs/).