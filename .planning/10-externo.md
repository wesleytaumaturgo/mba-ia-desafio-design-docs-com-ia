# Análise externa de implementabilidade — webhooks de status de pedido

Perspectiva: engenheiro que começaria a implementação em 2026-08-20, sem ter
participado da reunião. Esta análise foi formada antes da leitura de
`.planning/09-review.md`.

## 1. Onde você trava

| # | Pergunta | Onde você procurou | Gravidade (trava / atrasa / irrita) |
|---|---|---|---|
| 1 | O `customerId` fica definitivamente no path ou no body? | RFC §Questões em aberto (`RFC-QA-01`); FDD §Contratos públicos adota o path apenas provisoriamente; ADR-008 também mantém a decisão aberta. | trava |
| 2 | A criação do pedido deve emitir o evento de entrada em `PENDING`? `OrderService.create` cria o pedido e o primeiro histórico fora de `changeStatus` (`src/modules/orders/order.service.ts:95-113`), mas o publisher foi desenhado somente para `changeStatus` (`src/modules/orders/order.service.ts:126-178`). | RFC §Impacto e riscos; ADR-007 §Consequências; FDD §Criação do evento e §Riscos. Todos reconhecem a lacuna e pedem decisão antes do código. | trava |
| 3 | `PENDING` e `CANCELLED` são filtros públicos válidos e quais transições realmente geram evento? O enum tem os seis valores (`prisma/schema.prisma:16-23`) e o grafo real tem sete transições (`src/modules/orders/order.status.ts:3-10`), embora os documentos afirmem oito; a reunião cobriu somente quatro status. | RFC §Impacto e riscos; ADR-007 §Consequências; FDD §Criação do evento. | trava |
| 4 | “5 tentativas” significa cinco chamadas no total ou a chamada inicial mais cinco retries? Em qual instante o item entra na DLQ? | ADR-003 §Decisão; FDD §Retry e diagrama. A progressão tem cinco intervalos, mas cinco chamadas têm somente quatro intervalos entre elas. | trava |
| 5 | Como uma linha em `PROCESSING` é recuperada se o worker cair antes de marcá-la como `DELIVERED`, `FAILED` ou novamente `PENDING`? Há lease, `lockedAt`, timeout de processamento ou reset no startup? | FDD §Processamento pelo worker e campos de `webhook_outbox`; ADR-002. Nenhum mecanismo de recuperação é definido. | trava |
| 6 | A DLQ remove a linha da outbox ou mantém a origem como `FAILED`? | ADR-003 diz que o evento “sai da outbox”; FDD §DLQ diz que a origem é marcada `FAILED` e o diagrama chama isso de “move”. | trava |
| 7 | O replay preserva o `event_id` original ou cria uma nova identidade? | ADR-005 exige identificador estável para dedup e trata replay como nova chance do mesmo evento; FDD §DLQ cria nova outbox; FDD §Mapeamento define `event_id = WebhookOutbox.id`. | trava |
| 8 | Qual é a política de remoção de endpoint com eventos pendentes e histórico existente: soft delete, bloqueio, cancelamento ou entrega dos pendentes? Quais `onDelete` usar nas FKs? | FDD `DELETE /webhooks/:id` promete preservar entregas, mas não define o destino da outbox/DLQ nem as relações dos quatro models. O schema atual usa políticas explícitas diferentes (`prisma/schema.prisma:108-109,125-126`). | trava |
| 9 | Como a secret é armazenada em repouso: texto claro, criptografia reversível ou KMS? Qual chave, rotação da chave-mestra e formato/entropia de geração? | ADR-004 reconhece material sensível, mas não decide armazenamento; FDD mostra prefixo `whsec_` e exige assinatura, sem key management. O único mecanismo atual é hash não reversível de senha (`src/modules/auth/auth.service.ts:31-40`). | trava |
| 10 | Qual é a codificação exata de `X-Signature` (hex/base64, prefixo `sha256=` ou não) e quais bytes são assinados? O JSON é serializado uma vez e os mesmos bytes são enviados? | ADR-004 e FDD §Payload dizem apenas “HMAC-SHA256 sobre o corpo”. | trava |
| 11 | Qual é a política anti-SSRF para a URL fornecida pelo usuário: IPs privados/loopback/link-local, resolução DNS e rebinding, portas, redirects e limite de redirects? | ADR-004 e FDD só exigem `https`; o worker fará I/O para URL cadastrada. | trava |
| 12 | O worker processa o batch em série ou com concorrência? Qual o batch default/máximo e como impedir que um endpoint de 10 s bloqueie todos os demais? | ADR-002 fala em “batch pequeno”; FDD §Processamento deixa o número para implementação e não define concorrência. | trava |
| 13 | Como garantir ordering por `order_id` quando uma entrega anterior está em backoff e uma posterior já está elegível? Ordering é requisito real ou deve ser removido do contrato? | ADR-002 e FDD §Resiliência prometem ordering por pedido; a query descrita seleciona apenas `nextAttemptAt <= agora`, sem bloquear eventos posteriores do mesmo pedido. | trava |
| 14 | A meta de menos de 10 s vale só para a primeira tentativa, para todos os eventos sob a carga de 50/min, ou apenas “na maioria dos casos”? | PRD §Métricas exige menos de 10 s e também “pior caso” de 2 s; PRD §Aceite muda para “na maioria”; FDD §Rajada admite que a fila pode ultrapassar a régua. | trava |
| 15 | Onde e como as métricas descritas serão publicadas/coletadas? Qual backend, endpoint e biblioteca? | FDD §Observabilidade lista seis métricas; as dependências atuais não incluem cliente de métricas (`package.json:25-52`) e `buildApp` expõe apenas `/health` além da API (`src/app.ts:55-73`). | atrasa |
| 16 | Como o worker será empacotado, iniciado, monitorado e reiniciado em cada ambiente? Deve ter healthcheck/readiness e shutdown com drenagem? | ADR-002 reconhece o trabalho novo; `package.json` só tem scripts da API (`package.json:10-20`) e o compose só sobe MySQL (`docker-compose.yml:1-28`). | trava |
| 17 | O worker usa `fetch` nativo do Node 20 ou uma dependência HTTP? Qual comportamento para redirects, compressão, TLS e abort? | FDD §Dependências diz que o cliente HTTP é decisão da implementação; o runtime suporta `fetch` (`package.json:6-8`), mas o contrato de transporte não foi fechado. | atrasa |
| 18 | O limite de 64KB mede `Buffer.byteLength` do corpo UTF-8, conteúdo descomprimido ou outro valor? O limite é `> 65536` bytes? | FDD §Retry e §Resiliência só dizem “corpo renderizado acima de 64KB”. | atrasa |
| 19 | Quais são todos os campos, tipos, tamanhos, nulabilidade, uniques, FKs e políticas de retenção de `WebhookEndpoint`, `WebhookDelivery` e `WebhookDeadLetter`? | FDD detalha campos e índices apenas de `WebhookOutbox`; respostas HTTP permitem inferir parte dos demais models, mas não constituem schema completo. | trava |
| 20 | Quanto de `responseBody` guardar, para quais content-types, e como redigir dados sensíveis? | FDD §Histórico exige resposta recebida, sem limite ou política. A API atual aceita JSON de até 1MB (`src/app.ts:55-60`), mas isso não define resposta de terceiros. | atrasa |
| 21 | URL duplicada é proibida somente enquanto ativa? O que ocorre ao reativar uma duplicata? A comparação normaliza host, porta, barra final e casing? | FDD-CONTRATO-01 diz “url já cadastrada”; FDD-ERR-03 diz “já cadastrada e ativa”. | trava |
| 22 | As operações “outbox → DLQ” e “DLQ → nova outbox” precisam ser transações atômicas e como impedir replay concorrente duplo? | FDD §DLQ exige duas escritas/mudanças de estado, mas não define transação, lock ou unique de idempotência. | trava |
| 23 | Como um administrador descobre o `deadLetterId` que deve enviar ao replay? Existe listagem/consulta da DLQ ou a operação depende de acesso direto ao banco? | FDD-CONTRATO-07 expõe apenas `POST /admin/webhooks/dead-letter/:id/replay`; FDD-ERR-08 manda conferir o id “na consulta da fila”, mas nenhum dos sete contratos consulta a DLQ. | trava |
| 24 | `shouldEmitWebhookEvent(from, to)` é gate obrigatório ou código a remover? Qual regra ele aplica além do filtro por endpoint ativo e `subscribedStatuses`? | FDD §Integração manda criar o predicado em `order.status.ts`, porém §Criação do evento define o filtro sem referenciá-lo. | trava |
| 25 | `active: false`, alteração de filtros ou rotação afetam eventos já enfileirados, ou a configuração é resolvida novamente no envio? | O FDD grava payload por endpoint na publicação, mas o worker relê URL/secret do endpoint; não define consistência temporal das demais configurações. | trava |
| 26 | Como paginação e teto de 100 entregas se compõem: `total` é limitado a 100, qual ordenação vale e páginas além do recorte retornam o quê? | FDD-CONTRATO-06 aceita `page`/`pageSize`, promete os últimos 100 e devolve `totalPages`, sem definir a interação. | atrasa |

## 2. O que você implementaria errado

| # | O que faria | Onde diz isso | Por que está errado |
|---|---|---|---|
| 1 | Implementaria cinco chamadas e, depois da quinta falha, esperaria mais 12 horas para mandar à DLQ. | FDD §Retry: `tentativa 5 falha → +12h → DLQ`; ADR-003 associa cinco tentativas à progressão `1m/5m/30m/2h/12h`. | Cinco chamadas têm quatro intervalos entre elas. O quinto intervalo ou antecede uma sexta chamada, ou é apenas atraso sem tentativa. A janela “quase 15h” não fecha com “5 tentativas” como escrito. |
| 2 | Marcaria a linha como `PROCESSING` antes do POST e buscaria somente `PENDING`. | FDD §Processamento e critérios de aceite. | Um crash depois da marcação deixa a linha permanentemente invisível à query. Isso viola a garantia at-least-once; falta lease/recovery. |
| 3 | Entregaria evento posterior do mesmo pedido enquanto o anterior aguarda backoff, acreditando ainda garantir ordering por `order_id`. | ADR-002 §Consequências; FDD §Resiliência. | A elegibilidade por `nextAttemptAt` permite ultrapassagem. Um único worker evita paralelismo, mas não preserva ordem entre retries. |
| 4 | Criaria nova linha de outbox no replay e usaria o novo `id` como `X-Event-Id`. | FDD §DLQ e replay; FDD §Mapeamento payload ↔ schema. | O mesmo evento ganha nova chave de dedup e o cliente não o reconhece como duplicata do original, contrariando a finalidade do identificador estável de ADR-005. |
| 5 | Excluiria a linha da outbox ao dead-letter, seguindo o ADR. | ADR-003: “o evento sai da outbox”. | O FDD exige manter a origem como `FAILED`; seguir o documento arquitetural destrói o histórico que o FDD usa no replay/diagnóstico. |
| 6 | Validaria `https` no schema Zod e esperaria receber `WEBHOOK_URL_NOT_HTTPS`. | ADR-004 e FDD §Matriz dizem para usar Zod/`ValidationError`; FDD §Integração diz que o middleware não muda. | `validate` converte qualquer `ZodError` em `ValidationError` (`src/middlewares/validate.middleware.ts:25-32`), cujo código é fixo em `VALIDATION_ERROR` (`src/shared/errors/http-errors.ts:9-12`). O contrato de código específico não sai desse caminho. |
| 7 | Criaria as subclasses especificadas de `ValidationError`, `NotFoundError` e `ForbiddenError`, esperando códigos `WEBHOOK_*`. | FDD §Matriz e §Integração: cada erro estende a classe de status indicada e todos têm prefixo `WEBHOOK_`. | Esses construtores fixam seus códigos e não aceitam `errorCode` (`src/shared/errors/http-errors.ts:9-30`); `AppError.errorCode` é `readonly` (`src/shared/errors/app-error.ts:3-13`). É preciso mudar classes existentes, usar bases diferentes ou alterar o desenho. |
| 8 | Montaria `/webhooks` e `/admin/webhooks` em `buildApiRouter` e presumiria que o cadastro aninhado já está resolvido no router de customers. | FDD §Integração, linha de `src/routes/index.ts`. | O router de customers aceita apenas `CustomerController` (`src/modules/customers/customer.routes.ts:10-12`) e hoje só conhece rotas do customer (`src/modules/customers/customer.routes.ts:16-24`). O delta documentado omite como injetar/registrar o controller de webhook em `/customers/:customerId/webhooks`. |
| 9 | Processaria o batch serialmente e anunciaria latência máxima de 2 s. | ADR-002 vincula polling de 2 s à latência; PRD-RNF-03 e FDD §Resiliência chamam 2 s de pior caso. | Dois segundos são apenas espera até o próximo poll. Cada POST pode consumir 10 s; fila e batch adicionam espera. Sob 50 eventos/min, a latência não tem teto de 2 s. |
| 10 | Retentaria toda resposta não-2xx cinco vezes, inclusive erros permanentes 4xx. | FDD §Retry classifica qualquer não-2xx como falha retentável. | `400`, `401`, `403`, `404`, `410` e muitos `422` normalmente não se recuperam sem mudança externa. A regra aumenta atraso/carga e posterga sinalização sem benefício; precisa de classificação explícita ou de confirmação de que esse custo é intencional. |
| 11 | Faria hard delete do endpoint porque o contrato usa `DELETE 204`. | FDD-CONTRATO-04. | O mesmo contrato exige preservar deliveries e não decide o destino da outbox/DLQ. Com FKs, hard delete ou falha, ou apaga/corrompe histórico, ou deixa registros sem destino; o schema atual exige política relacional explícita (`prisma/schema.prisma:108-109,125-126`). |
| 12 | Usaria somente `https` como defesa para URL de saída. | ADR-004 e FDD-CONTRATO-01. | TLS não impede SSRF para serviços internos, loopback, metadata endpoints, DNS rebinding ou redirect para rede privada. A feature cria um request forgery primitive autenticado. |
| 13 | Criaria as 13 classes de erro no arquivo compartilhado, inclusive erros internos do worker com status HTTP 422. | FDD §Matriz e §Integração. | Quatro desses erros não são respostas HTTP. Acoplar falha operacional a semântica HTTP produz abstração falsa; o próprio FDD admite que o `statusCode` nunca trafega. |
| 14 | Omitiria `items` do payload e orientaria o cliente B2B a buscar o detalhe em `GET /orders/:id`. | FDD §Payload, DEC-24. | A rota está depois de `router.use(authenticate)` (`src/modules/orders/order.routes.ts:12-17`) e o JWT não representa cliente (`src/middlewares/auth.middleware.ts:6-25`). O consumidor declarado não consegue completar o fluxo. |
| 15 | Trataria `WEBHOOK_NOT_FOUND` como “id de outro cliente”, implementando ownership implícito. | FDD-ERR-04. | ADR-008 abre o CRUD a qualquer role interna e não existe relação user/customer (`prisma/schema.prisma:25-54`). O ramo pressupõe uma autorização que o pacote explicitamente não criou. |

## 3. O que falta para estimar

Não consigo sustentar a estimativa de três sprints. Ela aparece como requisito no
PRD, mas não vem acompanhada de tamanho de equipe, duração do sprint, capacidade,
divisão de trabalho ou premissas técnicas.

Antes de estimar, faltam:

- fechar os bloqueios de contrato e semântica dos itens 1–14 acima;
- schema completo e estratégia de migration/rollback para os quatro models;
- modelo de concorrência, recovery de `PROCESSING`, atomicidade de DLQ/replay e
  garantia real de ordering;
- política de secret at rest, formato da assinatura e defesa SSRF;
- batch/concurrency e SLO verificável sob 50 mudanças/min;
- destino das métricas e solução de deploy/supervisão/health do segundo processo;
- decisão sobre cliente HTTP e estratégia de teste de rede, timeout, fake clock,
  retries e crash recovery;
- volume esperado de endpoints, fan-out por transição, payloads e retenção de
  outbox/deliveries/DLQ para dimensionar banco e índices;
- capacidade e disponibilidade de quem fará a revisão de segurança e eventual
  tempo de correção após a revisão.

Com as decisões fechadas, eu quebraria a estimativa ao menos em migration/model,
CRUD/contratos, publisher transacional, worker/resiliência, segurança, observabilidade
e operação/deploy. No estado atual, “três sprints” é compromisso de calendário,
não uma estimativa derivável da especificação.

## 4. A documentação descreve o código que existe?

| Afirmação | Onde | Confere com o disco? | Evidência (arquivo:linha) |
|---|---|---|---|
| O banco atual é MySQL. | ADR-001; FDD §Dependências | Sim. | `prisma/schema.prisma:5-8`; `docker-compose.yml:1-3` |
| Seis dos sete models usam UUID `Char(36)` e a sequência usa `Int`. | ADR-001; FDD §Identificador | Sim. | `prisma/schema.prisma:25-26,40-41,56-57,74-75,99-100,116-117,133-137` |
| `changeStatus` inteiro roda em transação interativa. | ADR-007; FDD §Integração | Sim. | `src/modules/orders/order.service.ts:126-178` |
| `TxClient` existe e os helpers de estoque recebem o `tx`. | ADR-007; FDD assinatura do publisher | Parcial: existe, mas é alias local não exportado, portanto o publisher novo não pode importá-lo como tipo público. | `src/modules/orders/order.service.ts:24,204-207,233-236` |
| Update de order e insert de histórico são incondicionais; estoque é condicional. | ADR-007 | Sim. | `src/modules/orders/order.service.ts:151-167`; `src/modules/orders/order.status.ts:29-36` |
| Criação do pedido também grava histórico, fora de `changeStatus`. | ADR-007; FDD §Riscos | Sim. | `src/modules/orders/order.service.ts:95-113,126-178` |
| Todo router de orders exige autenticação. | ADR-001; RFC/PRD sobre baseline | Sim. | `src/modules/orders/order.routes.ts:12-17` |
| O JWT contém usuário interno, sem `customerId`, e só há `ADMIN`/`OPERATOR`. | ADR-008 | Sim. | `src/middlewares/auth.middleware.ts:6-25,40-43`; `prisma/schema.prisma:11-14` |
| `Customer` não possui credencial nem relação com `User`. | ADR-008 | Sim. | `prisma/schema.prisma:25-54` |
| `requireRole('ADMIN')` já tem precedente. | ADR-008; FDD §Integração | Sim. | `src/middlewares/auth.middleware.ts:49-60`; `src/modules/users/user.routes.ts:12-17` |
| O padrão de módulos não é uniforme; auth reutiliza repository de users. | ADR-006 | Sim. | `src/modules/auth/auth.service.ts:4-8,21-25`; `src/modules/orders/order.status.ts:1-37` |
| Pino não é usado “no projeto inteiro”; os imports estão na infraestrutura. | ADR-006 | Sim. | `src/server.ts:1-4`; `src/middlewares/request-logger.middleware.ts:1-3`; `src/middlewares/error.middleware.ts:1-5` |
| O logger tem factory, singleton e seis redact paths. | ADR-002/004; FDD §Observabilidade | Sim. | `src/shared/logger/index.ts:4-18,32` |
| O `requestId` fica em `req.id` e não chega hoje ao `OrderService.changeStatus`. | FDD §Tracing | Parcial: a origem existe, mas o delta documentado não altera controller/service para transportá-lo. | `src/middlewares/request-logger.middleware.ts:5-8`; `src/modules/orders/order.controller.ts:38-42`; `src/modules/orders/order.service.ts:126-130` |
| `createPrismaClient` permite cliente próprio no worker. | ADR-002; FDD §Integração | Sim. | `src/config/database.ts:4-10` |
| O pool foi explicitamente configurado. | Premissa negada em ADR-002/FDD | Não; a documentação acerta ao marcar a divergência. | `src/config/database.ts:4-8`; `.env.example:1-14` |
| O projeto lê ambiente de forma centralizada e fail-fast. | FDD §Configuração | Sim. | `src/config/env.ts:3-27` |
| O middleware de erro já suporta novas subclasses de `AppError` sem alteração. | ADR-006; FDD §Integração | Sim para subclasses normais. | `src/middlewares/error.middleware.ts:14-24` |
| Uma subclasse de `ValidationError` pode emitir código `WEBHOOK_*` sem mudar código existente. | FDD §Matriz/Integração | Não. | `src/shared/errors/http-errors.ts:9-12`; `src/shared/errors/app-error.ts:3-13`; `src/middlewares/validate.middleware.ts:25-32` |
| O registro de domínio novo passa por `Controllers`, `buildControllers` e `buildApiRouter`. | ADR-006; FDD §Integração | Sim. | `src/routes/index.ts:13-30`; `src/app.ts:26-52,66-67` |
| O cadastro aninhado pode apenas “pendurar-se” no router de customers sem outro delta. | FDD §Integração | Não como descrito; o builder aceita só `CustomerController`. | `src/modules/customers/customer.routes.ts:10-24`; `src/routes/index.ts:21-28` |
| A API monta `/api/v1`, `/health`, 404 e error middleware na ordem declarada. | FDD §Integração | Sim. | `src/app.ts:55-73` |
| O cliente B2B pode buscar detalhes omitidos do webhook em `GET /orders/:id`. | FDD §Payload, DEC-24 | Não com o modelo de identidade atual. | `src/modules/orders/order.routes.ts:12-17`; `src/middlewares/auth.middleware.ts:6-25,27-46`; `prisma/schema.prisma:40-54` |
| O payload mapeia `order_id`, `order_number`, `customer_id` e `total_cents` para campos reais. | FDD §Mapeamento | Sim. | `prisma/schema.prisma:74-85` |
| `from_status`/`to_status` existem no histórico. | FDD §Mapeamento | Sim. | `prisma/schema.prisma:116-123` |
| Há seis status e oito transições permitidas. | RFC/ADR-007/FDD | Não: são seis status e sete transições (2 + 2 + 2 + 1). | `prisma/schema.prisma:16-23`; `src/modules/orders/order.status.ts:3-10` |
| A única migration atual segue cabeçalhos Prisma e contém tabelas, índices e FKs. | ADR-001; FDD §Migration | Sim. | `prisma/migrations/20260519182739_init/migration.sql:1-13,109-125` |
| Os testes existentes cobrem `PATCH /orders/:id/status`. | ADR-007; FDD §Aceite | Sim. | `tests/orders.test.ts:59-87,89-107,109-132,134-160` |
| O projeto já tem scripts para subir e operar o worker. | ADR-002 reconhece ausência; FDD requer entry-point nova | Não. | `package.json:10-20`; `docker-compose.yml:1-28` |

Conclusão desta conferência: os documentos descrevem corretamente a maior parte
dos ganchos existentes, mas extrapolam o que esses ganchos oferecem em quatro
pontos relevantes: tipo transacional não exportado, propagação de `requestId`,
erro Zod com código específico e montagem da rota aninhada. Além disso, o disco
não oferece nenhuma base operacional para o segundo processo.

## 5. Três coisas que você mudaria

1. **Fechar um contrato executável de semântica e falha.** Resolver tentativas
   versus retries, momento da DLQ, recovery de `PROCESSING`, ordering durante
   backoff, identidade no replay e atomicidade. Hoje esses pontos permitem perda,
   duplicata não deduplicável e implementações incompatíveis.
2. **Publicar o schema completo e o security contract.** Definir os quatro models
   com FKs/delete behavior, ciclo de vida de endpoint, armazenamento/geração de
   secret, bytes e encoding da assinatura, e política anti-SSRF.
3. **Substituir números de reunião por um plano verificável de capacidade e
   operação.** Definir batch/concurrency, SLO sob 50/min, métricas, deploy,
   health/restart do worker e estratégia de testes; então refazer a estimativa de
   três sprints com capacidade real da equipe.

## 6. O que o review anterior não pegou

### Achados ausentes de `.planning/09-review.md`

1. **A máquina de estados do worker perde evento em crash.** O FDD manda marcar
   `PROCESSING` e buscar somente `PENDING`, mas não define lease nem recuperação.
   Uma queda nesse intervalo deixa a linha presa e invalida at-least-once. O
   review anterior discute a aritmética de retry, mas não esta falha de segurança
   de entrega.
2. **O ordering por pedido é falso mesmo com single-worker.** Um evento em backoff
   deixa de ser elegível; o seguinte, do mesmo `order_id`, pode ultrapassá-lo.
   Ordenar os elegíveis por `createdAt` não resolve. O review confere a origem da
   fala, mas não testa a garantia contra o algoritmo descrito.
3. **Replay quebra a chave de deduplicação.** O FDD cria nova outbox e define
   `event_id` como o id da linha. Assim, o replay do mesmo snapshot recebe outro
   `X-Event-Id`, contrariando a finalidade de ADR-005. O review detecta que “linha
   nova” não tem origem, mas não aponta a quebra funcional de dedup.
4. **`PROCESSING`, DLQ e replay não têm atomicidade/concurrency definida.** Não há
   transação descrita para inserir na DLQ e marcar a origem, nem lock/CAS para
   impedir dois replays simultâneos. O 409 contra replay repetido não basta sem
   mecanismo de concorrência.
5. **As classes de erro pedidas são incompatíveis com as bases existentes.**
   `ValidationError`, `NotFoundError` e `ForbiddenError` fixam o código
   (`src/shared/errors/http-errors.ts:9-30`), e `errorCode` é readonly
   (`src/shared/errors/app-error.ts:3-13`). Logo várias das 13 subclasses não
   conseguem emitir `WEBHOOK_*` como especificado. Além disso, Zod sempre vira
   `VALIDATION_ERROR` (`src/middlewares/validate.middleware.ts:25-32`).
6. **O delta de rotas não fecha o endpoint aninhado.** `buildCustomerRouter`
   recebe só `CustomerController` (`src/modules/customers/customer.routes.ts:10-24`);
   o FDD não explica como `/customers/:customerId/webhooks` recebe o controller
   novo.
7. **O tipo transacional citado não é público e o `requestId` não chega ao
   service.** `TxClient` é alias local (`src/modules/orders/order.service.ts:24`);
   `changeStatus` recebe apenas id, input e userId
   (`src/modules/orders/order.service.ts:126-130`), embora o publisher exija
   `requestId`. O controller também não o repassa
   (`src/modules/orders/order.controller.ts:38-42`).
8. **O schema dos quatro models não é implementável a partir do texto.** Faltam
   tipos/tamanhos/nulabilidade, FKs, uniques e `onDelete` de três models. As
   relações exigirão também campos inversos nos models existentes, cujas relações
   atuais estão em `prisma/schema.prisma:34-35,50,87-90`, delta não listado.
9. **`DELETE` de endpoint é incompatível com “histórico permanece” sem lifecycle
   definido.** Hard delete, soft delete, pendências, DLQ e secret têm efeitos
   diferentes; nenhuma política foi escolhida.
10. **O security contract de saída está incompleto.** Não há proteção SSRF,
    política de redirects/DNS/IP/porta, armazenamento reversível da secret,
    key management, nem encoding/canonicalização de `X-Signature`. Exigir apenas
    `https` não torna segura uma URL controlada por usuário.
11. **A observabilidade e a operação não têm integração real.** Não existe
    backend/exporter de métricas nas dependências (`package.json:25-52`), script
    para worker (`package.json:10-20`) nem serviço/supervisor no compose
    (`docker-compose.yml:1-28`). As seis métricas e o segundo processo não têm
    caminho de produção especificado.
12. **ADR e FDD divergem sobre retenção da origem na DLQ.** O ADR diz que o evento
    sai da outbox; o FDD mantém `FAILED`. Isso muda schema, consulta, retenção e
    replay, não apenas redação.
13. **Não existe caminho administrativo para descobrir IDs da DLQ.** O único
    contrato é replay por `:id`, embora a matriz de erro mencione uma consulta da
    fila inexistente. Sem acesso direto ao banco, RF-08 não é operável.
14. **DEC-24 depende de uma rota inacessível ao público declarado.** O FDD omite
    `items` porque o cliente buscaria `GET /orders/:id`, mas o router exige JWT
    interno (`src/modules/orders/order.routes.ts:12-17`) e `Customer` não possui
    identidade (`prisma/schema.prisma:40-54`).
15. **`shouldEmitWebhookEvent` não participa do fluxo que justificaria sua
    criação.** A integração exige a função, enquanto o algoritmo filtra somente
    endpoints e status assinados; sua semântica e necessidade ficaram órfãs.

### Pontos do review anterior que não são problema real para começar a feature

- **README ainda ser o enunciado** reprova o entregável acadêmico, mas não cria
  ambiguidade técnica para implementar webhooks. É trabalho documental separado,
  não blocker de engenharia da feature.
- **Fences `{}` para requests sem body e ausência de response de sucesso no
  `DELETE 204`** não confundem a implementação: o texto declara “sem corpo” e 204
  não pode ter corpo. É fragilidade do check FDD-3, não do contrato.
- **Repetição entre RFC, ADR e FDD e fronteira de abstração borrada** aumenta custo
  de leitura, mas não impede implementação quando o conteúdo repetido coincide.
  Eu priorizaria contradições de estado, identidade e segurança.
- **Adicionar redaction de secret sem fala na reunião** é um requisito técnico
  derivado do risco criado pela própria feature, não uma invenção indevida do
  ponto de vista de implementação. Pode precisar de rastreabilidade para o
  desafio, mas removê-lo seria pior e violaria o critério técnico do próprio FDD
  de não registrar secrets.
- **Não expor secret em listagens** também é uma escolha de segurança sensata.
  O problema é faltar uma decisão rastreável, não a regra em si; eu não a
  descartaria só porque a transcrição não a verbalizou.
