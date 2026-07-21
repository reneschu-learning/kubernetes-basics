# Resources and Quotas
Until now, we have not specified any resource-related information about our workloads in our manifests. This is bad practice as it doesn't tell Kubernetes how many resources our containers need. This will limit Kubernetes' ability to properly place our Pods on nodes based on available and needed resources. In addition, containers that don't specify resources use - by definition - more resources than they should, and are the first candidates for eviction when the cluster has resource pressure.

## Resource Requests and Limits
Let's improve our manifests by adding resource requests and limits to our containers. Resource requests specify the minimum amount of resources that a container needs to run, while resource limits specify the maximum amount of resources that a container can use. It is always a good practice to specify both requests and limits for CPU and memory resources in your container specifications.

Take a look ath the [deployment.yaml](deployment.yaml) file. You will see that we have added resource requests and limits to our container specification. The requests specify that the container needs at least 64Mi of memory and 250m of CPU to run, while the limits specify that the container can use up to 128Mi of memory and 500m of CPU.

**Note:** CPU resources are measured in millicores, where 1000m = 1 CPU core. Memory resources are measured in bytes, with suffixes like K, M, G, etc. to denote kilobytes, megabytes, gigabytes, etc. (i.e., the SI units) and Ki, Mi, Gi, etc. to denote kibibytes, mebibytes, gibibytes, etc. (i.e., the binary units). For example, 1Mi = 1 mebibyte = 1024 * 1024 bytes while 1M = 1 megabyte = 1000 * 1000 bytes. For more information, see the [Kubernetes documentation on resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-units-in-kubernetes).

Deploy the manifest and check and then check `k9s` (describe a Pod) to see the resource requests and limits for the container:

```bash
kubectl apply -f deployment.yaml
```

Since we specified reasonable resource requests and limits, our container should be able to run without any issues and you won't see anything special. But what happens if we specify a resource request that is too high for the cluster to satisfy? Let's try it out by changing the resource requests in our manifest to something that is too high for our cluster to satisfy. For example, let's change the memory request to 128Gi:

```yaml
resources:
  requests:
    memory: 128Gi
    cpu: 250m
  limits:
    memory: 128Gi
    cpu: 500m
```

Delete the existing deployment and apply the new manifest:

```bash
kubectl delete -f deployment.yaml
kubectl apply -f deployment.yaml
```

If you check the Pods in `k9s` again, you will see that all of them are in `Pending` state. This is because the resource request for memory is too high for the cluster to satisfy, and Kubernetes cannot schedule the Pods on any node.

Delete the bad deployment and reset the manifest to the original values (64Mi for memory request and 128Mi for memory limit):

```bash
kubectl delete -f deployment.yaml
```

As you can see, Kubernetes uses resource requests to place Pods on nodes, and if the resource requests are too high, the Pods will not be scheduled. Limits, on the other hand, work slightly differently. If a container exceeds a compressible resource limit (CPU), it will be throttled. Thus, our container can only use up to 500m of CPU, and if it tries to use more than that, it will be throttled. If, however, a container exceeds a non-compressible resource limit (memory), it will be able to use more memory than the limit if the node has enough available memory. However, if the node runs into memory pressure, the container will be killed and restarted. This is because memory is a non-compressible resource, and Kubernetes cannot take away memory from a container that is using it.

## Limit Ranges
A LimitRange is a policy that defines default resource requests and limits for containers in a namespace. It can also enforce minimum and maximum resource constraints. Here is an example of a LimitRange manifest. This is useful when people often forget to specify resource requests and limits in their container specifications. By creating a LimitRange, we can ensure that all containers in the namespace have reasonable resource requests and limits. However, if a manifest specifies resource requests and limits, those values override the default values specified in the LimitRange.

Take a look at the [limit-range.yaml](limit-range.yaml) file. The LimitRange object can specify four types of constraints for containers:

- **default**: The default resource limits
- **defaultRequest**: The default resource requests
- **min**: The minimum resource requests
- **max**: The maximum resource limits

Deploy the LimitRange manifest and the two deployment manifests (one with resource requests and limits, and one without) and check the resource requests and limits for the containers in the Pods:

```bash
kubectl apply -f limit-range.yaml
kubectl apply -f deployment.yaml
kubectl apply -f deployment-no-resources.yaml
```

You can see in `k9s` that the containers in the `gallery-dep` deployment have the resource requests and limits that we specified in the manifest, while the containers in the `gallery-dep2` deployment have the default resource requests and limits that we specified in the LimitRange manifest.

Delete the deployments and then try to deploy a manifest that specifies resource requests and limits that are outside the constraints specified in the LimitRange manifest:

```bash
kubectl delete -f deployment.yaml
kubectl delete -f deployment-no-resources.yaml
```

You can try to update the [deployment.yaml](deployment.yaml) manifest to specify requests lower than the `min` values or higher than the `max` values from the LimitRange manifest. Or specify limits lower than the `min` values or higher than the `max` values from the LimitRange manifest. Then try to deploy the manifest and check the Deployment `k9s`. You will see that no Pods are created. Check the ReplicaSet underneath the Deployment (`z` key) and describe it (`d` key). You will see error messages indicating that the resource requests and limits are outside the constraints specified in the LimitRange manifest.

## Resource Quotas
A ResourceQuota is a policy that defines resource usage limits for a namespace. It can limit the total amount of resources that can be used by all the Pods in a namespace. This is useful when you want to limit the amount of resources that can be used by a team or a project in a shared cluster. For example, you can limit the total amount of CPU and memory that can be used by all the Pods in a namespace. You can also limit the number of Pods, Services, and other resources that can be created in a namespace.

Take a look at the [resource-quota.yaml](resource-quota.yaml) file. The ResourceQuota object can specify resource usage limits for a namespace. In this example, we are limiting the total number of Pods to 5.

Deploy the ResourceQuota and the Deployment manifest and check the number of Pods in the namespace:

```bash
kubectl apply -f resource-quota.yaml
kubectl apply -f deployment.yaml
```

Now try scaling the Deployment to 10 replicas:

```bash
kubectl scale deployment gallery-dep --replicas=10
```

Check the Deployment in `k9s`. You will see that it was scaled to 5 replicas, which is the maximum number of Pods allowed by the ResourceQuota. If you check the ReplicaSet underneath the Deployment (`z` key) and describe it (`d` key), you will see error messages indicating that the number of Pods is above the limit specified in the ResourceQuota manifest.

Delete the Deployment and the ResourceQuota:

```bash
kubectl delete -f deployment.yaml
kubectl delete -f resource-quota.yaml 
```