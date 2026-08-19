# 08 — Teste negativo dos checks TRK-1..TRK-4 e GER-2

Cada check novo de `scripts/verify.sh` v7 foi sabotado uma vez, de forma isolada,
para provar que **falha quando deve falhar**. Sem isso um check verde não
distingue "o tracker está correto" de "o check não mede nada".

## Método

Todas as sabotagens são não destrutivas para o repositório: rodam sobre **cópias
sob `/tmp/trk-neg-08/`**, e o `verify.sh` as recebe por `TRACKER_FILE` (TRK-1..4)
ou por `GER2_README`/`GER2_DOCS_DIR` (GER-2) — a mesma parametrização que
`ADR_DIR` (bloco 4), `RFC_FILE` (bloco 5), `FDD_FILE` (bloco 6) e `PRD_FILE`
(bloco 7) já tinham. `docs/PRD.md`, `docs/RFC.md`, `docs/FDD.md`,
`docs/adrs/*.md` e `docs/TRACKER.md` reais não foram tocados em nenhum dos cinco
casos — `git status --porcelain` continua mostrando só `docs/TRACKER.md` e
`scripts/verify.sh` modificados durante a bateria inteira.

Ambiente: `engine: /usr/bin/grep grep (GNU grep) 3.11` · `BASE =
93e557087e6112aa8628f91024a80542b8af9a44` · `docs/TRACKER.md` real com 64 linhas
de dados e `34/34 OK`.

Filtro de saída usado nos recortes abaixo:

```bash
run() { "$@" ./scripts/verify.sh 2>&1 | awk '/^TRK-1 |^TRK-2 |^TRK-3 |^TRK-4 |^GER-2 |^ERRO/{f=1} f'; }
```

## Montagem das cinco cópias

```bash
SP=/tmp/trk-neg-08; rm -rf "$SP"; mkdir -p "$SP/ger2-docs/adrs"

# N1 — TRK-1: remove o separador de campo entre Fonte e Localização da linha PRD-FR-01
awk '
  /^\| PRD-FR-01 \|/ { sub(/ \| TRANSCRICAO \|/, " | TRANSCRICAO "); print; next }
  { print }
' docs/TRACKER.md > "$SP/N1-TRACKER.md"

# N2 — TRK-2: apaga as 19 linhas PRD-RNF (19/64 ≈ 30% das linhas de dados)
grep -vE '^\| PRD-RNF-[0-9]{2} \|' docs/TRACKER.md > "$SP/N2-TRACKER.md"

# N3 — TRK-3: troca a Localização de PRD-FR-01 por [23:14] Diego (inexistente em TRANSCRICAO.md)
awk -F'|' 'BEGIN{OFS="|"} $2 ~ / PRD-FR-01 / { $7=" `[23:14] Diego` "; print; next } {print}' \
  docs/TRACKER.md > "$SP/N3-TRACKER.md"

# N4 — TRK-4: troca o caminho CODIGO de FDD-ERR-02 por src/modules/webhooks/webhook.service.ts (não existe)
sed 's#`prisma/schema.prisma:16`#`src/modules/webhooks/webhook.service.ts`#' \
  docs/TRACKER.md > "$SP/N4-TRACKER.md"

# N5 — GER-2: acrescenta `src/inexistente.ts` ao PRD, sem o marcador (novo)
cp docs/PRD.md docs/RFC.md docs/FDD.md docs/TRACKER.md "$SP/ger2-docs/"
cp docs/adrs/*.md "$SP/ger2-docs/adrs/"
printf '\nReferência de teste negativo: `src/inexistente.ts` participa do fluxo.\n' \
  >> "$SP/ger2-docs/PRD.md"
```

---

## N1 · TRK-1 — campo removido da linha `PRD-FR-01`

Sabotagem: o separador `|` entre a coluna Fonte e a coluna Localização de uma
única linha é apagado, colapsando os dois campos em um. **Esperado: TRK-1
FALHA.**

```
$ TRACKER_FILE=/tmp/trk-neg-08/N1-TRACKER.md ./scripts/verify.sh
...
TRK-1 FALHA — header literal presente: sim; linha(s) malformada(s):
  campos=5 (esperado 6): | PRD-FR-01 | docs/PRD.md | Requisito Funcional | Cadastro de endpoint de webhook via POST | TRANSCRICAO  `[09:31] Marcos` |
TRK-2 OK — universo=68 ID(s) extraído(s) dos documentos, cobertos=64 (mínimo 80%)
TRK-3 OK — 57/64 linha(s) com Fonte=TRANSCRICAO (mínimo 70%), todas as Localizações conferidas por grep -F em TRANSCRICAO.md (0 não encontrada)
TRK-4 OK — 6 linha(s) com Fonte=CODIGO (mínimo 5), todos os caminhos presentes em git ls-files (0 ausente)
GER-2 OK — 27 caminho(s) distinto(s) examinado(s) em README.md/docs/ (sem marcador (novo)), 0 ausente(s) do índice do git

33/34 OK
```

**FALHOU COMO ESPERADO**, isolado: o header segue literal (a sabotagem não o
tocou), só a linha `PRD-FR-01` cai — e o check nomeia exatamente os 5 campos
encontrados contra os 6 esperados. TRK-3 cai de 58 para 57 linhas TRANSCRICAO
como efeito colateral honesto: a linha malformada perdeu o valor `TRANSCRICAO`
isolado no campo 6 (virou parte do texto colapsado), então deixa de contar —
TRK-3 continua OK porque 57/64 ainda passa de 70%.

## N2 · TRK-2 — 30% das linhas do tracker apagadas

Sabotagem: as 19 linhas `PRD-RNF-NN` são removidas da tabela principal (19 de
64 linhas de dados ≈ 30%). **Esperado: TRK-2 FALHA nomeando os IDs
descobertos.**

```
$ TRACKER_FILE=/tmp/trk-neg-08/N2-TRACKER.md ./scripts/verify.sh
...
TRK-1 OK — header literal presente, 45 linha(s) de dados, todas com 6 campos
TRK-2 FALHA — universo=68, cobertos=45 (mínimo 80%). ID(s) descoberto(s) sem linha no tracker:
  FDD-ERR-03
  FDD-ERR-09
  FDD-ERR-12
  FDD-ERR-13
  PRD-RNF-01
  PRD-RNF-02
  PRD-RNF-03
  PRD-RNF-04
  PRD-RNF-05
  PRD-RNF-06
  PRD-RNF-07
  PRD-RNF-08
  PRD-RNF-09
  PRD-RNF-10
  PRD-RNF-11
  PRD-RNF-12
  PRD-RNF-13
  PRD-RNF-14
  PRD-RNF-15
  PRD-RNF-16
  PRD-RNF-17
  PRD-RNF-18
  PRD-RNF-19
TRK-3 OK — 39/45 linha(s) com Fonte=TRANSCRICAO (mínimo 70%), todas as Localizações conferidas por grep -F em TRANSCRICAO.md (0 não encontrada)
TRK-4 OK — 6 linha(s) com Fonte=CODIGO (mínimo 5), todos os caminhos presentes em git ls-files (0 ausente)
GER-2 OK — 27 caminho(s) distinto(s) examinado(s) em README.md/docs/ (sem marcador (novo)), 0 ausente(s) do índice do git

33/34 OK
```

**FALHOU COMO ESPERADO**: o universo (68) é recalculado a partir dos
DOCUMENTOS, não do tracker sabotado — por isso não caiu junto — e a cobertura
despenca para 45/68 (66%), abaixo dos 80%. A lista nomeia as 19 PRD-RNF
removidas mais 4 órfãs que já não estavam na tabela principal (FDD-ERR-03/09/
12/13, §Itens sem origem identificável), confirmando que "descobertos" é
medido contra o universo real, não contra o que sobrou.

## N3 · TRK-3 — Localização trocada por `[23:14] Diego`

Sabotagem: a Localização de `PRD-FR-01` (`[09:31] Marcos`) é substituída por
`[23:14] Diego`, um timestamp que não existe em `TRANSCRICAO.md`. **Esperado:
TRK-3 FALHA nomeando a linha.**

```
$ TRACKER_FILE=/tmp/trk-neg-08/N3-TRACKER.md ./scripts/verify.sh
...
TRK-1 OK — header literal presente, 64 linha(s) de dados, todas com 6 campos
TRK-2 OK — universo=68 ID(s) extraído(s) dos documentos, cobertos=64 (mínimo 80%)
TRK-3 FALHA — 58/64 linha(s) TRANSCRICAO (mínimo 70%); Localização(ões) não encontrada(s) em TRANSCRICAO.md:
  PRD-FR-01: [23:14] Diego
TRK-4 OK — 6 linha(s) com Fonte=CODIGO (mínimo 5), todos os caminhos presentes em git ls-files (0 ausente)
GER-2 OK — 27 caminho(s) distinto(s) examinado(s) em README.md/docs/ (sem marcador (novo)), 0 ausente(s) do índice do git

33/34 OK
```

**FALHOU COMO ESPERADO**, isolado: a proporção de linhas `TRANSCRICAO` continua
58/64 (a coluna Fonte não mudou), só a checagem por `grep -F` cai — e nomeia
exatamente `PRD-FR-01: [23:14] Diego`, a única Localização inventada.

## N4 · TRK-4 — caminho CODIGO trocado por arquivo inexistente

Sabotagem: a Localização de `FDD-ERR-02` (`prisma/schema.prisma:16`) é trocada
por `src/modules/webhooks/webhook.service.ts`, caminho que não existe no
repositório (o módulo de webhooks nunca foi implementado — ver
`.planning/02-codigo.md` §4). **Esperado: TRK-4 FALHA.**

```
$ TRACKER_FILE=/tmp/trk-neg-08/N4-TRACKER.md ./scripts/verify.sh
...
TRK-1 OK — header literal presente, 64 linha(s) de dados, todas com 6 campos
TRK-2 OK — universo=68 ID(s) extraído(s) dos documentos, cobertos=64 (mínimo 80%)
TRK-3 OK — 58/64 linha(s) com Fonte=TRANSCRICAO (mínimo 70%), todas as Localizações conferidas por grep -F em TRANSCRICAO.md (0 não encontrada)
TRK-4 FALHA — 6 linha(s) com Fonte=CODIGO (mínimo 5); caminho(s) ausente(s) do índice do git:
  FDD-ERR-02: src/modules/webhooks/webhook.service.ts
GER-2 OK — 27 caminho(s) distinto(s) examinado(s) em README.md/docs/ (sem marcador (novo)), 0 ausente(s) do índice do git

33/34 OK
```

**FALHOU COMO ESPERADO**: a contagem de linhas `Fonte = CODIGO` continua 6
(mínimo 5 satisfeito), mas o caminho não resolve em `git ls-files` e o check
nomeia `FDD-ERR-02` e o caminho inventado.

## N5 · GER-2 — caminho inexistente acrescentado ao PRD

Sabotagem: uma frase citando `` `src/inexistente.ts` `` em crase, sem o
marcador `(novo)`, é acrescentada ao final de uma cópia de `docs/PRD.md`.
**Esperado: GER-2 FALHA.**

```
$ GER2_README=/dev/null GER2_DOCS_DIR=/tmp/trk-neg-08/ger2-docs ./scripts/verify.sh
...
TRK-1 OK — header literal presente, 64 linha(s) de dados, todas com 6 campos
TRK-2 OK — universo=68 ID(s) extraído(s) dos documentos, cobertos=64 (mínimo 80%)
TRK-3 OK — 58/64 linha(s) com Fonte=TRANSCRICAO (mínimo 70%), todas as Localizações conferidas por grep -F em TRANSCRICAO.md (0 não encontrada)
TRK-4 OK — 6 linha(s) com Fonte=CODIGO (mínimo 5), todos os caminhos presentes em git ls-files (0 ausente)
GER-2 FALHA — caminho(s) ausente(s) do índice do git e sem o marcador (novo):
  ausente do índice do git e sem o marcador (novo): src/inexistente.ts
```

**FALHOU COMO ESPERADO**, e nomeia o caminho exato. `GER2_README=/dev/null`
isola a varredura à cópia de `docs/` em `/tmp` (26 outros caminhos legítimos
nos demais documentos copiados continuam presentes e não disparam, só o
plantado).

## Controle · repositório limpo

Sem nenhuma sabotagem, contra `docs/TRACKER.md` real:

```
$ ./scripts/verify.sh
...
TRK-1 OK — header literal presente, 64 linha(s) de dados, todas com 6 campos
TRK-2 OK — universo=68 ID(s) extraído(s) dos documentos, cobertos=64 (mínimo 80%)
TRK-3 OK — 58/64 linha(s) com Fonte=TRANSCRICAO (mínimo 70%), todas as Localizações conferidas por grep -F em TRANSCRICAO.md (0 não encontrada)
TRK-4 OK — 6 linha(s) com Fonte=CODIGO (mínimo 5), todos os caminhos presentes em git ls-files (0 ausente)
GER-2 OK — 27 caminho(s) distinto(s) examinado(s) em README.md/docs/ (sem marcador (novo)), 0 ausente(s) do índice do git

34/34 OK
```

**34/34 OK.** Nenhuma sabotagem tocou `docs/PRD.md`, `docs/RFC.md`,
`docs/FDD.md`, `docs/adrs/*.md` ou `docs/TRACKER.md` reais; todas as cinco
rodaram contra cópias sob `/tmp/trk-neg-08/`.
