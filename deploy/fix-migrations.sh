#!/bin/bash
# ============================================================================
# Reset Database — Igreja Manager
# Drops ALL data and recreates the database from scratch.
#
# Usage (from your local machine):
#   ssh -i ~/.ssh/igreja.key ubuntu@147.15.109.89 'bash -s' < deploy/fix-migrations.sh
#
# ⚠️  ATENÇÃO: Este script apaga TODOS os dados do banco!
#     Use apenas em caso de problemas irrecuperáveis com migrations.
#
# Para deploys normais, use o GitHub Actions workflow com a opção
# "reset_database" marcada no workflow_dispatch manual.
# ============================================================================
set -euo pipefail

REMOTE_DIR="/opt/igreja-manager"
cd "$REMOTE_DIR"

echo "============================================"
echo "⚠️  RESET COMPLETO DO BANCO DE DADOS"
echo "============================================"
echo ""
echo "Isso vai:"
echo "  1. Parar todos os containers"
echo "  2. Apagar o volume do PostgreSQL"
echo "  3. Recriar tudo do zero"
echo ""

# Stop everything and remove volumes
echo "▶ Step 1: Parando containers e removendo volumes..."
docker compose -f docker-compose.prod.yml down -v 2>/dev/null || true

echo "▶ Step 2: Reiniciando serviços..."
docker compose -f docker-compose.prod.yml up -d

echo "▶ Step 3: Aguardando 30s para migrations rodarem..."
sleep 30

echo "▶ Step 4: Health check..."
for i in {1..10}; do
    if curl -sf http://localhost/api/v1/health > /dev/null 2>&1; then
        echo ""
        echo "✓ Backend está saudável! Banco recriado com sucesso."
        exit 0
    fi
    echo "  Tentativa $i/10..."
    sleep 5
done

echo ""
echo "✗ Health check falhou. Verificando logs:"
docker compose -f docker-compose.prod.yml logs --tail=50 backend
exit 1
