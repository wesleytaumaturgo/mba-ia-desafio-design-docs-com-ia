# 00 — Preflight

Pré-voo do desafio de documentação (design-docs). Toda saída abaixo é literal,
copiada de comandos executados nesta sessão. Nenhum src/, prisma/, tests/,
configuração ou TRANSCRICAO.md foi alterado.

## 0.1 Remote e push real

```
$ git remote -v
origin	https://github.com/wesleytaumaturgo/mba-ia-desafio-design-docs-com-ia (fetch)
origin	https://github.com/wesleytaumaturgo/mba-ia-desafio-design-docs-com-ia (push)
```

`origin` aponta para o fork pessoal (`wesleytaumaturgo/...`), não para o upstream
`devfullcycle/...`. OK.

Teste de push real (`.planning/.keep` já existia de uma sessão anterior — commit
`93e5570`, já enviado ao remoto — então o teste desta sessão usou um novo
marcador, `.planning/00-push-test.md`, para provar escrita real no remoto nesta
sessão):

```
$ mkdir -p .planning
$ printf '# Teste de push real — sessão %s\n' "$(git rev-parse HEAD)" > .planning/00-push-test.md
$ git add .planning/00-push-test.md
$ git status --porcelain
A  .planning/00-push-test.md
?? .planning/00-preflight.md
?? .planning/paths-reais.txt

$ git commit -m "chore(planning): teste de push real desta sessão"
[main c14e5a8] chore(planning): teste de push real desta sessão
 1 file changed, 1 insertion(+)
 create mode 100644 .planning/00-push-test.md

$ git push
To https://github.com/wesleytaumaturgo/mba-ia-desafio-design-docs-com-ia
   93e5570..c14e5a8  main -> main
```

Push real confirmado: `93e5570..c14e5a8 main -> main`. **OK.**

## 0.2 Baseline

```
$ git rev-parse HEAD   # capturado ANTES do commit de 0.1, nesta sessão
93e557087e6112aa8628f91024a80542b8af9a44
```

**$BASE = `93e557087e6112aa8628f91024a80542b8af9a44`** — referência de todos os
diffs do desafio a partir daqui. Confirmado como pai do commit de teste:

```
$ git rev-parse c14e5a8^1
93e557087e6112aa8628f91024a80542b8af9a44
```

```
$ sha256sum TRANSCRICAO.md
cdc56e0e86430ce966ffac71229b6968137f943c465ea7d957117fd229f20f14  TRANSCRICAO.md
```

OK.

## 0.3 Entregáveis são versionáveis

```
$ git check-ignore -v README.md docs docs/adrs .planning scripts
(sem saída, exit code 1 — nenhum caminho ignorado)
```

Nenhum entregável está ignorado hoje. Isso só é verdade por causa de um override
já commitado em sessão anterior (commit `93e5570`, antes do início desta
sessão) no `.gitignore` **local**:

```
$ cat -n .gitignore
     1	node_modules/
     2	dist/
     3	coverage/
     4	.env
     5	.env.local
     6	.env.*.local
     7	*.log
     8	.DS_Store
     9	.idea/
    10	.vscode/
    11	*.tsbuildinfo
    12	
    13	# ── Override do ~/.gitignore_global (linha 12: .planning/) ──
    14	# Artefatos de processo desta entrega precisam ser versionados.
    15	!.planning/

$ git config --get core.excludesFile
/home/wesley/.gitignore_global
```

Causa raiz original (registrada para rastreabilidade, já resolvida antes desta
sessão): `~/.gitignore_global` (pessoal, `core.excludesFile`, linha 12) ignora
`.planning/` globalmente para todos os repositórios do usuário. O `.gitignore`
local deste repositório não tinha essa entrada. A correção foi um override
local (`!.planning/`, linhas 13–15 acima) — não uma alteração no arquivo global
pessoal. **OK** (nenhum entregável ignorado no estado atual; nenhuma ação
corretiva pendente nesta sessão).

## 0.4 Higiene do índice

```
$ git ls-files | grep -iE "node_modules/|\.env$|dist/|\.idea/|\.DS_Store"
(sem saída, exit code 1)
```

```
$ git log --all --name-only --pretty=format: | sort -u | grep -iE "\.env|\.pem|\.key"
.env.example
```

Único resultado é `.env.example` (arquivo de template, não segredo real). Nenhum
`node_modules/`, `dist/`, `.idea/`, `.DS_Store`, `.env` real, `.pem` ou `.key`
no índice ou no histórico. **OK.**

## 0.5 Estrutura existente

```
$ git ls-files | head -200
.env.example
.eslintrc.json
.gitignore
.planning/.keep
.planning/00-push-test.md
.prettierignore
.prettierrc
README.md
TRANSCRICAO.md
docker-compose.yml
docs/FDD.md
docs/PRD.md
docs/RFC.md
docs/TRACKER.md
docs/adrs/README.md
package-lock.json
package.json
prisma/migrations/20260519182739_init/migration.sql
prisma/migrations/migration_lock.toml
prisma/schema.prisma
prisma/seed.ts
src/app.ts
src/config/database.ts
src/config/env.ts
src/middlewares/auth.middleware.ts
src/middlewares/error.middleware.ts
src/middlewares/request-logger.middleware.ts
src/middlewares/validate.middleware.ts
src/modules/auth/auth.controller.ts
src/modules/auth/auth.routes.ts
src/modules/auth/auth.schemas.ts
src/modules/auth/auth.service.ts
src/modules/customers/customer.controller.ts
src/modules/customers/customer.repository.ts
src/modules/customers/customer.routes.ts
src/modules/customers/customer.schemas.ts
src/modules/customers/customer.service.ts
src/modules/orders/order.controller.ts
src/modules/orders/order.repository.ts
src/modules/orders/order.routes.ts
src/modules/orders/order.schemas.ts
src/modules/orders/order.service.ts
src/modules/orders/order.status.ts
src/modules/products/product.controller.ts
src/modules/products/product.repository.ts
src/modules/products/product.routes.ts
src/modules/products/product.schemas.ts
src/modules/products/product.service.ts
src/modules/users/user.controller.ts
src/modules/users/user.repository.ts
src/modules/users/user.routes.ts
src/modules/users/user.schemas.ts
src/modules/users/user.service.ts
src/routes/index.ts
src/server.ts
src/shared/errors/app-error.ts
src/shared/errors/http-errors.ts
src/shared/errors/index.ts
src/shared/http/response.ts
src/shared/logger/index.ts
tests/auth.test.ts
tests/helpers/factories.ts
tests/orders.test.ts
tests/setup.ts
tsconfig.build.json
tsconfig.json
vitest.config.ts
```

Lista completa (67 arquivos, abaixo do limite de 200 — não há truncamento).

```
$ git ls-files docs docs/adrs
docs/FDD.md
docs/PRD.md
docs/RFC.md
docs/TRACKER.md
docs/adrs/README.md

$ find docs -type f | sort
docs/FDD.md
docs/PRD.md
docs/RFC.md
docs/TRACKER.md
docs/adrs/README.md
```

**Resposta explícita:** `docs/PRD.md`, `docs/RFC.md`, `docs/FDD.md` e
`docs/TRACKER.md` **JÁ EXISTEM** e já estão versionados. A pasta `docs/adrs/`
**JÁ EXISTE**, mas contém apenas `README.md` — nenhum ADR individual ainda.
Nenhum dos quatro arquivos de doc está vazio; todos têm apenas um título H1 e
um comentário HTML placeholder (nenhuma estrutura de seções/checklist).
`docs/adrs/README.md` não é um placeholder — define uma convenção de
nomenclatura. Conteúdo integral de cada um:

```
=== docs/PRD.md ===
# PRD — Product Requirements Document

<!-- documento a ser elaborado -->
```

```
=== docs/RFC.md ===
# RFC — Request for Comments

<!-- documento a ser elaborado -->
```

```
=== docs/FDD.md ===
# FDD — Feature Design Document

<!-- documento a ser elaborado -->
```

```
=== docs/TRACKER.md ===
# Tracker

<!-- acompanhamento do trabalho será preenchido posteriormente -->
```

```
=== docs/adrs/README.md ===
# Architectural Decision Records

Este diretório armazena os ADRs (Architectural Decision Records) do projeto.
Cada decisão arquitetural relevante deve ser registrada aqui em arquivos individuais,
nomeados sequencialmente (por exemplo `0001-titulo-da-decisao.md`).
```

**Atenção — conflito de convenção:** o contexto do desafio menciona
`docs/adrs/ADR-NNN-*.md` (3 dígitos, prefixo `ADR-`). O `docs/adrs/README.md` já
versionado no repositório prescreve `NNNN-titulo-da-decisao.md` (4 dígitos, sem
prefixo `ADR-`, ex.: `0001-titulo-da-decisao.md`). Divergência não resolvida
aqui — decisão a ser tomada antes de criar os ADRs.

## 0.6 Inventário de caminhos (insumo do verificador anti-alucinação)

```
$ git ls-files > .planning/00-inventario-paths.txt
$ wc -l .planning/00-inventario-paths.txt
67 .planning/00-inventario-paths.txt
```

67 caminhos rastreados no total (inclui os 2 arquivos de `.planning/` já
commitados nesta e na sessão anterior).

Arquivos sob `src/` que tocam ciclo de vida de pedido, erros e auditoria (nomes
apenas — conteúdo não lido):

```
$ git ls-files src | grep -iE "order|error|log|audit"
src/middlewares/error.middleware.ts
src/middlewares/request-logger.middleware.ts
src/modules/orders/order.controller.ts
src/modules/orders/order.repository.ts
src/modules/orders/order.routes.ts
src/modules/orders/order.schemas.ts
src/modules/orders/order.service.ts
src/modules/orders/order.status.ts
src/shared/errors/app-error.ts
src/shared/errors/http-errors.ts
src/shared/errors/index.ts
src/shared/logger/index.ts
```

Nenhum arquivo com "audit" no nome foi encontrado — não há módulo de auditoria
dedicado; o candidato mais próximo é `src/shared/logger/index.ts` e
`src/middlewares/request-logger.middleware.ts`. **Registrar como [ausente]:
módulo de auditoria explícito.**

## 0.7 VEREDITO — o repositório base prescreve workflow próprio?

```
$ for p in .claude CLAUDE.md AGENTS.md .cursorrules .cursor .github CONTRIBUTING.md; do
    if [ -e "$p" ]; then echo "$p: PRESENTE"; else echo "$p: [ausente]"; fi
  done
.claude: [ausente]
CLAUDE.md: [ausente]
AGENTS.md: [ausente]
.cursorrules: [ausente]
.cursor: [ausente]
.github: [ausente]
CONTRIBUTING.md: [ausente]

$ git ls-files | grep -iE "claude|cursor|agent|prompt|skill|template|\.github"
(sem saída, exit code 1)

$ git ls-files docs/README.md
(sem saída — arquivo não existe; docs/ tem apenas os 4 docs + adrs/README.md, ver 0.5)
```

Nenhum diretório/arquivo de configuração de agente (`.claude/`, `CLAUDE.md`,
`AGENTS.md`, `.cursorrules`, `.cursor/`, `.github/`, `CONTRIBUTING.md`) existe
no repositório. Não há template de seções para PRD/RFC/FDD, nem arquivo
prescrevendo ordem de fases ou formato de documento. O único artefato de
"processo" já existente é a convenção de nomenclatura de ADR em
`docs/adrs/README.md` (ver 0.5), que é uma convenção de nome de arquivo, não um
workflow de produção de documentos.

**TRANSCRICAO.md — metadados apenas:**

```
$ wc -l TRANSCRICAO.md
323 TRANSCRICAO.md

$ head -1 TRANSCRICAO.md
# Reunião Técnica — Sistema de Webhooks de Notificação de Pedidos

$ tail -1 TRANSCRICAO.md
[09:53] *Fim da call.*

$ grep -oE '^\[[0-9]{2}:[0-9]{2}\] [A-Za-zÀ-ÿ]+:' TRANSCRICAO.md | sed -E 's/^\[[0-9:]+\] //' | sort -u
Bruno:
Diego:
Larissa:
Marcos:
Sofia:

$ grep -oE '^\[[0-9]{2}:[0-9]{2}\]' TRANSCRICAO.md | head -1
[09:00]

$ grep -oE '^\[[0-9]{2}:[0-9]{2}\]' TRANSCRICAO.md | tail -1
[09:53]
```

323 linhas, janela 09:00–09:53, 5 participantes (Bruno, Diego, Larissa, Marcos,
Sofia). Nenhum conteúdo de fala foi lido além dessas linhas de metadados.

### Conclusão

**(a) O repositório base NÃO prescreve workflow próprio.**

Ressalva: `docs/PRD.md`, `docs/RFC.md`, `docs/FDD.md`, `docs/TRACKER.md` e
`docs/adrs/` já existem como esqueleto vazio (título + placeholder), e
`docs/adrs/README.md` fixa uma convenção de nome de arquivo para ADRs
(`NNNN-titulo-da-decisao.md`) que diverge da convenção `ADR-NNN-*.md` citada no
contexto do desafio. Isso não constitui um workflow de agente/fases — é apenas
scaffolding de arquivo e uma convenção de nomenclatura, que deve ser
reconciliada antes da criação dos ADRs.
