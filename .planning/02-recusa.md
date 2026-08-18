# 02 — Lista de recusa (extrato operacional para grep)

Extrato das seções `## Descartado` e `## Adiado para fase futura` de
`.planning/02-transcricao.md`. Só o operacional: o que **não** pode reaparecer
como escopo nos documentos dos blocos seguintes.

Cada `Termo-âncora` é literal da transcrição e serve de padrão de busca
(`grep -F`) contra PRD, RFC, ADRs e demais entregáveis. Este arquivo alimenta
**INV-7** nos blocos 7 e 9.

| ID | Termo-âncora | Classificação | Localização |
|---|---|---|---|
| REC-01 | `Síncrono` | DESCARTADO | `[09:06] Diego` |
| REC-02 | `Redis` | DESCARTADO | `[09:07] Diego` |
| REC-03 | `trigger do banco` | DESCARTADO | `[09:09] Diego` |
| REC-04 | `retry indefinido` | DESCARTADO | `[09:15] Diego` |
| REC-05 | `3 é pouco` | DESCARTADO | `[09:16] Diego` |
| REC-06 | `"failed" na própria outbox` | DESCARTADO | `[09:18] Diego` |
| REC-07 | `Trunca` | DESCARTADO | `[09:23] Sofia` |
| REC-08 | `exactly-once` | DESCARTADO | `[09:25] Diego` |
| REC-09 | `implícito do JWT` | DESCARTADO | `[09:32] Larissa` |
| REC-10 | `Painel` | DESCARTADO | `[09:40] Larissa` |
| REC-11 | `arquiva` | ADIADO | `[09:08] Diego` |
| REC-12 | `lock pessimista` | ADIADO | `[09:13] Diego` |
| REC-13 | `Email` | ADIADO | `[09:37] Larissa` |
| REC-14 | `endurecer` | ADIADO | `[09:37] Sofia` |
| REC-15 | `rate limiting` | ADIADO | `[09:39] Diego` |

**Totais:** 10 DESCARTADO · 5 ADIADO · 15 itens.

**Nota de uso.** Um hit de grep não é, sozinho, uma violação: `exactly-once`,
`Redis` e `rate limiting` podem legitimamente aparecer numa seção de
"alternativas consideradas e rejeitadas" ou "fora de escopo". O que INV-7 tem
que reprovar é o termo aparecendo como escopo, requisito ou decisão vigente.
