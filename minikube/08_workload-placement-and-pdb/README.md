# Workload Placement and Pod Disruption Budgets
By default, Kubernetes schedules workloads (Pods) on nodes based on resource availability and other factors. However, there are scenarios where you may want to influence or control where workloads are placed within your cluster. This can be achieved through various Kubernetes features such as Node Selectors, Taints and Tolerations, and Affinity/Anti-Affinity rules.

## Node Selectors
Node Selectors allow you to specify a set of key-value pairs that must match the labels on a node for a Pod to be scheduled on that node. This is a simple way to constrain pods to specific nodes. One common use case is to ensure that certain workloads run on nodes with specific hardware capabilities or geographic locations. In older versions of Kubernetes, node selectors were also used to place Pods on nodes with a specific operating system, such as Windows or Linux.

Take a look at the nodes in your cluster and their labels. You can do this using the describe functionality in `k9s` or by running the following command:

```bash
kubectl get nodes --show-labels
```

You can see that all nodes have common labels such as `kubernetes.io/arch`, `kubernetes.io/os`, and `kubernetes.io/hostname`. You can also add your own labels to nodes using the following command:

```bash
kubectl label nodes <node-name> <label-key>=<label-value>
```

For now, let's force a workload to run on the `minikube-m02` node by selecting it through the `kubernetes.io/hostname` label. Take a look at the [deployment-node-selector.yaml](deployment-node-selector.yaml) file and notice the `nodeSelector` property in the `spec` section of the `template`. You can apply it using the following command:

```bash
kubectl apply -f deployment-node-selector.yaml
```

List the Pods in `k9s` to see that all three replicas of the `gallery-dep` Deployment are running on the `minikube-m02` node. You have effectively constrained the placement of this workload to a specific node in your cluster. **Note:** If you specify a Node Selector that does not match any nodes in your cluster, the Pods will remain in a pending state until a matching node becomes available. Similarly, if the Pods are already running and the only matching node is removed from the cluster, the Pods will not be scheduled again.

## Taints and Tolerations
Taints and Tolerations provide a more flexible way to control workload placement. A Taint is applied to a node and allows you to repel certain Pods from being scheduled on that node unless the Pod has a matching Toleration. This is useful for scenarios where you want to dedicate certain nodes for specific workloads or to prevent certain workloads from running on specific nodes.

Let's apply a Taint to the `minikube-m02` node to repel all Pods except those that have a matching Toleration. We will also apply a taint to the `minikube` node that matches what most other Kubernetes implementations have on the control plane nodes. You can do this using the following commands:

```bash
kubectl taint nodes minikube-m02 workloads=frontend:NoSchedule
kubectl taint nodes minikube node-role.kubernetes.io/control-plane=:NoSchedule
```

Watch the Pods from the `gallery-dep` Deployment in `k9s`. So far, nothing happend because the Pods are already running on the `minikube-m02` node and the Taint effect only applies to new Pods (`NoSchedule`). However, when you try to scale the Deployment (e.g., `kubectl scale deployment gallery-dep --replicas=5`), you will see that the new Pods are stuck in a pending state because they cannot be scheduled on the `minikube-m02` node due to the Taint. In addition, Kubernetes cannot schedule them on another node because the `nodeSelector`. You can see the error when describing the Pods in `k9s` (`d` key).

Let's resolve the issue by adding a Toleration to the `gallery-dep` Deployment. Take a look at the [deployment-toleration.yaml](deployment-toleration.yaml) file and notice the `tolerations` property in the `spec` section of the `template`. You can apply it using the following command:

```bash
kubectl apply -f deployment-toleration.yaml
```

Watch the Pods from the `gallery-dep` Deployment in `k9s`. The updated manifest has recreated the Pods and they were scheduled on the `minikube-m02` node because they now have a matching Toleration for the Taint applied to that node. You can also scale the Deployment again (e.g., `kubectl scale deployment gallery-dep --replicas=5`) and see that the new Pods are successfully scheduled on the `minikube-m02` node.

Taints can have three different effects:
- `NoSchedule`: Pods that do not tolerate the Taint will not be scheduled on the node.
- `PreferNoSchedule`: Kubernetes will try to avoid scheduling Pods that do not tolerate the Taint on the node, but it is not a strict requirement.
- `NoExecute`: Pods that do not tolerate the Taint will be evicted from the node if they are already running on it, and new Pods that do not tolerate the Taint will not be scheduled on the node.

And Tolerations must exactly match the Taint in order for the Pod to be scheduled on the node. This includes the key, value, and effect of the Taint. Let's create another problem by changing the Taint on the `minikube-m02` node to have a different value. You can do this using the following command:

```bash
# Remove the old Taint and add a new one with a different value
kubectl taint nodes minikube-m02 workloads=frontend:NoSchedule-
kubectl taint nodes minikube-m02 workloads=frontend:NoExecute
```

As soon as you apply the new Taint, the Pods from the `gallery-dep` Deployment will be evicted from the `minikube-m02` node because they no longer have a matching Toleration for the new Taint. You can see this in `k9s` as the Pods have been terminated and are stuck in a pending state again. Let's delete the Deployment, change the Taint again, and deploy another manifest without any Node Selectors and Tolerations:

```bash
kubectl delete deployment gallery-dep
kubectl taint nodes minikube-m02 workloads=frontend:NoExecute-
kubectl taint nodes minikube-m02 workloads=frontend:PreferNoSchedule
kubectl apply -f deployment.yaml
```

Take a look at the Pods in `k9s`. You will see that all Pods are scheduled on the `minikube-m03` node because the Taint has a `PreferNoSchedule` effect and the Pods do not have a matching Toleration. However, if that node is unavailable, Pods can be rescheduled on the `minikube-m02` node because the Taint is not a strict requirement. Let's simulate a node maintenance and drain the `minikube-m03` node. You can do this using the following command:

```bash
kubectl drain minikube-m03 --ignore-daemonsets --delete-emptydir-data
```

You will see in `k9s` that all Pods on the `minikube-m03` node are evicted and rescheduled on the `minikube-m02` node. In addition, new Pods are not scheduled on the `minikube-m03` node because it is in a `SchedulingDisabled` state (see the nodes in `k9s`). Try scaling the Deployment again (e.g., `kubectl scale deployment gallery-dep --replicas=5`) and you will see that the new Pods are only scheduled on `minikube-m02` for now. Let's make the `minikube-m03` node schedulable again by uncordoning it and delete the Deployment and Taint for now. You can do this using the following commands:

```bash
kubectl uncordon minikube-m03
kubectl delete deployment gallery-dep
kubectl taint nodes minikube-m02 workloads=frontend:PreferNoSchedule-
```

## Affinity and Anti-Affinity
Affinity and Anti-Affinity rules provide a more advanced way to influence workload placement based on labels. While Taints are defined on the nodes and prevent Pods from being scheduled on certain nodes (unless they have a matching Toleration), Affinity rules are defined on the Pods and influence their scheduling based on the labels of the nodes or other Pods. Affinity rules can be used to co-locate Pods on the same node or to spread them across different nodes for high availability.

While Node Affinity tells the scheduler to place Pods on nodes with specific labels, Pod Affinity and Anti-Affinity rules tell the scheduler to place Pods in relation to other Pods. For example, you can use Pod Affinity to ensure that certain Pods are scheduled on the same node as other Pods, while Pod Anti-Affinity can be used to ensure that certain Pods are not scheduled on the same node as other Pods.

Let's look at a small example of Pod Anti-Affinity. First, deploy the [app.yaml](app.yaml) manifest. You can do this using the following command:

```bash
kubectl apply -f app.yaml
```

The manifest deploys a frontend and backend with a single Pod each. It is most likely that both Pods are scheduled on the same node (if not, delete the Deployment and deploy again). You can check this in `k9s`. Now, let's add a Pod Anti-Affinity rule to the backend Deployment to ensure that the backend Pod is not scheduled on the same node as the frontend Pod. Take a look at the [app-anti-affinity.yaml](app-anti-affinity.yaml) file and notice the `affinity` property in the `spec` section of the `template`. You can apply it using the following command:

```bash
kubectl apply -f app-anti-affinity.yaml
```

You will see in `k9s` that the backend Pod is now rescheduled on a different node than the frontend Pod. You can now delete the Deployment:

```bash
kubectl delete -f app-anti-affinity.yaml
```

## Pod Disruption Budgets
Pod Disruption Budgets (PDBs) are not directly related to workload placement; they allow you to specify the minimum number or percentage of Pods that must be available during voluntary disruptions, such as node maintenance or cluster upgrades. PDBs help ensure that your application maintains a certain level of availability during these disruptions. This can help prevent situations where too many Pods are evicted at once, leading to downtime for your application.

Take a look at the [deployment-all-nodes.yaml](deployment-all-nodes.yaml) manifest. It deploys our sample application with a Toleration that allows the Pods to be scheduled on all nodes in the cluster, including the control plane node. Now take a look at the [pdb.yaml](pdb.yaml) manifest. It defines a PDB for all Pods in the `gallery-dep` Deployment, allowing a maximum of 1 Pod to be unavailable during voluntary disruptions. You can apply both manifests using the following command:

```bash
kubectl apply -f deployment-all-nodes.yaml
kubectl apply -f pdb.yaml
```

You should see in `k9s` that all 6 Pods from the `gallery-dep` Deployment are distributed across all nodes in the cluster. Now, let's simulate a node maintenance and drain the `minikube-m02` node. You can do this using the following command:

```bash
kubectl drain minikube-m02 --ignore-daemonsets --delete-emptydir-data
```

You will see on the command line that Pod eviction is slowed down, so that there are always at least 5 Pods available.

Clean up everything by deleting the PDB and Deployment, and uncordon the `minikube-m02` node:

```bash
kubectl delete pdb gallery-pdb
kubectl delete deployment gallery-dep
kubectl uncordon minikube-m02
```