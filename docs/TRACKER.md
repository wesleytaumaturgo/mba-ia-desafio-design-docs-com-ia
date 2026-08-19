# Tracker — rastreabilidade do pacote de documentos

Este documento é a referência cruzada entre cada item rastreável do pacote
(`docs/PRD.md`, `docs/RFC.md`, `docs/FDD.md`, `docs/adrs/`) e a fonte que o
originou: a fala registrada em `.planning/02-transcricao.md` (conferível
literalmente em `TRANSCRICAO.md`, por `grep -F`) ou o código lido em
`.planning/02-codigo.md`/`.planning/02-ganchos-verificados.md` (conferível em
`git ls-files`). Para ler uma linha: `ID` e `Documento` localizam o item no
pacote; `Fonte` e `Localização` respondem "de onde isso veio, e como eu
confiro". Nenhuma linha da tabela principal tem Localização inventada — todo
item cuja origem não pôde ser apontada está em
[§Itens sem origem identificável](#itens-sem-origem-identificável), não
misturado à tabela com uma origem "provável".

## Referência cruzada

| ID | Documento | Tipo | Conteúdo (resumo) | Fonte | Localização |
|---|---|---|---|---|---|
| PRD-FR-01 | docs/PRD.md | Requisito Funcional | Cadastro de endpoint de webhook via POST | TRANSCRICAO | `[09:31] Marcos` |
| PRD-FR-02 | docs/PRD.md | Requisito Funcional | Secret gerada pela plataforma na criação | TRANSCRICAO | `[09:31] Marcos` |
| PRD-FR-03 | docs/PRD.md | Requisito Funcional | Editar, remover e listar webhooks do cliente | TRANSCRICAO | `[09:33] Bruno` |
| PRD-FR-04 | docs/PRD.md | Requisito Funcional | Endpoint declara lista de status ouvidos | TRANSCRICAO | `[09:33] Marcos` |
| PRD-FR-05 | docs/PRD.md | Requisito Funcional | Rotação de secret pela API | TRANSCRICAO | `[09:21] Sofia` |
| PRD-FR-06 | docs/PRD.md | Requisito Funcional | Consulta do histórico de entregas | TRANSCRICAO | `[09:34] Marcos` |
| PRD-FR-07 | docs/PRD.md | Requisito Funcional | Histórico expõe últimos 100 envios com detalhes | TRANSCRICAO | `[09:34] Marcos` |
| PRD-FR-08 | docs/PRD.md | Requisito Funcional | Replay manual de evento via endpoint admin | TRANSCRICAO | `[09:18] Diego` |
| PRD-FR-09 | docs/PRD.md | Requisito Funcional | Payload traz identificação, tipo, timestamp e chaves do pedido | TRANSCRICAO | `[09:43] Diego` |
| PRD-FR-10 | docs/PRD.md | Requisito Funcional | Headers da entrega: evento, assinatura, timestamp e content type | TRANSCRICAO | `[09:44] Diego` |
| PRD-FR-11 | docs/PRD.md | Requisito Funcional | Header identifica o endpoint de origem da entrega | TRANSCRICAO | `[09:44] Sofia` |
| PRD-RNF-01 | docs/PRD.md | Requisito Não Funcional | Entrega em menos de 10 segundos | TRANSCRICAO | `[09:02] Marcos` |
| PRD-RNF-02 | docs/PRD.md | Requisito Não Funcional | Intervalo de polling de eventos pendentes: 2s | TRANSCRICAO | `[09:09] Diego` |
| PRD-RNF-03 | docs/PRD.md | Requisito Não Funcional | Latência mínima imposta pelo intervalo de polling: 2s | TRANSCRICAO | `[09:10] Larissa` |
| PRD-RNF-04 | docs/PRD.md | Requisito Não Funcional | Fila indexada por status e created_at | TRANSCRICAO | `[09:08] Diego` |
| PRD-RNF-05 | docs/PRD.md | Requisito Não Funcional | Leitura processa só pendentes, em lotes pequenos | TRANSCRICAO | `[09:08] Diego` |
| PRD-RNF-06 | docs/PRD.md | Requisito Não Funcional | Retentativa até 5 vezes antes da DLQ | TRANSCRICAO | `[09:17] Larissa` |
| PRD-RNF-07 | docs/PRD.md | Requisito Não Funcional | Progressão do backoff: 4 intervalos 1m/5m/30m/2h, imposta pelas 5 tentativas de DEC-05 (leitura adotada; ver RFC-QA-05) | TRANSCRICAO | `[09:17] Larissa` |
| PRD-RNF-08 | docs/PRD.md | Requisito Não Funcional | Janela total entre falha e última tentativa: 2h36min — aritmética derivada de DEC-05, não dita em nenhuma fala (ver RFC-QA-05) | TRANSCRICAO | `[09:17] Larissa` |
| PRD-RNF-09 | docs/PRD.md | Requisito Não Funcional | Secret anterior válida 24h após rotação | TRANSCRICAO | `[09:21] Sofia` |
| PRD-RNF-10 | docs/PRD.md | Requisito Não Funcional | URL de webhook precisa usar TLS | TRANSCRICAO | `[09:23] Sofia` |
| PRD-RNF-11 | docs/PRD.md | Requisito Não Funcional | URL insegura é recusada com erro de validação | TRANSCRICAO | `[09:23] Sofia` |
| PRD-RNF-12 | docs/PRD.md | Requisito Não Funcional | Payload acima de 64KB gera erro | TRANSCRICAO | `[09:24] Larissa` |
| PRD-RNF-13 | docs/PRD.md | Requisito Não Funcional | Garantia de entrega at-least-once | TRANSCRICAO | `[09:24] Diego` |
| PRD-RNF-14 | docs/PRD.md | Requisito Não Funcional | Histórico exposto cobre últimos 100 envios | TRANSCRICAO | `[09:34] Marcos` |
| PRD-RNF-15 | docs/PRD.md | Requisito Não Funcional | Replay administrativo registra autor, para auditoria | TRANSCRICAO | `[09:36] Sofia` |
| PRD-RNF-16 | docs/PRD.md | Requisito Não Funcional | Cenário de carga citado (50 pedidos/min), não capacidade garantida — pergunta retórica que abriu a discussão de rate limiting | TRANSCRICAO | `[09:38] Diego` |
| PRD-RNF-17 | docs/PRD.md | Requisito Não Funcional | Tentativa sem resposta em 10s é tratada como falha | TRANSCRICAO | `[09:42] Diego` |
| PRD-RNF-18 | docs/PRD.md | Requisito Não Funcional | Esforço estimado: três sprints com revisão de segurança | TRANSCRICAO | `[09:47] Larissa` |
| PRD-RNF-19 | docs/PRD.md | Requisito Não Funcional | Dois dias úteis reservados para revisão de segurança | TRANSCRICAO | `[09:46] Sofia` |
| PRD-RNF-20 | docs/PRD.md | Requisito Não Funcional | Secret e header de assinatura entram na lista de redação de log | CODIGO | `src/shared/logger/index.ts:4` |
| PRD-RNF-21 | docs/PRD.md | Requisito Não Funcional | Data combinada de disponibilidade em produção: fim de novembro | TRANSCRICAO | `[09:45] Marcos` |
| RFC-ALT-01 | docs/RFC.md | Alternativa | Disparo síncrono no service de pedidos, descartado | TRANSCRICAO | `[09:06] Diego` |
| RFC-ALT-02 | docs/RFC.md | Alternativa | Redis Streams como transporte, descartado | TRANSCRICAO | `[09:07] Diego` |
| RFC-ALT-03 | docs/RFC.md | Alternativa | Trigger de banco como gatilho reativo, descartado | TRANSCRICAO | `[09:09] Diego` |
| RFC-ALT-04 | docs/RFC.md | Alternativa | Retry indefinido com backoff, descartado | TRANSCRICAO | `[09:15] Diego` |
| RFC-ALT-05 | docs/RFC.md | Alternativa | Teto de três tentativas, descartado | TRANSCRICAO | `[09:16] Diego` |
| RFC-ALT-06 | docs/RFC.md | Alternativa | Garantia exactly-once, descartada | TRANSCRICAO | `[09:25] Diego` |
| RFC-QA-01 | docs/RFC.md | Questão em aberto | customer_id no corpo ou no path, não fechado | TRANSCRICAO | `[09:32] Larissa` |
| RFC-QA-02 | docs/RFC.md | Questão em aberto | Nome do arquivo de processamento do worker, não fechado | TRANSCRICAO | `[09:28] Bruno` |
| RFC-QA-03 | docs/RFC.md | Questão em aberto | Rate limiting por cliente, fora de escopo e em aberto | TRANSCRICAO | `[09:39] Diego` |
| RFC-QA-04 | docs/RFC.md | Questão em aberto | Ordenação com mais de um worker, sem solução escolhida | TRANSCRICAO | `[09:12] Diego` |
| RFC-QA-05 | docs/RFC.md | Questão em aberto | Política de retry com três leituras incompatíveis na ata (5 tentativas × 5 intervalos × ~15h); a leitura adotada precisa de ratificação | TRANSCRICAO | `[09:17] Diego` |
| FDD-CONTRATO-01 | docs/FDD.md | Contrato | Forma do path `POST /customers/:customerId/webhooks` (aninhamento sob `/customers`; o verbo e os campos vêm de `[09:31] Marcos`) | CODIGO | `src/routes/index.ts:26` |
| FDD-CONTRATO-02 | docs/FDD.md | Contrato | Forma do path `GET /customers/:customerId/webhooks` (listagem paginada; o verbo vem de `[09:33] Bruno`) | CODIGO | `src/modules/customers/customer.routes.ts:16` |
| FDD-CONTRATO-03 | docs/FDD.md | Contrato | Forma do path `PATCH /webhooks/:id` (o verbo vem de `[09:33] Bruno`) | CODIGO | `src/modules/customers/customer.routes.ts:19` |
| FDD-CONTRATO-04 | docs/FDD.md | Contrato | Forma do path `DELETE /webhooks/:id` (o verbo vem de `[09:33] Bruno`) | CODIGO | `src/modules/customers/customer.routes.ts:24` |
| FDD-CONTRATO-05 | docs/FDD.md | Contrato | Forma do path `POST /webhooks/:id/secret/rotate` (sub-ação sob `/:id`; a capacidade de rotação vem de `[09:21] Sofia`) | CODIGO | `src/modules/orders/order.routes.ts:19` |
| FDD-CONTRATO-06 | docs/FDD.md | Contrato | `GET /webhooks/:id/deliveries` | TRANSCRICAO | `[09:34] Marcos` |
| FDD-CONTRATO-07 | docs/FDD.md | Contrato | `POST /admin/webhooks/dead-letter/:id/replay` | TRANSCRICAO | `[09:18] Diego` |
| FDD-ERR-01 | docs/FDD.md | Erro | `WEBHOOK_URL_NOT_HTTPS` — url sem TLS | TRANSCRICAO | `[09:23] Sofia` |
| FDD-ERR-02 | docs/FDD.md | Erro | `WEBHOOK_INVALID_STATUS_FILTER` — valor fora do enum `OrderStatus` | CODIGO | `prisma/schema.prisma:16` |
| FDD-ERR-04 | docs/FDD.md | Erro | `WEBHOOK_NOT_FOUND` — id de endpoint inexistente | TRANSCRICAO | `[09:28] Bruno` |
| FDD-ERR-05 | docs/FDD.md | Erro | `WEBHOOK_CUSTOMER_NOT_FOUND` — customerId inexistente | CODIGO | `src/modules/customers/customer.service.ts:25` |
| FDD-ERR-07 | docs/FDD.md | Erro | `WEBHOOK_REPLAY_FORBIDDEN` — replay sem role ADMIN | TRANSCRICAO | `[09:36] Larissa` |
| FDD-ERR-10 | docs/FDD.md | Erro | `WEBHOOK_PAYLOAD_TOO_LARGE` — corpo acima de 64KB | TRANSCRICAO | `[09:24] Larissa` |
| FDD-ERR-11 | docs/FDD.md | Erro | `WEBHOOK_DELIVERY_TIMEOUT` — sem resposta em 10s | TRANSCRICAO | `[09:42] Diego` |
| ADR-001 | docs/adrs/ADR-001-outbox-no-mysql.md | Decisão | Eventos vão para tabela outbox no MySQL existente | TRANSCRICAO | `[09:08] Larissa` |
| ADR-002 | docs/adrs/ADR-002-worker-processo-separado-polling.md | Decisão | Worker em processo separado, consumo por polling a cada 2s | TRANSCRICAO | `[09:10] Larissa` |
| ADR-003 | docs/adrs/ADR-003-retry-backoff-e-dlq-em-tabela-separada.md | Decisão | Retry com backoff exponencial e DLQ em tabela separada | TRANSCRICAO | `[09:17] Larissa` |
| ADR-004 | docs/adrs/ADR-004-hmac-sha256-secret-por-endpoint.md | Decisão | Assinatura HMAC-SHA256 com secret por endpoint | TRANSCRICAO | `[09:22] Sofia` |
| ADR-005 | docs/adrs/ADR-005-entrega-at-least-once-com-x-event-id.md | Decisão | Entrega at-least-once com X-Event-Id para dedup | TRANSCRICAO | `[09:26] Larissa` |
| ADR-006 | docs/adrs/ADR-006-reuso-dos-padroes-existentes.md | Decisão | Reuso dos padrões existentes do projeto no módulo novo | TRANSCRICAO | `[09:30] Larissa` |
| ADR-007 | docs/adrs/ADR-007-insercao-na-outbox-dentro-da-transacao.md | Decisão | Inserção na outbox dentro da transação do `changeStatus` | TRANSCRICAO | `[09:41] Diego` |
| ADR-008 | docs/adrs/ADR-008-modelo-de-autorizacao-do-modulo.md | Decisão | Modelo de autorização do módulo de webhooks | TRANSCRICAO | `[09:32] Larissa` |

## Itens sem origem identificável

Nenhuma linha desta seção recebeu Localização inventada. Cada uma foi varrida
em `.planning/02-transcricao.md` e em `.planning/02-codigo.md` /
`.planning/02-ganchos-verificados.md` e não encontrou fala nem artefato de
código que sustente o conteúdo específico do item — só a hierarquia genérica de
classes de erro (`AppError`/`ConflictError`/`UnprocessableEntityError`), comum a
qualquer código HTTP do módulo e por isso insuficiente para apontar como
origem de um item específico.

| ID | Documento | Por que não tem origem | Ação sugerida |
|---|---|---|---|
| FDD-ERR-03 | docs/FDD.md | `WEBHOOK_DUPLICATE_URL` (url já cadastrada e ativa para o mesmo cliente) não é citado em nenhuma fala da reunião nem tem precedente de constraint de unicidade de URL no código lido; só a classe genérica `ConflictError` se aplicaria, e ela não distingue esta regra de nenhuma outra | Confirmar com quem escreveu o FDD se a regra foi decidida fora da reunião registrada, ou documentá-la como decisão nova do FDD, não como algo herdado |
| PRD-RNF-22 | docs/PRD.md | A proibição de devolver a secret fora da criação e da rotação não tem fala nem código. `[09:31] Marcos` diz que a secret "é gerada pela gente e devolvida na criação" — cobre a devolução, não a proibição nas demais consultas. Não há precedente no código: a busca por `hmac\|crypto\|createHmac\|signature` em `src/ prisma/ tests/ package.json` é vazia. O item existia no PRD como critério de aceite sem ID; ganhou ID aqui para ficar visível, não para ganhar origem | Registrar como decisão nova do PRD/FDD, com dono e data. A regra em si é sensata e não deve ser removida por falta de fala — o que falta é o dono |
| FDD-ERR-06 | docs/FDD.md | **Origem falsa, corrigida aqui.** A linha declarava `[09:21] Sofia` como origem de `WEBHOOK_ROTATION_IN_GRACE_PERIOD`. A fala institui o grace period — "Quando ele rotaciona, a antiga fica válida por 24 horas em paralelo" — e **não** diz nem sugere que uma nova rotação seja recusada enquanto a janela está aberta. Não há lastro em código: `grep -rniE 'hmac\|crypto\|createHmac\|signature'` em `src/ prisma/ tests/ package.json` é vazio. A regra ainda tem efeito adverso: bloquear a re-rotação impede revogar uma secret comprometida por 24 horas, o oposto do que a fala protegia | Remover a regra de bloqueio, ou registrá-la como decisão nova do FDD com dono e data — origem declarada e falsa é pior do que origem ausente |
| FDD-ERR-08 | docs/FDD.md | `WEBHOOK_DEAD_LETTER_NOT_FOUND` (id de item de dead-letter inexistente) estava na tabela principal apontando para `src/shared/errors/http-errors.ts:27`, que é a classe genérica `NotFoundError` — a mesma origem genérica que esta seção declara insuficiente. A dead-letter queue é estrutura nova, sem precedente de código próprio, e nenhuma fala trata do id inexistente: `[09:18] Diego` cria o endpoint de replay, não o erro. `[09:28] Bruno` nomeia `WEBHOOK_NOT_FOUND`, não este | Registrar como decisão nova do FDD, com dono e data, ou derivá-la explicitamente do padrão de 404 do projeto em um DEC próprio |
| FDD-ERR-09 | docs/FDD.md | `WEBHOOK_DEAD_LETTER_ALREADY_REPLAYED` (proteção contra replay duplicado) não consta da reunião — RNF-18 discute deduplicação do lado do cliente, não idempotência do endpoint de replay — nem há precedente de código, já que a dead-letter queue é estrutura nova | Mesma ação: registrar como decisão nova do FDD, com dono e data, em vez de tracker apontando origem que não existe |
| FDD-ERR-12 | docs/FDD.md | `WEBHOOK_DELIVERY_FAILED` (resposta fora da faixa 2xx) não é citado explicitamente; DEC-05/RNF-07 cobrem o número de tentativas e o backoff, não o critério que classifica uma resposta HTTP como falha | Se o critério "fora de 2xx" foi decisão implícita, torná-la explícita em um DEC ou registrar como decisão nova do FDD |
| FDD-ERR-13 | docs/FDD.md | `WEBHOOK_SIGNATURE_UNAVAILABLE` (endpoint sem secret utilizável no momento do envio) não aparece em nenhuma fala sobre secret/rotação (DEC-07/08/09, RNF-13) nem em código — HMAC e secret são funcionalidade nova, `grep -rniE 'hmac|crypto|createHmac|signature'` em `src/ prisma/ tests/ package.json` retorna vazio (`.planning/02-codigo.md` §4) | Tratar como decisão nova do FDD (cenário de borda da rotação) e registrar quem a decidiu, já que não há fala nem código que a sustente |

## Validação de Localização (TRANSCRICAO)

Cada `[hh:mm] Nome` usado na tabela principal, conferido por `grep -cF` em
`TRANSCRICAO.md`:

| Localização | ocorrências |
|---|---|
| `[09:31] Marcos` | 1 |
| `[09:33] Bruno` | 1 |
| `[09:33] Marcos` | 1 |
| `[09:21] Sofia` | 2 |
| `[09:34] Marcos` | 1 |
| `[09:18] Diego` | 2 |
| `[09:43] Diego` | 1 |
| `[09:44] Diego` | 1 |
| `[09:44] Sofia` | 1 |
| `[09:02] Marcos` | 2 |
| `[09:09] Diego` | 2 |
| `[09:10] Larissa` | 1 |
| `[09:08] Diego` | 1 |
| `[09:17] Larissa` | 1 |
| `[09:17] Diego` | 1 |
| `[09:23] Sofia` | 2 |
| `[09:24] Larissa` | 1 |
| `[09:24] Diego` | 2 |
| `[09:36] Sofia` | 1 |
| `[09:38] Diego` | 1 |
| `[09:42] Diego` | 1 |
| `[09:47] Larissa` | 1 |
| `[09:46] Sofia` | 1 |
| `[09:06] Diego` | 2 |
| `[09:07] Diego` | 1 |
| `[09:15] Diego` | 2 |
| `[09:16] Diego` | 1 |
| `[09:25] Diego` | 2 |
| `[09:32] Larissa` | 1 |
| `[09:28] Bruno` | 2 |
| `[09:30] Larissa` | 1 |
| `[09:41] Diego` | 2 |
| `[09:39] Diego` | 1 |
| `[09:12] Diego` | 1 |
| `[09:36] Larissa` | 1 |
| `[09:22] Sofia` | 1 |
| `[09:26] Larissa` | 1 |

Nenhuma ocorrência zero. Todo caminho `Fonte = CODIGO` (`prisma/schema.prisma`,
`src/modules/customers/customer.service.ts`, `src/routes/index.ts`,
`src/modules/customers/customer.routes.ts`, `src/modules/orders/order.routes.ts`,
`src/shared/logger/index.ts`) foi conferido em `git ls-files` antes de entrar na
tabela.

## Critério de classificação de `Fonte = CODIGO`

Uma linha só recebe `Fonte = CODIGO` quando a Localização é o artefato
**específico** que origina o item — não a hierarquia genérica de classes de erro
nem um arquivo que apenas contém o item. É a mesma régua que a
[§Itens sem origem identificável](#itens-sem-origem-identificável) aplica, agora
aplicada também à tabela principal:

- **Sai de CODIGO por origem genérica.** `FDD-ERR-04`, `FDD-ERR-05` e
  `FDD-ERR-08` apontavam todas para `src/shared/errors/http-errors.ts:27`
  (`NotFoundError`), que serve a qualquer 404 do projeto e não distingue um item
  do outro. `FDD-ERR-04` tem origem melhor na transcrição — `[09:28] Bruno`
  nomeia `WEBHOOK_NOT_FOUND` literalmente; `FDD-ERR-05` tem origem específica em
  `src/modules/customers/customer.service.ts:25`, o único ponto do código que
  levanta "Customer not found"; `FDD-ERR-08` não tem nenhuma das duas e foi para
  a seção de itens sem origem.
- **Sai de CODIGO por origem transcrita.** `ADR-006` e `ADR-007` são decisões
  fechadas em reunião (`[09:30] Larissa` e `[09:41] Diego`, como
  `docs/adrs/README.md` já registrava). O código é onde a decisão cai, não de
  onde ela vem.
- **Entra em CODIGO.** `FDD-CONTRATO-01` a `-05`: a reunião deu o verbo e os
  campos, nunca a forma do path; a forma vem do padrão de roteamento do projeto,
  e cada linha aponta a rota existente que a origina. `PRD-RNF-20`: a lista de
  redação nasce da leitura de `src/shared/logger/index.ts:4`, que prova a
  ausência da secret entre os campos redigidos — nenhuma fala menciona
  `redactPaths`.
