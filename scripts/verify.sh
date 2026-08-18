#!/usr/bin/env bash
# verify.sh v2 — cobre apenas INV-1..INV-4 (invariantes cujos alvos já existem).
# Ver .planning/01-matriz.md para o restante dos critérios de aceite e seus blocos.
#
# v2 (2026-08-18) inverte o INV-1: de lista de BLOQUEIO para lista de PERMISSÃO.
#   Só README.md, docs/**, .planning/** e scripts/** podem divergir de $BASE.
#   Motivo e cobertura do buraco anterior: ver o comentário do próprio INV-1 e
#   os testes negativos N1..N4 em .planning/01-teste-negativo.md.
#
# v1 (2026-08-18) acrescenta, sem alterar nenhuma lógica de FALHA:
#   - resolução determinística do binário de grep (linha `engine:` na saída);
#   - guardas contra PASSAGEM VAZIA — um check que não mediu nada sai com
#     exit 2 e `ERRO DE VERIFICAÇÃO`, em vez de imprimir OK;
#   - contagem de entradas examinadas em toda linha OK. Um check que não sabe
#     dizer quantas entradas examinou não pode imprimir OK.
#
# Códigos de saída: 0 = tudo OK · 1 = FALHA de invariante · 2 = ERRO DE VERIFICAÇÃO.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

erro() { echo "ERRO DE VERIFICAÇÃO — $*" >&2; exit 2; }

# ---------------------------------------------------------------------------
# Engine de grep determinístico.
# `command -v grep` NÃO serve aqui: no shell interativo desta máquina `grep` é
# uma função que resolve para ugrep, e `command -v` devolve a string "grep",
# sem caminho. O mesmo verify.sh daria engines diferentes conforme quem o roda.
# A resolução abaixo ignora funções/alias/PATH e procura o binário real,
# preferindo GNU grep, que é o engine sob o qual os padrões deste script e as
# âncoras de .planning/02-recusa.md foram validados.
# ---------------------------------------------------------------------------
GREP=""
GREP_VER=""
for _cand in /usr/bin/grep /bin/grep /usr/local/bin/grep; do
  [ -x "$_cand" ] || continue
  _ver="$("$_cand" --version 2>/dev/null | head -1)"
  case "$_ver" in
    *"GNU grep"*) GREP="$_cand"; GREP_VER="$_ver"; break ;;
  esac
done
if [ -z "$GREP" ]; then
  # fallback: qualquer grep resolvido num ambiente limpo, contanto que seja binário
  _cand="$(env -i PATH=/usr/bin:/bin bash -c 'command -v grep' 2>/dev/null)"
  if [ -n "$_cand" ] && [ -x "$_cand" ]; then
    GREP="$_cand"
    GREP_VER="$("$_cand" --version 2>/dev/null | head -1)"
  fi
fi
[ -n "$GREP" ] || erro "nenhum binário grep utilizável encontrado"

BASE="${BASE:-93e557087e6112aa8628f91024a80542b8af9a44}"

# Guarda global: sem work tree do git, INV-1, INV-2 e INV-4 medem o vazio.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || erro "não estamos dentro de um work tree do git (cwd=$PWD)"

# Guarda de \$BASE: uma revisão inexistente faz git falhar silencioso e vários
# checks compararem vazio com vazio.
git rev-parse --verify --quiet "${BASE}^{commit}" >/dev/null \
  || erro "\$BASE não resolve para um commit: '$BASE'"

pass=0
total=4

echo "verify.sh v2 — BASE=$BASE"
echo "engine: $GREP $GREP_VER"
echo

# ---------------------------------------------------------------------------
# INV-1: nada fora do conjunto permitido muda desde BASE.
#
# Este check é uma lista de PERMISSÃO, não de bloqueio. A versão anterior
# enumerava o que era proibido tocar (src/, prisma/, tests/, package.json,
# package-lock.json, tsconfig.json, TRANSCRICAO.md) e por isso deixava passar
# tudo que não estivesse na enumeração: .gitignore, vitest.config.ts,
# docker-compose.yml, tsconfig.build.json, .eslintrc.json, .prettierrc,
# .prettierignore e .env.example podiam ser alterados sem falhar. Pior: como a
# lista era resolvida contra o que EXISTIA em $BASE, um arquivo NOVO criado
# dentro de src/ também passava.
#
# A regra agora é única e fechada: só README.md, docs/**, .planning/** e
# scripts/** podem divergir de $BASE. Qualquer outro caminho modificado (M),
# criado (A), removido (D) ou untracked é violação, exista ele em $BASE ou não.
# ---------------------------------------------------------------------------
permitido() {
  case "$1" in
    README.md|docs/*|.planning/*|scripts/*) return 0 ;;
    *) return 1 ;;
  esac
}

inv1_examinados=0
inv1_violacoes=""

# Fonte 1: tudo que diverge de $BASE no work tree (tracked).
while IFS=$'\t' read -r st p1 p2; do
  [ -n "${st:-}" ] || continue
  case "$st" in
    R*|C*)  # rename/copy: os dois lados contam
      for p in "$p1" "$p2"; do
        [ -n "$p" ] || continue
        inv1_examinados=$((inv1_examinados + 1))
        permitido "$p" || inv1_violacoes+="  $st  $p"$'\n'
      done
      ;;
    *)
      inv1_examinados=$((inv1_examinados + 1))
      permitido "$p1" || inv1_violacoes+="  $st   $p1"$'\n'
      ;;
  esac
done < <(git diff --name-status "$BASE" -- .)

# Fonte 2: arquivos novos ainda não rastreados.
while IFS= read -r p; do
  [ -n "$p" ] || continue
  inv1_examinados=$((inv1_examinados + 1))
  permitido "$p" || inv1_violacoes+="  untracked  $p"$'\n'
done < <(git ls-files --others --exclude-standard)

# Guarda de passagem vazia: as duas fontes mudas enquanto o repositório declara
# ter mudanças significa que o check não mediu nada.
if [ "$inv1_examinados" -eq 0 ] && [ -n "$(git status --porcelain)" ]; then
  erro "INV-1 examinou 0 caminhos, mas git status --porcelain não está vazio — as fontes do check não estão medindo nada"
fi

if [ -z "$inv1_violacoes" ]; then
  echo "INV-1 OK — $inv1_examinados caminhos examinados (M/A/D/untracked), 0 fora do conjunto permitido (README.md, docs/**, .planning/**, scripts/**)"
  pass=$((pass + 1))
else
  echo "INV-1 FALHA — caminho(s) fora do conjunto permitido (README.md, docs/**, .planning/**, scripts/**):"
  printf '%s' "$inv1_violacoes"
fi

# ---------------------------------------------------------------------------
# INV-2: TRANSCRICAO.md byte-a-byte idêntico ao BASE (reforço independente do INV-1)
# ---------------------------------------------------------------------------
# Passagem vazia comprovada: quando `git show` falha, o pipe para sha256sum
# produz o hash da string vazia (e3b0c442...). Com um TRANSCRICAO.md vazio em
# disco os dois lados coincidem e o check imprime OK sem ter lido nada de \$BASE.
[ -r TRANSCRICAO.md ] || erro "INV-2 não consegue ler TRANSCRICAO.md no work tree"
# `git cat-file -e` confirma a existência do blob sem passar o conteúdo por uma
# variável — command substitution comeria os newlines finais e mudaria o sha256.
git cat-file -e "$BASE:TRANSCRICAO.md" 2>/dev/null \
  || erro "INV-2 não encontrou TRANSCRICAO.md em \$BASE"
n_bytes_base="$(git cat-file -s "$BASE:TRANSCRICAO.md" 2>/dev/null || echo 0)"
[ "$n_bytes_base" -gt 0 ] || erro "INV-2: TRANSCRICAO.md em \$BASE tem 0 bytes"

n_bytes="$(wc -c < TRANSCRICAO.md)"
n_linhas="$(wc -l < TRANSCRICAO.md)"
hash_now="$(sha256sum TRANSCRICAO.md | awk '{print $1}')"
hash_base="$(git show "$BASE:TRANSCRICAO.md" | sha256sum | awk '{print $1}')"
if [ "$hash_now" = "$hash_base" ]; then
  echo "INV-2 OK — $n_linhas linhas / $n_bytes bytes conferidos, sha256 == sha256 em \$BASE [$hash_now]"
  pass=$((pass + 1))
else
  echo "INV-2 FALHA — hash divergente: atual=$hash_now base=$hash_base"
fi

# ---------------------------------------------------------------------------
# INV-3: entregáveis não estão bloqueados por .gitignore (local, global ou de sistema)
# NOTA: testar check-ignore contra README.md/docs/docs-adrs/.planning/scripts diretamente
# não detecta nada, porque esses caminhos já estão rastreados — o check-ignore padrão nunca
# reporta como ignorado um caminho já no índice, mascarando qualquer regra nova no .gitignore
# (confirmado por teste negativo, ver .planning/01-teste-negativo.md). O risco real é bloquear
# a CRIAÇÃO de arquivos futuros (novos ADRs, novos docs) — por isso o teste usa uma sonda
# hipotética (arquivo que ainda não existe) dentro de cada diretório protegido.
# ---------------------------------------------------------------------------
SONDAS=(
  README.md
  docs/PROBE-preflight-check.md
  docs/adrs/ADR-999-probe.md
  .planning/probe-novo.md
  scripts/probe-novo.sh
)
n_sondas="${#SONDAS[@]}"
[ "$n_sondas" -gt 0 ] || erro "INV-3 ficou sem sondas — a lista de caminhos a testar está vazia"

ignored_out="$(git check-ignore -v "${SONDAS[@]}" 2>&1)"
rc_ci=$?
# check-ignore: 0 = alguma sonda ignorada, 1 = nenhuma, >1 = erro de uso/ambiente.
[ "$rc_ci" -le 1 ] || erro "INV-3: git check-ignore falhou (rc=$rc_ci): $ignored_out"

if [ -z "$ignored_out" ]; then
  echo "INV-3 OK — $n_sondas sondas testadas em docs/, docs/adrs/, .planning/, scripts/ e README.md, nenhuma bloqueada por .gitignore"
  pass=$((pass + 1))
else
  echo "INV-3 FALHA — caminho(s) bloqueado(s) por regra de .gitignore:"
  echo "$ignored_out" | sed 's/^/  /'
fi

# ---------------------------------------------------------------------------
# INV-4: índice do git livre de node_modules/, .env, dist/, .idea/, .DS_Store
# ---------------------------------------------------------------------------
# Passagem vazia comprovada: rodando fora do repositório, `git ls-files` escreve
# o erro em stderr, o stdout vem vazio e o check imprime OK com zero caminhos
# examinados. A guarda global de work tree acima já cobre o caso; esta contagem
# fecha a porta para qualquer índice vazio por outro motivo.
indice="$(git ls-files)" || erro "INV-4: git ls-files falhou"
n_idx="$(printf '%s\n' "$indice" | "$GREP" -c . )"
[ "$n_idx" -gt 0 ] || erro "INV-4 encontrou um índice vazio — nada foi examinado"

hygiene_out="$(printf '%s\n' "$indice" | "$GREP" -iE "node_modules/|\.env$|dist/|\.idea/|\.DS_Store" || true)"
if [ -z "$hygiene_out" ]; then
  echo "INV-4 OK — $n_idx caminhos no índice, nenhum indevido (node_modules/, .env, dist/, .idea/, .DS_Store)"
  pass=$((pass + 1))
else
  echo "INV-4 FALHA — caminho(s) indevido(s) no índice:"
  echo "$hygiene_out" | sed 's/^/  /'
fi

echo
echo "$pass/$total OK"

[ "$pass" -eq "$total" ]
