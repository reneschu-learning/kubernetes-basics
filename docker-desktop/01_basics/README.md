# Pods, ReplicaSets, and Deployments
Let's start with the basics of Kubernetes. In this section, we will cover Pods, ReplicaSets, and Deployments, which are fundamental concepts in Kubernetes.

## Pods
A Pod is the smallest and simplest unit in the Kubernetes object model. It represents a single instance of a running process in your cluster. A Pod can contain one or more containers, which are tightly coupled and share the same network namespace, storage, and lifecycle. Pods are ephemeral by nature, meaning they can be created, destroyed, and recreated as needed.

Take a look at the [pod.yaml](pod.yaml) file to see an example of a Pod definition. You can create a Pod using the following command:

```bash
kubectl apply -f pod.yaml
```

Check the status of the Pod in k9s or by using:

```bash
kubectl get pods
```

Want to see the app in the pod? You can port-forward the pod to your local machine using

```bash
kubectl port-forward pod/gallery 8080:80
```

and then access it in your browser at `http://localhost:8080`.

While Pods are useful for running a single instance of an application, running a command inside the cluster, or debugging, they are not really managed by Kubernetes. If a Pod fails, it will not be automatically recreated. Just delete the Pod by running:

```bash
kubectl delete pod gallery
```

As you can see, Kubernetes does not automatically recreate the Pod. This is where ReplicaSets come into play.

## ReplicaSets
A ReplicaSet is a higher-level abstraction that manages the lifecycle of Pods. It ensures that a specified number of replicas of a Pod are running at any given time. If a Pod fails or is deleted, the ReplicaSet will automatically create a new Pod to maintain the desired number of replicas.

Take a look at the [replica-set.yaml](replica-set.yaml) file to see an example of a ReplicaSet definition. You can create a ReplicaSet using the following command:

```bash
kubectl apply -f replica-set.yaml
```

Check the status of the ReplicaSet and Pods in k9s or by using:

```bash
kubectl get replicaset gallery-rs
kubectl get pods
```

You can see that there are now 3 replicas of the Pod running. If you delete one of the Pods, the ReplicaSet will automatically create a new Pod to replace it.

```bash
kubectl delete pod gallery-rs-<pod-id>
```

You can also scale the number of replicas up or down using the following command:

```bash
kubectl scale replicaset gallery-rs --replicas=5
```

As you can see, ReplicaSets provide a way to ensure that a specified number of replicas of a Pod are always running. However, managing ReplicaSets directly can be cumbersome, especially when you want to update your application. This is where Deployments come into play.

## Deployments
A Deployment is a higher-level abstraction that manages ReplicaSets and provides declarative updates to Pods. It allows you to define the desired state of your application, and Kubernetes will ensure that the actual state matches the desired state. Deployments provide features such as rolling updates, rollbacks, and scaling.

Take a look at the [deployment.yaml](deployment.yaml) file to see an example of a Deployment definition. You can create a Deployment using the following command:

```bash
kubectl apply -f deployment.yaml
```

Check the status of the Deployment and Pods (and ReplicaSets) in k9s or by using:

```bash
kubectl get deployment gallery-dep
kubectl get replicasets
kubectl get pods
```

As you can see, the Deployment has created a ReplicaSet, which in turn has created the specified number of Pods. Thus, Pods are managed and scalable through the Deployment as well:

```bash
# Delete a pod and it will be recreated by the Deployment
kubectl delete pod/gallery-dep-<pod-id>

# Scale the Deployment to 5 replicas
kubectl scale deployment gallery-dep --replicas=5
```

The good thing about Deployments is that they also allow you to perform rolling updates and rollbacks. For example, if you want to update the image of your application, you can modify the Deployment definition and apply it again. Kubernetes will create a new ReplicaSet with the updated Pods and gradually replace the old Pods with the new ones. Look at the [deployment-rolling.yaml](deployment-rolling.yaml) file to see an example of a rolling update. You can apply it using:

```bash
kubectl apply -f deployment-rolling.yaml
```

Then watch the rollout status in k9s or using:

```bash
kubectl rollout status deployment/gallery-dep
```

You will see that Kubernetes starts replacing the old Pods with the new ones, ensuring that the desired number of replicas is maintained throughout the process. You can check your deployment rollout history using:

```bash
kubectl rollout history deployment/gallery-dep
```

For now, you should see two revisions, one for the initial deployment and one for the rolling update. You can also view the details of a specific revision using:

```bash
kubectl rollout history deployment/gallery-dep --revision=1
kubectl rollout history deployment/gallery-dep --revision=2
```

If something goes wrong during the update, you can easily roll back to a previous version using:

```bash
# Rollback to the previous revision
kubectl rollout undo deployment/gallery-dep

# Rollback to a specific revision
kubectl rollout undo deployment/gallery-dep --to-revision=1
```

Rolling updates are a nice way to update your application without downtime, but they require your application to be designed in a way that allows for multiple versions to run simultaneously. If that is not the case, you can set up the Deployment to perform a recreate update instead. This will terminate all the old Pods before creating the new ones, which may cause downtime but ensures that only one version of the application is running at any given time. You can set the update strategy in the Deployment definition using the `strategy` field.

Take a look at the [deployment-recreate.yaml](deployment-recreate.yaml) file to see an example of a Deployment with a recreate update strategy. You can apply it using:

```bash
kubectl apply -f deployment-recreate.yaml
```

After applying the Deployment, you can see in k9s that all the old Pods are terminated before the new Pods are created. This ensures that only one version of the application is running at any given time, but it may cause downtime during the update process. In the next module, we will learn about Services and how they can help us achieve a zero-downtime deployment strategy without the need to run multiple versions of the application simultaneously.