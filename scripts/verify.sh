#!/usr/bin/env bash
# verify.sh v0 — cobre apenas INV-1..INV-4 (invariantes cujos alvos já existem).
# Ver .planning/01-matriz.md para o restante dos critérios de aceite e seus blocos.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

BASE="${BASE:-93e557087e6112aa8628f91024a80542b8af9a44}"

pass=0
total=4

echo "verify.sh v0 — BASE=$BASE"
echo

# INV-1: código e transcrição intocados desde BASE (restrição absoluta do enunciado)
diff_out="$(git diff --name-only "$BASE" -- src prisma tests package.json package-lock.json tsconfig.json TRANSCRICAO.md 2>&1)"
if [ -z "$diff_out" ]; then
  echo "INV-1 OK — nenhum arquivo protegido (src/, prisma/, tests/, package.json, package-lock.json, tsconfig.json, TRANSCRICAO.md) mudou desde \$BASE"
  pass=$((pass + 1))
else
  echo "INV-1 FALHA — arquivos protegidos modificados desde \$BASE:"
  echo "$diff_out" | sed 's/^/  /'
fi

# INV-2: TRANSCRICAO.md byte-a-byte idêntico ao BASE (reforço independente do INV-1)
hash_now="$(sha256sum TRANSCRICAO.md | awk '{print $1}')"
hash_base="$(git show "$BASE:TRANSCRICAO.md" 2>/dev/null | sha256sum | awk '{print $1}')"
if [ "$hash_now" = "$hash_base" ]; then
  echo "INV-2 OK — sha256(TRANSCRICAO.md) == sha256(TRANSCRICAO.md em \$BASE) [$hash_now]"
  pass=$((pass + 1))
else
  echo "INV-2 FALHA — hash divergente: atual=$hash_now base=$hash_base"
fi

# INV-3: entregáveis não estão bloqueados por .gitignore (local, global ou de sistema)
# NOTA: testar check-ignore contra README.md/docs/docs-adrs/.planning/scripts diretamente
# não detecta nada, porque esses caminhos já estão rastreados — o check-ignore padrão nunca
# reporta como ignorado um caminho já no índice, mascarando qualquer regra nova no .gitignore
# (confirmado por teste negativo, ver .planning/01-teste-negativo.md). O risco real é bloquear
# a CRIAÇÃO de arquivos futuros (novos ADRs, novos docs) — por isso o teste usa uma sonda
# hipotética (arquivo que ainda não existe) dentro de cada diretório protegido.
ignored_out="$(git check-ignore -v \
  README.md \
  docs/PROBE-preflight-check.md \
  docs/adrs/ADR-999-probe.md \
  .planning/probe-novo.md \
  scripts/probe-novo.sh \
  2>&1)"
if [ -z "$ignored_out" ]; then
  echo "INV-3 OK — nem os entregáveis existentes nem arquivos futuros hipotéticos em docs/, docs/adrs/, .planning/, scripts/ estão bloqueados por .gitignore"
  pass=$((pass + 1))
else
  echo "INV-3 FALHA — caminho(s) bloqueado(s) por regra de .gitignore:"
  echo "$ignored_out" | sed 's/^/  /'
fi

# INV-4: índice do git livre de node_modules/, .env, dist/, .idea/, .DS_Store
hygiene_out="$(git ls-files | grep -iE "node_modules/|\.env$|dist/|\.idea/|\.DS_Store" || true)"
if [ -z "$hygiene_out" ]; then
  echo "INV-4 OK — índice sem node_modules/, .env, dist/, .idea/ ou .DS_Store"
  pass=$((pass + 1))
else
  echo "INV-4 FALHA — caminho(s) indevido(s) no índice:"
  echo "$hygiene_out" | sed 's/^/  /'
fi

echo
echo "$pass/$total OK"

[ "$pass" -eq "$total" ]
