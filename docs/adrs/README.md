# Architectural Decision Records

Esta pasta guarda os ADRs da feature de **webhooks de mudança de status de
pedido** — a entrega discutida na reunião técnica de [09:00]–[09:53] registrada
em `TRANSCRICAO.md`. Cada arquivo registra uma decisão que a reunião fechou, com
a fala que a fechou, as alternativas que foram descartadas com o motivo dito e as
consequências, positivas e negativas, de tê-la tomado. Os ADRs não decidem nada
por conta própria: onde a leitura do código existente contradisse o que a reunião
presumiu, a divergência está registrada dentro do ADR correspondente, sem
conciliação. O formato dos oito arquivos é MADR: `## Status`, `## Contexto`,
`## Decisão`, `## Alternativas Consideradas` e `## Consequências`, esta última
com `### Positivas` e `### Negativas` obrigatórias.

## Índice

| ADR | Título | Status | DEC de origem | Localização |
|---|---|---|---|---|
| [ADR-001](ADR-001-outbox-no-mysql.md) | Outbox de eventos no MySQL já existente | Aceito | DEC-01 | `[09:08] Larissa` |
| [ADR-002](ADR-002-worker-processo-separado-polling.md) | Worker em processo separado consumindo a outbox por polling | Aceito | DEC-02, DEC-03, DEC-12, DEC-14 (limitação DEC-04) | `[09:10] Larissa` · `[09:11] Diego` · `[09:28] Diego` · `[09:30] Bruno` |
| [ADR-003](ADR-003-retry-backoff-e-dlq-em-tabela-separada.md) | Retry com backoff exponencial e DLQ em tabela separada | Aceito | DEC-05, DEC-06 | `[09:17] Larissa` · `[09:18] Bruno` |
| [ADR-004](ADR-004-hmac-sha256-secret-por-endpoint.md) | Assinatura HMAC-SHA256 com secret por endpoint | Aceito | DEC-07, DEC-08, DEC-09 | `[09:22] Sofia` |
| [ADR-005](ADR-005-entrega-at-least-once-com-x-event-id.md) | Entrega at-least-once com X-Event-Id para dedup no cliente | Aceito | DEC-10 | `[09:26] Larissa` |
| [ADR-006](ADR-006-reuso-dos-padroes-existentes.md) | Reuso dos padrões existentes do projeto no módulo de webhooks | Aceito | DEC-11, DEC-13, DEC-15, DEC-16 | `[09:28] Diego` · `[09:29] Larissa` · `[09:30] Larissa` |
| [ADR-007](ADR-007-insercao-na-outbox-dentro-da-transacao.md) | Inserção na outbox dentro da transação do `changeStatus` | Aceito | DEC-18, DEC-21, DEC-22 | `[09:34] Diego` · `[09:41] Diego` |
| [ADR-008](ADR-008-modelo-de-autorizacao-do-modulo.md) | Modelo de autorização do módulo de webhooks | Aceito | DEC-17, DEC-19, DEC-20 | `[09:32] Larissa` · `[09:36] Larissa` · `[09:37] Sofia` |

Os IDs `DEC-NN` são os da extração da transcrição em
`.planning/02-transcricao.md`, e a coluna Localização traz a fala que fecha cada
decisão, no formato `[hh:mm] Nome`.

## Convenção de nomenclatura

Os arquivos desta pasta seguem o formato `ADR-NNN-titulo-em-kebab-case.md`, com
`NNN` de três dígitos e sequencial, e nada além disso convive aqui exceto este
`README.md`.

O scaffolding original desta pasta declarava outra convenção,
`NNNN-titulo-da-decisao.md`, com quatro dígitos; a divergência é deliberada e
está decidida em `.planning/03-design.md` D-01 — o critério de aceite do desafio
cita literalmente o formato de três dígitos, e é contra ele que a entrega é
conferida. Este README foi reescrito como índice em vez de apagado justamente
para que a troca de convenção ficasse registrada, e não silenciosa (D-06).
