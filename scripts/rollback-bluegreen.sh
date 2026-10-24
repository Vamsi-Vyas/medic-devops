#!/bin/bash
# ==============================================================================
# Instant Rollback Script for Blue-Green Deployment
# Rolls back traffic immediately to the previous deployment color
# ==============================================================================

set -e

NAMESPACE="healthcare"
PRODUCTION_SERVICE="healthcare-service"

CURRENT_COLOR=$(kubectl get svc $PRODUCTION_SERVICE -n $NAMESPACE -o jsonpath='{.spec.selector.version}')

if [ "$CURRENT_COLOR" == "blue" ]; then
    ROLLBACK_COLOR="green"
else
    ROLLBACK_COLOR="blue"
fi

echo "⚠️ INITIATING INSTANT ROLLBACK!"
echo "Current Color  : $CURRENT_COLOR"
echo "Reverting To   : $ROLLBACK_COLOR"

kubectl patch svc $PRODUCTION_SERVICE -n $NAMESPACE -p "{\"spec\":{\"selector\":{\"app\":\"healthcare-app\",\"version\":\"${ROLLBACK_COLOR}\"}}}"

echo "✅ Rollback complete! Production traffic restored to ${ROLLBACK_COLOR^^}."
