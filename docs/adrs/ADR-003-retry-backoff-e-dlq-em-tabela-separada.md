# ADR-003 — Retry com backoff exponencial e DLQ em tabela separada

## Status
Aceito — 2026-08-19 · decidido em reunião técnica de [09:00]–[09:53]

## Contexto

Com a entrega assíncrona (ADR-002), a falha do endpoint do cliente deixa de ser
um erro do pedido e passa a ser um estado do evento: alguém precisa decidir
quantas vezes tentar de novo, com que espaçamento, e o que fazer com o evento que
não entra de jeito nenhum.

A reunião não discutiu isso em abstrato — partiu de um caso real de operação:
`[09:16] Diego` — "Já tinha cliente nosso com indisponibilidade de duas horas em
manutenção planejada." A janela alvo saiu dessa observação:
`[09:15] Diego` — "Cinco já dá pra cobrir uma janela de até 12 ou 24 horas." — e
a conta da progressão escolhida foi dita em voz alta: `[09:17] Diego` — "Total de
quase 15 horas entre primeira falha e última tentativa."

Nada disso existe no código para ser reaproveitado. As buscas por
`retry|retries|backoff` e por `dead.?letter|dlq` em `src/`, `prisma/`, `tests/`
e `package.json` retornam vazias, assim como a busca por
`cron|scheduler|setInterval`: não há agendador, não há política de retentativa e
não há fila de descarte. A política decidida aqui nasce inteira com a feature, e
as duas tabelas envolvidas entram em `prisma/schema.prisma` pelas mesmas
convenções do restante do schema.

## Decisão

Uma entrega que falha é retentada até 5 vezes, com backoff exponencial na progressão 1m/5m/30m/2h/12h; esgotadas as tentativas, o evento sai da outbox e vai
para uma DLQ em tabela própria, `webhook_dead_letter`, que guarda o payload, o
motivo da falha e o timestamp. A saída da DLQ é o replay manual por endpoint
administrativo, que recoloca o evento na outbox como pendente — capacidade pedida
em `[09:18] Diego`: "Manual via endpoint admin. Tipo um POST
/admin/webhooks/dead-letter/:id/replay. Recoloca na outbox como pendente."
(a autorização desse endpoint é objeto de ADR-008).

Falas que fecham:

- `[09:17] Larissa` — "Decidido: 5 tentativas, backoff 1m/5m/30m/2h/12h." —
  **DEC-05**.
- `[09:18] Bruno` — "Faz sentido." (tabela `webhook_dead_letter` separada,
  proposta por Diego na mesma janela) — **DEC-06**, ratificada no resumo da
  reunião por `[09:48] Larissa`.

## Alternativas Consideradas

### Retry indefinido com backoff

Nunca desistir: continuar retentando com espaçamento crescente até o cliente
voltar.

- Quem levantou e quando: `[09:15] Diego`, ao enumerar as posições possíveis.
- **Motivo do descarte:** `[09:15] Diego` — "Algumas pessoas defendem retry
  indefinido com backoff, mas isso traz o problema de evento ficar pendurado". O
  trade-off dito é o evento que fica pendurado para sempre quando o cliente some
  de vez (REC-04).

### Teto de 3 tentativas

Uma política mais curta, matando o evento cedo.

- Quem levantou e quando: `[09:16] Diego`, comparando com o caso real de
  indisponibilidade de duas horas.
- **Motivo do descarte:** `[09:16] Diego` — "3 é pouco. Se o cliente teve
  indisponibilidade de manhã, a gente retentaria três vezes em 30 minutos e
  mataria." Trinta minutos não cobrem a indisponibilidade real observada em
  produção (REC-05).

### Marcar falha permanente como "failed" na própria outbox, sem tabela de DLQ

Manter tudo numa tabela só, distinguindo o evento morto por estado.

- Quem levantou e quando: `[09:18] Diego`, ao propor a forma oposta.
- **Motivo do descarte:** `[09:18] Diego` — "Eu fazia uma tabela
  webhook_dead_letter separada, com a payload, motivo da falha e timestamp." A
  razão dita para separar é manter a leitura da outbox principal limpa e ter uma
  tabela que serve de evidência para debug e reprocessamento (REC-06).

## Consequências

### Positivas

- A janela de ~15 horas cobre com margem a indisponibilidade real que motivou a
  discussão — duas horas de manutenção planejada (`[09:16] Diego`).
- A outbox principal continua sendo lida só por quem tem chance de entrega: o
  evento morto sai da tabela quente, o que preserva o "lê só os pendentes em
  batch pequeno" do worker (`[09:08] Diego`).
- A DLQ carrega payload, motivo e timestamp — material suficiente para diagnóstico
  sem consultar log, e é a origem do replay pedido em `[09:18] Diego`.
- As duas tabelas seguem o precedente de schema já existente
  (`prisma/schema.prisma`:116, `OrderStatusHistory`): id `@db.Char(36)` com
  `@default(uuid())`, FK indexada e índice temporal.

### Negativas

- Um evento só é declarado morto quase 15 horas depois da primeira falha
  (`[09:17] Diego`). Até lá ele ocupa linha na outbox, é relido pelo worker a
  cada ciclo elegível e consome uma chamada HTTP por tentativa — a cobertura
  longa é paga em retenção e trabalho repetido contra um endpoint que já falhou.
- Duas tabelas para operar em vez de uma, e nenhuma delas com rotina de limpeza:
  o arquivamento de linhas entregues ficou fora do escopo desta feature
  (`[09:08] Diego`, REC-11), e a DLQ não tem política de expurgo decidida.
- O caminho de saída da DLQ é humano. Sem alguém chamando o endpoint de replay o
  evento não volta, e a reunião recusou notificar o cliente por email quando o
  webhook dele falha — `[09:37] Larissa`: "Não. Email tá fora de escopo dessa
  fase. Talvez próxima fase, depois que a gente medir o impacto." (REC-13).
  Consequência declarada: a descoberta de que há evento na DLQ depende de alguém
  olhar.
- O replay recoloca o evento na outbox como pendente, ou seja, ele é reentregue
  fora da ordem original — o que reforça o limite já registrado em DEC-04
  (ADR-002) e o contrato at-least-once de ADR-005.
- Não há nada no repositório para reaproveitar: sem `retry|retries|backoff`, sem
  `dead.?letter|dlq` e sem `cron|scheduler|setInterval` em `src/`, `prisma/`,
  `tests/` ou `package.json`, o agendamento da próxima tentativa precisa ser
  construído dentro do próprio ciclo de polling do worker, e essa mecânica é
  código novo sem precedente no projeto.
