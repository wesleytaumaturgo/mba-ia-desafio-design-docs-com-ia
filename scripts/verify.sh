#!/usr/bin/env bash
# verify.sh v4 — cobre INV-1..INV-4 (invariantes), ADR-1..ADR-4 + EST-2 (bloco 4)
# e RFC-1..RFC-6 (bloco 5).
# Ver .planning/01-matriz.md para o restante dos critérios de aceite e seus blocos.
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

pass=0
total=15

echo "verify.sh v4 — BASE=$BASE"
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

echo
echo "$pass/$total OK"

[ "$pass" -eq "$total" ]
