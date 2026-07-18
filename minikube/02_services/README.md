# Services and Advanced Deployment Strategies
Deploying PODs in Kubernetes is great, but how do we expose them to the outside world? This is where Services come in. A Service in Kubernetes is an abstraction that defines a logical set of Pods and a policy by which to access them. Services enable communication between different components of an application and can also expose your application to external traffic.

## ClusterIP
The default type of Service is ClusterIP. This type of Service exposes the Pods on a cluster-internal IP. This means that the Service is only accessible from within the cluster. ClusterIP is useful for internal communication between different components of an application that are running within the same Kubernetes cluster.

Look at the [deployment.yaml](./deployment.yaml) and [cluster-ip.yaml](./cluster-ip.yaml). The first file deploys two versions of our sample application, while the second file creates a ClusterIP Service that exposes the Pods created by the deployment. Deploy both files using the following command:

```bash
kubectl apply -f deployment.yaml
kubectl apply -f cluster-ip.yaml
```

Use k9s to see the two Deployments, the Pods created by the Deployments, and the Service that exposes the Pods. You will see that the Service has a cluster IP, but no external IP. When looking at the Pods behind the Service, you see that it targets all four Pods created by the two Deployments, because the Service only used the `app: gallery` label to select the Pods and ignored the `version` label. Since the Service is of type ClusterIP, you can only access it from within the cluster. Let's use a temporary Pod to test the Service. Create a temporary Pod using the following command:

```bash
kubectl run -it --rm --restart=Never busybox --image=busybox sh
```

You are now connected to a temporary Pod running BusyBox. From here, you can use the `wget` command to test the Service. Run the following command to access the Service:

```bash
wget -qO- http://gallery-svc

# You can also use the full URL with the namespace if the Service is in a different namespace
# The format is `<service-name>.<namespace>.svc.<cluster domain>`.
# E.g., if the Service is in the `default` namespace, and you did not specify a custom cluster domain, you can access it using the following command:
wget -qO- http://gallery-svc.default.svc.cluster.local
```

Note that the Service creates a DNS entry for the Service name, which is why we can access it using the Service name instead of the IP address. This is a powerful feature of Kubernetes Services, as it allows you to decouple the application from the underlying infrastructure and makes it easier to manage and scale your applications. Since our sample application is based on React, you don't see that much HTML content, but you can see the application's version in the title element, so the Service is working and is able to route traffic to the Pods. In fact, the service is load-balancing the traffic between all the Pods that it targets. You can run the `wget` command multiple times to see that the response comes from different Pods, as indicated by the version in the title element:

```bash
for i in $(seq 1 20); do wget -qO- http://gallery-svc | grep "<title>"; done
```

Exit the temporary Pod by typing `exit` and pressing Enter.

## LoadBalancer
The LoadBalancer type of Service is used to expose the application to external traffic. When you create a Service of type LoadBalancer, Kubernetes will provision an external load balancer that routes traffic to the Pods targeted by the Service. This is useful for applications that need to be accessible from outside the cluster, such as web applications or APIs. In our demo environment, we don't have an external load balancer, but Minikube provides a way to access LoadBalancer Services, so we can still test it.

Take a look at the [load-balancer.yaml](./load-balancer.yaml) file. This file creates a LoadBalancer Service that exposes the Pods created by the deployment. Deploy the file using the following command:

```bash
kubectl apply -f load-balancer.yaml
```

Again, look at the Service in k9s. You will see that the LoadBalancer Service is trying to get an external IP (the state is `<pending>`). Since we don't have any real load balancer available, the Service will be stuck. However, Minikube can connect the LoadBalancer Service to the local machine by creating a tunnel. To create the tunnel, run the following command in a separate terminal:

```bash
minikube tunnel
```

**Note:** As long as the tunnel is running, your terminal will be blocked. You can open a second terminal to run other commands.

Once the tunnel is running, you can check the Service in k9s again. You will see that the LoadBalancer Service now has an external IP. If you are on your local machine, you can open a web browser and navigate to `http://localhost:8080` to see the sample application. If you are running the demo in GitHub Codespaces, networking is a little more complicated. You can access to external IP from the terminal using `curl` or `wget`:

```bash
wget -qO- http://<external-ip>
```

To see the application in a web browser, you must first create a proxy to the external IP. The tool `socat` is already installed in the Codespaces environment, so you can use it to create a proxy. Run the following command in a separate terminal:

```bash
socat TCP-LISTEN:8080,fork TCP:<external-ip>:8080
```

When the proxy is running, you should see a popup in your Codespace asking you to open the application in the browser. You should then see the application running and should even see the load balancing in action when refreshing the page multiple times.

Stop the proxy by pression `CTRL + C` in the terminal where it is running and close the tunnel by pressing `CTRL + C` in the terminal where it is running, then delete the LoadBalancer Service using the following command:

```bash
kubectl delete -f load-balancer.yaml
```

## Blue-Green Deployment
We know from the previous module that Deployments allow us to perform rolling updates or recreate updates. Both of these update strategies are useful, but they have their limitations (see previous module). Now that we know about Services, we can use a more advanced deployment strategy named "Blue-Green Deployment". In a Blue-Green Deployment, you have two identical environments: one for the current version (Blue) and one for the new version (Green). You can deploy the new version to the Green environment and test it without affecting the Blue environment. Once you are satisfied with the new version, you can switch traffic from the Blue environment to the Green environment. Let's set this up.

Take a look at the [blue-green.yaml](./blue-green.yaml) file. This file creates two Services, one for the `blue` environment and one for the `green` environment. Note that each Service now uses the `version` label in addition to the `app` label to select Pods from a specific Deployment. Deploy the file using the following commands:

```bash
kubectl apply -f blue-green.yaml
minikube tunnel

# Codespace: in a second terminal, start the proxy for the blue service
socat TCP-LISTEN:8080,fork TCP:<external-ip service blue>:8080
# Wait for the popup to open the browser and see the blue version of the application.

# Codespace: in a third terminal, start the proxy for the green service
socat TCP-LISTEN:8090,fork TCP:<external-ip service blue>:8090
# Wait for the popup to open the browser and see the green version of the application.
```

You can now navigate to `http://localhost:8080` (local machine) or open the browser through the first popup to version v1.0.1 of sample application as port 8080 is used by the `blue` Service. In addition, you can browse to `http://localhost:8090` (local machine) or open the browser through the second popup to see version v1.2.0 of the sample application as port 8090 is used by the `green` Service. Imagine port 8080 is the production environment that is used by external users, so they do not see the internal version on port 8090. Yet, you can test the application until it is ready to be released to the public. Once you are satisfied with the new version, you can switch traffic from the `blue` to `green` by updating the `blue` Service to select the `version: v2` label. Change the label in the `blue-green.yaml` file and apply the changes using the following command:

```bash
kubectl apply -f blue-green.yaml
```

Refresh the web browser where you saw version v1.0.1 and you should now see version v1.2.0 of the sample application, which is the new version that was previously only accessible on port 8090. You have successfully switched traffic from the `blue` environment to the `green` environment without any downtime or disruption to users. The `green` Service still exists and points to the same Pods as the `blue` Service. You can either delete the Service (and the second Deployment) or keep it for future use.

Clean up everything by stopping all proxies and the tunnel by pressing `CTRL + C` in the terminals where they are running, and delete the blue-green Service and the two Deployments using the following command:

```bash
kubectl delete -f blue-green.yaml
kubectl delete -f deployment.yaml
```