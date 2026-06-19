# Kubernetes for the Absolute Beginners - Hands-on Tutorial — Notes

> Course: Kubernetes for the Absolute Beginners - Hands-on Tutorial (KodeKloud)
> Status: 🔄 IN PROGRESS
> Previous: Crash Course notes in `k8s-crash-course.md`

---

## Kubernetes Concepts

Commands:
**kubectl run nginx --image nginx**
**kubectl get pods**

---

## ReplicaSets

The Replication Controller can help by automatically bringing up a new pod when the existing one fails. Thus, the replication controller ensures that the specified number of pods are running at all times, even if its just one or a hundred.

Similar terms Replication Controller & ReplicaSet.
Both have the same purpose but are not the same. Replication Controller is the older technology that is replaced by ReplicaSet.

ReplicaSet supports both equality-based and set-based selectors and usually is managed automatically by a Kubernetes Deployment. ReplicaSet must have the selector 

*kubectl create -f replicaset-definition.yml*
*kubectl get replicatset*
*kubectl delete replicateset myapp-replicaset*
*kubectl replace -f replicaset-definition.yml*
*kubectl scale -replicas=6 -f replicaset-definition.yml*
*kubectl edit replicaset myapp-replicaset*


## Deployments

*kubectl create -f deployment-definition.yml*
*kubectl get deployments*
*kubectl get all*

## Resource Limits

## Self-Healing Applications

## Rolling Updates & Rollbacks

## Services

## Namespaces

## ConfigMaps

## Secrets

## Init Containers

