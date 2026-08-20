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

Este documento acumula **duas funções**: é a referência cruzada descrita acima
e é o **glossário dos identificadores usados no pacote**. Qualquer `DEC-NN`,
`RF-NN`, `RNF-NN`, `REC-NN`, `DIV-NN`, `COD-NN` ou `GAN-NN` que o leitor
encontre em `docs/PRD.md`, `docs/RFC.md`, `docs/FDD.md`, `docs/adrs/` ou
`README.md` tem aqui uma linha própria, com o que o identificador significa e
de onde ele veio — sem depender dos artefatos de processo em `.planning/`, que
não fazem parte da entrega. Identificador citado nos documentos e ausente
daqui é falha do tracker, não licença para o leitor adivinhar — e essa cobertura
foi medida por um check dedicado do verificador executável, sobre o mesmo
universo amplo que um leitor externo enxerga. O verificador também não faz parte
da árvore entregue — é ferramenta de processo, não documento —, mas está
preservado no histórico e é reproduzível a partir do commit `07f8496`, como o
`README.md` §Como navegar a entrega descreve.

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
| PRD-RNF-03 | docs/PRD.md | Requisito Não Funcional | O polling acrescenta até 2s de espera de agendamento antes da primeira tentativa — 2s é o teto desse componente, não um piso da entrega (leitura adotada; a ata é ambígua, ver RNF-03) | TRANSCRICAO | `[09:10] Larissa` |
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
| DEC-01 | docs/adrs/ADR-001-outbox-no-mysql.md | Decisão | Eventos vão para uma tabela outbox no MySQL já existente, não para infra nova — decisão que origina ADR-001; citada também em `docs/adrs/README.md` | TRANSCRICAO | `[09:08] Larissa` |
| DEC-02 | docs/adrs/ADR-002-worker-processo-separado-polling.md | Decisão | Worker consome a outbox por polling em loop, a cada 2 segundos; citada também em `docs/FDD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:10] Larissa` |
| DEC-03 | docs/adrs/ADR-002-worker-processo-separado-polling.md | Decisão | Worker roda como processo separado da API, no mesmo banco e mesma stack; citada também em `docs/FDD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:11] Diego` |
| DEC-04 | docs/adrs/ADR-002-worker-processo-separado-polling.md | Decisão | Single-worker: sem garantia de ordering global, só por order_id, e a limitação é documentada; citada também em `docs/RFC.md`, `docs/FDD.md`, ADR-003, ADR-005 e `docs/adrs/README.md` | TRANSCRICAO | `[09:13] Larissa` |
| DEC-05 | docs/adrs/ADR-003-retry-backoff-e-dlq-em-tabela-separada.md | Decisão | Retry com backoff exponencial: 5 tentativas, progressão 1m/5m/30m/2h/12h, depois DLQ — a leitura adotada no pacote diverge da progressão dita na fala e está registrada em RFC-QA-05; citada também em `docs/PRD.md`, `docs/FDD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:17] Larissa` |
| DEC-06 | docs/adrs/ADR-003-retry-backoff-e-dlq-em-tabela-separada.md | Decisão | DLQ em tabela separada `webhook_dead_letter`, com payload, motivo da falha e timestamp; citada também em `docs/FDD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:18] Bruno` |
| DEC-07 | docs/adrs/ADR-004-hmac-sha256-secret-por-endpoint.md | Decisão | Assinatura HMAC-SHA256 calculada sobre o corpo do request; citada também em `docs/FDD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:22] Sofia` |
| DEC-08 | docs/adrs/ADR-004-hmac-sha256-secret-por-endpoint.md | Decisão | Secret única por endpoint de webhook, não global da plataforma; citada também em `docs/FDD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:22] Sofia` |
| DEC-09 | docs/adrs/ADR-004-hmac-sha256-secret-por-endpoint.md | Decisão | Secret rotacionável, com a antiga válida em paralelo por 24h; citada também em `docs/FDD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:22] Sofia` |
| DEC-10 | docs/adrs/ADR-005-entrega-at-least-once-com-x-event-id.md | Decisão | Entrega at-least-once, com dedup pelo cliente via header X-Event-Id; citada também em `docs/RFC.md`, `docs/FDD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:26] Larissa` |
| DEC-11 | docs/adrs/ADR-006-reuso-dos-padroes-existentes.md | Decisão | Webhooks viram um módulo `src/modules/webhooks` no mesmo padrão dos demais domínios; citada também em `docs/FDD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:28] Diego` |
| DEC-12 | docs/adrs/ADR-002-worker-processo-separado-polling.md | Decisão | `src/worker.ts` (novo) como entry-point separada; lógica de processamento em arquivo dentro do módulo — o nome do arquivo ficou em aberto em RFC-QA-02; citada também em `docs/FDD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:28] Diego` |
| DEC-13 | docs/adrs/ADR-006-reuso-dos-padroes-existentes.md | Decisão | Todos os códigos de erro do módulo levam prefixo `WEBHOOK_`; citada também em `docs/FDD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:29] Larissa` |
| DEC-14 | docs/adrs/ADR-002-worker-processo-separado-polling.md | Decisão | Worker instancia PrismaClient próprio, mesma DATABASE_URL, por ser outro processo Node; citada também em `docs/FDD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:30] Bruno` |
| DEC-15 | docs/adrs/ADR-006-reuso-dos-padroes-existentes.md | Decisão | Reuso máximo do que já existe (1/2): AppError, Pino, error middleware, padrão de módulos; citada também em `docs/FDD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:30] Larissa` |
| DEC-16 | docs/adrs/ADR-006-reuso-dos-padroes-existentes.md | Decisão | Reuso máximo do que já existe (2/2): padrão de schemas Zod e de códigos de erro; citada também em `docs/FDD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:30] Larissa` |
| DEC-17 | docs/adrs/ADR-008-modelo-de-autorizacao-do-modulo.md | Decisão | Endpoint de cadastro é autenticado normal e o customer_id NÃO é derivado do JWT; citada também em `docs/PRD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:32] Larissa` |
| DEC-18 | docs/adrs/ADR-007-insercao-na-outbox-dentro-da-transacao.md | Decisão | O filtro de status é aplicado na inserção do outbox, não na hora do envio; citada também em `docs/FDD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:34] Diego` |
| DEC-19 | docs/adrs/ADR-008-modelo-de-autorizacao-do-modulo.md | Decisão | Replay de DLQ exige role ADMIN e reaproveita o `requireRole` existente; citada também em `docs/FDD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:36] Larissa` |
| DEC-20 | docs/adrs/ADR-008-modelo-de-autorizacao-do-modulo.md | Decisão | CRUD de configuração de webhook fica aberto a qualquer role autenticada por enquanto; citada também em `docs/adrs/README.md` | TRANSCRICAO | `[09:37] Sofia` |
| DEC-21 | docs/adrs/ADR-007-insercao-na-outbox-dentro-da-transacao.md | Decisão | Inserção na `webhook_outbox` acontece dentro da mesma transação do changeStatus, com rollback se falhar; citada também em `docs/FDD.md` e `docs/adrs/README.md` | TRANSCRICAO | `[09:41] Diego` |
| DEC-22 | docs/adrs/ADR-007-insercao-na-outbox-dentro-da-transacao.md | Decisão | Integração via função que recebe o tx da transação, sem injetar repository no OrderService; citada também em `docs/adrs/README.md` | TRANSCRICAO | `[09:41] Diego` |
| DEC-23 | docs/FDD.md | Decisão | Timeout de 10 segundos no HTTP call do worker; estouro vira falha e vai pra retry | TRANSCRICAO | `[09:42] Sofia` |
| DEC-24 | docs/FDD.md | Decisão | Payload enxuto: não carrega items; cliente busca detalhe depois no GET /orders/:id | TRANSCRICAO | `[09:44] Bruno` |
| DEC-25 | docs/PRD.md | Decisão | Prazo estimado de três sprints, já com a revisão de segurança da Sofia no fim; citada também em `docs/FDD.md` | TRANSCRICAO | `[09:47] Larissa` |
| DEC-26 | docs/FDD.md | Decisão | Id da outbox é UUID, seguindo o padrão do resto do projeto | TRANSCRICAO | `[09:51] Larissa` |
| DEC-27 | docs/FDD.md | Decisão | Outbox guarda o payload já renderizado (snapshot no momento da inserção) | TRANSCRICAO | `[09:52] Bruno` |
| RF-01 | docs/PRD.md | Requisito Funcional | Cliente cadastra webhook por endpoint POST, informando a url — requisito da ata que origina PRD-FR-01; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:31] Marcos` |
| RF-02 | docs/PRD.md | Requisito Funcional | A secret é gerada pela plataforma e devolvida na resposta da criação; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:31] Marcos` |
| RF-03 | docs/PRD.md | Requisito Funcional | Editar (PATCH), remover (DELETE) e listar por customer (GET) os webhooks; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:33] Bruno` |
| RF-04 | docs/PRD.md | Requisito Funcional | Cada endpoint define a lista de status que quer ouvir; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:33] Marcos` |
| RF-05 | docs/PRD.md | Requisito Funcional | Cliente pede nova secret pela API (rotação); citado também em `docs/FDD.md` | TRANSCRICAO | `[09:21] Sofia` |
| RF-06 | docs/PRD.md | Requisito Funcional | Consulta do histórico de entregas de um webhook; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:34] Marcos` |
| RF-07 | docs/PRD.md | Requisito Funcional | O histórico expõe os últimos 100 envios com sucesso/falha, payload, response e tempo de resposta; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:34] Marcos` |
| RF-08 | docs/PRD.md | Requisito Funcional | Replay manual de item da DLQ por endpoint admin, recolocando o evento na outbox como pendente; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:18] Diego` |
| RF-09 | docs/PRD.md | Requisito Funcional | Payload JSON do evento (1/2): identificação, tipo, timestamp e chaves do pedido; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:43] Diego` |
| RF-10 | docs/PRD.md | Requisito Funcional | Payload JSON do evento (2/2): campos básicos da order, sem items; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:43] Diego` |
| RF-11 | docs/PRD.md | Requisito Funcional | Headers do request de entrega (1/2): identificação, assinatura e timestamp de envio; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:44] Diego` |
| RF-12 | docs/PRD.md | Requisito Funcional | Headers do request de entrega (2/2): content type; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:44] Diego` |
| RF-13 | docs/PRD.md | Requisito Funcional | Header X-Webhook-Id com o id do endpoint cadastrado, para cliente com vários webhooks; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:44] Sofia` |
| RNF-01 | docs/PRD.md | Requisito Não Funcional | Definição de "tempo real" pelos clientes: abaixo de 10 segundos — origem de PRD-RNF-01; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:02] Marcos` |
| RNF-02 | docs/PRD.md | Requisito Não Funcional | Intervalo de polling do worker: 2 segundos; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:09] Diego` |
| RNF-03 | docs/PRD.md | Requisito Não Funcional | Fala literal da ata: "A latência mínima vai ser 2 segundos no pior caso. Aceitamos." — formulação ambígua ("mínima" e "pior caso" não são o mesmo número); a leitura vigente do pacote é a de teto, em PRD-RNF-03; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:10] Larissa` |
| RNF-04 | docs/PRD.md | Requisito Não Funcional | Índices exigidos na outbox: campo de status e created_at; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:08] Diego` |
| RNF-05 | docs/PRD.md | Requisito Não Funcional | Worker lê apenas pendentes, em batch pequeno; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:08] Diego` |
| RNF-06 | docs/PRD.md | Requisito Não Funcional | Arquivamento de linhas entregues após ~30 dias — declarado fora do escopo desta feature, ver REC-11 | TRANSCRICAO | `[09:08] Diego` |
| RNF-07 | docs/PRD.md | Requisito Não Funcional | Número de tentativas antes da DLQ: 5 | TRANSCRICAO | `[09:17] Larissa` |
| RNF-11 | docs/PRD.md | Requisito Não Funcional | Premissa histórica: cliente já teve indisponibilidade de duas horas em manutenção planejada; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:16] Diego` |
| RNF-12 | docs/PRD.md | Requisito Não Funcional | Cenário citado ao rejeitar 3 tentativas: três retries em 30 minutos, ver REC-05 | TRANSCRICAO | `[09:16] Diego` |
| RNF-13 | docs/PRD.md | Requisito Não Funcional | Grace period da secret antiga após rotação: 24 horas; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:21] Sofia` |
| RNF-14 | docs/PRD.md | Requisito Não Funcional | TLS obrigatório: url do webhook precisa ser https; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:23] Sofia` |
| RNF-15 | docs/PRD.md | Requisito Não Funcional | Cadastro com http é recusado com erro de validação, no schema Zod; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:23] Sofia` |
| RNF-16 | docs/PRD.md | Requisito Não Funcional | Tamanho anômalo citado como motivação do limite: 500KB | TRANSCRICAO | `[09:23] Sofia` |
| RNF-17 | docs/PRD.md | Requisito Não Funcional | Limite de tamanho de payload: 64KB, com erro caso ultrapasse; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:24] Larissa` |
| RNF-18 | docs/PRD.md | Requisito Não Funcional | Contrato at-least-once: o cliente tem que suportar receber o mesmo evento duas vezes; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:24] Diego` |
| RNF-19 | docs/PRD.md | Requisito Não Funcional | Histórico de entregas exposto: últimos 100 envios; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:34] Marcos` |
| RNF-20 | docs/PRD.md | Requisito Não Funcional | Auditoria: o endpoint admin registra quem executou o replay; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:36] Sofia` |
| RNF-21 | docs/PRD.md | Requisito Não Funcional | Cenário de carga citado: 50 pedidos mudando de status em um minuto para um cliente; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:38] Diego` |
| RNF-22 | docs/PRD.md | Requisito Não Funcional | Timeout do HTTP call do worker: 10 segundos; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:42] Diego` |
| RNF-23 | docs/PRD.md | Requisito Não Funcional | Prazo comercial: entrega para fim de novembro | TRANSCRICAO | `[09:45] Marcos` |
| RNF-24 | docs/PRD.md | Requisito Não Funcional | Pressão de negócio: risco de migração para o concorrente se não entregar até fim do trimestre; citado também em `docs/RFC.md` | TRANSCRICAO | `[09:00] Marcos` |
| RNF-25 | docs/PRD.md | Requisito Não Funcional | Demanda originada de três clientes B2B nomeados: Atlas Comercial, MaxDistribuição e Nova Cargo; citado também em `docs/RFC.md` | TRANSCRICAO | `[09:00] Marcos` |
| RNF-26 | docs/PRD.md | Requisito Não Funcional | Estimativa de esforço: três sprints, revisão de segurança incluída; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:47] Larissa` |
| RNF-27 | docs/PRD.md | Requisito Não Funcional | Reserva de pelo menos dois dias úteis para revisão de segurança antes do deploy; citado também em `docs/FDD.md` | TRANSCRICAO | `[09:46] Sofia` |
| REC-01 | docs/adrs/ADR-001-outbox-no-mysql.md | Descartado | Disparo síncrono do webhook dentro do service de orders — transação já pesada e cliente lento travaria os outros pedidos; citado também em ADR-007 | TRANSCRICAO | `[09:06] Diego` |
| REC-02 | docs/adrs/ADR-001-outbox-no-mysql.md | Descartado | Redis Streams / Redis Cluster como transporte dos eventos — exigiria subir mais infra e é overengineering para um time pequeno | TRANSCRICAO | `[09:07] Diego` |
| REC-03 | docs/adrs/ADR-001-outbox-no-mysql.md | Descartado | Trigger de banco para notificar o worker de forma reativa — MySQL não tem listener nativo; citado também em ADR-002 | TRANSCRICAO | `[09:09] Diego` |
| REC-04 | docs/adrs/ADR-003-retry-backoff-e-dlq-em-tabela-separada.md | Descartado | Retry indefinido com backoff — evento ficaria pendurado para sempre se o cliente sumisse | TRANSCRICAO | `[09:15] Diego` |
| REC-05 | docs/adrs/ADR-003-retry-backoff-e-dlq-em-tabela-separada.md | Descartado | Limite de 3 tentativas de entrega — cobriria só 30 minutos e mataria o evento antes de indisponibilidades reais | TRANSCRICAO | `[09:16] Diego` |
| REC-06 | docs/adrs/ADR-003-retry-backoff-e-dlq-em-tabela-separada.md | Descartado | Marcar falha permanente na própria outbox, sem tabela de DLQ — tabela separada mantém a leitura da outbox principal mais limpa | TRANSCRICAO | `[09:18] Diego` |
| REC-08 | docs/adrs/ADR-005-entrega-at-least-once-com-x-event-id.md | Descartado | Garantia de entrega exactly-once — exigiria coordenação dos dois lados e ficaria muito mais complexo | TRANSCRICAO | `[09:25] Diego` |
| REC-09 | docs/adrs/ADR-008-modelo-de-autorizacao-do-modulo.md | Descartado | customer_id derivado implicitamente do JWT — o JWT atual é do usuário operador, não do cliente | TRANSCRICAO | `[09:32] Larissa` |
| REC-11 | docs/adrs/ADR-001-outbox-no-mysql.md | Adiado | Arquivamento das linhas já entregues da outbox — declarado fora do escopo desta feature; citado também em ADR-003 | TRANSCRICAO | `[09:08] Diego` |
| REC-13 | docs/adrs/ADR-003-retry-backoff-e-dlq-em-tabela-separada.md | Adiado | Aviso por email ao cliente quando o webhook dele falha — fora de escopo desta fase, talvez na próxima | TRANSCRICAO | `[09:37] Larissa` |
| REC-14 | docs/adrs/ADR-008-modelo-de-autorizacao-do-modulo.md | Adiado | Endurecimento do controle de acesso do CRUD de configuração — por enquanto qualquer role autenticada serve | TRANSCRICAO | `[09:37] Sofia` |
| GAN-11 | docs/adrs/ADR-001-outbox-no-mysql.md | Gancho declarado | "Suporte a trigger no banco já existe hoje" — gancho AUSENTE no código na verificação de `.planning/02-ganchos-verificados.md`; a refutação está registrada em DIV-05 | TRANSCRICAO | `[09:09] Diego` |
| GAN-22 | docs/adrs/ADR-004-hmac-sha256-secret-por-endpoint.md | Gancho declarado | "Validação por schema Zod já é o padrão do projeto" — gancho CONFIRMADO em `src/middlewares/validate.middleware.ts` e nas rotas de orders | TRANSCRICAO | `[09:23] Sofia` |
| COD-01 | docs/FDD.md | Ponto de acoplamento | Mudança de status do pedido e ciclo de vida: `OrderService.changeStatus`, mais `canTransition` e `shouldDebitStock` em `src/modules/orders/order.status.ts` — é onde o gancho de emissão de evento entra | CODIGO | `src/modules/orders/order.service.ts:126` |
| COD-10 | docs/FDD.md | Ponto de acoplamento | Configuração de ambiente: toda variável nova do módulo entra no `envSchema` de `src/config/env.ts` e no `.env.example`; um segundo processo Node reaproveita `env` e chama `createPrismaClient()` de `src/config/database.ts` | CODIGO | `src/config/env.ts:27` |
| DIV-01 | docs/RFC.md | Divergência | A fala diz "decrementa stock_quantity dos produtos do pedido"; o campo se chama `stockQuantity` e é também o nome literal da coluna no MySQL — `stock_quantity` não existe; citada também em `docs/FDD.md` | CODIGO | `prisma/schema.prisma:62` |
| DIV-02 | docs/RFC.md | Divergência | A fala nomeia `order_id`, `order_number`, `from_status`, `to_status`, `customer_id` como campos do payload; as colunas são `id`, `orderNumber`, `customerId`, `fromStatus`, `toStatus` — nenhuma das cinco grafias snake_case existe no banco; citada também em `docs/FDD.md` | CODIGO | `prisma/schema.prisma:75` |
| DIV-03 | docs/RFC.md | Divergência | A fala cita "os campos básicos da order tipo total_cents"; o campo é `totalCents`, `Int`, e existem ainda `subtotalCents` e `discountCents`, não citados; citada também em `docs/FDD.md` | CODIGO | `prisma/schema.prisma:79` |
| DIV-04 | docs/adrs/ADR-007-insercao-na-outbox-dentro-da-transacao.md | Divergência | A fala diz que a transação "faz update na order, insere no history e atualiza estoque"; a atualização de estoque é condicional à transição — em 4 das 7 transições nenhum produto é tocado | CODIGO | `src/modules/orders/order.service.ts:151` |
| DIV-05 | docs/RFC.md | Divergência | A fala diz "trigger no banco a gente até tem"; não há trigger algum no repositório — a migration tem só `CREATE TABLE`, `CREATE INDEX` e `ADD FOREIGN KEY`; citada também em ADR-001 e ADR-002 | CODIGO | `prisma/migrations/20260519182739_init/migration.sql` |
| DIV-06 | docs/adrs/ADR-002-worker-processo-separado-polling.md | Divergência | A fala diz "o pool de conexão do Prisma já tá lá"; não há configuração de pool em lugar nenhum — o pool existe por default do Prisma, não por configuração do projeto; citada também em `docs/FDD.md` | CODIGO | `src/config/database.ts:4` |
| DIV-07 | docs/RFC.md | Divergência | A fala supõe "usuários que representam o cliente"; `UserRole` tem só `ADMIN` e `OPERATOR`, e `Customer` é model sem senha, sem papel e sem relação com `User`; citada também em `docs/PRD.md`, `docs/FDD.md` e ADR-008 | CODIGO | `prisma/schema.prisma:11` |
| DIV-08 | docs/RFC.md | Divergência | A fala diz que os clientes "ficam batendo no GET /orders"; o router de orders é precedido por `router.use(authenticate)`, que só aceita JWT de usuário interno — cliente externo não tem credencial hoje; citada também em `docs/PRD.md`, `docs/FDD.md` e ADR-001 | CODIGO | `src/modules/orders/order.routes.ts:14` |
| DIV-09 | docs/adrs/ADR-006-reuso-dos-padroes-existentes.md | Divergência | A fala diz que todo módulo tem controller, service, repository, routes e schemas; o módulo `auth` não tem repository e `orders` tem um sexto arquivo, `src/modules/orders/order.status.ts`; citada também em `docs/FDD.md` | CODIGO | `src/modules/auth/auth.service.ts:6` |
| DIV-10 | docs/RFC.md | Divergência | A fala diz "tudo é uuid"; vale para 6 dos 7 models — `OrderNumberSequence.id` é `Int @id @default(1)`; citada também em `docs/FDD.md` | CODIGO | `prisma/schema.prisma:133` |
| DIV-11 | docs/RFC.md | Divergência | A fala trata `changeStatus` como ponto único de mudança de status; `create` também grava a transição inicial num caminho separado, e um gancho só em `changeStatus` não vê a criação do pedido; citada também em `docs/FDD.md` e ADR-007 | CODIGO | `src/modules/orders/order.service.ts:106` |
| DIV-12 | docs/RFC.md | Divergência | A reunião cita só `PAID`, `PROCESSING`, `SHIPPED` e `DELIVERED`; o enum tem seis valores — `PENDING` e `CANCELLED` participam de 4 das 7 transições e não foram citados; citada também em `docs/FDD.md` e ADR-007 | CODIGO | `prisma/schema.prisma:16` |
| DIV-13 | docs/adrs/ADR-006-reuso-dos-padroes-existentes.md | Divergência | A fala diz que o logger Pino "já tá no projeto inteiro"; o singleton é importado em exatamente 3 arquivos — `src/server.ts`, `src/middlewares/error.middleware.ts` e `src/middlewares/request-logger.middleware.ts` — e nenhum service, controller ou repository loga; citada também em ADR-008 | CODIGO | `src/shared/logger/index.ts:32` |
| DIV-14 | docs/adrs/ADR-001-outbox-no-mysql.md | Divergência | A fala diz "outbox no MySQL existente resolve"; o MySQL existe, mas não há precedente de transacionalidade de outbox — nenhum repository aceita `tx` e a única escrita transacional multi-tabela vive dentro do `OrderService` | CODIGO | `prisma/schema.prisma:6` |

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
| PRD-RNF-22 | docs/PRD.md | A proibição de devolver a secret fora da criação e da rotação não tem fala nem código. `[09:31] Marcos` diz que a secret "é gerada pela gente e devolvida na criação" — cobre a devolução, não a proibição nas demais consultas. Não há precedente no código: a busca por `hmac\|crypto\|createHmac\|signature` em `src/ prisma/ tests/ package.json` é vazia. O item existia no PRD como critério de aceite sem ID; ganhou ID aqui para ficar visível, não para ganhar origem | Registrar como decisão nova do PRD/FDD, com dono e data. A regra em si é sensata e não deve ser removida por falta de fala — o que falta é o dono |
| FDD-ERR-08 | docs/FDD.md | `WEBHOOK_DEAD_LETTER_NOT_FOUND` (id de item de dead-letter inexistente) estava na tabela principal apontando para `src/shared/errors/http-errors.ts:27`, que é a classe genérica `NotFoundError` — a mesma origem genérica que esta seção declara insuficiente. A dead-letter queue é estrutura nova, sem precedente de código próprio, e nenhuma fala trata do id inexistente: `[09:18] Diego` cria o endpoint de replay, não o erro. `[09:28] Bruno` nomeia `WEBHOOK_NOT_FOUND`, não este | Registrar como decisão nova do FDD, com dono e data, ou derivá-la explicitamente do padrão de 404 do projeto em um DEC próprio |
| FDD-ERR-12 | docs/FDD.md | `WEBHOOK_DELIVERY_FAILED` (resposta fora da faixa 2xx) não é citado explicitamente; DEC-05/RNF-07 cobrem o número de tentativas e o backoff, não o critério que classifica uma resposta HTTP como falha | Se o critério "fora de 2xx" foi decisão implícita, torná-la explícita em um DEC ou registrar como decisão nova do FDD |
| RFC-QA-06 | docs/RFC.md | Ausência de decisão na reunião; registrada como questão em aberto. Recuperação de linha em `PROCESSING` após queda do worker: `grep -inE 'lease\|reinici\|retoma\|em processamento\|timeout de processamento'` em `TRANSCRICAO.md` devolve só `[09:11] Diego` ("se a API reinicia, perde o worker"), que motiva separar o processo e não trata da linha em voo | Decidir lease, timeout de processamento ou reset no startup antes de implementar — a garantia at-least-once de DEC-10 depende disso |
| RFC-QA-07 | docs/RFC.md | Ausência de decisão na reunião; registrada como questão em aberto. O alcance real da perda de ordenação foi descoberto na análise do algoritmo, não dito por ninguém: `grep -inE 'backoff.{0,40}ordem\|ordem.{0,40}backoff\|ordem.{0,30}retentativa'` é vazio. DEC-04 (`[09:13] Larissa`) existe, mas declara alcance menor | Decidir se a ordem por `order_id` é contrato ou best-effort; ampliação do alcance já declarada em ADR-002 |
| RFC-QA-08 | docs/RFC.md | Ausência de decisão na reunião; registrada como questão em aberto. Armazenamento da secret em repouso e key management: `grep -inE 'secret.{0,30}(cifrad\|criptograf\|hash\|plain\|texto claro\|em claro)\|proteg.{0,20}secret'` é vazio. `[09:21] Bruno` põe a secret na tabela e não trata de protegê-la | Decisão de segurança, com dono e data, antes da migration que cria a coluna |
| RFC-QA-09 | docs/RFC.md | Ausência de decisão na reunião; registrada como questão em aberto. Política anti-SSRF: `grep -inE 'ssrf\|rebind\|loopback\|127\.0\|localhost\|ip privado\|rede interna\|redirect'` é vazio. `[09:23] Sofia` exige `https` e nada além | Decisão de segurança sobre faixa de IP, resolução de DNS e redirects antes de o worker fazer a primeira chamada |
| RFC-QA-10 | docs/RFC.md | Ausência de decisão na reunião; registrada como questão em aberto. Schema dos três models além da outbox: `grep -inE 'nullable\|not null\|unique\|varchar\|foreign key'` é vazio. A reunião nomeia as tabelas, nunca o formato delas | Fechar colunas, nulabilidade, uniques e FKs antes de escrever a migration |
| RFC-QA-11 | docs/RFC.md | Ausência de decisão na reunião; registrada como questão em aberto. Atomicidade e concorrência da DLQ: `grep -inE '(dlq\|dead.?letter).{0,40}(transaç\|atomic\|lock)\|replay.{0,40}(simultân\|concorr)'` é vazio. `[09:40] Bruno` fecha a atomicidade de outra escrita, a da outbox dentro de `changeStatus` | Definir a transação de `outbox → DLQ` e o controle de replay concorrente antes de expor o endpoint de replay |
| RFC-QA-12 | docs/RFC.md | Ausência de decisão na reunião; registrada como questão em aberto. Que resposta do cliente é falha retentável e qual é terminal: a própria linha do RFC declara "ninguém na reunião" como origem, e a ata fecha só o timeout (`[09:42] Diego`) — 4xx e 5xx nunca foram separados. Citada também em `docs/FDD.md`, onde FDD-ERR-12 pede a mesma ratificação | Decidir a faixa de status HTTP que é retentável antes de o worker fazer a primeira chamada — hoje o desenho retenta por 2h36 um 4xx que não se recupera |
| RFC-QA-13 | docs/RFC.md | Ausência de decisão na reunião; registrada como questão em aberto. Se a secret pode ser lida fora da criação e da rotação: a linha do RFC declara "ninguém na reunião" como origem — a ata manda devolvê-la nas duas (`[09:31] Marcos`, `[09:21] Sofia`) e cala sobre o resto. É a mesma lacuna que PRD-RNF-22 registra do lado do PRD | Decidir com dono e data se a secret é legível em consulta; secret legível anula a secret por endpoint de DEC-08 |

## Códigos retirados

Itens que existiram no pacote e foram **removidos**, com o motivo de cada um. A
seção existe para que o leitor que encontre um salto na numeração saiba que ele
é intencional. Nenhum ID foi renumerado depois da retirada: renumerar quebraria
as referências cruzadas dos quatro documentos por uma questão cosmética, e o
salto na sequência é o preço aceito. Os quatro saíram na mesma passagem, e por
um mesmo critério — a regra que cada um codificava não tem fala na reunião nem
precedente no código, e uma regra inventada é pior do que uma lacuna declarada.
O salto correspondente está anunciado em `docs/FDD.md` §Matriz de erros.

| ID retirado | Documento | Código | Por que saiu |
|---|---|---|---|
| FDD-ERR-03 | docs/FDD.md | `WEBHOOK_DUPLICATE_URL` | **Regra sem origem.** Recusava com 409 o cadastro de uma url já ativa para o mesmo cliente. Nenhuma fala da reunião trata de unicidade de url, e o código não tem precedente de constraint que a sustente: só a classe genérica `ConflictError` se aplicaria, e ela não distingue esta regra de nenhuma outra. Retiradas a linha da matriz e os dois ramos `409` dos contratos de `POST /customers/:customerId/webhooks` e `PATCH /webhooks/:id` |
| FDD-ERR-06 | docs/FDD.md | `WEBHOOK_ROTATION_IN_GRACE_PERIOD` | **Origem falsa e efeito adverso.** A linha declarava `[09:21] Sofia` como origem, mas a fala institui o grace period — "Quando ele rotaciona, a antiga fica válida por 24 horas em paralelo" — e **não** diz nem sugere que uma nova rotação seja recusada enquanto a janela está aberta. Também não há lastro em código: `grep -rniE 'hmac\|crypto\|createHmac\|signature'` em `src/ prisma/ tests/ package.json` é vazio. Pior que a origem: a regra contradizia o propósito da decisão que dizia implementar — bloquear a re-rotação impede revogar uma secret comprometida durante as 24 horas em que ela ainda assina. Retiradas a linha da matriz e o ramo de erro do contrato de `POST /webhooks/:id/secret/rotate`; o comportamento vigente está declarado no próprio contrato, em `docs/FDD.md` §Contratos públicos |
| FDD-ERR-09 | docs/FDD.md | `WEBHOOK_DEAD_LETTER_ALREADY_REPLAYED` | **Regra sem origem.** Recusava com 409 um segundo replay do mesmo item da dead-letter queue. A reunião não discutiu idempotência do endpoint de replay — RNF-18 trata de deduplicação do lado do cliente, que é outra coisa — e a DLQ é estrutura nova, sem precedente de código. Escolher entre recusar, duplicar ou ser idempotente é decisão pendente, e está declarada como tal em `docs/FDD.md` §Não decidido na reunião e em RFC-QA-11. Retiradas a linha da matriz e o ramo `409` do contrato de replay |
| FDD-ERR-13 | docs/FDD.md | `WEBHOOK_SIGNATURE_UNAVAILABLE` | **Regra sem origem.** Previa o envio a um endpoint sem secret utilizável no momento da entrega. Nenhuma fala sobre secret ou rotação (DEC-07, DEC-08, DEC-09, RNF-13) cobre esse cenário de borda, e não há código: HMAC e secret são funcionalidade nova — `grep -rniE 'hmac\|crypto\|createHmac\|signature'` em `src/ prisma/ tests/ package.json` retorna vazio. Retirada a linha da matriz; nenhum contrato a expunha |

## Validação de Localização (TRANSCRICAO)

Cada `[hh:mm] Nome` usado na tabela principal, conferido por `grep -cF` em
`TRANSCRICAO.md`. São 134 linhas com `Fonte = TRANSCRICAO`, que usam 53
Localizações distintas:

| Localização | ocorrências |
|---|---|
| `[09:00] Marcos` | 1 |
| `[09:02] Marcos` | 2 |
| `[09:06] Diego` | 2 |
| `[09:07] Diego` | 1 |
| `[09:08] Diego` | 1 |
| `[09:08] Larissa` | 1 |
| `[09:09] Diego` | 2 |
| `[09:10] Larissa` | 1 |
| `[09:11] Diego` | 2 |
| `[09:12] Diego` | 1 |
| `[09:13] Larissa` | 1 |
| `[09:15] Diego` | 2 |
| `[09:16] Diego` | 1 |
| `[09:17] Diego` | 1 |
| `[09:17] Larissa` | 1 |
| `[09:18] Bruno` | 1 |
| `[09:18] Diego` | 2 |
| `[09:21] Sofia` | 2 |
| `[09:22] Sofia` | 1 |
| `[09:23] Sofia` | 2 |
| `[09:24] Diego` | 2 |
| `[09:24] Larissa` | 1 |
| `[09:25] Diego` | 2 |
| `[09:26] Larissa` | 1 |
| `[09:28] Bruno` | 2 |
| `[09:28] Diego` | 2 |
| `[09:29] Larissa` | 1 |
| `[09:30] Bruno` | 1 |
| `[09:30] Larissa` | 1 |
| `[09:31] Marcos` | 1 |
| `[09:32] Larissa` | 1 |
| `[09:33] Bruno` | 1 |
| `[09:33] Marcos` | 1 |
| `[09:34] Diego` | 2 |
| `[09:34] Marcos` | 1 |
| `[09:36] Larissa` | 1 |
| `[09:36] Sofia` | 1 |
| `[09:37] Larissa` | 1 |
| `[09:37] Sofia` | 1 |
| `[09:38] Diego` | 1 |
| `[09:39] Diego` | 1 |
| `[09:41] Diego` | 2 |
| `[09:42] Diego` | 1 |
| `[09:42] Sofia` | 2 |
| `[09:43] Diego` | 1 |
| `[09:44] Bruno` | 1 |
| `[09:44] Diego` | 1 |
| `[09:44] Sofia` | 1 |
| `[09:45] Marcos` | 1 |
| `[09:46] Sofia` | 1 |
| `[09:47] Larissa` | 2 |
| `[09:51] Larissa` | 1 |
| `[09:52] Bruno` | 1 |

**Menor valor da coluna: 1.** Nenhuma ocorrência zero — toda Localização de
`Fonte = TRANSCRICAO` existe literalmente em `TRANSCRICAO.md`. Os 11 caminhos
distintos de `Fonte = CODIGO` foram conferidos em `git ls-files` antes de
entrar na tabela:

- `prisma/migrations/20260519182739_init/migration.sql`
- `prisma/schema.prisma`
- `src/config/database.ts`
- `src/config/env.ts`
- `src/modules/auth/auth.service.ts`
- `src/modules/customers/customer.routes.ts`
- `src/modules/customers/customer.service.ts`
- `src/modules/orders/order.routes.ts`
- `src/modules/orders/order.service.ts`
- `src/routes/index.ts`
- `src/shared/logger/index.ts`

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
