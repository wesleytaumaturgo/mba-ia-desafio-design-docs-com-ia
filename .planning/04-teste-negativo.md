# 04 — Prova de que os checks ADR-1..ADR-4 e EST-2 falham

Cada um dos cinco checks novos de `scripts/verify.sh` v3 foi sabotado de verdade,
rodado, revertido e rodado de novo. Saída literal desta sessão. Nenhuma sabotagem
permanece no repositório ao final (ver `git status --porcelain` na última seção).

Contexto da execução: os oito ADRs e o README já estavam **staged** (`git add
docs/adrs scripts/verify.sh`) quando os testes rodaram — é o que torna
`git checkout -- <arquivo>` uma reversão real para N2 e N3, e é por isso que o
`git status --porcelain` do fim mostra `A ` e `M ` em vez de `??`. As contagens
de INV-4 (87 caminhos no índice) refletem esse staging.

Nos testes N4, `$TMP` é o diretório de scratch desta sessão sob `/tmp`:

```
TMP=/tmp/claude-1000/-home-wesley-Github-MBA-Desafio-mba-ia-desafio-design-docs-com-ia/4cb2cd61-934b-40d9-a4b3-43b12aaf7c7e/scratchpad
```

Os cinco checks leem `$ADR_DIR` (default `docs/adrs`). A parametrização existe
exatamente para o N4: sem ela não há como rodar o check contra uma cópia sem
sabotar a entrega.

Convenção dos blocos abaixo: onde a chamada tem pipe (`| tail -N`), a linha
`exit:` traz o código de saída do próprio `verify.sh` — capturado por
`${PIPESTATUS[0]}` —, e não o do `tail`. O `tail` existe só para encurtar a
colagem; a saída completa está no bloco sem pipe de cada teste.

---

## N1 — ADR-1: um nono ADR reprova a faixa 5–8

```
$ cp docs/adrs/ADR-008-modelo-de-autorizacao-do-modulo.md docs/adrs/ADR-009-nono-adr-temporario.md
$ ls docs/adrs/ | wc -l
10

$ ./scripts/verify.sh
verify.sh v3 — BASE=93e557087e6112aa8628f91024a80542b8af9a44
engine: /usr/bin/grep grep (GNU grep) 3.11

INV-1 OK — 23 caminhos examinados (M/A/D/untracked), 0 fora do conjunto permitido (README.md, docs/**, .planning/**, scripts/**)
INV-2 OK — 323 linhas / 21011 bytes conferidos, sha256 == sha256 em $BASE [cdc56e0e86430ce966ffac71229b6968137f943c465ea7d957117fd229f20f14]
INV-3 OK — 5 sondas testadas em docs/, docs/adrs/, .planning/, scripts/ e README.md, nenhuma bloqueada por .gitignore
INV-4 OK — 87 caminhos no índice, nenhum indevido (node_modules/, .env, dist/, .idea/, .DS_Store)
ADR-1 FALHA — 9 arquivo(s) no formato (exigido: 5 a 8) contra 9 esperado(s) = 10 .md menos README.md em docs/adrs
ADR-2 OK — 9 ADRs examinados, 7 seções conferidas em cada (5 headers MADR + Positivas/Negativas não vazias)
ADR-3 OK — 22 DEC do mapa §4 conferidas, todas presentes nos 9 ADRs; 6/6 nomes do enunciado cobertos (mínimo 5)
ADR-4 OK — 9 ADRs examinados, 64 caminhos distintos sem (novo) conferidos contra git ls-files, 9 ADR(s) com pelo menos um caminho real
EST-2 OK — 10 entradas em docs/adrs, todas ADR-NNN-*.md ou README.md

8/9 OK
exit: 1
```

Nota: a cópia temporária tem nome válido, então EST-2 continua OK e a segunda
condição do ADR-1 (`n_adr == n_md − 1`) também bate — quem reprova é só a faixa.
As duas condições cobrem defeitos diferentes, e o N5 exercita a outra.

```
$ rm docs/adrs/ADR-009-nono-adr-temporario.md
$ ./scripts/verify.sh | tail -7
ADR-1 OK — 8 ADRs no formato ADR-NNN-titulo-em-kebab-case.md (faixa 5–8), 9 arquivos .md em docs/adrs, 8 esperados fora o README.md
ADR-2 OK — 8 ADRs examinados, 7 seções conferidas em cada (5 headers MADR + Positivas/Negativas não vazias)
ADR-3 OK — 22 DEC do mapa §4 conferidas, todas presentes nos 8 ADRs; 6/6 nomes do enunciado cobertos (mínimo 5)
ADR-4 OK — 8 ADRs examinados, 57 caminhos distintos sem (novo) conferidos contra git ls-files, 8 ADR(s) com pelo menos um caminho real
EST-2 OK — 9 entradas em docs/adrs, todas ADR-NNN-*.md ou README.md

9/9 OK
exit: 0
```

**FALHA como esperado.** Reversão confirmada.

---

## N2 — ADR-2: ADR sem `### Negativas`

```
$ sed -i '/^### Negativas$/d' docs/adrs/ADR-004-hmac-sha256-secret-por-endpoint.md
$ git diff --stat -- docs/adrs/ADR-004-hmac-sha256-secret-por-endpoint.md
 docs/adrs/ADR-004-hmac-sha256-secret-por-endpoint.md | 1 -
 1 file changed, 1 deletion(-)

$ ./scripts/verify.sh | tail -8
ADR-1 OK — 8 ADRs no formato ADR-NNN-titulo-em-kebab-case.md (faixa 5–8), 9 arquivos .md em docs/adrs, 8 esperados fora o README.md
ADR-2 FALHA — seção ausente ou vazia:
  ADR-004-hmac-sha256-secret-por-endpoint.md — header ausente: '### Negativas'
ADR-3 OK — 22 DEC do mapa §4 conferidas, todas presentes nos 8 ADRs; 6/6 nomes do enunciado cobertos (mínimo 5)
ADR-4 OK — 8 ADRs examinados, 57 caminhos distintos sem (novo) conferidos contra git ls-files, 8 ADR(s) com pelo menos um caminho real
EST-2 OK — 9 entradas em docs/adrs, todas ADR-NNN-*.md ou README.md

8/9 OK
exit: 1
```

```
$ git checkout -- docs/adrs/ADR-004-hmac-sha256-secret-por-endpoint.md
$ git status --porcelain -- docs/adrs/ADR-004-hmac-sha256-secret-por-endpoint.md
A  docs/adrs/ADR-004-hmac-sha256-secret-por-endpoint.md
(A  = staged, sem M no work tree — restaurado)

$ ./scripts/verify.sh | tail -3
EST-2 OK — 9 entradas em docs/adrs, todas ADR-NNN-*.md ou README.md

9/9 OK
exit: 0
```

**FALHA como esperado.** Reversão confirmada.

---

## N3 — ADR-3: DEC-NN citada trocada por uma inexistente

`DEC-10` é citada em um único ADR (`ADR-005`), o que torna a troca suficiente
para deixar a decisão descoberta em todo o conjunto.

```
$ sed -i 's/DEC-10/DEC-99/g' docs/adrs/ADR-005-entrega-at-least-once-com-x-event-id.md
$ grep -c "DEC-99" docs/adrs/ADR-005-entrega-at-least-once-com-x-event-id.md
1

$ ./scripts/verify.sh | tail -8
INV-4 OK — 87 caminhos no índice, nenhum indevido (node_modules/, .env, dist/, .idea/, .DS_Store)
ADR-1 OK — 8 ADRs no formato ADR-NNN-titulo-em-kebab-case.md (faixa 5–8), 9 arquivos .md em docs/adrs, 8 esperados fora o README.md
ADR-2 OK — 8 ADRs examinados, 7 seções conferidas em cada (5 headers MADR + Positivas/Negativas não vazias)
ADR-3 FALHA — DEC do mapa §4 ausente(s) nos ADRs: DEC-10; nomes cobertos: 6/6 (mínimo 5)
ADR-4 OK — 8 ADRs examinados, 57 caminhos distintos sem (novo) conferidos contra git ls-files, 8 ADR(s) com pelo menos um caminho real
EST-2 OK — 9 entradas em docs/adrs, todas ADR-NNN-*.md ou README.md

8/9 OK
exit: 1
```

```
$ git checkout -- docs/adrs/ADR-005-entrega-at-least-once-com-x-event-id.md
$ ./scripts/verify.sh | tail -3
EST-2 OK — 9 entradas em docs/adrs, todas ADR-NNN-*.md ou README.md

9/9 OK
exit: 0
```

**FALHA como esperado.** Reversão confirmada.

---

## N4 — ADR-4: caminhos reais marcados `(novo)` em cópia sob `/tmp`

A sabotagem roda sobre uma cópia, não sobre a entrega: marcar `(novo)` num
caminho que existe é exatamente a mentira que o ADR-4 tem que pegar, e não é algo
que se queira escrever no repositório nem por um minuto. Por isso os cinco checks
leem `$ADR_DIR`.

### Variante A — o teste: cópia com os dois candidatos ao critério ADR-4

`ADR-006` e `ADR-007` são os dois ADRs que o `.planning/03-design.md` §4 nomeia
como candidatos do critério ADR-4. A cópia contém os dois, e todos os caminhos
deles recebem o marcador.

```
$ mkdir -p "$TMP/adr4-A"
$ cp docs/adrs/ADR-006-reuso-dos-padroes-existentes.md docs/adrs/ADR-007-insercao-na-outbox-dentro-da-transacao.md "$TMP/adr4-A/"
$ sed -E -i 's/`([A-Za-z0-9_./-]+\.(ts|js|prisma|json|sql|yml|yaml))`/`\1` (novo)/g' "$TMP/adr4-A"/ADR-*.md
$ grep -rhoE '`[A-Za-z0-9_./-]+\.(ts|js|prisma|json|sql|yml|yaml)`( *\(novo\))?' "$TMP/adr4-A" | grep -vc '(novo)'
0

$ ADR_DIR="$TMP/adr4-A" ./scripts/verify.sh
verify.sh v3 — BASE=93e557087e6112aa8628f91024a80542b8af9a44
engine: /usr/bin/grep grep (GNU grep) 3.11

INV-1 OK — 22 caminhos examinados (M/A/D/untracked), 0 fora do conjunto permitido (README.md, docs/**, .planning/**, scripts/**)
INV-2 OK — 323 linhas / 21011 bytes conferidos, sha256 == sha256 em $BASE [cdc56e0e86430ce966ffac71229b6968137f943c465ea7d957117fd229f20f14]
INV-3 OK — 5 sondas testadas em docs/, docs/adrs/, .planning/, scripts/ e README.md, nenhuma bloqueada por .gitignore
INV-4 OK — 87 caminhos no índice, nenhum indevido (node_modules/, .env, dist/, .idea/, .DS_Store)
ADR-1 FALHA — 2 arquivo(s) no formato (exigido: 5 a 8) contra 1 esperado(s) = 2 .md menos README.md em $TMP/adr4-A
ADR-2 OK — 2 ADRs examinados, 7 seções conferidas em cada (5 headers MADR + Positivas/Negativas não vazias)
ADR-3 FALHA — DEC do mapa §4 ausente(s) nos ADRs: DEC-01 DEC-02 DEC-03 DEC-04 DEC-05 DEC-06 DEC-07 DEC-08 DEC-09 DEC-10 DEC-12 DEC-14 DEC-17 DEC-19 DEC-20; nomes cobertos: 1/6 (mínimo 5)
  Padrão Outbox no MySQL
  Retry com backoff e DLQ
  HMAC-SHA256 com secret por endpoint
  At-least-once com X-Event-Id
  Worker em processo separado em polling
ADR-4 FALHA — 2 ADRs examinados, 0 caminho(s) sem (novo) encontrado(s), nenhum presente em git ls-files
EST-2 OK — 2 entradas em $TMP/adr4-A, todas ADR-NNN-*.md ou README.md

6/9 OK
exit: 1
```

O check sob teste é o **ADR-4**, e ele falha. ADR-1 e ADR-3 também falham porque
a cópia é deliberadamente parcial (2 ADRs, sem README) — são efeitos do recorte,
não do marcador `(novo)`; a variante B isola isso.

### Variante B — controle: cópia completa, `(novo)` só em ADR-006 e ADR-007

```
$ cp docs/adrs/*.md "$TMP/adr4-B/"
$ sed -E -i 's/`([A-Za-z0-9_./-]+\.(ts|js|prisma|json|sql|yml|yaml))`/`\1` (novo)/g' "$TMP/adr4-B"/ADR-006-*.md "$TMP/adr4-B"/ADR-007-*.md
$ ADR_DIR="$TMP/adr4-B" ./scripts/verify.sh | tail -6
ADR-2 OK — 8 ADRs examinados, 7 seções conferidas em cada (5 headers MADR + Positivas/Negativas não vazias)
ADR-3 OK — 22 DEC do mapa §4 conferidas, todas presentes nos 8 ADRs; 6/6 nomes do enunciado cobertos (mínimo 5)
ADR-4 OK — 8 ADRs examinados, 33 caminhos distintos sem (novo) conferidos contra git ls-files, 6 ADR(s) com pelo menos um caminho real
EST-2 OK — 9 entradas em $TMP/adr4-B, todas ADR-NNN-*.md ou README.md

9/9 OK
exit: 0
```

Leitura do controle: com o conjunto completo, marcar `(novo)` nos dois candidatos
**não** derruba o ADR-4 — os outros seis ADRs continuam citando 33 caminhos reais
conferidos contra `git ls-files`. É a margem que o `.planning/03-design.md` §4
descreve como dobrada, medida aqui: o critério não depende de nenhum ADR
específico. Por isso a sabotagem que prova o check é a da variante A, onde os
únicos ADRs presentes são os que perderam os caminhos reais.

Nenhuma das duas cópias toca a entrega: `docs/adrs/` continuou intacta durante o
N4 inteiro, e as duas variantes rodaram sobre `$TMP`.

**FALHA como esperado** (variante A). Nada a reverter no repositório.

---

## N5 — EST-2: arquivo estranho na pasta

```
$ touch docs/adrs/NOTAS.md
$ ls docs/adrs/
ADR-001-outbox-no-mysql.md
ADR-002-worker-processo-separado-polling.md
ADR-003-retry-backoff-e-dlq-em-tabela-separada.md
ADR-004-hmac-sha256-secret-por-endpoint.md
ADR-005-entrega-at-least-once-com-x-event-id.md
ADR-006-reuso-dos-padroes-existentes.md
ADR-007-insercao-na-outbox-dentro-da-transacao.md
ADR-008-modelo-de-autorizacao-do-modulo.md
NOTAS.md
README.md

$ ./scripts/verify.sh | tail -8
ADR-1 FALHA — 8 arquivo(s) no formato (exigido: 5 a 8) contra 9 esperado(s) = 10 .md menos README.md em docs/adrs
ADR-2 OK — 8 ADRs examinados, 7 seções conferidas em cada (5 headers MADR + Positivas/Negativas não vazias)
ADR-3 OK — 22 DEC do mapa §4 conferidas, todas presentes nos 8 ADRs; 6/6 nomes do enunciado cobertos (mínimo 5)
ADR-4 OK — 8 ADRs examinados, 57 caminhos distintos sem (novo) conferidos contra git ls-files, 8 ADR(s) com pelo menos um caminho real
EST-2 FALHA — entrada(s) fora do permitido (ADR-NNN-*.md, README.md) em docs/adrs:
  NOTAS.md

7/9 OK
exit: 1
```

Nota: o ADR-1 também falha aqui, e por outro motivo — é a segunda condição
(`n_adr == n_md − 1`) pegando um `.md` a mais na pasta. Esperado, não é bug: o
N1 exercitou a faixa, o N5 exercita a igualdade. `NOTAS.md` é untracked, e é por
isso que o EST-2 usa `ls -A` em vez de `git ls-files`.

```
$ rm docs/adrs/NOTAS.md
$ ./scripts/verify.sh | tail -8
INV-4 OK — 87 caminhos no índice, nenhum indevido (node_modules/, .env, dist/, .idea/, .DS_Store)
ADR-1 OK — 8 ADRs no formato ADR-NNN-titulo-em-kebab-case.md (faixa 5–8), 9 arquivos .md em docs/adrs, 8 esperados fora o README.md
ADR-2 OK — 8 ADRs examinados, 7 seções conferidas em cada (5 headers MADR + Positivas/Negativas não vazias)
ADR-3 OK — 22 DEC do mapa §4 conferidas, todas presentes nos 8 ADRs; 6/6 nomes do enunciado cobertos (mínimo 5)
ADR-4 OK — 8 ADRs examinados, 57 caminhos distintos sem (novo) conferidos contra git ls-files, 8 ADR(s) com pelo menos um caminho real
EST-2 OK — 9 entradas em docs/adrs, todas ADR-NNN-*.md ou README.md

9/9 OK
exit: 0
```

**FALHA como esperado.** Reversão confirmada.

---

## Estado do repositório ao final

```
$ git status --porcelain
A  docs/adrs/ADR-001-outbox-no-mysql.md
A  docs/adrs/ADR-002-worker-processo-separado-polling.md
A  docs/adrs/ADR-003-retry-backoff-e-dlq-em-tabela-separada.md
A  docs/adrs/ADR-004-hmac-sha256-secret-por-endpoint.md
A  docs/adrs/ADR-005-entrega-at-least-once-com-x-event-id.md
A  docs/adrs/ADR-006-reuso-dos-padroes-existentes.md
A  docs/adrs/ADR-007-insercao-na-outbox-dentro-da-transacao.md
A  docs/adrs/ADR-008-modelo-de-autorizacao-do-modulo.md
M  docs/adrs/README.md
M  scripts/verify.sh
```

Nenhuma sabotagem sobreviveu: nem o nono ADR, nem o `NOTAS.md`, nem as edições de
`ADR-004` e `ADR-005`. As duas cópias do N4 vivem fora do repositório, sob
`$TMP`.

## Resumo

| Check | Sabotagem | Falhou como esperado? |
|---|---|---|
| ADR-1 | 9º ADR temporário na pasta | S |
| ADR-2 | `### Negativas` removida de `ADR-004` | S |
| ADR-3 | `DEC-10` trocada por `DEC-99` em `ADR-005` | S |
| ADR-4 | `(novo)` em todos os caminhos de `ADR-006` e `ADR-007`, em cópia sob `/tmp` | S |
| EST-2 | `touch docs/adrs/NOTAS.md` | S |
