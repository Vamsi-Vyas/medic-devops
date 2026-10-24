#!/bin/bash
# ==============================================================================
# Automated Blue-Green Deployment Script for Healthcare System
# Used in Jenkins Pipeline (PBL-8)
# Zero Downtime Deployment with Automated Health Verification
# ==============================================================================

set -e

NAMESPACE="healthcare"
APP_LABEL="healthcare-app"
PRODUCTION_SERVICE="healthcare-service"
PREVIEW_SERVICE="healthcare-preview-service"

echo "=================================================================="
echo "🏥 Starting Automated Blue-Green Deployment for Healthcare System"
echo "=================================================================="

# Step 1: Ensure namespace exists
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create namespace $NAMESPACE

# Step 2: Determine Current Active Color from Service Selector
CURRENT_COLOR=$(kubectl get svc $PRODUCTION_SERVICE -n $NAMESPACE -o jsonpath='{.spec.selector.version}' 2>/dev/null || echo "none")

if [ "$CURRENT_COLOR" == "blue" ]; then
    TARGET_COLOR="green"
elif [ "$CURRENT_COLOR" == "green" ]; then
    TARGET_COLOR="blue"
else
    echo "⚠️ No existing production service detected. Initializing with BLUE as active."
    CURRENT_COLOR="none"
    TARGET_COLOR="blue"
fi

echo "🟢 Current Active Version : ${CURRENT_COLOR^^}"
echo "🚀 Target Candidate Version: ${TARGET_COLOR^^}"

# Step 3: Deploy or Update Candidate Version
echo "📦 Deploying Candidate pods (${TARGET_COLOR})..."
kubectl apply -f k8s/blue-green/deployment-${TARGET_COLOR}.yaml -n $NAMESPACE

# Step 4: Wait for Rollout to Complete
echo "⏳ Waiting for ${TARGET_COLOR} deployment rollout to finish..."
kubectl rollout status deployment/healthcare-${TARGET_COLOR} -n $NAMESPACE --timeout=120s

# Step 5: Route Preview Service to Candidate for Smoke Testing
echo "🔍 Pointing preview service to ${TARGET_COLOR}..."
kubectl apply -f k8s/blue-green/service-preview.yaml -n $NAMESPACE
kubectl patch svc $PREVIEW_SERVICE -n $NAMESPACE -p "{\"spec\":{\"selector\":{\"app\":\"${APP_LABEL}\",\"version\":\"${TARGET_COLOR}\"}}}"

# Step 6: Automated Smoke Testing
echo "🧪 Running automated health checks against ${TARGET_COLOR} deployment..."
sleep 5

# Get candidate pod IP or test via service
CANDIDATE_POD=$(kubectl get pods -n $NAMESPACE -l app=$APP_LABEL,version=$TARGET_COLOR -o jsonpath='{.items[0].metadata.name}')

echo "Checking pod: $CANDIDATE_POD"
HEALTH_CHECK=$(kubectl exec -n $NAMESPACE $CANDIDATE_POD -- wget -qO- http://localhost:3000/healthz 2>/dev/null || echo "FAILED")

if [[ "$HEALTH_CHECK" == *"UP"* ]]; then
    echo "✅ Health check passed! Response: $HEALTH_CHECK"
else
    echo "❌ Health check FAILED for candidate deployment: $HEALTH_CHECK"
    echo "Aborting switchover. Production remains on ${CURRENT_COLOR}."
    exit 1
fi

# Step 7: Flip Production Traffic to Target Color (Zero-Downtime Cutover)
echo "🔄 Switching Production traffic to ${TARGET_COLOR^^}..."
if [ "$CURRENT_COLOR" == "none" ]; then
    kubectl apply -f k8s/blue-green/service-production.yaml -n $NAMESPACE
fi

kubectl patch svc $PRODUCTION_SERVICE -n $NAMESPACE -p "{\"spec\":{\"selector\":{\"app\":\"${APP_LABEL}\",\"version\":\"${TARGET_COLOR}\"}}}"

echo "=================================================================="
echo "🎉 SUCCESS: Production traffic seamlessly switched to ${TARGET_COLOR^^}!"
echo "Production Service: NodePort 30080 -> ${TARGET_COLOR^^}"
echo "Preview Service   : NodePort 30081 -> ${CURRENT_COLOR^^}"
echo "=================================================================="
