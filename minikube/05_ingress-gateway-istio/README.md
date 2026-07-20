# Ingress, Gateway API, and Istio
From one of the previous labs, we learned how to expose an application through a Service of type LoadBalancer. While this works well for simple use cases, it has some limitations. Let's assume you have an application that consists of multiple microservices, each with its own Service. If you want to expose all of these Services to the outside world, you would need to create a LoadBalancer for each Service, which results to all of them having their own public IP address. This is not ideal, as it can be costly and difficult to manage. Wouldn't it be better if we could expose all of these Services through a single public IP address? This is where Ingress and the Gateway API come in.

## Ingress
An Ingress is a Kubernetes resource that allows you to define rules for routing external HTTP and HTTPS traffic to your Services. It acts as a reverse proxy, allowing you to expose multiple Services through a single public IP address. One of the most popular simple Ingress controllers is NGINX. Let's use it to expose two versions of our application through a single public IP address with two different paths.

**NOTE:** The NGINX Ingress controller is retired and will not be maintained after 2025. It is recommended to use the Gateway API instead (see below). However, for the purpose of this lab, we will still use the NGINX Ingress controller.

Before we start, let's make sure that the NGINX Ingress controller is installed in our cluster. Minikube has a nice feature that allows you to enable the NGINX Ingress controller with a single command:

```bash
minikube addons enable ingress
```

Once the NGINX Ingress controller is installed, take a look at the [deployment.yaml](deployment.yaml) to see how it deploys two versions of our sample application (`v2.2.1` and `v2.3.0`) and its backend including all necessary resources such as ConfigMaps, Secrets, and Services. If you look closely at the Services, you will notice that they are of type ClusterIP, which means they are only accessible within the cluster. All external traffic will be routed through the Ingress controller, which is defined in the [ingress.yaml](ingress.yaml) file.

The Ingress controller defines two rules for routing traffic to the two versions of our application. The first rule routes traffic to the `gallery-svc-v4` Service when the request path starts with `/v4`, while the second rule routes traffic to the `gallery-svc-v5` Service when the request path starts with `/v5`. This allows us to expose both versions of our application through a single public IP address, with different paths for each version. Note that the Ingress defines a host name of `gallery.local`, which we will need to add to our `hosts` file(on Linux or Mac, this file is located at `/etc/hosts`, while on Windows, it is located at `C:\Windows\System32\drivers\etc\hosts`).

If you're running Minikube on Linux or Mac, you can add the following line to your `hosts` file by running the following command:

```bash
echo "$(minikube ip) gallery.local" | sudo tee -a /etc/hosts
```

Otherwise, get the IP address of your Minikube cluster (`minikube ip`) and add it to your `hosts` file on Windows.

Deploy the application and the Ingress controller by running the following command:

```bash
kubectl apply -f deployment.yaml
kubectl apply -f ingress.yaml
```

If you're running on a local machine, open your browser and navigate to `http://gallery.local/v4` to see the first version of the application, and `http://gallery.local/v5` to see the second version. You should see different versions of the application being served through the same public IP address, with different paths for each version.

When running in a Codespace, you can use the `curl` command to see the response from the different Ingress paths:

```bash
curl -sL http://gallery.local/v4 | grep "<title>"
curl -sL http://gallery.local/v5 | grep "<title>"
```

Since the NGINX Ingress controller is retired, let's delete it and use the Gateway API with Istio instead:

```bash
kubectl delete -f ingress.yaml
minikube addons disable ingress
```

## Gateway API and Istio
The Gateway API is a new set of resources that provides a more expressive and extensible way to define ingress and routing rules in Kubernetes. It is designed to replace the Ingress resource and provide more advanced features such as traffic splitting, retries, and timeouts. Istio is a popular service mesh that provides advanced traffic management capabilities, including support for the Gateway API. In this lab, we will use Istio to expose our application through a Gateway resource, which is part of the Gateway API.

Before we start, let's make sure that Istio is installed in our cluster. Minikube has a nice feature that allows you to enable Istio with a single command:

```bash
minikube addons enable istio
```

Once the installation is done, take a look at the [gateway.yaml](gateway.yaml) and [http-route.yaml](http-route.yaml) files to see how they define a Gateway resource and an HTTPRoute resource for routing traffic to our application. The Gateway resource defines a listener on port 8080 for the host name `gallery.local`, while the HTTPRoute resource defines two rules for routing traffic to the two versions of our application based on the request path. The first rule routes traffic to the `gallery-svc-v4` Service when the request path starts with `/v4`, while the second rule routes traffic to the `gallery-svc-v5` Service when the request path starts with `/v5`. This allows us to expose both versions of our application through a single public IP address, with different paths for each version. As you can see, the Gateway API is more modular and flexible than the Ingress resource.

Deploy the application and the Gateway resources by running the following command:

```bash
kubectl apply -f gateway.yaml
kubectl apply -f http-route.yaml
```

We are still using the same host name of `gallery.local`, so make sure that you still have it in your `hosts` file. If you are running on a local machine, open your browser and navigate to `http://gallery.local:8080/v4` to see the first version of the application, and `http://gallery.local:8080/v5` to see the second version. You should see different versions of the application being served through the same public IP address, with different paths for each version.

When running in a Codespace, you can use the `curl` command to see the response from the different Ingress paths:

```bash
curl -sL http://gallery.local:8080/v4 | grep "<title>"
curl -sL http://gallery.local:8080/v5 | grep "<title>"
```

Istio allows you to define more advanced routing rules, such as traffic splitting. Remember the canary deployment strategy? Let's build this using Istio. First, delete the existing resources:

```bash
kubectl delete -f gateway.yaml
kubectl delete -f http-route.yaml
kubectl delete -f deployment.yaml
```

Now take a look at the [http-route-canary.yaml](http-route-canary.yaml) file. Instead of routing based on the request path, we define multiple backends and assign weights to them. In this case, we route 90% of the traffic to the `gallery-svc-v4` Service and 10% of the traffic to the `gallery-svc-v5` Service. This allows us to gradually roll out the new version of our application and monitor its performance before fully switching over.

Deploy the application and the Gateway resources by running the following command:

```bash
kubectl apply -f deployment-canary.yaml
kubectl apply -f gateway.yaml
kubectl apply -f http-route-canary.yaml
```

**Note:** The `deployment-canary.yaml` file is almost identical to the `deployment.yaml` file but doesn't set a custom `BASE_PATH` for the two versions as both of them now share the same path `/`.

If you are running on a local machine, open your browser and navigate to `http://gallery.local:8080`. You will see one version of the application being served. When you refresh the page multiple times, you will eventually see the other version of the application being served as well. This is because 90% of the traffic is routed to the `gallery-svc-v4` Service and 10% of the traffic is routed to the `gallery-svc-v5` Service.

To verify this, let's use `curl`, which also works in a Codespace, to make multiple requests to the application and see the response:

```bash
for i in {1..100}; do curl -sL http://gallery.local:8080 | grep "<title>"; done
```

You should see that roughly 90% of the requests return the title of the first version of the application and roughly 10% of the requests return the title of the second version of the application. This is a simple example of how to use Istio and the Gateway API to implement a canary deployment strategy.

Let's clean up everything:

```bash
kubectl delete -f gateway.yaml
kubectl delete -f http-route-canary.yaml
kubectl delete -f deployment-canary.yaml
```

If you want, you can also uninstall Istio by running:

```bash
minikube addons disable istio
```

In case you want to learn more about Istio, check out the [Istio documentation](https://istio.io/latest/docs/). It provides a lot of information about the features and capabilities of Istio, including traffic management, security, observability, and more.