# 01 — Scaffolding existente

Inventário do estado atual de `docs/*.md`. Nenhum arquivo sob `docs/` foi
alterado nesta sessão — apenas lido. Toda saída abaixo é literal, capturada
nesta sessão.

```
$ find docs -name '*.md' | sort
docs/FDD.md
docs/PRD.md
docs/RFC.md
docs/TRACKER.md
docs/adrs/README.md
```

## docs/PRD.md

`wc -w`: 12 · `wc -l`: 3

```
# PRD — Product Requirements Document

<!-- documento a ser elaborado -->
```

## docs/RFC.md

`wc -w`: 12 · `wc -l`: 3

```
# RFC — Request for Comments

<!-- documento a ser elaborado -->
```

## docs/FDD.md

`wc -w`: 12 · `wc -l`: 3

```
# FDD — Feature Design Document

<!-- documento a ser elaborado -->
```

## docs/TRACKER.md

`wc -w`: 10 · `wc -l`: 3

```
# Tracker

<!-- acompanhamento do trabalho será preenchido posteriormente -->
```

## docs/adrs/README.md

`wc -w`: 30 · `wc -l`: 5

```
# Architectural Decision Records

Este diretório armazena os ADRs (Architectural Decision Records) do projeto.
Cada decisão arquitetural relevante deve ser registrada aqui em arquivos individuais,
nomeados sequencialmente (por exemplo `0001-titulo-da-decisao.md`).
```

Nota: `docs/adrs/README.md` **não é placeholder** — é conteúdo real que fixa uma
convenção de nomenclatura (`NNNN-titulo-da-decisao.md`). Essa convenção diverge
da decisão normativa D-01 (`ADR-NNN-titulo-em-kebab-case.md`) e será substituída
no Bloco 4, não neste bloco (ver `.planning/01-matriz.md`, seção "Decisões
normativas").

## Inventário de placeholders

Comandos usados (cada string testada isoladamente contra os 5 arquivos):

```
$ grep -noE "TODO" docs/PRD.md docs/RFC.md docs/FDD.md docs/TRACKER.md docs/adrs/README.md
(sem saída, exit 1)

$ grep -noE "<[^>]*>" docs/PRD.md docs/RFC.md docs/FDD.md docs/TRACKER.md docs/adrs/README.md
docs/PRD.md:3:<!-- documento a ser elaborado -->
docs/RFC.md:3:<!-- documento a ser elaborado -->
docs/FDD.md:3:<!-- documento a ser elaborado -->
docs/TRACKER.md:3:<!-- acompanhamento do trabalho será preenchido posteriormente -->

$ grep -noiE "lorem" docs/PRD.md docs/RFC.md docs/FDD.md docs/TRACKER.md docs/adrs/README.md
(sem saída, exit 1)

$ grep -noE "\[[^]]*\]" docs/PRD.md docs/RFC.md docs/FDD.md docs/TRACKER.md docs/adrs/README.md
(sem saída, exit 1)

$ grep -noiE "a ser elaborado" docs/PRD.md docs/RFC.md docs/FDD.md docs/TRACKER.md docs/adrs/README.md
docs/PRD.md:3:a ser elaborado
docs/RFC.md:3:a ser elaborado
docs/FDD.md:3:a ser elaborado

$ grep -noiE "será preenchido" docs/PRD.md docs/RFC.md docs/FDD.md docs/TRACKER.md docs/adrs/README.md
docs/TRACKER.md:3:será preenchido

$ grep -noE "FIXME|XXX" docs/PRD.md docs/RFC.md docs/FDD.md docs/TRACKER.md docs/adrs/README.md
(sem saída, exit 1)
```

| String literal | Arquivo | Contagem |
| --- | --- | --- |
| `<!-- documento a ser elaborado -->` (comentário HTML completo) | docs/PRD.md | 1 |
| `<!-- documento a ser elaborado -->` | docs/RFC.md | 1 |
| `<!-- documento a ser elaborado -->` | docs/FDD.md | 1 |
| `<!-- acompanhamento do trabalho será preenchido posteriormente -->` | docs/TRACKER.md | 1 |
| `a ser elaborado` | docs/PRD.md, docs/RFC.md, docs/FDD.md | 3 (1 cada) |
| `será preenchido` | docs/TRACKER.md | 1 |
| `TODO` | — | 0 |
| `Lorem` | — | 0 |
| `[...]` (texto entre colchetes) | — | 0 |
| `FIXME` / `XXX` | — | 0 |

`docs/adrs/README.md` não contém nenhuma das strings acima — não é placeholder,
é conteúdo real (ver nota acima).

Esta tabela é a fonte para a condição "zero placeholders" usada em PRD-1,
RFC-1, FDD-1 e TRK-1 na matriz (`.planning/01-matriz.md`): o check dessas
condições faz `grep -qE '<!--.*(a ser elaborado|será preenchido).*-->'` contra
o arquivo alvo e exige zero ocorrências.

## `ls -la docs/adrs/`

```
$ ls -la docs/adrs/
total 12
drwxrwxr-x 2 wesley wesley 4096 ago 18 10:40 .
drwxrwxr-x 3 wesley wesley 4096 ago 18 10:40 ..
-rw-rw-r-- 1 wesley wesley  267 ago 18 10:40 README.md
```
