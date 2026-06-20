# Kubernetes Crash Course: For Absolute Beginners — Notes

> Course: Crash Course: Kubernetes For Absolute Beginners (KodeKloud)  
> Status: ✅ COMPLETED — 2026-06-17 (11/13 lessons; remaining 2 are navigation-only)  
> Next: Kubernetes for the Absolute Beginners - Hands-on Tutorial → notes in `k8s-beginners.md`

---

##Kubernetes

A container orchestration technology that manages and deploys thousands of containers in a cluster

##Nodes

A machine where kubernetes is deployed. 

## Cluster 

A group of nodes working together 

## Master 

Another node with kubernetes installed on it. The master watches over the nodes in the cluster and is responsible for the actual orchestration of containers on the worker nodes. 

##Kubectl commands : 

```bash
kubectl run hello-minikube  # is used to deploy an application on the cluster
kubectl cluster-info  # is used to get information about the cluster
kubectl get nodes  # is used to get information about all nodes in the cluster
kubectl run nginx-pod --image=nginx  # is used to create a pod named nginx-pod based on an nginx image
kubectl get pods -o wide  # to check for the node the pod is placed on
kubectl describe pod nginx  # events section is your best debug tool
kubectl create -f pod-definition.yml  # create a pod based on the definition saved in a file
```

## Pod

A single instance of an application. A smaller object you can create on kubernetes. A Pod is a wrapper around one or more containers that share network + storage.You never talk to a container directly — you talk to the Pod.

-- On object definition we have:  
## apiVersion
This is the version of the Kubernetes API we are using to create the object. Depending on what we are trying to create, we must use the right API version. Different objects need different versions

## Kind 
This refers to the type of object we are trying to create. (pod - service - replicaset - deployment)

## metadata
 name (string) and/or labels (dictionary)
