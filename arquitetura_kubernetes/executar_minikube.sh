#!/usr/bin/env bash
# Sobe o Pod e o Service no minikube e salva a saída de cada comando em artefatos/
# Uso: ./executar_minikube.sh
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p artefatos
LOG="artefatos/execucao_$(date +%Y%m%d_%H%M%S).log"

run() {
  echo "\$ $*" | tee -a "$LOG"
  "$@" 2>&1 | tee -a "$LOG"
  echo | tee -a "$LOG"
}

run minikube start
run minikube status
run kubectl get nodes -o wide

# Em um cluster recém-criado, a ServiceAccount "default" leva alguns segundos para existir
until kubectl get serviceaccount default >/dev/null 2>&1; do sleep 2; done

run kubectl apply -f pod.yml
run kubectl apply -f service.yml
run kubectl wait --for=condition=Ready pod/meu-app-python --timeout=180s

run kubectl get pods -o wide --show-labels
run kubectl get svc meu-app-python-service -o wide
run kubectl describe pod meu-app-python
run kubectl describe svc meu-app-python-service
run kubectl get endpoints meu-app-python-service
run kubectl logs meu-app-python

URL="$(minikube service meu-app-python-service --url)"
echo "URL do Service: $URL" | tee -a "$LOG"
run curl -s "$URL"

echo "Log salvo em $LOG"
echo "Abra $URL no navegador e tire um print para a pasta artefatos/."
