# Show K8s Cluster Components
This demo is designed to be run on a Kubernetes cluster created through Minikube. If you are running on a different cluster, the commands may vary slightly.

## Show nodes in the cluster
Take a look at the nodes in the cluster with the following command:

```bash
kubectl get nodes -o wide
```

## Show namespaces in the cluster
See the namespaces in the cluster with the following command:

```bash
kubectl get namespaces
```

## Show pods in the kube-system namespace
Let's take a closer look at the control plane components running in the `kube-system` namespace. You can do this with the following command:

```bash
kubectl get pods -n kube-system -o wide
```

See the kube-apiserver, kube-controller-manager, kube-scheduler, and etcd? These are the core components of the Kubernetes control plane. You can also see other components like CoreDNS, kube-proxy, and any other add-ons that may be running in the cluster. Note that some components run on all nodes in the server (e.g., kube-proxy for networking).

## Where are kubelet and the container runtime?
The kubelet is the primary "node agent" that runs on each node in the cluster. It is responsible for managing the pods and containers on that node. You can see the kubelet running on each node by checking the processes on the node itself, but it does not appear as a pod in the `kube-system` namespace because it is a system service running directly on the host.

Similarly, the container runtime (e.g., Docker, containerd) runs on each node and is responsible for running the containers. Like the kubelet, it is not a pod in the `kube-system` namespace but a system service on the host.

Run `kubectl describe node/<node-name>` to see the versions of kubelet and containerd. Seeing the actual processes requires access to the node itself. In a Kind cluster in Docker Desktop, you can to this by running a debug container and elevating to the host:

```bash
kubectl debug node/<node-name> -it --image=ubuntu
chroot /host
ps aux | grep kubelet
ps aux | grep containerd
```

Leave the debug container by typing `exit` twice.