# FDD — Sistema de webhooks para eventos de mudança de status de pedido

## Contexto e motivação técnica

Este documento é o recorte de implementação do que o RFC propôs em nível de
arquitetura. Ele existe porque a feature inteira é estrutura nova: a varredura do
repositório em `.planning/02-codigo.md` §4 procurou `outbox`, `worker`, `webhook`,
`hmac`, `retry`, `dead-letter`, `event`, `idempot`, `cron` e `trigger` em `src/`,
`prisma/`, `tests/` e `package.json` e devolveu saída vazia em todos os doze
padrões. Não há símbolo, arquivo ou tabela existente que sirva de ponto de partida
parcial — só padrões a seguir.

O recorte técnico, então, é este: existe exatamente **um** ponto de acoplamento
com código que já roda em produção, o método `OrderService.changeStatus`
(`src/modules/orders/order.service.ts`:126), e ele é o método mais denso do
projeto. Tudo o mais é código novo dentro de convenções velhas. As convenções
estão levantadas símbolo a símbolo em `.planning/02-codigo.md` (COD-01 a COD-10) e
são o insumo de §Integração com o sistema existente.

O que este documento fecha, e o RFC deliberadamente não fechou: as colunas e os
índices das tabelas novas, os estados e transições da linha de outbox, o contrato
HTTP de cada endpoint com request, response e status code, a matriz de erros
completa, os números da política de resiliência e o que exatamente muda em cada
arquivo existente.

Duas questões que o RFC deixa abertas precisam de resposta para que o contrato
seja escrevível. Elas foram resolvidas **provisoriamente** aqui, e a decisão
continua aberta lá: o identificador do cliente vai no path
(`resolução provisória, ver RFC-QA-01`) e a lógica de processamento do worker mora
em `src/modules/webhooks/webhook.processor.ts` (novo)
(`resolução provisória, ver RFC-QA-02`).

## Objetivos técnicos

- Gravar uma linha de outbox dentro da mesma transação que muda o status do
  pedido, de modo que o rollback do status implique o rollback do evento.
- Aplicar o filtro de status **na inserção**, não no envio (DEC-18): só vira linha
  de outbox a transição que algum endpoint cadastrado declarou querer ouvir.
- Consumir a outbox por polling a cada 2 segundos, em processo separado da API,
  com cliente de banco próprio (DEC-02, DEC-03, DEC-14).
- Entregar cada evento por HTTP `POST` com corpo JSON assinado em HMAC-SHA256, com
  secret única por endpoint cadastrado (DEC-07, DEC-08).
- Aplicar timeout de 10 segundos por tentativa de entrega e tratar o estouro como
  falha (DEC-23).
- Retentar entrega falha 5 vezes, com a progressão 1m/5m/30m/2h/12h, e mover o
  evento para a dead-letter queue quando as tentativas se esgotarem (DEC-05,
  DEC-06).
- Recusar payload que ultrapasse 64KB, com erro (RNF-17).
- Expor os últimos 100 envios de cada endpoint, com sucesso/falha, payload,
  response e tempo de resposta (RF-07, RNF-19).
- Permitir replay manual de item da dead-letter queue por endpoint administrativo,
  recolocando o evento na outbox como pendente (RF-08), registrando quem executou
  (RNF-20).
- Prefixar com `WEBHOOK_` todos os códigos de erro do módulo (DEC-13).
- Não introduzir estrutura própria de erro, log, validação ou roteamento: reusar
  as do projeto (DEC-11, DEC-15, DEC-16).

## Escopo e exclusões

**Entra:** as quatro tabelas novas e sua migration; o módulo
`src/modules/webhooks/` (novo) no padrão dos demais domínios; a entry-point
`src/worker.ts` (novo); a função de publicação chamada de dentro da transação de
`changeStatus`; os sete endpoints de §Contratos públicos; a política de retry e a
dead-letter queue; a assinatura HMAC-SHA256 com rotação e grace period de 24
horas; o histórico de entregas; o replay administrativo.

**Não entra** — cada item abaixo foi recusado ou adiado na própria reunião e está
aqui como fronteira do escopo, sem ID de requisito:

- Disparo síncrono do webhook dentro do service de pedidos.
- Redis Streams ou qualquer broker externo como transporte dos eventos.
- Trigger de banco como gatilho reativo do worker.
- Retry indefinido, sem teto de tentativas.
- Marcar a falha permanente na própria tabela de outbox, dispensando a tabela de
  dead-letter.
- Truncar o payload que ultrapasse o limite de tamanho — o caso extremo citado na
  reunião foi um evento de 500KB, e a escolha foi recusar em vez de encurtar.
- Garantia de entrega exactly-once.
- Derivar o identificador do cliente do JWT.
- Painel ou dashboard visual para o cliente acompanhar as entregas.
- Arquivamento ou expurgo das linhas já entregues da outbox.
- Escala horizontal do worker, por particionamento ou por lock pessimista.
- Aviso por e-mail ao cliente quando a entrega dele falha.
- Endurecimento do controle de acesso do CRUD de configuração de endpoint.
- Limitação de taxa de envio por cliente.

## Fluxos detalhados

### Criação do evento na outbox

Ocorre dentro do callback de `$transaction` de `OrderService.changeStatus`. A
localização exata da chamada, o motivo de ela ser incondicional e a forma de
passagem do handle transacional estão em
[ADR-007](adrs/ADR-007-insercao-na-outbox-dentro-da-transacao.md) — este documento
não repete a colocação, descreve o comportamento.

```
PATCH /orders/:id/status
  └─ OrderService.changeStatus
       └─ $transaction(tx)
            ├─ valida transição (canTransition)
            ├─ efeitos de estoque, quando a transição os tem
            ├─ update na order
            ├─ insert em order_status_history
            └─ publishWebhookEvent(tx, { orderId, from, to, changedById })
                 ├─ 0 endpoint interessado  → 0 linha, retorna 0
                 └─ N endpoints interessados → N linhas em webhook_outbox
                                                (uma por endpoint), status PENDING
```

O filtro é aplicado aqui (DEC-18). "Interessado" significa: endpoint ativo, do
`customerId` da order, cujo array de status assinados contém o `to` da transição.
Como o filtro roda na inserção, o par (evento, endpoint) é resolvido antes de
qualquer entrega — daí **uma linha de outbox por endpoint destinatário**, e não uma
linha por transição. A alternativa (uma linha por transição, com fan-out no envio)
foi descartada em ADR-007.

O payload é renderizado e gravado no momento da inserção (DEC-27): a linha carrega
um snapshot, não uma referência. Uma mudança posterior no pedido não reescreve
evento já emitido.

**O conjunto filtrável é o enum real, e ele é maior do que a reunião supôs
(DIV-12).** `OrderStatus` tem seis valores — `PENDING`, `PAID`, `PROCESSING`,
`SHIPPED`, `DELIVERED`, `CANCELLED` (`prisma/schema.prisma`:16–23). A reunião
nomeou quatro (`PAID`, `PROCESSING`, `SHIPPED`, `DELIVERED`); `PENDING` e
`CANCELLED` existem, participam de 4 das 8 transições da tabela `transitions`
(`src/modules/orders/order.status.ts`:3–10) e carregam o efeito de reposição de
estoque, e ninguém os citou. A validação do filtro aceita o enum inteiro, via
`z.nativeEnum(OrderStatus)`, porque restringir a quatro seria inventar uma regra
que a reunião não tomou. **A lacuna fica declarada, não preenchida:** ninguém
decidiu se `PENDING` e `CANCELLED` devem ser assináveis, e o comportamento
implementado — aceitá-los — é a leitura literal de DEC-18, não uma decisão nova.
Some-se a isso que a entrada em `PENDING` acontece fora de `changeStatus` (DIV-11,
registrada em ADR-007), o que significa que assinar `PENDING` hoje não produziria
evento algum. Esse par precisa de decisão antes do código.

### Processamento pelo worker

`src/worker.ts` (novo) é a entry-point (DEC-12); a lógica mora em
`src/modules/webhooks/webhook.processor.ts` (novo). O processo é separado da API,
no mesmo banco e na mesma stack (DEC-03), e instancia `PrismaClient` próprio
(DEC-14).

```
loop a cada 2s
  ├─ SELECT das linhas PENDING com nextAttemptAt <= agora,
  │    ordenadas por createdAt, em batch pequeno
  ├─ para cada linha:
  │    ├─ marca PROCESSING
  │    ├─ serializa o payload; se > 64KB → falha terminal, vai direto para a DLQ
  │    ├─ assina: HMAC-SHA256 sobre o corpo do request
  │    ├─ POST na url do endpoint, timeout de 10s
  │    ├─ 2xx      → DELIVERED + linha em webhook_deliveries
  │    └─ não-2xx, erro de rede ou timeout → FAILED, agenda próxima tentativa
  └─ dorme 2s
```

A leitura é só de pendentes, em batch pequeno (RNF-05). O tamanho do batch **não
foi fixado na reunião**: entra como variável de ambiente, e o valor é decisão da
implementação — lacuna declarada, não número inventado aqui.

A latência mínima aceita é de 2 segundos no pior caso (RNF-03), consequência
direta do intervalo de polling, e cabe folgada na régua de "abaixo de 10 segundos"
que os clientes deram (RNF-01).

Worker único: não há garantia de ordenação global, apenas por `order_id` e
enquanto o processo for um só (DEC-04). Isso é limitação contratada, e está no
contrato porque escalar o worker é questão em aberto (RFC-QA-04).

### Retry

Toda falha de entrega — resposta não-2xx, erro de conexão ou estouro do timeout de
10 segundos — incrementa `attempts` e agenda `nextAttemptAt`. São 5 tentativas, na
progressão **1 minuto, 5 minutos, 30 minutos, 2 horas, 12 horas** (DEC-05,
RNF-07, RNF-08). O total entre a primeira falha e a última tentativa é de quase 15
horas (RNF-09), o que cobre a janela de 12 a 24 horas que a reunião mirou (RNF-10)
e a indisponibilidade de duas horas em manutenção planejada já observada em cliente
(RNF-11).

```
tentativa 1 falha → +1m  → tentativa 2 falha → +5m  → tentativa 3 falha
   → +30m → tentativa 4 falha → +2h → tentativa 5 falha → +12h → DLQ
```

A linha volta a `PENDING` com `nextAttemptAt` no futuro; o `SELECT` do worker
respeita `nextAttemptAt <= agora`, então o backoff é implementado pela query, não
por `sleep` no processo.

Payload acima de 64KB é falha **terminal**, não retentável: não adianta retentar o
que vai falhar de novo pelo mesmo motivo. Vai direto para a dead-letter queue com
o motivo registrado.

### DLQ e replay

Esgotadas as 5 tentativas, a linha é movida para `webhook_dead_letter` — tabela
separada, com payload, motivo da falha e timestamp (DEC-06) — e a linha de origem
na outbox é marcada como `FAILED`.

```
webhook_outbox (FAILED)
      │  move
      ▼
webhook_dead_letter ──POST /admin/webhooks/dead-letter/:id/replay (role ADMIN)──┐
      ▲                                                                          │
      └──────────────── nova linha PENDING em webhook_outbox ◄───────────────────┘
```

O replay é manual, por endpoint administrativo, e recoloca o evento na outbox como
pendente (RF-08). Ele **cria uma linha nova** em `webhook_outbox` a partir do
snapshot guardado, com `attempts` zerado, em vez de ressuscitar a linha antiga: a
linha antiga é o registro histórico da falha e não é reescrita. O item da DLQ é
marcado como já reprocessado, e uma segunda tentativa de replay sobre o mesmo item
é recusada.

Exige role `ADMIN`, reaproveitando `requireRole` (DEC-19), e registra quem
executou, para auditoria (RNF-20).

## Contratos públicos

Todos os paths abaixo são relativos ao prefixo `/api/v1`, montado em
`src/app.ts`:67. Todos exigem `Authorization: Bearer <jwt>`, pelo `authenticate`
de `src/middlewares/auth.middleware.ts`:27. O identificador do cliente vai no
**path** — `POST /customers/:customerId/webhooks` — por decisão provisória
(`resolução provisória, ver RFC-QA-01`); o formato do corpo mudaria se a revisão
preferisse a outra forma.

O envelope de erro é o do projeto, `{ error: { code, message, details? } }`,
produzido por `src/middlewares/error.middleware.ts`:14. Sucesso de recurso único
não é envelopado; listagem usa `{ data, pagination }` de
`src/shared/http/response.ts`:22.

| ID | Método | Path | RF de origem |
|---|---|---|---|
| FDD-CONTRATO-01 | POST | `/customers/:customerId/webhooks` | RF-01, RF-02, RF-04 |
| FDD-CONTRATO-02 | GET | `/customers/:customerId/webhooks` | RF-03 |
| FDD-CONTRATO-03 | PATCH | `/webhooks/:id` | RF-03, RF-04 |
| FDD-CONTRATO-04 | DELETE | `/webhooks/:id` | RF-03 |
| FDD-CONTRATO-05 | POST | `/webhooks/:id/secret/rotate` | RF-05 |
| FDD-CONTRATO-06 | GET | `/webhooks/:id/deliveries` | RF-06, RF-07 |
| FDD-CONTRATO-07 | POST | `/admin/webhooks/dead-letter/:id/replay` | RF-08 |

### POST /customers/:customerId/webhooks

Cadastra um endpoint de webhook para o cliente e devolve a secret gerada
(`FDD-CONTRATO-01`).

Headers: `Authorization: Bearer <jwt>` · `Content-Type: application/json`

Request:

```json
{
  "url": "https://atlas.example.com/hooks/orders",
  "subscribedStatuses": ["PAID", "PROCESSING", "SHIPPED", "DELIVERED"],
  "description": "Integração de pedidos Atlas"
}
```

Response:

```json
{
  "id": "3f2b1c88-7d54-4a1e-9a10-5b0d2c9e77aa",
  "customerId": "c1a2b3d4-5e6f-4071-8a9b-0c1d2e3f4a5b",
  "url": "https://atlas.example.com/hooks/orders",
  "subscribedStatuses": ["PAID", "PROCESSING", "SHIPPED", "DELIVERED"],
  "active": true,
  "secret": "whsec_2f9c1a7e5b3d40f8ae6c1d92b47f0e35",
  "createdAt": "2026-08-19T12:00:00.000Z"
}
```

A secret é gerada pela plataforma e devolvida **apenas aqui e na rotação** (RF-02);
nas demais respostas ela não trafega.

**Status:** 201 — endpoint criado.
**Status:** 400 — `WEBHOOK_URL_NOT_HTTPS`, url que não usa TLS.
**Status:** 404 — `WEBHOOK_CUSTOMER_NOT_FOUND`, `customerId` inexistente.
**Status:** 409 — `WEBHOOK_DUPLICATE_URL`, url já cadastrada para o cliente.
**Status:** 422 — `WEBHOOK_INVALID_STATUS_FILTER`, status fora de `OrderStatus`.

### GET /customers/:customerId/webhooks

Lista os endpoints de webhook do cliente, paginado (`FDD-CONTRATO-02`).

Headers: `Authorization: Bearer <jwt>`

Request — query string, sem corpo:

```json
{
  "page": 1,
  "pageSize": 20
}
```

Response:

```json
{
  "data": [
    {
      "id": "3f2b1c88-7d54-4a1e-9a10-5b0d2c9e77aa",
      "customerId": "c1a2b3d4-5e6f-4071-8a9b-0c1d2e3f4a5b",
      "url": "https://atlas.example.com/hooks/orders",
      "subscribedStatuses": ["PAID", "SHIPPED"],
      "active": true,
      "createdAt": "2026-08-19T12:00:00.000Z"
    }
  ],
  "pagination": { "page": 1, "pageSize": 20, "total": 1, "totalPages": 1 }
}
```

**Status:** 200 — lista devolvida, possivelmente vazia.
**Status:** 404 — `WEBHOOK_CUSTOMER_NOT_FOUND`, `customerId` inexistente.

### PATCH /webhooks/:id

Edita url, lista de status assinados ou o estado ativo de um endpoint
(`FDD-CONTRATO-03`).

Headers: `Authorization: Bearer <jwt>` · `Content-Type: application/json`

Request:

```json
{
  "url": "https://atlas.example.com/hooks/orders/v2",
  "subscribedStatuses": ["PAID", "CANCELLED"],
  "active": false
}
```

Response:

```json
{
  "id": "3f2b1c88-7d54-4a1e-9a10-5b0d2c9e77aa",
  "customerId": "c1a2b3d4-5e6f-4071-8a9b-0c1d2e3f4a5b",
  "url": "https://atlas.example.com/hooks/orders/v2",
  "subscribedStatuses": ["PAID", "CANCELLED"],
  "active": false,
  "updatedAt": "2026-08-19T13:10:00.000Z"
}
```

**Status:** 200 — endpoint atualizado.
**Status:** 400 — `WEBHOOK_URL_NOT_HTTPS`, url que não usa TLS.
**Status:** 404 — `WEBHOOK_NOT_FOUND`, id inexistente.
**Status:** 409 — `WEBHOOK_DUPLICATE_URL`, url já cadastrada para o cliente.
**Status:** 422 — `WEBHOOK_INVALID_STATUS_FILTER`, status fora de `OrderStatus`.

### DELETE /webhooks/:id

Remove o endpoint. Entregas já registradas no histórico permanecem
(`FDD-CONTRATO-04`).

Headers: `Authorization: Bearer <jwt>`

Request — sem corpo:

```json
{}
```

Response — 204 não tem corpo; o corpo abaixo é o do caso de erro:

```json
{
  "error": {
    "code": "WEBHOOK_NOT_FOUND",
    "message": "Webhook endpoint not found"
  }
}
```

**Status:** 204 — endpoint removido.
**Status:** 404 — `WEBHOOK_NOT_FOUND`, id inexistente.

### POST /webhooks/:id/secret/rotate

Gera nova secret para o endpoint e devolve o valor em claro (`FDD-CONTRATO-05`).
A secret anterior segue válida em paralelo por 24 horas (DEC-09, RNF-13); durante
a janela, cada entrega leva a assinatura calculada com a secret nova, e o cliente
pode aceitar qualquer uma das duas enquanto migra.

Headers: `Authorization: Bearer <jwt>`

Request — sem corpo:

```json
{}
```

Response:

```json
{
  "id": "3f2b1c88-7d54-4a1e-9a10-5b0d2c9e77aa",
  "secret": "whsec_8b41d0c6e29a4f17b5d3a0e8c7f2149d",
  "previousSecretValidUntil": "2026-08-20T13:30:00.000Z",
  "rotatedAt": "2026-08-19T13:30:00.000Z"
}
```

**Status:** 200 — secret rotacionada.
**Status:** 404 — `WEBHOOK_NOT_FOUND`, id inexistente.
**Status:** 409 — `WEBHOOK_ROTATION_IN_GRACE_PERIOD`, rotação anterior ainda dentro
das 24 horas.

### GET /webhooks/:id/deliveries

Devolve o histórico de entregas do endpoint, limitado aos últimos 100 envios
(RF-07, RNF-19), com sucesso/falha, payload enviado, response recebida e tempo de
resposta (`FDD-CONTRATO-06`).

Headers: `Authorization: Bearer <jwt>`

Request — query string, sem corpo:

```json
{
  "page": 1,
  "pageSize": 20
}
```

Response:

```json
{
  "data": [
    {
      "id": "b7c9e0a1-2d34-45f6-8901-a2b3c4d5e6f7",
      "eventId": "9f1c0b0e-4a2d-4c31-b6f5-8e7d6c5b4a39",
      "outcome": "FAILED",
      "attempt": 3,
      "requestPayload": { "event_type": "order.status_changed" },
      "responseStatus": 503,
      "responseBody": "service unavailable",
      "durationMs": 10000,
      "attemptedAt": "2026-08-19T13:45:12.004Z"
    }
  ],
  "pagination": { "page": 1, "pageSize": 20, "total": 1, "totalPages": 1 }
}
```

**Status:** 200 — histórico devolvido, possivelmente vazio.
**Status:** 404 — `WEBHOOK_NOT_FOUND`, id inexistente.

### POST /admin/webhooks/dead-letter/:id/replay

Recoloca na outbox, como pendente, o evento que morreu na dead-letter queue
(`FDD-CONTRATO-07`). Exige role `ADMIN` (DEC-19) e registra o autor da operação
(RNF-20).

Headers: `Authorization: Bearer <jwt>` · role `ADMIN`

Request — sem corpo:

```json
{}
```

Response:

```json
{
  "deadLetterId": "e4d5c6b7-a890-4123-9def-0123456789ab",
  "outboxId": "1a2b3c4d-5e6f-4708-9a0b-1c2d3e4f5a6b",
  "status": "PENDING",
  "replayedBy": "0d1e2f3a-4b5c-4d6e-8f90-a1b2c3d4e5f6",
  "replayedAt": "2026-08-19T14:00:00.000Z"
}
```

**Status:** 202 — evento recolocado na outbox.
**Status:** 403 — `WEBHOOK_REPLAY_FORBIDDEN`, autenticado sem role `ADMIN`.
**Status:** 404 — `WEBHOOK_DEAD_LETTER_NOT_FOUND`, id inexistente.
**Status:** 409 — `WEBHOOK_DEAD_LETTER_ALREADY_REPLAYED`, item já reprocessado.

### Payload do evento entregue

Corpo do `POST` que o worker envia à url cadastrada (RF-09, RF-10). Sem `items`,
para não inflar o corpo: o cliente busca o detalhe depois em `GET /orders/:id`
(DEC-24).

```json
{
  "event_id": "9f1c0b0e-4a2d-4c31-b6f5-8e7d6c5b4a39",
  "event_type": "order.status_changed",
  "timestamp": "2026-08-19T13:45:02.004Z",
  "order_id": "7c8d9e0f-1a2b-4c3d-8e9f-0a1b2c3d4e5f",
  "order_number": "ORD-000123",
  "from_status": "PAID",
  "to_status": "PROCESSING",
  "customer_id": "c1a2b3d4-5e6f-4071-8a9b-0c1d2e3f4a5b",
  "total_cents": 149900
}
```

Headers do request de entrega (RF-11, RF-12, RF-13):

| Header | Conteúdo |
|---|---|
| `X-Event-Id` | UUID do evento, o mesmo de `event_id` — chave de dedup do cliente (DEC-10) |
| `X-Signature` | HMAC-SHA256 calculado sobre o corpo do request (DEC-07) |
| `X-Timestamp` | timestamp do envio, ISO 8601 |
| `X-Webhook-Id` | id do endpoint cadastrado, para cliente com vários webhooks (RF-13) |
| `Content-Type` | `application/json` (RF-12) |

A reunião nomeou um único campo básico da order além das chaves: o valor total
(RF-10). O schema tem outros dois valores monetários que ninguém pediu
(`subtotalCents` e `discountCents`, `prisma/schema.prisma`:79–80); eles ficam fora
do payload. Lacuna declarada, não preenchida por conta própria.

### Mapeamento payload ↔ schema

O payload é **contrato público** e usa `snake_case`, como a reunião especificou. O
schema Prisma é **interno** e usa `camelCase` em todos os campos — não há `@map` de
coluna em nenhum campo do arquivo, então o nome do atributo é também o nome no
MySQL. As duas convenções coexistem por decisão, e esta tabela é a tradução; não há
contradição a conciliar (DIV-01, DIV-02, DIV-03).

| Campo do payload (snake_case) | Origem no schema (camelCase) | `arquivo:linha` |
|---|---|---|
| `order_id` | `Order.id` | `prisma/schema.prisma`:75 |
| `order_number` | `Order.orderNumber` | `prisma/schema.prisma`:76 |
| `customer_id` | `Order.customerId` | `prisma/schema.prisma`:77 |
| `total_cents` | `Order.totalCents` | `prisma/schema.prisma`:81 |
| `from_status` | `OrderStatusHistory.fromStatus` | `prisma/schema.prisma`:119 |
| `to_status` | `OrderStatusHistory.toStatus` | `prisma/schema.prisma`:120 |
| `event_id` | `WebhookOutbox.id` — gerado na inserção, UUID (DEC-26) | `prisma/schema.prisma` (novo model) |
| `event_type` | constante `order.status_changed`, sem origem no schema | — |
| `timestamp` | `WebhookOutbox.createdAt` | `prisma/schema.prisma` (novo model) |

A tradução acontece na renderização do snapshot, dentro de
`publishWebhookEvent` — nenhum outro ponto do sistema traduz entre as duas
convenções.

## Matriz de erros

Todos os códigos do módulo levam o prefixo `WEBHOOK_` (DEC-13). Cada classe nova
estende a classe de status apropriada de `src/shared/errors/http-errors.ts` —
nunca `AppError` direto — seguindo o precedente de `InsufficientStockError`
(`src/shared/errors/http-errors.ts`:55), e é reexportada pelo barril
`src/shared/errors/index.ts`. É isso que garante o mapeamento automático para o
status HTTP no primeiro ramo de `src/middlewares/error.middleware.ts`:15.

| ID | Código | HTTP | Classe base | Quando ocorre | Ação do cliente |
|---|---|---|---|---|---|
| FDD-ERR-01 | WEBHOOK_URL_NOT_HTTPS | 400 | `ValidationError` | url informada não usa TLS (RNF-14, RNF-15) | corrigir a url para https e repetir |
| FDD-ERR-02 | WEBHOOK_INVALID_STATUS_FILTER | 422 | `UnprocessableEntityError` | lista de status assinados traz valor fora de `OrderStatus` | usar somente valores do enum publicado |
| FDD-ERR-03 | WEBHOOK_DUPLICATE_URL | 409 | `ConflictError` | url já cadastrada e ativa para o mesmo cliente | editar o endpoint existente em vez de criar outro |
| FDD-ERR-04 | WEBHOOK_NOT_FOUND | 404 | `NotFoundError` | id de endpoint inexistente ou de outro cliente | conferir o id devolvido na criação |
| FDD-ERR-05 | WEBHOOK_CUSTOMER_NOT_FOUND | 404 | `NotFoundError` | `customerId` do path não existe | conferir o identificador do cliente |
| FDD-ERR-06 | WEBHOOK_ROTATION_IN_GRACE_PERIOD | 409 | `ConflictError` | nova rotação pedida com a janela de 24 horas ainda aberta | aguardar o fim da janela antes de rotacionar de novo |
| FDD-ERR-07 | WEBHOOK_REPLAY_FORBIDDEN | 403 | `ForbiddenError` | replay pedido por usuário autenticado sem role `ADMIN` (DEC-19) | pedir a operação a quem tem o papel |
| FDD-ERR-08 | WEBHOOK_DEAD_LETTER_NOT_FOUND | 404 | `NotFoundError` | id de item da dead-letter queue inexistente | conferir o id na consulta da fila |
| FDD-ERR-09 | WEBHOOK_DEAD_LETTER_ALREADY_REPLAYED | 409 | `ConflictError` | item já reprocessado por um replay anterior | consultar a outbox pelo evento reenviado |
| FDD-ERR-10 | WEBHOOK_PAYLOAD_TOO_LARGE | 422 | `UnprocessableEntityError` | corpo renderizado passa de 64KB (RNF-17) | nenhuma; é falha terminal, o evento vai para a fila de morte |
| FDD-ERR-11 | WEBHOOK_DELIVERY_TIMEOUT | 422 | `UnprocessableEntityError` | endpoint do cliente não respondeu em 10 segundos (DEC-23) | nenhuma na hora; o envio é retentado |
| FDD-ERR-12 | WEBHOOK_DELIVERY_FAILED | 422 | `UnprocessableEntityError` | endpoint respondeu fora da faixa 2xx | nenhuma na hora; o envio é retentado |
| FDD-ERR-13 | WEBHOOK_SIGNATURE_UNAVAILABLE | 422 | `UnprocessableEntityError` | endpoint sem secret utilizável no momento do envio | rotacionar a secret pelo endpoint de rotação |

As quatro últimas linhas nascem no worker, fora de um ciclo request/response: o
`statusCode` que a classe carrega não trafega para cliente nenhum, mas existe
porque a classe estende a hierarquia do projeto e o código é o que fica gravado em
`webhook_deliveries` e em `webhook_dead_letter`. Elas são lidas pelo cliente por
`GET /webhooks/:id/deliveries`, não por resposta direta.

## Estratégias de resiliência

| Mecanismo | Valor | Origem |
|---|---|---|
| Timeout do HTTP call do worker | 10 segundos | DEC-23, RNF-22 |
| Tentativas antes da fila de morte | 5 | DEC-05, RNF-07 |
| Progressão do backoff | 1m · 5m · 30m · 2h · 12h | DEC-05, RNF-08 |
| Janela total coberta | quase 15 horas | RNF-09 |
| Limite de tamanho do corpo | 64KB | RNF-17 |
| Grace period da secret anterior | 24 horas | DEC-09, RNF-13 |
| Intervalo de polling | 2 segundos | DEC-02, RNF-02 |
| Latência aceita no pior caso | 2 segundos | RNF-03 |
| Histórico exposto | últimos 100 envios | RF-07, RNF-19 |

**Timeout.** Cliente que não responde em 10 segundos é tratado como falha e o
evento entra na política de retentativa. O valor não é arredondado nem derivado: é
o número dito na reunião.

**Retentativa e fila de morte.** Cinco tentativas, na progressão fixa acima, e
depois `webhook_dead_letter`, com payload, motivo da falha e timestamp (DEC-06). A
progressão é literal — nenhum termo foi acrescentado para "fechar" a curva.

**Limite de tamanho.** Corpo renderizado acima de 64KB é recusado com erro
(FDD-ERR-10). É falha terminal, não retentável.

**Garantia de entrega.** At-least-once (DEC-10): o cliente pode receber o mesmo
evento duas vezes (RNF-18) e deduplica pelo `X-Event-Id`. A garantia é do contrato,
não um efeito colateral — a marcação de `DELIVERED` acontece depois do envio, e um
crash entre o envio e a marcação produz reenvio.

**Ordenação.** Garantida por `order_id` enquanto o worker for único (DEC-04). Não
há garantia global.

**Rajada.** O cenário citado foi de 50 pedidos mudando de status em um minuto para
um cliente (RNF-21). Com polling de 2 segundos e batch pequeno, isso é fila, não
perda: o atraso cresce, a régua de 10 segundos (RNF-01) é o que aperta primeiro.

## Observabilidade

O módulo importa o singleton `logger` de `src/shared/logger/index.ts`:32; o worker,
por ser outro processo, usa a factory `createLogger` (`src/shared/logger/index.ts`:13).
O formato é o Pino de dois argumentos — objeto estruturado primeiro, mensagem-evento
depois, em `snake_case` — como já se faz em `src/server.ts`:10 e em
`src/middlewares/request-logger.middleware.ts`:23.

### Métricas

- `webhook_outbox_pending_total` — profundidade da outbox: linhas pendentes com
  `nextAttemptAt` já vencido. É o indicador de atraso do worker.
- `webhook_outbox_age_seconds` — idade da linha pendente mais antiga. É contra esta
  métrica que se mede a régua de 10 segundos dos clientes (RNF-01).
- `webhook_delivery_duration_ms` — distribuição do tempo de resposta do endpoint do
  cliente, com o timeout de 10 segundos como teto natural.
- `webhook_delivery_total` — contador de entregas, particionado por resultado
  (entregue, falha, timeout) e por endpoint.
- `webhook_retry_total` — contador de retentativas, particionado por número da
  tentativa, para ver em que degrau da progressão os clientes se recuperam.
- `webhook_dead_letter_total` — contador de eventos que esgotaram as 5 tentativas.
  Crescimento aqui é incidente, não estatística.

### Logs

- `webhook_event_published` — emitido na inserção, dentro da transação. Campos:
  `orderId`, `fromStatus`, `toStatus`, `endpointCount`, `requestId`.
- `webhook_delivery_attempted` — emitido antes do envio. Campos: `eventId`,
  `webhookId`, `attempt`, `url`.
- `webhook_delivery_succeeded` — resposta 2xx. Campos: `eventId`, `webhookId`,
  `responseStatus`, `durationMs`.
- `webhook_delivery_failed` — resposta não-2xx, erro de rede ou estouro do timeout.
  Campos: `eventId`, `webhookId`, `attempt`, `responseStatus`, `durationMs`,
  `errorCode`.
- `webhook_dead_lettered` — evento movido para a fila de morte. Campos: `eventId`,
  `webhookId`, `attempts`, `reason`.
- `webhook_replay_executed` — replay administrativo. Campos: `deadLetterId`,
  `outboxId`, `actorId` — este último é o que atende a exigência de auditoria de
  quem executou (RNF-20).
- `webhook_secret_rotated` — rotação de secret. Campos: `webhookId`, `actorId`,
  `previousSecretValidUntil`. **O valor da secret nunca entra no log.**

**A lista de redação atual não cobre secret de webhook.** `redactPaths`
(`src/shared/logger/index.ts`:4–11) tem seis entradas — `req.headers.authorization`,
`req.headers.cookie`, `*.password`, `*.passwordHash`, `*.token` e `*.accessToken` —
e nenhuma delas casa com o campo de secret deste módulo nem com o header
`X-Signature`. Acrescentar as entradas novas é trabalho desta feature, não algo que
o projeto já resolve.

### Tracing

- **O `requestId` nasce no middleware HTTP.** Ele é gerado por `uuidv4()` — ou
  herdado do header `x-request-id` da requisição — em
  `src/middlewares/request-logger.middleware.ts`:6–8, e devolvido em
  `X-Request-Id`. Toda linha de log da API já o carrega.
- **O worker roda fora desse caminho.** Não há requisição HTTP de entrada no
  processo do worker, então não há `requestId` para herdar: a correlação entre a
  mudança de status e a entrega precisa de um segundo mecanismo.
- O mecanismo é a própria linha de outbox: `publishWebhookEvent` grava o
  `requestId` da requisição que originou a mudança de status num campo da linha, e
  o worker o relê e o repete em todo log de entrega. É o único fio que liga o
  `PATCH /orders/:id/status` ao `POST` que chega no cliente.
- O `X-Event-Id` enviado ao cliente é o mesmo `id` da linha de outbox, o que
  estende a correlação para fora do sistema: o cliente que reclama de um evento
  cita o identificador que localiza a linha, a entrega e a falha.
- Não há tracing distribuído no projeto hoje — nenhuma biblioteca de trace consta
  de `package.json`. O correlacionador aqui é campo em log e em tabela, não span; o
  passo para OpenTelemetry fica registrado como possibilidade, não como escopo.

## Dependências e compatibilidade

**Runtime.** Node `>=20` e ESM (`package.json`:6, :8). O worker é um segundo
processo Node do mesmo repositório, com script próprio; nada nele exige versão
diferente da API.

**Prisma.** As quatro tabelas novas se declaram em `prisma/schema.prisma` seguindo
o par de convenções do arquivo: modelo `PascalCase` com `@@map` para nome de tabela
`snake_case`, atributos em `camelCase`, e a migration correspondente gerada pelo
script `db:migrate` de `package.json`:14. O relacionamento com o pedido tem
precedente exato em `OrderStatusHistory` (`prisma/schema.prisma`:116): FK `orderId`
com `@@index([orderId])` mais um índice temporal. Os índices exigidos pela reunião
para a outbox — campo de status e `createdAt` (RNF-04) — entram como `@@index`.

**Migration.** Um arquivo novo sob `prisma/migrations/`, no formato do existente
(`prisma/migrations/20260519182739_init/migration.sql`, 125 linhas, com cabeçalhos
`-- CreateTable` e `-- AddForeignKey`). Só cria tabelas e índices; nenhuma tabela
existente é alterada, o que torna a migration reversível por `DROP`.

**Identificador. O padrão de UUID do projeto não é universal (DIV-10).** DEC-26
manda seguir "o padrão do resto do projeto" para o id da outbox, e o padrão vale
para **6 dos 7 models**: `String @id @default(uuid()) @db.Char(36)` em
`prisma/schema.prisma`:26, 41, 57, 75, 100 e 117. A exceção é
`OrderNumberSequence`, cujo `id` é `Int @id @default(1)`
(`prisma/schema.prisma`:133–138) — tabela de sequência de linha única, onde UUID não
faria sentido. As quatro tabelas novas seguem o padrão dos seis, e o registro da
exceção está aqui para que "tudo é uuid" não seja lido como verdade absoluta por
quem for escrever o schema.

**Configuração.** As variáveis novas do módulo — intervalo de polling, tamanho do
batch, timeout de entrega — entram no `envSchema` de `src/config/env.ts`:3 e no
`.env.example`, com `.default()` onde couber. O projeto nunca lê `process.env`
direto fora desse arquivo, e o carregamento é fail-fast (`process.exit(1)` em
falha de validação).

**O que a feature não tem hoje.** Nada. A varredura de `.planning/02-codigo.md` §4
confirmou ausência de outbox, fila, worker, scheduler, HMAC, retry, dead-letter,
webhook, evento, publisher, idempotência e trigger em `src/`, `prisma/`, `tests/` e
`package.json`. A única dependência de criptografia do projeto é `bcrypt`
(`package.json`:27), usada só no hash de senha
(`src/modules/auth/auth.service.ts`:36) — a assinatura HMAC-SHA256 usa o módulo
`crypto` do próprio Node, sem dependência nova. Um cliente HTTP para o envio é
dependência nova a decidir na implementação.

**Pool de conexão (DIV-06).** A reunião presumiu pool configurado; não há
configuração de pool em lugar nenhum — `createPrismaClient`
(`src/config/database.ts`:4–8) passa apenas `log`. O pool existe por default do
Prisma. Um segundo processo abre um segundo pool, e o dimensionamento do MySQL
precisa considerar isso.

## Critérios de aceite técnicos

- Uma mudança de status com endpoint assinante produz exatamente uma linha de
  `webhook_outbox` por endpoint interessado, com `status = PENDING`.
- Uma mudança de status sem nenhum endpoint assinante produz zero linha de outbox.
- Erro na escrita da outbox faz a transação inteira sofrer rollback: a order
  permanece no status anterior e `order_status_history` não ganha linha.
- Cadastro com url `http://` é recusado com HTTP 400 e código
  `WEBHOOK_URL_NOT_HTTPS`.
- Todo código de erro devolvido pelo módulo começa com `WEBHOOK_`.
- O worker lê apenas linhas com `status = PENDING` e `nextAttemptAt` vencido,
  ordenadas por `createdAt`.
- Uma entrega que não responde em 10 segundos é abortada e contabilizada como
  falha, com `durationMs` registrado.
- Após 5 falhas, a linha aparece em `webhook_dead_letter` com payload, motivo e
  timestamp, e não é mais lida pelo worker.
- Os intervalos entre tentativas consecutivas são 1m, 5m, 30m, 2h e 12h, nessa
  ordem.
- Corpo renderizado acima de 64KB não é enviado e vai direto para a dead-letter
  queue, com `WEBHOOK_PAYLOAD_TOO_LARGE` como motivo.
- Toda entrega leva os headers `X-Event-Id`, `X-Signature`, `X-Timestamp`,
  `X-Webhook-Id` e `Content-Type: application/json`.
- A assinatura em `X-Signature` verifica com a secret do endpoint e falha com
  qualquer outra.
- Após rotação, uma assinatura calculada com a secret anterior continua verificável
  pelo cliente por 24 horas.
- `GET /webhooks/:id/deliveries` devolve no máximo 100 registros, cada um com
  resultado, payload, response e tempo de resposta.
- Replay sem role `ADMIN` responde HTTP 403; com role `ADMIN`, cria linha nova em
  `webhook_outbox` com `attempts = 0` e grava o identificador de quem executou.
- Um segundo replay do mesmo item da dead-letter queue responde HTTP 409.
- O mesmo evento entregue duas vezes carrega o mesmo `X-Event-Id`.
- Nenhuma linha de log contém o valor de uma secret nem o conteúdo de
  `X-Signature`.
- Os testes de integração existentes de `PATCH /orders/:id/status`
  (`tests/orders.test.ts`) continuam passando sem alteração de expectativa.

## Riscos e mitigação

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Defeito na escrita da outbox derruba a mudança de status do pedido | Média | **Alto** — atinge fluxo em produção, não só a feature | A função recebe o handle transacional e não inverte dependências (ADR-007); cobertura de teste na transição sem assinante, que é o caminho de custo zero |
| A transação de `changeStatus` fica mais lenta e segura o lock da order por mais tempo | Alta | Médio | Inserção única e sem I/O externo; o envio é do worker, nunca da transação |
| Cobertura nasce com buraco: a criação do pedido não passa por `changeStatus` (DIV-11) | Alta | Médio — cliente não recebe evento de entrada em `PENDING` | Buraco declarado em ADR-007 e em §Fluxos detalhados; decisão sobre emitir ou não evento na criação precisa vir antes do código |
| Assinar `PENDING` ou `CANCELLED` sem que a reunião tenha decidido (DIV-12) | Média | Médio | O filtro aceita o enum inteiro e a lacuna está declarada; nenhuma regra foi inventada para fechá-la |
| Secret vazando em log por ausência de entrada em `redactPaths` | Média | **Alto** — comprometeria a assinatura de todos os eventos do endpoint | Entrada nova em `redactPaths` é item de escopo desta feature, com critério de aceite próprio |
| Worker único vira gargalo sob rajada (RNF-21) | Média | Médio | Métrica de idade da linha pendente mais antiga; escalar é questão em aberto (RFC-QA-04), não decisão silenciosa |
| Cliente lento consome a janela de 10 segundos em toda tentativa | Alta | Baixo | Timeout fecha a tentativa; o backoff tira o endpoint lento do caminho dos demais |
| Segundo pool de conexão do worker pressiona o MySQL (DIV-06) | Média | Médio | Dimensionamento explícito na configuração do processo novo, já que o projeto não configura pool hoje |
| Contrato público muda se RFC-QA-01 for reaberta | Média | Médio | A forma provisória está marcada em todas as ocorrências; a mudança é de rota, não de payload |
| Prazo de três sprints com dois dias úteis reservados para revisão de segurança (DEC-25, RNF-26, RNF-27) | Média | Médio | A revisão entra no fim do cronograma, como acordado; assinatura e redação de log são o que ela examina |

## Integração com o sistema existente

Doze caminhos reais são tocados ou explicitamente não tocados. A **localização
exata da inserção dentro da transação** está em
[ADR-007](adrs/ADR-007-insercao-na-outbox-dentro-da-transacao.md) e não é repetida
aqui; o que segue é o que o ADR não tem — assinatura da função nova, campos da
linha gravada, comportamento em caso de erro e o delta por arquivo.

**Assinatura da função nova**, no arquivo
`src/modules/webhooks/webhook.publisher.ts` (novo):

```ts
export async function publishWebhookEvent(
  tx: TxClient,
  input: {
    orderId: string;
    from: OrderStatus;
    to: OrderStatus;
    changedById: string;
    requestId?: string;
  },
): Promise<number>;
```

O primeiro parâmetro é o `TxClient` (`src/modules/orders/order.service.ts`:24),
exatamente como `debitStock` (linha 204) — é o que a torna participante da
transação. O retorno é a quantidade de linhas de outbox criadas, zero inclusive.

**Campos da linha de `webhook_outbox`:** `id` (UUID, DEC-26) · `webhookEndpointId`
(FK) · `orderId` (FK) · `eventType` (`order.status_changed`) · `payload` (snapshot
renderizado, DEC-27) · `status` (`PENDING` · `PROCESSING` · `DELIVERED` · `FAILED`,
os quatro estados que a reunião nomeou em RNF-04) · `attempts` · `nextAttemptAt` ·
`lastErrorCode` · `requestId` · `createdAt` · `updatedAt`. Índices: status,
`createdAt` (RNF-04), `nextAttemptAt`, `orderId` e `webhookEndpointId`.

**Comportamento em caso de erro:** `publishWebhookEvent` não engole exceção. Uma
falha de escrita propaga para o callback de `$transaction` e derruba a transação
inteira — a order não muda de status e a resposta de `PATCH /orders/:id/status` é
de erro. Essa é a consequência aceita de DEC-21, e é o que diferencia esta chamada
de um efeito colateral opcional.

| Caminho | O que muda |
|---|---|
| `src/modules/orders/order.service.ts` | Ganha uma chamada a `publishWebhookEvent` dentro do callback transacional de `changeStatus` e um import do módulo de webhooks. Construtor (linhas 27–30) intocado: nenhum repository novo é injetado. |
| `src/modules/orders/order.status.ts` | Ganha o predicado `shouldEmitWebhookEvent(from, to)`, na forma `(from, to) => boolean`, ao lado de `shouldDebitStock` (linha 29). A política de transição segue sendo dado neste arquivo, não `if` no service. |
| `src/shared/errors/http-errors.ts` | Ganha 13 classes novas, uma por linha de §Matriz de erros, cada uma estendendo a classe de status correspondente — precedente literal `InsufficientStockError` (linha 55), que estende `UnprocessableEntityError` (linha 39). |
| `src/shared/errors/index.ts` | Ganha as 13 classes novas na lista de reexport (hoje linhas 3–13). É por este barril que os módulos importam erro; nenhum arquivo de `src/modules/` importa `http-errors` direto. |
| `src/middlewares/error.middleware.ts` | **Nada muda.** As classes novas estendem `AppError` por herança e caem no primeiro ramo do handler (linha 15), que já monta `{ error: { code, message, details? } }`. Registrar isso é parte do desenho: a ausência de mudança aqui é o que prova o reuso (DEC-15). |
| `src/middlewares/auth.middleware.ts` | **Nada muda.** As rotas novas compõem `authenticate` (linha 27) e, no replay, `requireRole('ADMIN')` (linha 49), no formato já usado em `src/modules/users/user.routes.ts`:11–17. O universo de papéis segue com dois valores. |
| `src/routes/index.ts` | O tipo `Controllers` (linha 13) ganha o campo de webhooks e `buildApiRouter` (linha 21) ganha as linhas `router.use('/webhooks', ...)` e `router.use('/admin/webhooks', ...)`; o path de cadastro pendura-se no router de customers (linha 26). |
| `src/app.ts` | `buildControllers` (linha 26) instancia repository, service e controller do módulo novo e injeta o `prisma` já existente, na mesma ordem dos demais domínios. Nada muda no encadeamento de `buildApp` (linha 55): `/health` (62), `/api/v1` (67), 404 (69) e `errorMiddleware` (73) seguem na ordem atual. |
| `src/config/database.ts` | **Nada muda no arquivo.** O worker chama `createPrismaClient()` (linha 4) em vez de importar o singleton `prisma` (linha 10), porque `PrismaClient` é por processo (DEC-14). A factory já existe exatamente para isso. |
| `src/config/env.ts` | O `envSchema` (linha 3) ganha as variáveis do módulo, com `.default()` onde houver padrão, e o `.env.example` é atualizado no mesmo commit. |
| `prisma/schema.prisma` | Ganha quatro models — `WebhookEndpoint`, `WebhookOutbox`, `WebhookDelivery`, `WebhookDeadLetter` — com `@@map` para `webhook_endpoints`, `webhook_outbox`, `webhook_deliveries` e `webhook_dead_letter`, mais o enum de estado da linha de outbox, ao lado de `OrderStatus` (linha 16). |
| `src/shared/logger/index.ts` | `redactPaths` (linhas 4–11) ganha as entradas do secret de webhook e do header de assinatura. É a única mudança de comportamento neste arquivo; `createLogger` (linha 13) e o singleton (linha 32) ficam como estão. |

Arquivos novos do módulo, todos marcados `(novo)`:
`src/modules/webhooks/webhook.controller.ts` (novo) ·
`src/modules/webhooks/webhook.service.ts` (novo) ·
`src/modules/webhooks/webhook.repository.ts` (novo) ·
`src/modules/webhooks/webhook.routes.ts` (novo) ·
`src/modules/webhooks/webhook.schemas.ts` (novo) ·
`src/modules/webhooks/webhook.publisher.ts` (novo) ·
`src/modules/webhooks/webhook.processor.ts` (novo) ·
`src/worker.ts` (novo).

O módulo segue o padrão de `src/modules/orders/`, com a ressalva de que esse padrão
já tem exceções no repositório: `src/modules/auth/` não tem repository e
`src/modules/orders/` tem um sexto arquivo fora da lista canônica (DIV-09,
registrada em ADR-006). Os dois arquivos extras aqui — publisher e processor — são,
portanto, desvio precedido, não invenção.
