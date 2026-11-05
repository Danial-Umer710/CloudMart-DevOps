#!/usr/bin/env bash
# Smoke test for the running stack:
#   docker compose up -d --build && ./scripts/smoke_test.sh
set -euo pipefail

PRODUCT=${PRODUCT_URL:-http://localhost:5001}
USERS=${USER_URL:-http://localhost:5000}
ORDERS=${ORDER_URL:-http://localhost:5002}
FRONTEND=${FRONTEND_URL:-http://localhost:8080}
EMAIL="smoke-$(date +%s)@example.com"
JSON='Content-Type: application/json'

wait_for() {
  for _ in $(seq 1 60); do curl -sf "$1" >/dev/null && return 0; sleep 2; done
  echo "FAIL: timed out waiting for $1"; exit 1
}
json() { python3 -c "import json,sys; print(json.load(sys.stdin)$1)"; }

wait_for "$PRODUCT/products"
wait_for "$USERS/health"
wait_for "$ORDERS/health"

n=$(curl -sf "$PRODUCT/products" | json '.__len__()')
[ "$n" -gt 0 ]
echo "PASS  product-service GET /products   -> $n products"

curl -sf -X POST "$USERS/register" -H "$JSON" \
  -d "{\"name\":\"Smoke\",\"email\":\"$EMAIL\",\"password\":\"pass123\"}" >/dev/null
echo "PASS  user-service POST /register     -> $EMAIL"

uid=$(curl -sf -X POST "$USERS/login" -H "$JSON" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"pass123\"}" | json '["user"]["id"]')
echo "PASS  user-service POST /login        -> user_id=$uid"

oid=$(curl -sf -X POST "$ORDERS/orders" -H "$JSON" \
  -d "{\"user_id\":$uid,\"product_id\":1,\"quantity\":1,\"total_price\":999.99}" | json '["order_id"]')
echo "PASS  order-service POST /orders      -> order_id=$oid"

code=$(curl -s -o /dev/null -w '%{http_code}' "$FRONTEND/")
[ "$code" = 200 ]
echo "PASS  frontend GET /                  -> HTTP $code"

curl -sf "$PRODUCT/metrics" | grep -q '^flask_exporter_info'
echo "PASS  product-service GET /metrics    -> Prometheus metrics exposed"

echo "SMOKE TEST PASSED"
