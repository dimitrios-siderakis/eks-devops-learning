# Kubernetes for the Absolute Beginners - Hands-on Tutorial — Notes

> Course: Kubernetes for the Absolute Beginners - Hands-on Tutorial (KodeKloud)
> Status: ✅ COMPLETED — 100% (57/57 lessons) on 2026-06-20
> Previous: Crash Course notes in `k8s-crash-course.md`

---

## Kubernetes Concepts

Common commands:
```bash
kubectl run nginx --image nginx
kubectl get pods
```

---

## ReplicaSets

The Replication Controller can help by automatically bringing up a new pod when the existing one fails. Thus, the replication controller ensures that the specified number of pods are running at all times, even if its just one or a hundred.

Similar terms Replication Controller & ReplicaSet.
Both have the same purpose but are not the same. Replication Controller is the older technology that is replaced by ReplicaSet.

ReplicaSet supports both equality-based and set-based selectors and usually is managed automatically by a Kubernetes Deployment. ReplicaSet must have the selector.

```bash
kubectl create -f replicaset-definition.yml
kubectl get replicatset
kubectl delete replicateset myapp-replicaset
kubectl replace -f replicaset-definition.yml
kubectl scale -replicas=6 -f replicaset-definition.yml
kubectl edit replicaset myapp-replicaset
```


## Deployments

```bash
kubectl create -f deployment-definition.yml
kubectl get deployments
kubectl get all
```


## Services
A Service in Kubernetes is an abstraction that provides a stable network endpoint for a group of Pods.

Why do Services exist?

Pods are ephemeral:

They can be deleted and recreated.
Their IP addresses can change.
A Deployment might create multiple replicas of the same application.

Instead of connecting directly to Pods, clients connect to a Service, which automatically routes traffic to the available Pods.


Deployment
    ↓
 ReplicaSet
    ↓
    Pods
      ↑
      │ (labels)
      │
   Service

Deployment manages the Pods.
ReplicaSet ensures the desired number of Pods exist.
Service provides stable networking and load balancing to those Pods.

A simple way to remember it:

Deployment = manages application instances
Service = gives those instances a stable network address


Services :
1. NodePort
2. ClusterIP
3. Load Balancer


