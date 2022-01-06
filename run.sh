#!/bin/sh

set -e
# podman machine init --cpus=4 --memory=8096
# podman machine start
# podman system connection default podman-machine-default-root
# export KIND_EXPERIMENTAL_PROVIDER=podman
# kind create cluster --config kind-config.yaml
kubectl apply -k github.com/appvia/auditd-container
kubectl --namespace auditd wait --for condition=ready pod -l name=auditd

kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml

kubectl --namespace cert-manager wait --for condition=ready pod -l app.kubernetes.io/instance=cert-manager

kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/security-profiles-operator/main/deploy/operator.yaml
kubectl --namespace security-profiles-operator wait --for condition=ready pod -l name=spod

# sed -i '' 's/https:\/\/:/https:\/\/localhost:/g' ~/.kube/config
# kubectl apply -k .
# wait for crds to be ready
# kubens security-profiles-operator
kubectl --namespace security-profiles-operator patch spod spod --type=merge -p '{"spec":{"enableLogEnricher":true}}'
kubectl --namespace security-profiles-operator wait --for condition=ready pod -l name=spod

# kubectl -n security-profiles-operator patch spod spod --type=merge -p '{"spec":{"enableBpfRecorder":true}}'
kubectl apply -f logrecorder.yaml
kubectl wait --for condition=ready pod my-pod
sleep 30
kubectl delete -f logrecorder.yaml

kubectl wait --for condition=ready sp test-recording-nginx
kubectl wait --for condition=ready sp test-recording-redis

kubectl get -o yaml sp test-recording-nginx > test-recording-nginx.yaml
kubectl get -o yaml sp test-recording-redis > test-recording-redis.yaml