# Health Checks
So far, we have seen how to use Deployments and Services to deploy and expose our applications. We have also seen that Kubernetes can automatically restart our application if it crashes. However, what happens if our application is running but is not functioning correctly? For example, what if our application is returning errors or is taking too long to respond? In this case, Kubernetes will not know that there is a problem and will continue to send traffic to the application, which can lead to a poor user experience.

To solve this problem, Kubernetes provides a mechanism called health checks. Health checks allow us to define a set of conditions that determine whether our application is healthy or not. If the application fails the health check, Kubernetes can take action to fix the problem, such as restarting the application or removing it from the load balancer.

## Startup, Liveness, and Readiness Probes
Imagine that we have a web application that takes a long time to start up. If we deploy this application to Kubernetes, it may take several seconds or even minutes for the application to become ready to serve traffic. During this time, Kubernetes will continue to send traffic to the application, which can lead to errors and timeouts. Or worse, Kubernetes may think that the application is unhealthy and restart it, which will lead to an endless loop of restarts.

To avoid this problem, Kubernetes provides a special type of health check called a startup probe. A startup probe is a health check that is used to determine whether an application has started up successfully. While the startup probe is running, Kubernetes will not check other probes to avoid restarting the application before it has had a chance to start up. Once the startup probe has completed successfully, Kubernetes will begin checking the other probes. If the startup probe fails repeatedly, Kubernetes will restart the application according to its restart policy.

Once the application is running, Kubernetes will use liveness and readiness probes to determine whether the application is healthy and ready to serve traffic. A liveness probe is a health check that is used to determine whether an application is still running. If the liveness probe fails, Kubernetes will restart the application. A readiness probe is a health check that is used to determine whether an application is ready to serve traffic. If the readiness probe fails, Kubernetes will remove the application from the load balancer until it becomes ready again, but the application will not be restarted.

Take a look at the [healt-checks.yaml](./health-checks.yaml) file, which contains a Deployment that defines a startup, liveness, and readiness probe for our application. It also contains a Service that exposes the application to the outside world. Apply the Deployment and Service to your cluster using the following command:

```bash
kubectl apply -f health-checks.yaml
```

Switch to `k9s` and watch the Pods being created. You will see that the Pods are displayed in red with the status `RUNNING` but `0/1` being `READY`. This is because the startup probe is still running and has not completed successfully yet. Once the startup probe completes successfully, the Pods will change color and you will see `1/1` in the `READY` column. Switch to the Services view and view the Pods targeted by the `gallery-svc` Service.

Let's take a look at the application. Create the Minikube tunnel and, if you are in Codespace, the proxy:

```bash
minikube tunnel

# Codespace: in a second terminal, start the proxy for the frontend service
socat TCP-LISTEN:8080,fork TCP:<external-ip frontend service>:8080
```

You can now browse to `http://localhost:8080` (or follow the popup) to see the application running. Switch to the `Config` tab. This version of the application has a checkbox at the bottom to bring it into an unhealthy state. Check the box and refresh the page. You should see an error message. Go back to `k9s`. You will see that one of the Pods in the service is marked in red and will not receive any traffic. When you now hard refresh the web page now, you should see the application running again because traffic is now routed to the two remaining healthy Pods. Note: sometimes it may take a few retries before your browser will connect to a healthy Pod.

Switch to the Pods view again, run a describe command on the unhealthy Pod (`d` key), and toggle auto-refresh (`r` key). You will see that the readiness and liveness probes are failing and, after a few seconds, see the message that the container is being restarted. Once it started up, the startup probe will run again, and the Pod will become healthy again.

Delete the Deployment and Service using the following command:

```bash
kubectl delete -f health-checks.yaml
```