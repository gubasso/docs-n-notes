# Kubernetes

<!-- vim-markdown-toc GFM -->

* [General](#general)
* [minikube](#minikube)
* [kubeclt](#kubeclt)
* [Configuration File (declarative approach)](#configuration-file-declarative-approach)
* [Resources:](#resources)

<!-- vim-markdown-toc -->

## General

- Master Node
- Worker Node

- Objects
    - Pods
        - 1/n containers
        - share volumes with other pods
        - cluster-internal IP (localhost)
            - IP changes when pod is replaced
        - behaves like containers (e.g. will not persist data inside)
    - Deployments
        - controls multiple pods
        - we can have multiple deployments
    - Services
        - exposes Pods
            - internally: to the cluster (default)
            - externally
        - group Pods with shared IP
    - Volume

- [Install tools docs/guide](https://kubernetes.io/docs/tasks/tools/)

- `kubectl`: tool for sending instructioins to the cluster

- `minikube`: install locally, simulates k8s cluster
    - 1 vm with master and worker node
    - run as a dev environment
    - single node cluster

- `kubelet`: manages the Pod and containers
    - monitors pod and check health

## minikube

- `minikube start --driver=<driver_name>`
    - `<driver_name>`: e.g. `virtualbox`

- `minikube status`

- `minikube dashboard`
    - web dashboard

## kubeclt

- Always runs in local machine
- To send instructions to k8s cluster

- `<object(s)>`: can be `deployments`, `pods`, etc...

- `kubectl create deployment <depl_name> --image=<image_name>`
    - `<image_name>`: the cluster will look for the image name
        - the cluster is not in our local machine
        - will not reach the local machine to search for image by name
        - image has to be in a registry
        - container that will run inside the pod

- `kubeclt get <object>`
    - list of objects

- `kubeclt delete <object> <obj_name>`
    - deletes object

- `kubectl create service ...`
    - creates a service

- `kubectl expose deployment <depl_name> --type=<type> --port=8080`
    - creates a service too, with more options??
    - `<type>`
        - `ClusterIP`: reachable only inside the cluster
        - `NodePort`:
            - exposed externally
            - IP address of Worker Node
        - `LoadBalancer`:
            - unique address generated by the load balancer
            - evenly distribute incoming traffic accross all Pods which are part of this service
            - only available if cluster supports it
            - if in `minikube`: external-ip is <pending>
                - `minikube service <deployment_name>`
                    - returns IP to access the exposed loadbalancer IP

- `kubectl scale deployment/<depl_name> --replicas=3`
    - `kubectl get pods` will show 3 pods created

---

If project is updates (code changed). Update, CI workflow.

To deploy a new version of our app.

- `kubectl set image deployment/<depl_name> <image_in_cluster>=<image_recent_built>`
    - `<image_in_cluster>`: name of image inside cluste (check dashboard)
    - `<image_recent_built>`: image from registry that was recent update/rebuilt (e.g. academind/kub-first-app)
        - only will update in cluster, if new image has a different `tag` (e.g. academind/kub-first-app:v1)
        - if same tag, will not update

---

To check the status of image update:

- `kubectl rollout status deployment/<depl_name>`

---

deployment history:

- `kubectl rollout history deployment/<depl_name>`
    - `--revision=<revision_number>`: add details to output

---

To rollback/undo some update in deployment, e.g. if requested to update an image, and image name/tag had a typo/didn't exist in registry.

The process of update will be stuck.

To end this process with error:

- `kubectl rollout undo deployment/<depl_name>`
    - undo the latest deployment
    - `--to-revision=<revision_number>`

## Configuration File (declarative approach)

`<name_I_want>.yaml`
```
```

## Resources:

- [Kubermatic](https://www.kubermatic.com/)
    - Automate operations of thousands of Kubernetes clusters across multi-cloud, on-prem, and edge environments with unparalleled density and resilience. Powered by Kubermatic Kubernetes Platform.
- [Kubernetes YAML Generator - Powered by Octopus](https://k8syaml.com/)
- [Helm Helm Chart: kubernetes k8s package manager](https://harness.io/blog/continuous-delivery/what-is-helm/)