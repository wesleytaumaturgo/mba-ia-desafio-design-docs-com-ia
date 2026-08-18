# 01 — Prova de que os checks falham

Cada um dos 4 invariantes de `scripts/verify.sh` foi sabotado de verdade,
rodado, revertido e rodado de novo. Saída literal desta sessão. Nenhuma
sabotagem permanece no repositório ao final (ver `git status --porcelain` na
última seção).

## INV-1 — código intocado

```
$ echo "// x" >> src/app.ts
$ git status --porcelain -- src/app.ts
 M src/app.ts

$ ./scripts/verify.sh
verify.sh v0 — BASE=93e557087e6112aa8628f91024a80542b8af9a44

INV-1 FALHA — arquivos protegidos modificados desde $BASE:
  src/app.ts
INV-2 OK — sha256(TRANSCRICAO.md) == sha256(TRANSCRICAO.md em $BASE) [cdc56e0e86430ce966ffac71229b6968137f943c465ea7d957117fd229f20f14]
INV-3 OK — nenhum entregável (README.md, docs, docs/adrs, .planning, scripts) está ignorado
INV-4 OK — índice sem node_modules/, .env, dist/, .idea/ ou .DS_Store

3/4 OK
exit: 1
```

```
$ git checkout -- src/app.ts
$ git status --porcelain -- src/app.ts
(sem saída — limpo)

$ ./scripts/verify.sh
verify.sh v0 — BASE=93e557087e6112aa8628f91024a80542b8af9a44

INV-1 OK — nenhum arquivo protegido (src/, prisma/, tests/, package.json, package-lock.json, tsconfig.json, TRANSCRICAO.md) mudou desde $BASE
INV-2 OK — sha256(TRANSCRICAO.md) == sha256(TRANSCRICAO.md em $BASE) [cdc56e0e86430ce966ffac71229b6968137f943c465ea7d957117fd229f20f14]
INV-3 OK — nenhum entregável (README.md, docs, docs/adrs, .planning, scripts) está ignorado
INV-4 OK — índice sem node_modules/, .env, dist/, .idea/ ou .DS_Store

4/4 OK
exit: 0
```

**FALHA como esperado.** Reversão confirmada.

## INV-2 — TRANSCRICAO.md byte-a-byte igual ao BASE

```
$ printf '\n' >> TRANSCRICAO.md
$ git status --porcelain -- TRANSCRICAO.md
 M TRANSCRICAO.md

$ ./scripts/verify.sh
verify.sh v0 — BASE=93e557087e6112aa8628f91024a80542b8af9a44

INV-1 FALHA — arquivos protegidos modificados desde $BASE:
  TRANSCRICAO.md
INV-2 FALHA — hash divergente: atual=0b1cb5885d9b48e28eb5224fe78ca885337c70b1619ebf6b1443ce2eefd1aa91 base=cdc56e0e86430ce966ffac71229b6968137f943c465ea7d957117fd229f20f14
INV-3 OK — nenhum entregável (README.md, docs, docs/adrs, .planning, scripts) está ignorado
INV-4 OK — índice sem node_modules/, .env, dist/, .idea/ ou .DS_Store

2/4 OK
exit: 1
```

Nota: INV-1 também falha aqui porque `TRANSCRICAO.md` está no escopo de ambos
os checks (ele é um dos arquivos protegidos da restrição absoluta) — esperado,
não é bug.

```
$ git checkout -- TRANSCRICAO.md
$ git status --porcelain -- TRANSCRICAO.md
(sem saída — limpo)

$ ./scripts/verify.sh
verify.sh v0 — BASE=93e557087e6112aa8628f91024a80542b8af9a44

INV-1 OK — nenhum arquivo protegido (src/, prisma/, tests/, package.json, package-lock.json, tsconfig.json, TRANSCRICAO.md) mudou desde $BASE
INV-2 OK — sha256(TRANSCRICAO.md) == sha256(TRANSCRICAO.md em $BASE) [cdc56e0e86430ce966ffac71229b6968137f943c465ea7d957117fd229f20f14]
INV-3 OK — nenhum entregável (README.md, docs, docs/adrs, .planning, scripts) está ignorado
INV-4 OK — índice sem node_modules/, .env, dist/, .idea/ ou .DS_Store

4/4 OK
exit: 0
```

**FALHA como esperado.** Reversão confirmada.

## INV-3 — entregáveis não bloqueados por `.gitignore`

**Tentativa 1 — sabotagem NÃO detectada (check fraco, não a prova de nada):**

```
$ cp .gitignore /tmp/gitignore.bak
$ echo "docs/" >> .gitignore
$ git status --porcelain -- .gitignore
 M .gitignore

$ git check-ignore -v README.md docs docs/adrs .planning scripts
(sem saída, exit 1 — NÃO detectou a sabotagem)

$ ./scripts/verify.sh
INV-3 OK — nenhum entregável (README.md, docs, docs/adrs, .planning, scripts) está ignorado
4/4 OK
```

**Diagnóstico:** `git check-ignore` no modo padrão (com índice) nunca reporta
como ignorado um caminho **já rastreado** — `docs`, `docs/adrs`, `.planning` e
`scripts` já estão no índice, então qualquer regra nova de `.gitignore` que os
atinja é mascarada. Confirmado isolando os caminhos:

```
$ git check-ignore -v docs; echo "exit: $?"
(sem saída) exit: 1

$ git check-ignore -v --no-index docs; echo "exit: $?"
.gitignore:16:docs/	docs
exit: 0
```

Tentativa de correção com `--no-index` introduziu um FALSO POSITIVO: mesmo sem
sabotagem, `.planning` já casa com a regra de negação `!.planning/` do próprio
`.gitignore` (linha 15), e `check-ignore --no-index` reporta exit 0 para
qualquer padrão casado, inclusive negação:

```
$ git checkout -- .gitignore   # volta ao estado limpo antes de re-testar
$ git check-ignore -v --no-index README.md docs docs/adrs .planning scripts
.gitignore:15:!.planning/	.planning
exit: 0   # ERRADO: nada está sabotado, mas o check acusaria FALHA
```

**Correção real (2ª tentativa):** o risco de fato é bloquear a **criação de
arquivos futuros** (novos ADRs, novos docs) dentro dos diretórios protegidos —
exatamente o que aconteceu originalmente com `.planning/.keep` no pré-voo,
quando o arquivo ainda não existia. O check foi trocado para testar uma sonda
hipotética (caminho que não existe no disco) dentro de cada diretório, em vez
dos caminhos já existentes — `check-ignore` não exige que o arquivo exista
fisicamente:

```
$ git check-ignore -v README.md docs/PROBE-preflight-check.md docs/adrs/ADR-999-probe.md .planning/probe-novo.md scripts/probe-novo.sh
(sem saída, exit 1 — estado limpo, sem falso positivo)
```

**Sabotagem, versão final do check:**

```
$ echo "docs/" >> .gitignore
$ git status --porcelain -- .gitignore
 M .gitignore

$ ./scripts/verify.sh
verify.sh v0 — BASE=93e557087e6112aa8628f91024a80542b8af9a44

INV-1 OK — nenhum arquivo protegido (src/, prisma/, tests/, package.json, package-lock.json, tsconfig.json, TRANSCRICAO.md) mudou desde $BASE
INV-2 OK — sha256(TRANSCRICAO.md) == sha256(TRANSCRICAO.md em $BASE) [cdc56e0e86430ce966ffac71229b6968137f943c465ea7d957117fd229f20f14]
INV-3 FALHA — caminho(s) bloqueado(s) por regra de .gitignore:
  .gitignore:16:docs/	docs/PROBE-preflight-check.md
  .gitignore:16:docs/	docs/adrs/ADR-999-probe.md
INV-4 OK — índice sem node_modules/, .env, dist/, .idea/ ou .DS_Store

3/4 OK
exit: 1
```

**Reversão:**

```
$ git checkout -- .gitignore
$ git status --porcelain -- .gitignore
(sem saída — limpo)

$ ./scripts/verify.sh
verify.sh v0 — BASE=93e557087e6112aa8628f91024a80542b8af9a44

INV-1 OK — nenhum arquivo protegido (src/, prisma/, tests/, package.json, package-lock.json, tsconfig.json, TRANSCRICAO.md) mudou desde $BASE
INV-2 OK — sha256(TRANSCRICAO.md) == sha256(TRANSCRICAO.md em $BASE) [cdc56e0e86430ce966ffac71229b6968137f943c465ea7d957117fd229f20f14]
INV-3 OK — nem os entregáveis existentes nem arquivos futuros hipotéticos em docs/, docs/adrs/, .planning/, scripts/ estão bloqueados por .gitignore
INV-4 OK — índice sem node_modules/, .env, dist/, .idea/ ou .DS_Store

4/4 OK
exit: 0
```

**FALHA como esperado — na 2ª tentativa.** `scripts/verify.sh` já reflete o
check corrigido (sonda de arquivo futuro, não caminho já rastreado).

## INV-4 — higiene do índice

```
$ mkdir -p node_modules
$ touch node_modules/x.js
$ git add -f node_modules/x.js
$ git status --porcelain -- node_modules
A  node_modules/x.js

$ ./scripts/verify.sh
verify.sh v0 — BASE=93e557087e6112aa8628f91024a80542b8af9a44

INV-1 OK — nenhum arquivo protegido (src/, prisma/, tests/, package.json, package-lock.json, tsconfig.json, TRANSCRICAO.md) mudou desde $BASE
INV-2 OK — sha256(TRANSCRICAO.md) == sha256(TRANSCRICAO.md em $BASE) [cdc56e0e86430ce966ffac71229b6968137f943c465ea7d957117fd229f20f14]
INV-3 OK — nem os entregáveis existentes nem arquivos futuros hipotéticos em docs/, docs/adrs/, .planning/, scripts/ estão bloqueados por .gitignore
INV-4 FALHA — caminho(s) indevido(s) no índice:
  node_modules/x.js

3/4 OK
exit: 1
```

```
$ git rm --cached node_modules/x.js
rm 'node_modules/x.js'
$ rm -rf node_modules
$ git status --porcelain -- node_modules
(sem saída — limpo)

$ ./scripts/verify.sh
verify.sh v0 — BASE=93e557087e6112aa8628f91024a80542b8af9a44

INV-1 OK — nenhum arquivo protegido (src/, prisma/, tests/, package.json, package-lock.json, tsconfig.json, TRANSCRICAO.md) mudou desde $BASE
INV-2 OK — sha256(TRANSCRICAO.md) == sha256(TRANSCRICAO.md em $BASE) [cdc56e0e86430ce966ffac71229b6968137f943c465ea7d957117fd229f20f14]
INV-3 OK — nem os entregáveis existentes nem arquivos futuros hipotéticos em docs/, docs/adrs/, .planning/, scripts/ estão bloqueados por .gitignore
INV-4 OK — índice sem node_modules/, .env, dist/, .idea/ ou .DS_Store

4/4 OK
exit: 0
```

**FALHA como esperado.** Reversão confirmada.

## Estado final do repositório

```
$ git status --porcelain
?? .planning/01-matriz.md
?? .planning/01-scaffolding.md
?? .planning/paths-reais.txt
?? scripts/
```

Só restam os arquivos novos deste bloco (`.planning/01-matriz.md`,
`.planning/01-scaffolding.md`, `scripts/` com `verify.sh`) e
`.planning/paths-reais.txt`, um arquivo de rascunho de sessão anterior, não
tocado nem criado neste bloco. Nenhuma sabotagem permanece; `src/`, `prisma/`,
`tests/`, `TRANSCRICAO.md`, `.gitignore` e `package.json` estão no estado
original de `$BASE`.

---

# 01b — Prova de que INV-1 falha por lista de PERMISSÃO

Anexo de 2026-08-18, referente ao `scripts/verify.sh` **v2**. Não substitui nada
do registro acima: as provas da seção "INV-1 — código intocado" foram feitas
contra a v0/v1, que implementava INV-1 como lista de BLOQUEIO (array
`PROTEGIDOS` com `src`, `prisma`, `tests`, `package.json`, `package-lock.json`,
`tsconfig.json`, `TRANSCRICAO.md`).

Auditoria de disco mostrou que aquela formulação tinha dois buracos medidos:

1. **Tudo que não estava na enumeração passava.** `.gitignore`,
   `vitest.config.ts`, `docker-compose.yml`, `tsconfig.build.json`,
   `.eslintrc.json`, `.prettierrc`, `.prettierignore` e `.env.example` podiam
   ser alterados sem INV-1 falhar.
2. **Arquivo NOVO dentro de `src/` passava**, porque a lista era resolvida
   contra o que existia em `$BASE` — o que não existia lá não era conferido.

A v2 inverte a regra: o conjunto PERMITIDO é `{ README.md, docs/**,
.planning/**, scripts/** }` e qualquer caminho fora dele que apareça como
modificado (M), criado (A), removido (D) ou untracked é violação. As duas
fontes são `git diff --name-status "$BASE" -- .` e
`git ls-files --others --exclude-standard`.

Os quatro testes abaixo são o critério de aceite dessa inversão: N1, N2 e N3
têm que FALHAR (se algum passar, a inversão não está aplicada) e N4 tem que
PASSAR (se falhar, o conjunto permitido está errado).

### N1 — arquivo de configuração fora da enumeração antiga (`vitest.config.ts`)

```
$ echo "" >> vitest.config.ts
$ ./scripts/verify.sh
verify.sh v2 — BASE=93e557087e6112aa8628f91024a80542b8af9a44
engine: /usr/bin/grep grep (GNU grep) 3.11

INV-1 FALHA — caminho(s) fora do conjunto permitido (README.md, docs/**, .planning/**, scripts/**):
  M   vitest.config.ts
INV-2 OK — 323 linhas / 21011 bytes conferidos, sha256 == sha256 em $BASE [cdc56e0e86430ce966ffac71229b6968137f943c465ea7d957117fd229f20f14]
INV-3 OK — 5 sondas testadas em docs/, docs/adrs/, .planning/, scripts/ e README.md, nenhuma bloqueada por .gitignore
INV-4 OK — 76 caminhos no índice, nenhum indevido (node_modules/, .env, dist/, .idea/, .DS_Store)

3/4 OK
$ echo $?
1
$ git checkout -- vitest.config.ts
$ git status --porcelain
 M .planning/01-teste-negativo.md
 M scripts/verify.sh
?? .planning/paths-reais.txt
```

**Esperado:** INV-1 FALHA. Sob a lista de bloqueio anterior este caso passava, porque `vitest.config.ts` não estava no array `PROTEGIDOS`.

### N2 — `.gitignore`

```
$ echo "" >> .gitignore
$ ./scripts/verify.sh
verify.sh v2 — BASE=93e557087e6112aa8628f91024a80542b8af9a44
engine: /usr/bin/grep grep (GNU grep) 3.11

INV-1 FALHA — caminho(s) fora do conjunto permitido (README.md, docs/**, .planning/**, scripts/**):
  M   .gitignore
INV-2 OK — 323 linhas / 21011 bytes conferidos, sha256 == sha256 em $BASE [cdc56e0e86430ce966ffac71229b6968137f943c465ea7d957117fd229f20f14]
INV-3 OK — 5 sondas testadas em docs/, docs/adrs/, .planning/, scripts/ e README.md, nenhuma bloqueada por .gitignore
INV-4 OK — 76 caminhos no índice, nenhum indevido (node_modules/, .env, dist/, .idea/, .DS_Store)

3/4 OK
$ echo $?
1
$ git checkout -- .gitignore
$ git status --porcelain
 M .planning/01-teste-negativo.md
 M scripts/verify.sh
?? .planning/paths-reais.txt
```

**Esperado:** INV-1 FALHA. Mesmo buraco de N1: `.gitignore` não constava da enumeração de bloqueio.

### N3 — arquivo NOVO, untracked, dentro de `src/`

```
$ mkdir -p src/modules/webhooks && touch src/modules/webhooks/probe.ts
$ ./scripts/verify.sh
verify.sh v2 — BASE=93e557087e6112aa8628f91024a80542b8af9a44
engine: /usr/bin/grep grep (GNU grep) 3.11

INV-1 FALHA — caminho(s) fora do conjunto permitido (README.md, docs/**, .planning/**, scripts/**):
  untracked  src/modules/webhooks/probe.ts
INV-2 OK — 323 linhas / 21011 bytes conferidos, sha256 == sha256 em $BASE [cdc56e0e86430ce966ffac71229b6968137f943c465ea7d957117fd229f20f14]
INV-3 OK — 5 sondas testadas em docs/, docs/adrs/, .planning/, scripts/ e README.md, nenhuma bloqueada por .gitignore
INV-4 OK — 76 caminhos no índice, nenhum indevido (node_modules/, .env, dist/, .idea/, .DS_Store)

3/4 OK
$ echo $?
1
$ rm -rf src/modules/webhooks
$ git status --porcelain
 M .planning/01-teste-negativo.md
 M scripts/verify.sh
?? .planning/paths-reais.txt
```

**Esperado:** INV-1 FALHA, com status `untracked`. Este é o caso que a lista de bloqueio não tinha como pegar: `git diff` contra `$BASE` não enxerga arquivo untracked, e o caminho não existia em `$BASE` para ser conferido. É a razão de a fonte 2 (`git ls-files --others`) ser obrigatória.

### N4 — arquivos dentro do conjunto permitido (prova de ausência de falso positivo)

```
$ touch docs/probe.md scripts/probe.sh
$ ./scripts/verify.sh
verify.sh v2 — BASE=93e557087e6112aa8628f91024a80542b8af9a44
engine: /usr/bin/grep grep (GNU grep) 3.11

INV-1 OK — 13 caminhos examinados (M/A/D/untracked), 0 fora do conjunto permitido (README.md, docs/**, .planning/**, scripts/**)
INV-2 OK — 323 linhas / 21011 bytes conferidos, sha256 == sha256 em $BASE [cdc56e0e86430ce966ffac71229b6968137f943c465ea7d957117fd229f20f14]
INV-3 OK — 5 sondas testadas em docs/, docs/adrs/, .planning/, scripts/ e README.md, nenhuma bloqueada por .gitignore
INV-4 OK — 76 caminhos no índice, nenhum indevido (node_modules/, .env, dist/, .idea/, .DS_Store)

4/4 OK
$ echo $?
0
$ rm -f docs/probe.md scripts/probe.sh
$ git status --porcelain
 M .planning/01-teste-negativo.md
 M scripts/verify.sh
?? .planning/paths-reais.txt
```

**Esperado:** INV-1 **OK**. `docs/**` e `scripts/**` estão no conjunto permitido; a contagem de examinados sobe (dois untracked a mais) e o número de violações continua zero. Se este teste falhasse, o conjunto permitido estaria errado e o verificador bloquearia a própria produção dos entregáveis.

