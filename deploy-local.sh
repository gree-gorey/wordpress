#!/bin/bash

# This script assumes you have the right kubeconfig under ~/.kube/config

# "Secret" :) variables; in real life they come from e.g. Gitlab secrets
ROOT_PASSWORD='hx9PyFLGF2vA+4iqEjgXAGpz99QDNS4/'
USER_PASSWORD='bpcv0byVPiUr/8uos2BRmGBp4FXcv9lL'
REPLICATION_PASSWORD='qi8vt42tJ4sFUzeiBWij2bJOHBlTKHD+'

msg() {
  echo "==========================="
  echo " * $1"
  echo
}

end() {
  echo
  echo
}

msg "Creating namespace..."
kubectl apply -f ./manifests/namespace.yaml
end

msg "Deploying metrics-server..."
helm template \
  --name metrics-server \
  --namespace kube-system \
  charts/metrics-server > \
  templated.yaml
kubectl apply -n kube-system -f templated.yaml
# clean up test pods
kubectl delete po -n kube-system metrics-server-test --wait=false
end

msg "Deploying nfs server..."
helm template \
  --name nfs \
  --namespace kube-system \
  charts/nfs-server-provisioner > \
  templated.yaml
kubectl apply -n kube-system -f templated.yaml
end

msg "Deploying db..."
helm template \
  --name mariadb \
  --namespace wp \
  --set mariadb.rootUser.password=$ROOT_PASSWORD \
  --set mariadb.db.password=$USER_PASSWORD \
  --set mariadb.replication.password=$REPLICATION_PASSWORD \
  charts/mariadb > \
  templated.yaml
kubectl apply -n wp -f templated.yaml
# clean up test pods
TEST_POD=$(kubectl get po -n wp -o custom-columns=NAME:.metadata.name | grep mariadb-test)
kubectl delete po -n wp $TEST_POD --wait=false
end

msg "Deploying wordpress (with large-ish CPU limits)..."
helm template \
  --name wp \
  --namespace wp \
  --set db.password=$USER_PASSWORD \
  --set resources.limits.cpu=700m \
  --set resources.requests.cpu=700m \
  charts/wordpress  > \
  templated.yaml
kubectl apply -n wp -f templated.yaml
end
