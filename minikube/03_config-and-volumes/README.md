# Configuration, Secrets, and Volumes
So far, we have learned how to deploy applications using Deployments and expose them using Services. In this module, we will learn how to configure our applications using ConfigMaps and Secrets, and how to persist data using Volumes.

## Environment Variables
Environment variables are a way to pass configuration data to applications running in containers. They can be set in the Deployment manifest file using the `env` field. Environment variables can be used to store configuration data such as database connection strings, API keys, and other application settings.

Take a look at the [deployment-env.yaml](deployment-env.yaml) file, which creates a Deployment and a corresponding Service (load balancer). Note that the container definition includes an `env` field that sets the `CONFIG_VAR1` environment variable to the value `Some value`. This environment variable can be accessed by the application running in the container. Deploy the application using the following command:

```bash
kubectl apply -f deployment-env.yaml
minikube tunnel

# Codespace: in a second terminal, start the proxy for the service
socat TCP-LISTEN:8080,fork TCP:<external-ip service>:8080
```

Then open a browser and navigate to `http://localhost:8080` (or follow the popup). This version of the application has a tab named `Config`, which displays the values of several variables and a secret. For now, only the variable `CONFIG_VAR1` shows a value.

Stop the proxy (`Ctrl + C`), stop the Minikube tunnel (`Ctrl + C`), and delete the Deployment and Service using the following command:

```bash
kubectl delete -f deployment-env.yaml
```

## ConfigMaps
ConfigMaps are used to store non-confidential data in key-value pairs. They allow you to decouple configuration artifacts from image content to keep containerized applications portable. ConfigMaps can be used to store configuration files, command-line arguments, environment variables, and other configuration data. Let's move the environment variable into a ConfigMap and add a couple more.

First, look at the [config-map.yaml](config-map.yaml) file, which creates a ConfigMap named `gallery-config` with two key-value pairs: `CONFIG_VAR1` and `CONFIG_FILE`. The `CONFIG_VAR1` key has the value `Some value from ConfigMap`, and the `CONFIG_FILE` key points to a configuration file named `/conf/config.json`. Next, look at the [deployment-config-map.yaml](deployment-config-map.yaml) file, in which we have replaced the environment variable with a reference to the ConfigMa. The container definition now includes an `envFrom` field that references the `gallery-config` ConfigMap. This allows the application to access the configuration data stored in the ConfigMap as environment variables.

Deploy the ConfigMap and Deployment using the following command:

```bash
kubectl apply -f config-map.yaml
kubectl apply -f deployment-config-map.yaml
minikube tunnel

# Codespace: in a second terminal, start the proxy for the service
socat TCP-LISTEN:8080,fork TCP:<external-ip service>:8080
```

Then open a browser and navigate to `http://localhost:8080` (or follow the popup) and switch to the `Config` tab. Now, both the variable `CONFIG_VAR1` and the variable `CONFIG_FILE` show values. Currently, the `CONFIG_FILE` variable points to a configuration file that does not exist, so you will see an error message in the field `CONFIG_FILE content`. We will fix this later.

What happens if we change the value of `CONFIG_VAR1` in the ConfigMap? Let's try it out. Edit the ConfigMap and change the value of `CONFIG_VAR1` to `New value from ConfigMap`. Then, apply the changes using the following command (remember to stop the proxy and the Minikube tunnel first):

```bash
kubectl apply -f config-map.yaml
minikube tunnel

# Codespace: in a second terminal, start the proxy for the service
socat TCP-LISTEN:8080,fork TCP:<external-ip service>:8080
```

Refresh the web page and check the `Config` tab again. You will see that the page still shows the old value of `CONFIG_VAR1`. This is because the Deployment was created with the old value of the ConfigMap, and it does not automatically update when the ConfigMap changes. To see the new value, we need to restart the Deployment:

```bash
kubectl rollout restart deployment gallery-dep
```

If you now refresh the web page and check the `Config` tab again, you will see that the page now shows the new value of `CONFIG_VAR1`.

You can also use ConfigMaps to mount configuration files into containers. Take a look at the [config-map-volume.yaml](config-map-volume.yaml) file, which creates a ConfigMap named `gallery-config-files` with a key-value pair that contains the contents of a configuration file named `config.json`. The value of the key is the contents of the file. Next, look at the [deployment-config-map-volume.yaml](deployment-config-map-volume.yaml) file, in which we have added a volume that mounts the `gallery-config-files` ConfigMap into the container at the path `/conf`. This allows the application to access the configuration file as a regular file.

Deploy the ConfigMap and deploy and restart the Deployment using the following command (remember to stop the proxy and the Minikube tunnel first):

```bash
kubectl apply -f config-map-volume.yaml
kubectl apply -f deployment-config-map-volume.yaml
minikube tunnel

# Codespace: in a second terminal, start the proxy for the service
socat TCP-LISTEN:8080,fork TCP:<external-ip service>:8080
```

In this case, you don't need to restart the deployment because we changed the deployment manifest by adding the config mag volume. This automatically causes the deployment to restart the Pods. Browse to `http://localhost:8080` (or follow the popup)and check the `Config` tab again. Now, the variable `CONFIG_FILE` points to a configuration file that exists, so you will see the contents of the file in the field `CONFIG_FILE content`. **Note:** We will discuss Volumes in more detail later in this module.

When you mount a ConfigMap as a volume and later change the contents of the ConfigMap, Kubernetes will update the contents of the volume in the container. This is different from using environment variables, where the values are set at the time of container creation and do not change when the ConfigMap changes. Since our sample application is based on React and runs in the Browser (no server-side code), it cannot  automatically update the content of the mounted ConfigMap file. However, if you were to use a server-side application, such as Node.js or Python, it would be able to read the updated values from the ConfigMap without needing to restart the Deployment.

Stop the proxy and the Minikube tunnel.

## Secrets
Secrets are used to store sensitive data, such as passwords, OAuth tokens, and SSH keys. At a high level, Secrets are similar to ConfigMaps, but they are specifically designed to handle sensitive information. However, Secrets are not encrypted but merely encoded in base64. Therefore, you should always consider other solutions like Azure Key Vault, AWS Secrets Manager, or HashiCorp Vault for storing sensitive information in production environments.

Take a look at the [secret.yaml](secret.yaml) file, which creates a Secret named `gallery-secrets` with a single secret named `SECRET1`. The value of the key is the base64-encoded value of the password. Remember that Secrets are not encrypted, so you can easily decode the value of the secret using the following command:

```bash
echo "VGhlIHN1cGVyIHNlY3JldCBwYXNzd29yZCBpczogU3VwZXJTZWNyZXQxMjMh" | base64 --decode
```

Next, look at the [deployment-cmv-secret.yaml](deployment-cmv-secret.yaml) file, in which we have referenced the `gallery-secret` Secret in the environment. This allows the application to access the sensitive data stored in the Secret as an environment variable.

Deploy the Secret and deploy and restart the Deployment using the following command:

```bash
kubectl apply -f secret.yaml
kubectl apply -f deployment-cmv-secret.yaml
minikube tunnel

# Codespace: in a second terminal, start the proxy for the service
socat TCP-LISTEN:8080,fork TCP:<external-ip service>:8080
```

Navigate to `http://localhost:8080` (or follow the popup) and check the `Config` tab again. Now, the variable `SECRET1` shows the value of the secret. Even though the value of the secret is base64-encoded, the web page shows the decoded value of the secret. Before creating the environment variable, Kubernetes decodes the value of the secret.

Similar to ConfigMaps, you can also mount Secrets as volumes into containers. Since the mechanism works exactly the same as ConfigMaps, we will not run a demo for this here.

For now, let's delete everything we have created so far using the following commands (remember to stop the proxy and the Minikube tunnel first):

```bash
kubectl delete -f secret.yaml
kubectl delete -f config-map-volume.yaml
kubectl delete -f config-map.yaml
kubectl delete -f deployment-cmv-secret.yaml
```

## Volumes
Volumes are used to persist data generated by and used by containers. They allow you to decouple storage from the lifecycle of a Pod, so that data can be preserved across container restarts. Volumes can be used to store data in a variety of storage backends, such as local disks, network-attached storage, and cloud storage. In this module, we will learn how to create Volumes and use them in our applications.

Since we are running our Kubernetes cluster on Docker Desktop, the only Volume types that are supported are `emptyDir` and `hostPath`. The `emptyDir` Volume type creates a temporary folder that can be used by all containers within a Pod, while the `hostPath` volume type mounts a file or directory from the host node's filesystem into a Pod. This allows you to persist data on the host node, so that it can be accessed by other Pods running on the same node and survives Pod restarts.

Take a look at the [deployment-full.yaml](deployment-full.yaml) file, which contains the following things:

- A deployment for our sample app using version `v1.4.0` with a corresponding ConfigMap, Secret.
- Another deployment for a new backend with two containers, which reuse the same ConfigMap:
  - The first container is a simple web API allowing the frontend to write log messages to a file (`emptyDir`) and read content from a mounted volume (`hostPath`).
  - The second container is a simple `busybox` container that runs a `tail` command to continuously show the content of the log file.
- Two services, one for the frontend and one for the backend.

Deploy the application using the following command:

```bash
kubectl apply -f deployment-full.yaml
minikube tunnel

# Codespace: in a second terminal, start the proxy for the frontend service
socat TCP-LISTEN:8080,fork TCP:<external-ip frontend service>:8080
```

Then open a browser and navigate to `http://localhost:8080` (or follow the popup), then switch to the `About` tab and, finally, to the `Config` tab. You can see that there is a new variable named `BACKEND_SERVICE`, which points to the backend service, so the application can call the backend API. Let's check if the backend is working: go to `k9s`, switch to the `Deployments` view, and open the `gallery-backend` Deployment. Select one of the Pods, hit `ENTER`, then select the `busybox` container and hit `ENTER` again to see its logs. If this Pod received traffic, you should see log messages from the frontend application. If you don't see any log messages, go back to the Pods view (hit `ESC` twice), and try again using the other Pod.

Remember, the data flow is as follows: the frontend application calls the backend API, which writes log messages to a file in the `emptyDir` volume. The `busybox` container reads the log file from the same `emptyDir` volume and displays the log messages in its logs. Thus, when you see the log message in the `busybox` container logs, it means that `emptyDir` is working as expected.

In order to test the `hostPath` volume, we need to connect directly to one of the Minikube hosts. First, check on which nodes the backend Pods run:

```bash
kubectl get pods -o wide | grep backend
```

After the IP address you see the node names (e.g., `minikube-m02` and `minikube-m03`). In Minikube, these nodes are Docker containers, so we can directly connect to one of them:

```bash
docker exec -it <node-name> /bin/bash
```

You are now attached to one of the nodes and can inspect and change its filesystem. Let's check that the file exists (it was created during the mount operation) and write some content into the file that is mounted by our Pods:

```bash
# Show the content of /tmp; you should see the hostData.json file
ls /tmp

# Write some content to the hostData.json file
echo '{ "message": "Hello from hostPath volume!" }' > /tmp/hostData.json

# Exit the container
exit
```

Now refresh the web page's `Config` tab a couple times. You should sometimes see the content of the `hostData.json`. Why only sometimes? This is because the backend Deployment runs two replicas, which should be on different nodes. Since a `hostPath` volume is tied to a specific node, only the Pod running on the node where the file was created will be able to read it. The other Pod will not see the file, and thus you will see an empty value in the `Config` tab. This is why `hostPath` volumes are not suitable for production environments, as they do not provide data redundancy or high availability.

Finally, let's delete everything again using the following command (remember to stop the proxy and the Minikube tunnel first):

```bash
kubectl delete -f deployment-full.yaml
```