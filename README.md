# Kubernetes Basics Demo
This repository contains demos describing the basics of Kubernetes. The repository contains two flavors of demos: one for Minikube and one for Docker Desktop.

The demo uses several versions of a sample application called `picture-gallery`. You can find the source code of the application in [this](https://github.com/reneschu-learning/picture-gallery) repository. If you want to see the exact code that corresponds to the different versions used in the deployments, check out the version tags in the `picture-gallery` repository.

## Docker Desktop
The Docker Desktop demos are designed to be run on a Kubernetes cluster created through Docker Desktop using Kind. If you haven't already done so, please install Docker Desktop and enable Kubernetes in the settings. Ensure that you are using Kind as the Kubernetes cluster provider and you set up three nodes.

During the demos, you will be using `kubectl` to interact with the Kubernetes cluster and `k9s` to visualize the cluster resources. When running on your local machine, make sure that you install `k9s` by following the instructions in the [k9s documentation](https://k9scli.io/topics/install/). If you are running the demos in GitHub Codespaces, `k9s` is already installed and ready to use.

## Minikube
The Minikube demos are designed to be run on a Kubernetes cluster created through Minikube. You can either install Minikube on your local machine or use GitHub Codespaces to run the demos in a cloud environment.

### Minikube on your local machine
To install Minikube on your local machine, follow the instructions in the [Minikube documentation](https://minikube.sigs.k8s.io/docs/start/). After installing Minikube, you can start a cluster with the following command:

```bash
minikube start --nodes=3
```

### Minikube in GitHub Codespaces
To run the Minikube demos in GitHub Codespaces, you can use the provided `devcontainer.json` configuration. This configuration sets up a development environment with Minikube and the necessary tools pre-installed. To start a Codespace, click the "Code" button in the repository and select "Open with Codespaces". Once the Codespace is ready, you will see a `minikube.log` file showing up in the root of the repository. The Codespace will automatically start a Minikube cluster with three nodes. Wait until you see a message similar to the following in the `minikube.log` file:

```
* Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

You can also check the status of the Minikube cluster by running the following command in the terminal:

```bash
minikube status
```

In case Minikube is not running or did not start after your Codespace timed out, you can start it manually by running the following command:

```bash
minikube start --nodes=3
```

When everything is working, you should open a second terminal in the Codespace (click the "+" button in the terminal tab) and run `k9s` to visualize the cluster resources. You can switch between the two terminals using the terminal tab at the bottom of the Codespace window.