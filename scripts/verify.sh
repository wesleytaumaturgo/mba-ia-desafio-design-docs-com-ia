#!/usr/bin/env bash
# verify.sh v7 — cobre INV-1..INV-4 (invariantes), ADR-1..ADR-4 + EST-2 (bloco 4),
# RFC-1..RFC-6 (bloco 5), FDD-1..FDD-7 (bloco 6), PRD-1..PRD-6 + INV-7 (bloco 7)
# e TRK-1..TRK-4 + GER-2 (bloco 8).
# Ver .planning/01-matriz.md para o restante dos critérios de aceite e seus blocos.
#
# v7 (2026-08-19) acrescenta os cinco checks do tracker:
#   TRK-1 header literal da tabela principal + toda linha de dados com 6
#   campos · TRK-2 cobertura ≥80% do universo de IDs C-2 extraído dos
#   DOCUMENTOS (nunca do tracker) · TRK-3 ≥70% das linhas com Fonte=TRANSCRICAO
#   e toda Localização conferível por grep -F em TRANSCRICAO.md · TRK-4 ≥5
#   linhas com Fonte=CODIGO e caminho real em git ls-files · GER-2 nenhum
#   caminho de código citado em README.md/docs/ (recursivo) é inexistente no
#   repositório, salvo o marcador (novo) de C-1. TRK-1..4 leem $TRACKER_FILE
#   (default docs/TRACKER.md) e TRK-3 lê $TRANSCRICAO_FILE (default
#   TRANSCRICAO.md), parametrizáveis para que os testes negativos rodem contra
#   cópia sob /tmp — ver .planning/08-teste-negativo.md.
#
# v6 (2026-08-19) acrescenta os sete checks do PRD:
#   PRD-1 existência, tamanho mínimo e ausência de placeholder ·
#   PRD-2 os 12 headers '## ' canônicos + '### Fora de escopo' ·
#   PRD-3 ≥8 requisitos funcionais rastreáveis (PRD-FR-NN) ·
#   PRD-4 ≥1 objetivo com meta numérica em §Objetivos e métricas de sucesso ·
#   PRD-5 ≥2 itens em §Fora de escopo, todos com '[hh:mm] Nome' conferível ·
#   PRD-6 ≥2 riscos com Probabilidade/Impacto/Mitigação preenchidos ·
#   INV-7 nenhum item de .planning/02-recusa.md reaparece como requisito
#   vigente (PRD-FR-NN, PRD-RNF-NN, FDD-CONTRATO-NN, FDD-ERR-NN) em docs/PRD.md
#   ou docs/FDD.md. Especificado em .planning/02-recusa.md §INV-7 v2, que só
#   entrou em uso agora porque antes docs/PRD.md e docs/FDD.md eram stubs (um
#   INV-7 contra arquivo vazio passa por vacuidade). Os seis checks PRD-* leem
#   $PRD_FILE (default docs/PRD.md), parametrizável para que os testes
#   negativos rodem contra uma cópia sob /tmp — ver .planning/07-teste-negativo.md.
#   O denominador do PRD-2 (a lista de 12 headers '## ' + '### Fora de escopo')
#   é digitado à mão a partir de .planning/03-design.md §6, NUNCA extraído do
#   próprio PRD.
#
# v5 (2026-08-19) acrescenta os sete checks do FDD:
#   FDD-1 existência, tamanho mínimo e ausência de placeholder ·
#   FDD-2 os 12 headers canônicos · FDD-3 endpoints com request/response/status ·
#   FDD-4 matriz de erros com prefixo WEBHOOK_ e zero código sem prefixo ·
#   FDD-5 caminhos reais na §Integração · FDD-6 Métricas/Logs/Tracing com itens ·
#   FDD-7 invariante de D-10 (nenhum dos cinco termos snake_case afirmado como
#   nome de coluna fora da subseção de mapeamento). Os sete leem $FDD_FILE
#   (default docs/FDD.md), parametrizável para que os testes negativos rodem
#   contra uma cópia sob /tmp — ver .planning/06-teste-negativo.md.
#   O denominador do FDD-2 (a lista de 12 headers) é digitado à mão a partir de
#   .planning/03-design.md §6, NUNCA extraído do próprio FDD.
#
# v4 (2026-08-19) acrescenta os seis checks do RFC:
#   RFC-1 existência, tamanho mínimo e ausência de placeholder ·
#   RFC-2 as 8 seções canônicas + revisores conferíveis na transcrição ·
#   RFC-3 alternativas descartadas com trade-off · RFC-4 questões em aberto ·
#   RFC-5 links de ADR resolvíveis · RFC-6 teto de palavras e ausência de
#   detalhe de FDD. Os seis leem $RFC_FILE (default docs/RFC.md), parametrizável
#   para que os testes negativos rodem contra uma cópia sob /tmp — ver
#   .planning/05-teste-negativo.md.
#   O denominador do RFC-2 (a lista de 8 headers) é digitado à mão a partir de
#   .planning/03-design.md §6, NUNCA extraído do próprio RFC: um denominador
#   lido do arquivo medido mede consistência do arquivo consigo mesmo.
#   Os links do RFC-5 são resolvidos contra docs/ (C-6), e não contra o
#   diretório da cópia, para que a sabotagem de link seja a única variável.
#
# v3.1 (2026-08-19) reescreve o ADR-3 com denominador EXTERNO aos ADRs:
#   as 6 decisões principais do enunciado e suas âncoras provadas vêm de
#   .planning/04-cobertura.md. A v3 tirava o denominador de .planning/03-design.md
#   §4 (o mesmo mapa que planejou os ADRs) e mantinha as 6 regex dentro do
#   script, sem prova de discriminância — media consistência interna do pacote,
#   não cobertura. Sabotagens S1..S3 em .planning/04-teste-negativo.md.
#   Nenhum ADR foi alterado por este patch.
#
# v3 (2026-08-19) acrescenta os cinco checks do pacote de ADRs:
#   ADR-1 formato e contagem de arquivos · ADR-2 seções MADR com conteúdo ·
#   ADR-3 cobertura das decisões principais ·
#   ADR-4 ADR que referencia caminho real do código · EST-2 higiene da pasta.
#   Os cinco leem $ADR_DIR (default docs/adrs), parametrizável para que os testes
#   negativos rodem contra uma cópia sob /tmp — ver .planning/04-teste-negativo.md.
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

ADR_DIR="${ADR_DIR:-docs/adrs}"
RFC_FILE="${RFC_FILE:-docs/RFC.md}"
FDD_FILE="${FDD_FILE:-docs/FDD.md}"
PRD_FILE="${PRD_FILE:-docs/PRD.md}"
TRACKER_FILE="${TRACKER_FILE:-docs/TRACKER.md}"
TRANSCRICAO_FILE="${TRANSCRICAO_FILE:-TRANSCRICAO.md}"

pass=0
total=34

echo "verify.sh v7 — BASE=$BASE"
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

# ===========================================================================
# Bloco 4 — pacote de ADRs. Todos os checks abaixo leem $ADR_DIR.
# ===========================================================================
[ -d "$ADR_DIR" ] || erro "ADR-1..ADR-4/EST-2: '$ADR_DIR' não é um diretório"

# Lista canônica de ADRs examinados pelos checks ADR-2, ADR-3 e ADR-4.
adr_files=()
while IFS= read -r _f; do
  [ -n "$_f" ] || continue
  adr_files+=("$_f")
done < <(find "$ADR_DIR" -maxdepth 1 -type f -name 'ADR-*.md' | sort)

# ---------------------------------------------------------------------------
# ADR-1: entre 5 e 8 arquivos no formato ADR-NNN-titulo-em-kebab-case.md, e essa
# contagem igual ao total de *.md da pasta menos o README.md.
# A segunda condição é o que impede que um arquivo fora do formato (ou um nono
# ADR) passe despercebido só porque o primeiro número continua na faixa.
# ---------------------------------------------------------------------------
n_md="$(ls -A "$ADR_DIR" | "$GREP" -cE '\.md$' || true)"
n_adr="$(ls -A "$ADR_DIR" | "$GREP" -cE '^ADR-[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*\.md$' || true)"
# Passagem vazia: pasta sem nenhum .md significa que o check não mediu nada.
[ "$n_md" -gt 0 ] || erro "ADR-1 não encontrou nenhum arquivo .md em $ADR_DIR — nada foi medido"
n_esperado=$((n_md - 1))
if [ "$n_adr" -ge 5 ] && [ "$n_adr" -le 8 ] && [ "$n_adr" -eq "$n_esperado" ]; then
  echo "ADR-1 OK — $n_adr ADRs no formato ADR-NNN-titulo-em-kebab-case.md (faixa 5–8), $n_md arquivos .md em $ADR_DIR, $n_esperado esperados fora o README.md"
  pass=$((pass + 1))
else
  echo "ADR-1 FALHA — $n_adr arquivo(s) no formato (exigido: 5 a 8) contra $n_esperado esperado(s) = $n_md .md menos README.md em $ADR_DIR"
fi

# ---------------------------------------------------------------------------
# ADR-2: cada ADR tem os 5 headers '## ' do MADR, e '### Positivas' e
# '### Negativas' com pelo menos uma linha não vazia de conteúdo.
# ---------------------------------------------------------------------------
adr2_examinados=0
adr2_violacoes=""
for _f in ${adr_files[@]+"${adr_files[@]}"}; do
  adr2_examinados=$((adr2_examinados + 1))
  for _h in "## Status" "## Contexto" "## Decisão" "## Alternativas Consideradas" "## Consequências"; do
    "$GREP" -qxF "$_h" "$_f" || adr2_violacoes+="  ${_f##*/} — header ausente: '$_h'"$'\n'
  done
  for _sub in "### Positivas" "### Negativas"; do
    if ! "$GREP" -qxF "$_sub" "$_f"; then
      adr2_violacoes+="  ${_f##*/} — header ausente: '$_sub'"$'\n'
      continue
    fi
    _n_conteudo="$(awk -v h="$_sub" '$0==h {f=1; next} /^#/ {f=0} f && NF {c++} END {print c+0}' "$_f")"
    [ "$_n_conteudo" -gt 0 ] || adr2_violacoes+="  ${_f##*/} — '$_sub' sem conteúdo"$'\n'
  done
done
# Passagem vazia: sem ADR para abrir, o laço acima nunca roda e o check imprimiria OK.
[ "$adr2_examinados" -gt 0 ] || erro "ADR-2 não examinou nenhum ADR-*.md em $ADR_DIR"

if [ -z "$adr2_violacoes" ]; then
  echo "ADR-2 OK — $adr2_examinados ADRs examinados, 7 seções conferidas em cada (5 headers MADR + Positivas/Negativas não vazias)"
  pass=$((pass + 1))
else
  echo "ADR-2 FALHA — seção ausente ou vazia:"
  printf '%s' "$adr2_violacoes"
fi

# ---------------------------------------------------------------------------
# ADR-3: o conjunto de ADRs cobre no mínimo 5 das 6 decisões principais da
# reunião — o critério literal do enunciado.
#
# O denominador é EXTERNO aos ADRs: as seis decisões e suas âncoras vêm da
# tabela de .planning/04-cobertura.md, digitada à mão a partir do enunciado e
# provada discriminante (T1/T2) naquele arquivo. A versão anterior deste check
# tirava o denominador de .planning/03-design.md §4 — o mesmo mapa que planejou
# os ADRs — e mantinha as seis regex dentro do próprio script, sem prova: media
# consistência interna do pacote, não cobertura das decisões da reunião.
#
# Uma linha marcada `[sem âncora viável]` conta como NÃO coberta e vira
# verificação manual (MAN-NN) — jamais coberta por omissão.
# ---------------------------------------------------------------------------
COBERTURA=".planning/04-cobertura.md"
[ -r "$COBERTURA" ] || erro "ADR-3 não consegue ler $COBERTURA"
# 3a coluna da tabela = âncora ERE; o \| do markdown é desescapado.
cob_tab="$(sed -nE 's/^\| *(COB-[0-9]) *\|[^|]*\| *`(.*)` *\| *(ADR-[0-9]{3}).*/\1\t\2/p' "$COBERTURA" \
             | sed 's/\\|/|/g')"
n_cob="$(printf '%s' "$cob_tab" | "$GREP" -c . || true)"
# Passagem vazia e denominador adulterado: as duas saem por exit 2, não por OK.
[ "$n_cob" -ge 6 ] || erro "ADR-3 carregou $n_cob âncora(s) de $COBERTURA — o denominador são as 6 decisões principais do enunciado"
[ "$n_cob" -le 6 ] || erro "ADR-3 carregou $n_cob âncoras de $COBERTURA — o denominador tem que ser exatamente 6, nem uma a mais"

adr3_cobertas=0
adr3_cobertos_ids=""
adr3_descobertas=""
while IFS=$'\t' read -r _cob _anc; do
  [ -n "$_cob" ] || continue
  if [ "$_anc" = "[sem âncora viável]" ]; then
    adr3_descobertas+=" $_cob(sem âncora viável — verificação manual)"
    continue
  fi
  if "$GREP" -qiE -e "$_anc" -- ${adr_files[@]+"${adr_files[@]}"}; then
    adr3_cobertas=$((adr3_cobertas + 1))
    adr3_cobertos_ids+=" $_cob"
  else
    adr3_descobertas+=" $_cob"
  fi
done <<< "$cob_tab"

if [ "$adr3_cobertas" -ge 5 ]; then
  echo "ADR-3 OK — $n_cob decisões principais examinadas, $adr3_cobertas cobertas (mínimo 5):$adr3_cobertos_ids"
  pass=$((pass + 1))
else
  echo "ADR-3 FALHA — $n_cob decisões principais examinadas, $adr3_cobertas cobertas (mínimo 5); sem cobertura:$adr3_descobertas"
fi

# ---------------------------------------------------------------------------
# ADR-4: pelo menos 1 ADR cita, em crase e SEM o marcador (novo), um caminho de
# arquivo que existe de fato no índice do git.
# ---------------------------------------------------------------------------
adr4_examinados=0
adr4_com_caminho_real=0
adr4_caminhos=0
for _f in ${adr_files[@]+"${adr_files[@]}"}; do
  adr4_examinados=$((adr4_examinados + 1))
  _achou=0
  while IFS= read -r _p; do
    [ -n "$_p" ] || continue
    adr4_caminhos=$((adr4_caminhos + 1))
    git ls-files --error-unmatch "$_p" >/dev/null 2>&1 && _achou=1
  done < <("$GREP" -ohE '`[A-Za-z0-9_./-]+\.(ts|js|prisma|json|sql|yml|yaml)`( *\(novo\))?' "$_f" \
             | "$GREP" -v '(novo)' | tr -d '`' | sort -u)
  [ "$_achou" -eq 1 ] && adr4_com_caminho_real=$((adr4_com_caminho_real + 1))
done
# Passagem vazia: nenhum ADR aberto significa que o check não mediu nada.
[ "$adr4_examinados" -gt 0 ] || erro "ADR-4 não examinou nenhum ADR-*.md em $ADR_DIR"

if [ "$adr4_com_caminho_real" -ge 1 ]; then
  echo "ADR-4 OK — $adr4_examinados ADRs examinados, $adr4_caminhos caminhos distintos sem (novo) conferidos contra git ls-files, $adr4_com_caminho_real ADR(s) com pelo menos um caminho real"
  pass=$((pass + 1))
else
  echo "ADR-4 FALHA — $adr4_examinados ADRs examinados, $adr4_caminhos caminho(s) sem (novo) encontrado(s), nenhum presente em git ls-files"
fi

# ---------------------------------------------------------------------------
# EST-2: docs/adrs/ não contém nada além de ADR-NNN-*.md e README.md.
# Usa `ls -A` (e não `git ls-files`) de propósito: arquivo novo ainda não
# rastreado também suja a pasta entregue.
# ---------------------------------------------------------------------------
est2_examinados=0
est2_violacoes=""
while IFS= read -r _e; do
  [ -n "$_e" ] || continue
  est2_examinados=$((est2_examinados + 1))
  [ "$_e" = "README.md" ] && continue
  printf '%s\n' "$_e" | "$GREP" -qE '^ADR-[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*\.md$' \
    || est2_violacoes+="  $_e"$'\n'
done < <(ls -A "$ADR_DIR")
# Passagem vazia: diretório sem nenhuma entrada não prova higiene, prova cegueira.
[ "$est2_examinados" -gt 0 ] || erro "EST-2 não listou nenhuma entrada em $ADR_DIR"

if [ -z "$est2_violacoes" ]; then
  echo "EST-2 OK — $est2_examinados entradas em $ADR_DIR, todas ADR-NNN-*.md ou README.md"
  pass=$((pass + 1))
else
  echo "EST-2 FALHA — entrada(s) fora do permitido (ADR-NNN-*.md, README.md) em $ADR_DIR:"
  printf '%s' "$est2_violacoes"
fi

# ===========================================================================
# Bloco 5 — RFC-1..RFC-6 sobre $RFC_FILE.
# ===========================================================================

# ---------------------------------------------------------------------------
# RFC-1: o arquivo existe, tem no mínimo 900 palavras e não sobrou placeholder
# do esqueleto.
# ---------------------------------------------------------------------------
rfc_existe=0
[ -f "$RFC_FILE" ] && rfc_existe=1

rfc1_palavras=0
rfc1_placeholder=0
if [ "$rfc_existe" -eq 1 ]; then
  rfc1_palavras="$(wc -w < "$RFC_FILE" | tr -d ' ')" \
    || erro "RFC-1 não conseguiu contar palavras de $RFC_FILE"
  rfc1_placeholder="$("$GREP" -cE '<!--.*(a ser elaborado|será preenchido).*-->' "$RFC_FILE" || true)"
fi

if [ "$rfc_existe" -eq 1 ] && [ "$rfc1_palavras" -ge 900 ] && [ "$rfc1_placeholder" -eq 0 ]; then
  echo "RFC-1 OK — $RFC_FILE existe, $rfc1_palavras palavras (mínimo 900), $rfc1_placeholder placeholder(s) do esqueleto"
  pass=$((pass + 1))
elif [ "$rfc_existe" -eq 0 ]; then
  echo "RFC-1 FALHA — $RFC_FILE não existe"
else
  echo "RFC-1 FALHA — $rfc1_palavras palavras (mínimo 900) e $rfc1_placeholder placeholder(s) '<!-- ... a ser elaborado / será preenchido ... -->' (exigido: 0) em $RFC_FILE"
fi

# Sem arquivo, RFC-2..RFC-6 não medem nada — passagem vazia sai por exit 2, e
# não por uma sequência de OK ou de FALHA que fingiria ter medido.
[ "$rfc_existe" -eq 1 ] || erro "RFC-2..RFC-6 não têm o que medir: $RFC_FILE ausente"

# ---------------------------------------------------------------------------
# RFC-2: as 8 seções canônicas de .planning/03-design.md §6, header literal, e
# a seção de Metadados com pelo menos 3 revisores conferíveis em TRANSCRICAO.md.
#
# A lista de 8 headers abaixo é o denominador e é digitada à mão a partir de
# §6 — extraí-la do próprio RFC mediria o arquivo contra ele mesmo.
# ---------------------------------------------------------------------------
rfc2_headers=(
  "## Metadados"
  "## Resumo executivo (TL;DR)"
  "## Contexto e problema"
  "## Proposta técnica"
  "## Alternativas consideradas"
  "## Questões em aberto"
  "## Impacto e riscos"
  "## Decisões relacionadas"
)
# Denominador adulterado (header somado ou removido do array) sai por exit 2.
[ "${#rfc2_headers[@]}" -eq 8 ] \
  || erro "RFC-2 carregou ${#rfc2_headers[@]} header(s) no denominador — §6 de .planning/03-design.md tem exatamente 8"

rfc2_ausentes=""
rfc2_conferidos=0
for _h in "${rfc2_headers[@]}"; do
  rfc2_conferidos=$((rfc2_conferidos + 1))
  "$GREP" -qxF "$_h" "$RFC_FILE" || rfc2_ausentes+="  header ausente: '$_h'"$'\n'
done

# Revisores: nome que aparece na seção ## Metadados E é encontrado por grep -F
# em TRANSCRICAO.md. O denominador dos nomes vem de .planning/03-design.md §2 D-07.
TRANSCRICAO="TRANSCRICAO.md"
[ -r "$TRANSCRICAO" ] || erro "RFC-2 não consegue ler $TRANSCRICAO para conferir os revisores"
rfc2_nomes=(Bruno Diego Larissa Marcos Sofia)
[ "${#rfc2_nomes[@]}" -eq 5 ] \
  || erro "RFC-2 carregou ${#rfc2_nomes[@]} nome(s) de revisor — D-07 fixa 5"

rfc2_secao="$(awk '/^## Metadados$/ {f=1; next} /^## / {f=0} f' "$RFC_FILE")"
# Seção vazia: o check não mediu nada e não pode imprimir OK por omissão.
[ -n "$rfc2_secao" ] || erro "RFC-2 encontrou a seção '## Metadados' vazia (ou ausente) em $RFC_FILE"

rfc2_revisores=0
rfc2_revisores_ids=""
for _n in "${rfc2_nomes[@]}"; do
  printf '%s\n' "$rfc2_secao" | "$GREP" -qF "$_n" || continue
  "$GREP" -qF "$_n" "$TRANSCRICAO" || continue
  rfc2_revisores=$((rfc2_revisores + 1))
  rfc2_revisores_ids+=" $_n"
done

if [ -z "$rfc2_ausentes" ] && [ "$rfc2_revisores" -ge 3 ]; then
  echo "RFC-2 OK — $rfc2_conferidos headers canônicos conferidos, 0 ausentes; $rfc2_revisores revisores em §Metadados achados por grep -F em $TRANSCRICAO (mínimo 3):$rfc2_revisores_ids"
  pass=$((pass + 1))
else
  echo "RFC-2 FALHA — $rfc2_conferidos headers conferidos, $rfc2_revisores revisor(es) conferível(is) em $TRANSCRICAO (mínimo 3):$rfc2_revisores_ids"
  printf '%s' "$rfc2_ausentes"
fi

# ---------------------------------------------------------------------------
# RFC-3: pelo menos 2 alternativas descartadas, cada uma com a linha
# '**Trade-off do descarte:**' seguida de conteúdo não vazio.
#
# O awk devolve uma linha por bloco: ID <TAB> marcador achado <TAB> conteúdo
# não vazio depois do marcador. Um bloco só conta como íntegro com os dois.
# ---------------------------------------------------------------------------
rfc3_blocos="$(awk '
  function flush() { if (id != "") printf "%s\t%d\t%d\n", id, marca, conteudo }
  /^### RFC-ALT-[0-9][0-9]/ { flush(); id=$2; marca=0; conteudo=0; next }
  /^#/                      { flush(); id=""; next }
  id != "" {
    if (index($0, "**Trade-off do descarte:**") == 1) {
      marca = 1
      resto = substr($0, length("**Trade-off do descarte:**") + 1)
      gsub(/^[ \t]+|[ \t]+$/, "", resto)
      if (length(resto) > 0) conteudo = 1
      next
    }
    if (marca == 1 && conteudo == 0 && NF > 0) conteudo = 1
  }
  END { flush() }
' "$RFC_FILE")"

rfc3_n=0
rfc3_ok=0
rfc3_violacoes=""
while IFS=$'\t' read -r _id _marca _conteudo; do
  [ -n "$_id" ] || continue
  rfc3_n=$((rfc3_n + 1))
  if [ "$_marca" -eq 0 ]; then
    rfc3_violacoes+="  $_id — sem a linha '**Trade-off do descarte:**'"$'\n'
  elif [ "$_conteudo" -eq 0 ]; then
    rfc3_violacoes+="  $_id — '**Trade-off do descarte:**' sem conteúdo"$'\n'
  else
    rfc3_ok=$((rfc3_ok + 1))
  fi
done <<< "$rfc3_blocos"

if [ "$rfc3_ok" -ge 2 ] && [ -z "$rfc3_violacoes" ]; then
  echo "RFC-3 OK — $rfc3_n blocos '### RFC-ALT-NN' examinados, $rfc3_ok com trade-off do descarte preenchido (mínimo 2)"
  pass=$((pass + 1))
else
  echo "RFC-3 FALHA — $rfc3_n blocos '### RFC-ALT-NN' examinados, $rfc3_ok íntegro(s) (mínimo 2)"
  printf '%s' "$rfc3_violacoes"
fi

# ---------------------------------------------------------------------------
# RFC-4: pelo menos 2 linhas de tabela com ID RFC-QA-NN.
# ---------------------------------------------------------------------------
rfc4_n="$("$GREP" -cE '^\| *RFC-QA-[0-9]{2} *\|' "$RFC_FILE" || true)"
if [ "$rfc4_n" -ge 2 ]; then
  echo "RFC-4 OK — $rfc4_n linhas '| RFC-QA-NN |' em $RFC_FILE (mínimo 2)"
  pass=$((pass + 1))
else
  echo "RFC-4 FALHA — $rfc4_n linha(s) '| RFC-QA-NN |' em $RFC_FILE (mínimo 2)"
fi

# ---------------------------------------------------------------------------
# RFC-5: os links relativos de ADR (C-6) resolvem para arquivo existente.
# A resolução é sempre contra docs/, o diretório canônico do RFC — não contra o
# diretório de $RFC_FILE — para que a cópia sob /tmp dos testes negativos
# mantenha o link quebrado como única variável.
# ---------------------------------------------------------------------------
rfc5_distintos=0
rfc5_quebrados=0
rfc5_lista=""
while IFS= read -r _l; do
  [ -n "$_l" ] || continue
  rfc5_distintos=$((rfc5_distintos + 1))
  if [ -f "docs/$_l" ]; then
    rfc5_lista+=" ${_l##*/}"
  else
    rfc5_quebrados=$((rfc5_quebrados + 1))
    rfc5_lista+=" ${_l##*/}(QUEBRADO)"
  fi
done < <("$GREP" -ohE '\]\(adrs/ADR-[^)]*\.md\)' "$RFC_FILE" \
           | sed -E 's/^\]\(//; s/\)$//' | sort -u)

if [ "$rfc5_distintos" -ge 2 ] && [ "$rfc5_quebrados" -eq 0 ]; then
  echo "RFC-5 OK — $rfc5_distintos links '](adrs/ADR-*.md)' distintos (mínimo 2), $rfc5_quebrados quebrado(s), resolvidos contra docs/"
  pass=$((pass + 1))
else
  echo "RFC-5 FALHA — $rfc5_distintos link(s) distinto(s) (mínimo 2), $rfc5_quebrados quebrado(s) contra docs/:$rfc5_lista"
fi

# ---------------------------------------------------------------------------
# RFC-6: teto de palavras (INV-8) e ausência de detalhe que pertence ao FDD —
# código de erro do módulo, fence json e tabela de endpoint. Ver §5 do design.
# ---------------------------------------------------------------------------
rfc6_palavras="$rfc1_palavras"
rfc6_fdd="$("$GREP" -cE 'WEBHOOK_[A-Z]|^```json|^\| *(GET|POST|PUT|PATCH|DELETE) ' "$RFC_FILE" || true)"

if [ "$rfc6_palavras" -ge 900 ] && [ "$rfc6_palavras" -le 2200 ] && [ "$rfc6_fdd" -eq 0 ]; then
  echo "RFC-6 OK — $rfc6_palavras palavras na faixa 900–2200, $rfc6_fdd linha(s) de detalhe de FDD em 3 padrões conferidos"
  pass=$((pass + 1))
else
  echo "RFC-6 FALHA — $rfc6_palavras palavras (faixa 900–2200) e $rfc6_fdd linha(s) de detalhe de FDD (exigido: 0) em $RFC_FILE"
  "$GREP" -nE 'WEBHOOK_[A-Z]|^```json|^\| *(GET|POST|PUT|PATCH|DELETE) ' "$RFC_FILE" | sed 's/^/  /' || true
fi

# ===========================================================================
# Bloco 6 — FDD-1..FDD-7 sobre $FDD_FILE.
# ===========================================================================

# ---------------------------------------------------------------------------
# FDD-1: o arquivo existe, tem no mínimo 1500 palavras e não sobrou placeholder
# do esqueleto.
# ---------------------------------------------------------------------------
fdd_existe=0
[ -f "$FDD_FILE" ] && fdd_existe=1

fdd1_palavras=0
fdd1_placeholder=0
if [ "$fdd_existe" -eq 1 ]; then
  fdd1_palavras="$(wc -w < "$FDD_FILE" | tr -d ' ')" \
    || erro "FDD-1 não conseguiu contar palavras de $FDD_FILE"
  fdd1_placeholder="$("$GREP" -cE '<!--.*(a ser elaborado|será preenchido).*-->' "$FDD_FILE" || true)"
fi

if [ "$fdd_existe" -eq 1 ] && [ "$fdd1_palavras" -ge 1500 ] && [ "$fdd1_placeholder" -eq 0 ]; then
  echo "FDD-1 OK — $FDD_FILE existe, $fdd1_palavras palavras (mínimo 1500), $fdd1_placeholder placeholder(s) do esqueleto"
  pass=$((pass + 1))
elif [ "$fdd_existe" -eq 0 ]; then
  echo "FDD-1 FALHA — $FDD_FILE não existe"
else
  echo "FDD-1 FALHA — $fdd1_palavras palavras (mínimo 1500) e $fdd1_placeholder placeholder(s) '<!-- ... a ser elaborado / será preenchido ... -->' (exigido: 0) em $FDD_FILE"
fi

# Sem arquivo, FDD-2..FDD-7 não medem nada — passagem vazia sai por exit 2.
[ "$fdd_existe" -eq 1 ] || erro "FDD-2..FDD-7 não têm o que medir: $FDD_FILE ausente"

# ---------------------------------------------------------------------------
# FDD-2: as 12 seções canônicas de .planning/03-design.md §6, header literal.
#
# A lista abaixo é o denominador e é digitada à mão a partir de §6 — extraí-la
# do próprio FDD mediria o arquivo contra ele mesmo.
# ---------------------------------------------------------------------------
fdd2_headers=(
  "## Contexto e motivação técnica"
  "## Objetivos técnicos"
  "## Escopo e exclusões"
  "## Fluxos detalhados"
  "## Contratos públicos"
  "## Matriz de erros"
  "## Estratégias de resiliência"
  "## Observabilidade"
  "## Dependências e compatibilidade"
  "## Critérios de aceite técnicos"
  "## Riscos e mitigação"
  "## Integração com o sistema existente"
)
# Denominador adulterado (header somado ou removido do array) sai por exit 2.
[ "${#fdd2_headers[@]}" -eq 12 ] \
  || erro "FDD-2 carregou ${#fdd2_headers[@]} header(s) no denominador — §6 de .planning/03-design.md tem exatamente 12 headers '## ' para o FDD"

fdd2_ausentes=""
fdd2_conferidos=0
for _h in "${fdd2_headers[@]}"; do
  fdd2_conferidos=$((fdd2_conferidos + 1))
  "$GREP" -qxF "$_h" "$FDD_FILE" || fdd2_ausentes+="  header ausente: '$_h'"$'\n'
done

if [ -z "$fdd2_ausentes" ]; then
  echo "FDD-2 OK — $fdd2_conferidos headers canônicos conferidos em $FDD_FILE, 0 ausentes"
  pass=$((pass + 1))
else
  echo "FDD-2 FALHA — $fdd2_conferidos headers conferidos, $(printf '%s' "$fdd2_ausentes" | "$GREP" -c .) ausente(s):"
  printf '%s' "$fdd2_ausentes"
fi

# ---------------------------------------------------------------------------
# FDD-3: pelo menos 4 blocos '### MÉTODO /path' e, em CADA bloco, no mínimo dois
# fences ```json (request e response) e ao menos uma linha '**Status:** NNN'.
# O bloco vai do header do endpoint até o próximo header de qualquer nível.
# A exigência é por bloco: um endpoint incompleto reprova mesmo que sobrem
# quatro completos (mesma leitura provada em S3 do bloco 5).
# ---------------------------------------------------------------------------
fdd3_blocos="$(awk '
  function flush() { if (id != "") printf "%s\t%d\t%d\n", id, fences, status }
  /^### (GET|POST|PUT|PATCH|DELETE) \// { flush(); id=$2" "$3; fences=0; status=0; next }
  /^#/                                  { flush(); id=""; next }
  id != "" {
    if ($0 ~ /^```json/)                     fences++
    if ($0 ~ /\*\*Status:\*\* *[0-9][0-9][0-9]/) status++
  }
  END { flush() }
' "$FDD_FILE")"

fdd3_n=0
fdd3_ok=0
fdd3_violacoes=""
while IFS=$'\t' read -r _id _fences _status; do
  [ -n "$_id" ] || continue
  fdd3_n=$((fdd3_n + 1))
  if [ "$_fences" -lt 2 ]; then
    fdd3_violacoes+="  $_id — $_fences fence(s) \`\`\`json (mínimo 2)"$'\n'
  elif [ "$_status" -lt 1 ]; then
    fdd3_violacoes+="  $_id — nenhuma linha '**Status:** NNN'"$'\n'
  else
    fdd3_ok=$((fdd3_ok + 1))
  fi
done <<< "$fdd3_blocos"

if [ "$fdd3_ok" -ge 4 ] && [ -z "$fdd3_violacoes" ]; then
  echo "FDD-3 OK — $fdd3_n blocos '### MÉTODO /path' examinados, $fdd3_ok com ≥2 fences \`\`\`json e ≥1 '**Status:** NNN' (mínimo 4)"
  pass=$((pass + 1))
else
  echo "FDD-3 FALHA — $fdd3_n blocos '### MÉTODO /path' examinados, $fdd3_ok íntegro(s) (mínimo 4)"
  printf '%s' "$fdd3_violacoes"
fi

# ---------------------------------------------------------------------------
# FDD-4: dentro da §Matriz de erros, pelo menos 8 linhas de tabela cujo campo de
# CÓDIGO casa WEBHOOK_[A-Z_]{3,} e ZERO código de erro sem o prefixo (C-5,
# DEC-13).
#
# Nota de leitura: o formato da matriz fixado pelo bloco é
# '| ID (FDD-ERR-NN) | Código | HTTP | ...', então o campo de código é a 2a
# célula, não a 1a. É esse campo que C-5 chama de "primeira coluna da matriz" —
# a coluna de ID é rastreabilidade (C-2), não código de erro.
#
# A segunda perna varre a seção inteira à procura de token SCREAMING_SNAKE que
# não comece com WEBHOOK_: é o que pega um código de erro do módulo escrito sem
# o prefixo, esteja ele em linha de tabela ou em prosa.
# ---------------------------------------------------------------------------
fdd4_secao="$(awk '/^## Matriz de erros$/ {f=1; next} /^## / {f=0} f' "$FDD_FILE")"
# Seção vazia: o check não mediu nada e não pode imprimir OK por omissão.
[ -n "$fdd4_secao" ] || erro "FDD-4 encontrou a seção '## Matriz de erros' vazia (ou ausente) em $FDD_FILE"

fdd4_com_prefixo="$(printf '%s\n' "$fdd4_secao" \
  | awk -F'|' '/^\| *FDD-ERR-[0-9][0-9] *\|/ {
      gsub(/^[ \t]+|[ \t]+$/, "", $3)
      # o mawk desta máquina não implementa intervalo {n,}; [A-Z_][A-Z_][A-Z_]+
      # é a forma equivalente de "no mínimo 3" e roda em qualquer awk.
      if ($3 ~ /^WEBHOOK_[A-Z_][A-Z_][A-Z_]+$/) c++
    } END { print c+0 }')"

fdd4_sem_prefixo="$(printf '%s\n' "$fdd4_secao" \
  | "$GREP" -oE '\b[A-Z][A-Z0-9]*(_[A-Z0-9]+)+\b' \
  | "$GREP" -vE '^WEBHOOK_' | sort -u || true)"
fdd4_n_sem="$(printf '%s' "$fdd4_sem_prefixo" | "$GREP" -c . || true)"

if [ "$fdd4_com_prefixo" -ge 8 ] && [ "$fdd4_n_sem" -eq 0 ]; then
  echo "FDD-4 OK — $fdd4_com_prefixo linhas '| FDD-ERR-NN |' com código WEBHOOK_[A-Z_]{3,} na §Matriz de erros (mínimo 8), $fdd4_n_sem código(s) sem o prefixo"
  pass=$((pass + 1))
else
  echo "FDD-4 FALHA — $fdd4_com_prefixo linha(s) com código WEBHOOK_ (mínimo 8) e $fdd4_n_sem código(s) sem o prefixo (exigido: 0) na §Matriz de erros de $FDD_FILE"
  [ "$fdd4_n_sem" -gt 0 ] && printf '%s\n' "$fdd4_sem_prefixo" | sed 's/^/  sem prefixo: /'
fi

# ---------------------------------------------------------------------------
# FDD-5: os caminhos citados em crase na §Integração com o sistema existente,
# descontados os marcados (novo) por C-1, existem no índice do git: pelo menos
# 4 distintos e ZERO ausentes.
# ---------------------------------------------------------------------------
fdd5_secao="$(awk '/^## Integração com o sistema existente$/ {f=1; next} /^## / {f=0} f' "$FDD_FILE")"
[ -n "$fdd5_secao" ] || erro "FDD-5 encontrou a seção '## Integração com o sistema existente' vazia (ou ausente) em $FDD_FILE"

fdd5_distintos=0
fdd5_existentes=0
fdd5_ausentes=""
while IFS= read -r _p; do
  [ -n "$_p" ] || continue
  fdd5_distintos=$((fdd5_distintos + 1))
  if git ls-files --error-unmatch "$_p" >/dev/null 2>&1; then
    fdd5_existentes=$((fdd5_existentes + 1))
  else
    fdd5_ausentes+="  ausente do índice do git e sem o marcador (novo): $_p"$'\n'
  fi
done < <(printf '%s\n' "$fdd5_secao" \
           | "$GREP" -ohE '`[A-Za-z0-9_./-]+\.(ts|js|prisma|json|sql|yml|yaml)`( *\(novo\))?' \
           | "$GREP" -v '(novo)' | tr -d '`' | sort -u)

# Passagem vazia: seção sem nenhum caminho em crase não prova integração nenhuma.
[ "$fdd5_distintos" -gt 0 ] || erro "FDD-5 não encontrou nenhum caminho em crase na §Integração de $FDD_FILE — nada foi medido"

if [ "$fdd5_existentes" -ge 4 ] && [ -z "$fdd5_ausentes" ]; then
  echo "FDD-5 OK — $fdd5_distintos caminhos distintos sem (novo) na §Integração, $fdd5_existentes presentes em git ls-files (mínimo 4), 0 ausentes"
  pass=$((pass + 1))
else
  echo "FDD-5 FALHA — $fdd5_distintos caminho(s) distinto(s) sem (novo), $fdd5_existentes presente(s) em git ls-files (mínimo 4):"
  printf '%s' "$fdd5_ausentes"
fi

# ---------------------------------------------------------------------------
# FDD-6: '### Métricas', '### Logs' e '### Tracing' presentes, com pelo menos 3
# itens de lista cada. Item de lista = linha começando com '- ' ou '* ',
# contada até o próximo header de qualquer nível.
# ---------------------------------------------------------------------------
fdd6_subs=("### Métricas" "### Logs" "### Tracing")
[ "${#fdd6_subs[@]}" -eq 3 ] \
  || erro "FDD-6 carregou ${#fdd6_subs[@]} subseção(ões) no denominador — §6 de .planning/03-design.md fixa 3"

fdd6_violacoes=""
fdd6_conferidos=0
fdd6_itens_total=0
for _sub in "${fdd6_subs[@]}"; do
  fdd6_conferidos=$((fdd6_conferidos + 1))
  if ! "$GREP" -qxF "$_sub" "$FDD_FILE"; then
    fdd6_violacoes+="  subseção ausente: '$_sub'"$'\n'
    continue
  fi
  _n_itens="$(awk -v h="$_sub" '$0==h {f=1; next} /^#/ {f=0} f && /^[-*] / {c++} END {print c+0}' "$FDD_FILE")"
  fdd6_itens_total=$((fdd6_itens_total + _n_itens))
  [ "$_n_itens" -ge 3 ] || fdd6_violacoes+="  '$_sub' — $_n_itens item(ns) de lista (mínimo 3)"$'\n'
done

if [ -z "$fdd6_violacoes" ]; then
  echo "FDD-6 OK — $fdd6_conferidos subseções de §Observabilidade conferidas, $fdd6_itens_total itens de lista no total, mínimo 3 em cada"
  pass=$((pass + 1))
else
  echo "FDD-6 FALHA — $fdd6_conferidos subseções conferidas em $FDD_FILE:"
  printf '%s' "$fdd6_violacoes"
fi

# ---------------------------------------------------------------------------
# FDD-7: invariante de D-10 — nenhuma linha do FDD afirma que a COLUNA se chama
# total_cents, order_number, from_status, to_status ou stock_quantity. Esses
# cinco são vocabulário do payload (contrato público, snake_case); o schema é
# camelCase e a tradução vive só em '### Mapeamento payload ↔ schema'.
#
# Implementação deliberadamente estreita, para não gerar falso positivo: proíbe
# a construção "coluna | campo do schema | no banco" a menos de 40 caracteres de
# um dos cinco termos, nos dois sentidos. Ficam fora da varredura a subseção de
# mapeamento (onde a correspondência é o assunto) e o conteúdo de qualquer fence
# de código (onde o termo é o nome do campo JSON, não uma afirmação sobre o
# schema).
# ---------------------------------------------------------------------------
FDD7_TERMOS='total_cents|order_number|from_status|to_status|stock_quantity'
FDD7_SCHEMA='coluna|campo do schema|no banco'

fdd7_varridas="$(awk '
  /^### Mapeamento payload/ { map=1; next }
  /^#/                      { map=0 }
  /^```/                    { fence = !fence; next }
  map || fence              { next }
  { printf "%d:%s\n", FNR, $0 }
' "$FDD_FILE")"

fdd7_n_varridas="$(printf '%s' "$fdd7_varridas" | "$GREP" -c . || true)"
# Passagem vazia: se a exclusão comeu o documento inteiro, o check não mediu nada.
[ "$fdd7_n_varridas" -gt 0 ] || erro "FDD-7 não varreu nenhuma linha de $FDD_FILE — a exclusão de mapeamento/fences consumiu o documento inteiro"

fdd7_violacoes="$(printf '%s\n' "$fdd7_varridas" \
  | "$GREP" -iE "($FDD7_SCHEMA).{0,40}($FDD7_TERMOS)|($FDD7_TERMOS).{0,40}($FDD7_SCHEMA)" || true)"
fdd7_n="$(printf '%s' "$fdd7_violacoes" | "$GREP" -c . || true)"

if [ "$fdd7_n" -eq 0 ]; then
  echo "FDD-7 OK — $fdd7_n_varridas linhas varridas fora de '### Mapeamento payload ↔ schema' e de fences, $fdd7_n linha(s) nomeando os cinco termos como coluna do schema"
  pass=$((pass + 1))
else
  echo "FDD-7 FALHA — $fdd7_n linha(s) afirmando que a coluna do schema se chama por um dos cinco termos snake_case (exigido: 0) em $FDD_FILE:"
  printf '%s\n' "$fdd7_violacoes" | sed 's/^/  /'
fi

# ===========================================================================
# Bloco 7 — PRD-1..PRD-6 sobre $PRD_FILE, e INV-7 (vazamento de recusa).
# ===========================================================================

# ---------------------------------------------------------------------------
# PRD-1: o arquivo existe, tem no mínimo 900 palavras e não sobrou placeholder
# do esqueleto.
# ---------------------------------------------------------------------------
prd_existe=0
[ -f "$PRD_FILE" ] && prd_existe=1

prd1_palavras=0
prd1_placeholder=0
if [ "$prd_existe" -eq 1 ]; then
  prd1_palavras="$(wc -w < "$PRD_FILE" | tr -d ' ')" \
    || erro "PRD-1 não conseguiu contar palavras de $PRD_FILE"
  prd1_placeholder="$("$GREP" -cE '<!--.*(a ser elaborado|será preenchido).*-->' "$PRD_FILE" || true)"
fi

if [ "$prd_existe" -eq 1 ] && [ "$prd1_palavras" -ge 900 ] && [ "$prd1_placeholder" -eq 0 ]; then
  echo "PRD-1 OK — $PRD_FILE existe, $prd1_palavras palavras (mínimo 900), $prd1_placeholder placeholder(s) do esqueleto"
  pass=$((pass + 1))
elif [ "$prd_existe" -eq 0 ]; then
  echo "PRD-1 FALHA — $PRD_FILE não existe"
else
  echo "PRD-1 FALHA — $prd1_palavras palavras (mínimo 900) e $prd1_placeholder placeholder(s) '<!-- ... a ser elaborado / será preenchido ... -->' (exigido: 0) em $PRD_FILE"
fi

# Sem arquivo, PRD-2..PRD-6 e INV-7 não medem nada — passagem vazia sai por
# exit 2, e não por uma sequência de OK ou de FALHA que fingiria ter medido.
[ "$prd_existe" -eq 1 ] || erro "PRD-2..PRD-6 e INV-7 não têm o que medir: $PRD_FILE ausente"

# ---------------------------------------------------------------------------
# PRD-2: as 12 seções canônicas '## ' de .planning/03-design.md §6, header
# literal, mais o header '### Fora de escopo' — a subseção de que PRD-5
# depende para enumerar o que foi descartado ou adiado.
#
# A lista abaixo é o denominador e é digitada à mão a partir de §6 — extraí-la
# do próprio PRD mediria o arquivo contra ele mesmo.
# ---------------------------------------------------------------------------
prd2_headers=(
  "## Resumo e contexto"
  "## Problema e motivação"
  "## Público-alvo e cenários de uso"
  "## Objetivos e métricas de sucesso"
  "## Escopo"
  "## Requisitos funcionais"
  "## Requisitos não funcionais"
  "## Decisões e trade-offs principais"
  "## Dependências"
  "## Riscos e mitigação"
  "## Critérios de aceitação"
  "## Estratégia de testes e validação"
)
# Denominador adulterado (header somado ou removido do array) sai por exit 2.
[ "${#prd2_headers[@]}" -eq 12 ] \
  || erro "PRD-2 carregou ${#prd2_headers[@]} header(s) '## ' no denominador — §6 de .planning/03-design.md tem exatamente 12 headers '## ' para o PRD"

prd2_ausentes=""
prd2_conferidos=0
for _h in "${prd2_headers[@]}"; do
  prd2_conferidos=$((prd2_conferidos + 1))
  "$GREP" -qxF "$_h" "$PRD_FILE" || prd2_ausentes+="  header ausente: '$_h'"$'\n'
done
prd2_conferidos=$((prd2_conferidos + 1))
"$GREP" -qxF "### Fora de escopo" "$PRD_FILE" || prd2_ausentes+="  header ausente: '### Fora de escopo'"$'\n'

if [ -z "$prd2_ausentes" ]; then
  echo "PRD-2 OK — $prd2_conferidos headers canônicos conferidos em $PRD_FILE (12 '## ' + '### Fora de escopo'), 0 ausentes"
  pass=$((pass + 1))
else
  echo "PRD-2 FALHA — $prd2_conferidos headers conferidos:"
  printf '%s' "$prd2_ausentes"
fi

# ---------------------------------------------------------------------------
# PRD-3: pelo menos 8 linhas de tabela com ID PRD-FR-NN em §Requisitos
# funcionais — o critério literal do enunciado (11 conceituais estão
# disponíveis; a folga sobre o mínimo de 8 já existe por construção).
# ---------------------------------------------------------------------------
prd3_n="$("$GREP" -cE '^\| *PRD-FR-[0-9]{2} *\|' "$PRD_FILE" || true)"
if [ "$prd3_n" -ge 8 ]; then
  echo "PRD-3 OK — $prd3_n linhas '| PRD-FR-NN |' em $PRD_FILE (mínimo 8)"
  pass=$((pass + 1))
else
  echo "PRD-3 FALHA — $prd3_n linha(s) '| PRD-FR-NN |' em $PRD_FILE (mínimo 8)"
fi

# ---------------------------------------------------------------------------
# PRD-4: dentro da §Objetivos e métricas de sucesso, pelo menos 1 linha com
# meta numérica quantitativa (%, ms, s, min ou segundo(s)).
# ---------------------------------------------------------------------------
prd4_secao="$(awk '/^## Objetivos e métricas de sucesso$/ {f=1; next} /^## / {f=0} f' "$PRD_FILE")"
# Seção vazia: o check não mediu nada e não pode imprimir OK por omissão.
[ -n "$prd4_secao" ] || erro "PRD-4 encontrou a seção '## Objetivos e métricas de sucesso' vazia (ou ausente) em $PRD_FILE"

prd4_n="$(printf '%s\n' "$prd4_secao" | "$GREP" -cE '[0-9]+ *(%|ms|s|min|segundos?)' || true)"
if [ "$prd4_n" -ge 1 ]; then
  echo "PRD-4 OK — $prd4_n linha(s) com meta quantitativa (%, ms, s, min, segundo(s)) na §Objetivos e métricas de sucesso (mínimo 1)"
  pass=$((pass + 1))
else
  echo "PRD-4 FALHA — $prd4_n linha(s) com meta quantitativa na §Objetivos e métricas de sucesso (mínimo 1)"
fi

# ---------------------------------------------------------------------------
# PRD-5: dentro de '### Fora de escopo', pelo menos 2 itens de lista
# ('- ' ou '* '), e TODOS eles com uma Localização '[hh:mm] Nome' conferível —
# a marca de D-08 de que o item veio da lista de recusa, não foi inventado.
# ---------------------------------------------------------------------------
prd5_secao="$(awk '/^### Fora de escopo$/ {f=1; next} /^#/ {f=0} f' "$PRD_FILE")"
[ -n "$prd5_secao" ] || erro "PRD-5 encontrou a seção '### Fora de escopo' vazia (ou ausente) em $PRD_FILE"

prd5_itens_raw="$(printf '%s\n' "$prd5_secao" | "$GREP" -E '^[-*] ' || true)"
prd5_n_itens="$(printf '%s' "$prd5_itens_raw" | "$GREP" -c . || true)"
prd5_n_com_loc="$(printf '%s' "$prd5_itens_raw" | "$GREP" -cE '\[[0-9]{2}:[0-9]{2}\] [A-ZÀ-Ý][a-zà-ÿ]+' || true)"

if [ "$prd5_n_itens" -ge 2 ] && [ "$prd5_n_com_loc" -eq "$prd5_n_itens" ]; then
  echo "PRD-5 OK — $prd5_n_itens itens de lista em §Fora de escopo (mínimo 2), $prd5_n_com_loc com '[hh:mm] Nome' conferível (todos)"
  pass=$((pass + 1))
else
  echo "PRD-5 FALHA — $prd5_n_itens item(ns) de lista em §Fora de escopo (mínimo 2), $prd5_n_com_loc com '[hh:mm] Nome' conferível (exigido: todos)"
fi

# ---------------------------------------------------------------------------
# PRD-6: dentro da §Riscos e mitigação, pelo menos 2 linhas de tabela com os
# 3 campos Probabilidade, Impacto e Mitigação preenchidos (além do próprio
# Risco).
# ---------------------------------------------------------------------------
prd6_secao="$(awk '/^## Riscos e mitigação$/ {f=1; next} /^## / {f=0} f' "$PRD_FILE")"
[ -n "$prd6_secao" ] || erro "PRD-6 encontrou a seção '## Riscos e mitigação' vazia (ou ausente) em $PRD_FILE"

prd6_ok="$(printf '%s\n' "$prd6_secao" | awk -F'|' '
  /^\|/ {
    if (NF < 6) next
    risco=$2; prob=$3; imp=$4; mit=$5
    gsub(/^[ \t]+|[ \t]+$/, "", risco)
    gsub(/^[ \t]+|[ \t]+$/, "", prob)
    gsub(/^[ \t]+|[ \t]+$/, "", imp)
    gsub(/^[ \t]+|[ \t]+$/, "", mit)
    if (risco == "Risco" || risco ~ /^-+$/) next
    if (length(prob) > 0 && length(imp) > 0 && length(mit) > 0) c++
  }
  END { print c+0 }
')"

if [ "$prd6_ok" -ge 2 ]; then
  echo "PRD-6 OK — $prd6_ok linha(s) de risco com Probabilidade/Impacto/Mitigação preenchidos na §Riscos e mitigação (mínimo 2)"
  pass=$((pass + 1))
else
  echo "PRD-6 FALHA — $prd6_ok linha(s) de risco com os 3 campos preenchidos na §Riscos e mitigação (mínimo 2)"
fi

# ---------------------------------------------------------------------------
# INV-7: nenhum item de .planning/02-recusa.md pode reaparecer como requisito
# vigente no PRD ou no FDD. Especificado em .planning/02-recusa.md §INV-7 v2.
# A âncora regex de cada REC-NN só é procurada DENTRO de linhas que comecem
# com ID de requisito rastreável — nunca em prosa, onde a menção ao recusado
# é legítima (§Fora de escopo, §Alternativas consideradas, §Questões em
# aberto).
# ---------------------------------------------------------------------------
INV7_RECUSA="${INV7_RECUSA:-.planning/02-recusa.md}"
read -r -a inv7_alvos <<< "${INV7_ALVOS:-$PRD_FILE $FDD_FILE}"
INV7_ID_RE='^\| *(PRD-FR|PRD-RNF|FDD-CONTRATO|FDD-ERR)-[0-9]{2} *\|'

[ -r "$INV7_RECUSA" ] || erro "INV-7 não consegue ler a lista de recusa: $INV7_RECUSA"

# 3a coluna da tabela de recusa = âncora regex; o \| do markdown é desescapado.
inv7_ancoras="$(sed -nE 's/^\| *(REC-[0-9]{2}) *\|[^|]*\| *`(.*)` *\| *(DESCARTADO|ADIADO).*/\1\t\2/p' "$INV7_RECUSA" \
                 | sed 's/\\|/|/g')"
inv7_n_anc="$(printf '%s' "$inv7_ancoras" | "$GREP" -c . || true)"
# Passagem vazia e denominador adulterado: as duas saem por exit 2, não por OK.
[ "$inv7_n_anc" -ge 14 ] \
  || erro "INV-7 carregou $inv7_n_anc âncora(s) de $INV7_RECUSA — mínimo 14 (guarda contra denominador vazio ou truncado)"

inv7_vaz=0
inv7_usadas=0
inv7_saida=""
while IFS=$'\t' read -r _rec _anc; do
  [ -n "$_rec" ] || continue
  [ "$_anc" = "[sem âncora viável]" ] && continue
  inv7_usadas=$((inv7_usadas + 1))
  for _alvo in "${inv7_alvos[@]}"; do
    [ -f "$_alvo" ] || continue
    while IFS= read -r _hit; do
      [ -n "$_hit" ] || continue
      _lnum="${_hit%%:*}"
      _texto="${_hit#*:}"
      _reqid="$(printf '%s' "$_texto" | sed -E 's/^\| *([A-Z]+-[A-Z]+-[0-9]{2}).*/\1/')"
      inv7_saida+="  VAZAMENTO  $_rec -> $_reqid  ($_alvo:$_lnum)"$'\n'
      inv7_saida+="             $(printf '%s' "$_texto" | cut -c1-100)"$'\n'
      inv7_vaz=$((inv7_vaz + 1))
    done < <("$GREP" -nE "$INV7_ID_RE" "$_alvo" | "$GREP" -iE "$_anc")
  done
done <<< "$inv7_ancoras"

echo "INV-7 — $inv7_n_anc item(ns) na lista de recusa, $inv7_usadas com âncora aplicável, alvos: ${inv7_alvos[*]}"
if [ "$inv7_vaz" -eq 0 ]; then
  echo "INV-7 OK — nenhum item recusado reaparece como requisito"
  pass=$((pass + 1))
else
  echo "INV-7 FALHA — $inv7_vaz vazamento(s):"
  printf '%s' "$inv7_saida"
fi

# ---------------------------------------------------------------------------
# Seção compartilhada TRK-1..TRK-4: isola a tabela principal do tracker
# (## Referência cruzada), sem misturar com a tabela de §Itens sem origem
# identificável, que tem um formato de coluna diferente.
# ---------------------------------------------------------------------------
[ -r "$TRACKER_FILE" ] || erro "TRK-1 não consegue ler $TRACKER_FILE"

TRK_HEADER='| ID | Documento | Tipo | Conteúdo (resumo) | Fonte | Localização |'
TRK_ID_RE='(PRD-FR|PRD-RNF|RFC-ALT|RFC-QA|FDD-CONTRATO|FDD-ERR)-[0-9]{2}|ADR-[0-9]{3}'

trk_secao="$(awk '/^## Referência cruzada$/ {f=1; next} /^## / {f=0} f' "$TRACKER_FILE")"
[ -n "$trk_secao" ] || erro "TRK-1 encontrou a seção '## Referência cruzada' vazia (ou ausente) em $TRACKER_FILE"

# Linhas de dados: começam com '| ' seguido de um ID que casa o universo C-2.
# Isso exclui naturalmente o header ('| ID | ...') e o separador ('|---|...').
trk_linhas_dados="$(printf '%s\n' "$trk_secao" | "$GREP" -E "^\\| *($TRK_ID_RE) *\\|")"

# ---------------------------------------------------------------------------
# TRK-1: header literal da tabela principal presente, e toda linha de dados
# com exatamente 6 campos (ID | Documento | Tipo | Conteúdo (resumo) | Fonte |
# Localização).
# ---------------------------------------------------------------------------
trk1_header_ok=0
printf '%s\n' "$trk_secao" | "$GREP" -qxF "$TRK_HEADER" && trk1_header_ok=1

trk1_linhas=0
trk1_malformadas=""
while IFS= read -r _l; do
  [ -n "$_l" ] || continue
  trk1_linhas=$((trk1_linhas + 1))
  _nf="$(printf '%s' "$_l" | awk -F'|' '{print NF}')"
  [ "$_nf" -eq 8 ] || trk1_malformadas+="  campos=$((_nf - 2)) (esperado 6): $_l"$'\n'
done <<< "$trk_linhas_dados"

[ "$trk1_linhas" -gt 0 ] || erro "TRK-1 não encontrou nenhuma linha de dados na tabela principal de $TRACKER_FILE"

if [ "$trk1_header_ok" -eq 1 ] && [ -z "$trk1_malformadas" ]; then
  echo "TRK-1 OK — header literal presente, $trk1_linhas linha(s) de dados, todas com 6 campos"
  pass=$((pass + 1))
else
  echo "TRK-1 FALHA — header literal presente: $([ "$trk1_header_ok" -eq 1 ] && echo sim || echo não); linha(s) malformada(s):"
  printf '%s' "$trk1_malformadas"
fi

# ---------------------------------------------------------------------------
# TRK-2: universo = IDs distintos que casam C-2, extraídos dos DOCUMENTOS
# (docs/PRD.md docs/RFC.md docs/FDD.md docs/adrs/*.md) — nunca do tracker.
# Cobertos = presentes na coluna ID da tabela principal do tracker.
# cobertos/universo >= 0.80.
# ---------------------------------------------------------------------------
TRK2_DOCS=(docs/PRD.md docs/RFC.md docs/FDD.md docs/adrs/*.md)

trk2_universo="$("$GREP" -ohE "$TRK_ID_RE" "${TRK2_DOCS[@]}" 2>/dev/null | sort -u)"
trk2_n_universo="$(printf '%s' "$trk2_universo" | "$GREP" -c . || true)"
[ "$trk2_n_universo" -gt 0 ] || erro "TRK-2 não encontrou nenhum ID rastreável nos documentos (${TRK2_DOCS[*]})"

trk2_cobertos="$(printf '%s\n' "$trk_linhas_dados" \
  | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' \
  | "$GREP" -E "^($TRK_ID_RE)\$" | sort -u)"

trk2_n_cobertos="$(comm -12 <(printf '%s\n' "$trk2_universo") <(printf '%s\n' "$trk2_cobertos") | "$GREP" -c . || true)"
trk2_faltantes="$(comm -23 <(printf '%s\n' "$trk2_universo") <(printf '%s\n' "$trk2_cobertos"))"

if [ $(( trk2_n_cobertos * 100 )) -ge $(( trk2_n_universo * 80 )) ]; then
  echo "TRK-2 OK — universo=$trk2_n_universo ID(s) extraído(s) dos documentos, cobertos=$trk2_n_cobertos (mínimo 80%)"
  pass=$((pass + 1))
else
  echo "TRK-2 FALHA — universo=$trk2_n_universo, cobertos=$trk2_n_cobertos (mínimo 80%). ID(s) descoberto(s) sem linha no tracker:"
  printf '%s\n' "$trk2_faltantes" | sed 's/^/  /'
fi

# ---------------------------------------------------------------------------
# TRK-3: linhas com Fonte=TRANSCRICAO / total >= 0.70, e cada Localização
# dessas linhas encontrada por grep -F em $TRANSCRICAO_FILE — zero não
# encontradas.
# ---------------------------------------------------------------------------
[ -r "$TRANSCRICAO_FILE" ] || erro "TRK-3 não consegue ler $TRANSCRICAO_FILE"

trk3_total=0
trk3_transcricao=0
trk3_nao_encontradas=""
while IFS='|' read -r _b _id _doc _tipo _cont _fonte _loc _e; do
  [ -n "$(printf '%s' "$_id" | tr -d '[:space:]')" ] || continue
  trk3_total=$((trk3_total + 1))
  _fonte_trim="$(printf '%s' "$_fonte" | sed -E 's/^[ \t]+|[ \t]+$//g')"
  if [ "$_fonte_trim" = "TRANSCRICAO" ]; then
    trk3_transcricao=$((trk3_transcricao + 1))
    _id_trim="$(printf '%s' "$_id" | sed -E 's/^[ \t]+|[ \t]+$//g')"
    _loc_trim="$(printf '%s' "$_loc" | sed -E "s/^[ \\t]+|[ \\t]+\$//g; s/^\`//; s/\`\$//")"
    "$GREP" -qF "$_loc_trim" "$TRANSCRICAO_FILE" \
      || trk3_nao_encontradas+="  $_id_trim: $_loc_trim"$'\n'
  fi
done <<< "$trk_linhas_dados"

[ "$trk3_total" -gt 0 ] || erro "TRK-3 não encontrou nenhuma linha de dados na tabela principal de $TRACKER_FILE"

if [ $(( trk3_transcricao * 100 )) -ge $(( trk3_total * 70 )) ] && [ -z "$trk3_nao_encontradas" ]; then
  echo "TRK-3 OK — $trk3_transcricao/$trk3_total linha(s) com Fonte=TRANSCRICAO (mínimo 70%), todas as Localizações conferidas por grep -F em $TRANSCRICAO_FILE (0 não encontrada)"
  pass=$((pass + 1))
else
  echo "TRK-3 FALHA — $trk3_transcricao/$trk3_total linha(s) TRANSCRICAO (mínimo 70%); Localização(ões) não encontrada(s) em $TRANSCRICAO_FILE:"
  printf '%s' "$trk3_nao_encontradas"
fi

# ---------------------------------------------------------------------------
# TRK-4: linhas com Fonte=CODIGO >= 5, cada Localização (sem ':linha')
# presente em git ls-files, zero ausentes.
# ---------------------------------------------------------------------------
trk4_codigo=0
trk4_ausentes=""
while IFS='|' read -r _b _id _doc _tipo _cont _fonte _loc _e; do
  [ -n "$(printf '%s' "$_id" | tr -d '[:space:]')" ] || continue
  _fonte_trim="$(printf '%s' "$_fonte" | sed -E 's/^[ \t]+|[ \t]+$//g')"
  if [ "$_fonte_trim" = "CODIGO" ]; then
    trk4_codigo=$((trk4_codigo + 1))
    _id_trim="$(printf '%s' "$_id" | sed -E 's/^[ \t]+|[ \t]+$//g')"
    _loc_trim="$(printf '%s' "$_loc" | sed -E "s/^[ \\t]+|[ \\t]+\$//g; s/^\`//; s/\`\$//")"
    _path_only="${_loc_trim%%:*}"
    git ls-files --error-unmatch "$_path_only" >/dev/null 2>&1 \
      || trk4_ausentes+="  $_id_trim: $_path_only"$'\n'
  fi
done <<< "$trk_linhas_dados"

if [ "$trk4_codigo" -ge 5 ] && [ -z "$trk4_ausentes" ]; then
  echo "TRK-4 OK — $trk4_codigo linha(s) com Fonte=CODIGO (mínimo 5), todos os caminhos presentes em git ls-files (0 ausente)"
  pass=$((pass + 1))
else
  echo "TRK-4 FALHA — $trk4_codigo linha(s) com Fonte=CODIGO (mínimo 5); caminho(s) ausente(s) do índice do git:"
  printf '%s' "$trk4_ausentes"
fi

# ---------------------------------------------------------------------------
# GER-2: nenhum caminho de código citado em crase em README.md ou docs/
# (recursivo) é inexistente no repositório, salvo o marcador (novo) por C-1.
# Guarda: menos de 10 caminhos distintos examinados é passagem vazia/truncada.
# ---------------------------------------------------------------------------
GER2_README="${GER2_README:-README.md}"
GER2_DOCS_DIR="${GER2_DOCS_DIR:-docs}"

ger2_arquivos=()
[ -f "$GER2_README" ] && ger2_arquivos+=("$GER2_README")
while IFS= read -r _f; do
  ger2_arquivos+=("$_f")
done < <(find "$GER2_DOCS_DIR" -type f -name '*.md' | sort)

[ "${#ger2_arquivos[@]}" -gt 0 ] || erro "GER-2 não encontrou README.md nem arquivo algum em docs/ para varrer"

ger2_brutos="$("$GREP" -ohE '`[A-Za-z0-9_./-]+\.(ts|js|prisma|json|sql|yml|yaml)`( *\(novo\))?' "${ger2_arquivos[@]}")"
ger2_distintos="$(printf '%s\n' "$ger2_brutos" | "$GREP" -v '(novo)' | tr -d '`' | sort -u)"
ger2_n="$(printf '%s' "$ger2_distintos" | "$GREP" -c . || true)"

[ "$ger2_n" -ge 10 ] \
  || erro "GER-2 examinou $ger2_n caminho(s) distinto(s) em README.md/docs/ — mínimo 10 (guarda contra varredura vazia ou truncada)"

ger2_ausentes=""
while IFS= read -r _p; do
  [ -n "$_p" ] || continue
  git ls-files --error-unmatch "$_p" >/dev/null 2>&1 \
    || ger2_ausentes+="  ausente do índice do git e sem o marcador (novo): $_p"$'\n'
done <<< "$ger2_distintos"

if [ -z "$ger2_ausentes" ]; then
  echo "GER-2 OK — $ger2_n caminho(s) distinto(s) examinado(s) em README.md/docs/ (sem marcador (novo)), 0 ausente(s) do índice do git"
  pass=$((pass + 1))
else
  echo "GER-2 FALHA — caminho(s) ausente(s) do índice do git e sem o marcador (novo):"
  printf '%s' "$ger2_ausentes"
fi

echo
echo "$pass/$total OK"

[ "$pass" -eq "$total" ]
