#!/bin/bash

# Secret :) variables; in real life they come from e.g. Gitlab secrets
ROOT_PASSWORD='hx9PyFLGF2vA+4iqEjgXAGpz99QDNS4/'
USER_PASSWORD='bpcv0byVPiUr/8uos2BRmGBp4FXcv9lL'
REPLICATION_PASSWORD='qi8vt42tJ4sFUzeiBWij2bJOHBlTKHD+'

# This script assumes you have the right kubeconfig under ~/.kube/config

msg() {
  echo "==========================="
  echo " * $1"
  echo
}

end() {
  echo
  echo
}

# msg "Creating namespace..."
# kubectl apply -f namespace.yaml
# end

msg "Deploying nfs server..."
helm template \
  --name nfs \
  --namespace kube-system \
  charts/nfs-server-provisioner > \
  templated.yaml
kubectl apply -n kube-system -f templated.yaml
end

# msg "Deploying db..."
# helm template \
#   --name mariadb \
#   --namespace wp \
#   --set mariadb.rootUser.password=$ROOT_PASSWORD \
#   --set mariadb.db.password=$USER_PASSWORD \
#   --set mariadb.replication.password=$REPLICATION_PASSWORD \
#   charts/mariadb > \
#   templated.yaml
# kubectl apply -n wp -f templated.yaml
# end

# msg "Creating pvc..."
# kubectl apply -f namespace.yaml
# end
