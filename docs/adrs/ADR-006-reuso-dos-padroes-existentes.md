# ADR-006 — Reuso dos padrões existentes do projeto no módulo de webhooks

## Status
Aceito — 2026-08-19 · decidido em reunião técnica de [09:00]–[09:53]

## Contexto

Perto do fim da reunião, Bruno fez o inventário do que o projeto já tem, para que
a feature não inventasse forma nova: `[09:27] Bruno` — "Cada domínio é um módulo
em src/modules com controller, service, repository, routes e schemas."; `[09:29]
Bruno` — "O middleware de erro centralizado já trata AppError, Zod e Prisma." e
"E o logger, que é Pino, já tá no projeto inteiro." Larissa transformou o
inventário em decisão na janela seguinte.

O disco confirma a maior parte desse inventário. `AppError` está em
`src/shared/errors/app-error.ts`:3 e é reexportada pelo barril
`src/shared/errors/index.ts`:1; as classes de domínio estendem a classe de status
e não `AppError` diretamente — `InsufficientStockError` em
`src/shared/errors/http-errors.ts`:55 e `InvalidStatusTransitionError` em :45 —
com `errorCode` em `SCREAMING_SNAKE_CASE` (:59 e :49) propagado ao corpo da
resposta por `src/middlewares/error.middleware.ts`:18. A validação por Zod é o
padrão único de entrada (`src/middlewares/validate.middleware.ts`:11), com
schemas e tipos inferidos pareados por módulo
(`src/modules/orders/order.schemas.ts`:18 e :33). O registro de um domínio novo
na árvore de rotas passa por três símbolos nomeáveis: o tipo `Controllers`
(`src/routes/index.ts`:13), `buildControllers` (`src/app.ts`:26) e
`buildApiRouter` (`src/routes/index.ts`:21).

Duas afirmações da reunião, porém, não sobrevivem à leitura do repositório, e
elas mudam o que "seguir o padrão" significa na prática:

- **DIV-09 — o padrão de módulo não é uniforme.** `[09:27] Bruno`: "Cada domínio
  é um módulo em src/modules com controller, service, repository, routes e
  schemas." A regra vale para `users`, `customers`, `products` e `orders`; já
  `src/modules/auth/` tem quatro arquivos e nenhum repository — reusa o
  `UserRepository` de outro módulo (`src/modules/auth/auth.service.ts`:6) — e
  `orders` tem um sexto arquivo fora da lista,
  `src/modules/orders/order.status.ts`. Existem, portanto, pelo menos dois
  precedentes divergentes do "padrão" citado.
- **DIV-13 — Pino não está no projeto inteiro.** `[09:29] Bruno`: "E o logger,
  que é Pino, já tá no projeto inteiro." O logger existe como factory e singleton
  (`src/shared/logger/index.ts`:13 e :32) e a dependência está em
  `package.json`:30, mas é importado em exatamente três arquivos —
  `src/server.ts`:4, `src/middlewares/error.middleware.ts`:5 e
  `src/middlewares/request-logger.middleware.ts`:3. Nenhum service, controller ou
  repository do projeto loga hoje.

## Decisão

O módulo de webhooks é escrito por reuso máximo dos padrões que já existem no projeto, e não por invenção de estrutura própria. Concretamente:

- Webhooks viram um módulo em `src/modules/webhooks` (novo), no mesmo formato dos
  demais domínios — **DEC-11**, fechada por `[09:28] Diego`: "Faz."
- Os erros do módulo estendem a classe de status apropriada de
  `src/shared/errors/http-errors.ts` (precedente literal: `InsufficientStockError`,
  linha 55), são exportados pelo barril `src/shared/errors/index.ts` e caem
  automaticamente no primeiro ramo de `src/middlewares/error.middleware.ts`:15.
- Todos os códigos de erro do módulo levam o prefixo `WEBHOOK_` — **DEC-13**,
  fechada por `[09:29] Larissa`: "Prefixo WEBHOOK_ pra tudo do módulo."
- Entrada validada por Zod com o `validate` existente
  (`src/middlewares/validate.middleware.ts`:11) e schemas num arquivo
  `*.schemas.ts` do módulo, com tipos inferidos pareados, como em
  `src/modules/orders/order.schemas.ts`:18 e :33.
- Rotas registradas pelos três símbolos de `src/routes/index.ts`:13 e :21 e
  `src/app.ts`:26; listagens usando `paginated`
  (`src/shared/http/response.ts`:22) e recurso único devolvido cru, como faz
  `src/modules/orders/order.controller.ts`:23.
- Log pelo singleton de `src/shared/logger/index.ts`:32 (ou pela factory
  `createLogger`, linha 13, no processo do worker — ADR-002), no formato Pino de
  dois argumentos com evento em `snake_case`.

Falas que fecham, ambas em `[09:30] Larissa`: "Decisão: reuso máximo do que já
existe. AppError, Pino, error middleware, padrão de módulos" — **DEC-15** — e
"padrão de schemas Zod, padrão de códigos de erro." — **DEC-16**.

## Alternativas Consideradas

### Módulo standalone fora de `src/modules`

Tratar webhooks como subsistema próprio, com estrutura interna livre, fora da
convenção de domínio do projeto.

- `(alternativa plausível, não discutida na reunião)`
- **Motivo do descarte:** o custo está no código: um domínio fora de
  `src/modules` não entra na árvore de rotas pelos três símbolos que a composição
  do projeto exige (`Controllers` em `src/routes/index.ts`:13,
  `buildControllers` em `src/app.ts`:26 e `buildApiRouter` em
  `src/routes/index.ts`:21) — a montagem passaria a ter duas formas, e o
  `buildApiRouter` deixaria de ser o único lugar onde um domínio novo aparece.

### Hierarquia de erro própria do módulo, estendendo `AppError` diretamente

Criar um `WebhookError` base para a feature, com o mapeamento de status HTTP
resolvido dentro do módulo.

- `(alternativa plausível, não discutida na reunião)`
- **Motivo do descarte:** o mapeamento automático para status HTTP depende de a
  classe herdar a camada de status (`ConflictError`, `UnprocessableEntityError`,
  etc.) de `src/shared/errors/http-errors.ts`; estender `AppError` direto obriga
  a fixar `statusCode` à mão em cada erro novo, e nenhum erro de domínio do
  projeto faz isso hoje.

### Manter os códigos de erro sem prefixo, no formato já vigente

Nomear os erros do módulo como `INVALID_URL`, `DELIVERY_FAILED` etc., seguindo
literalmente o formato de `INSUFFICIENT_STOCK` e `INVALID_STATUS_TRANSITION`.

- Quem levantou e quando: `[09:28] Bruno`, ao citar a convenção existente de
  códigos.
- **Motivo do descarte:** `[09:29] Larissa` — "Prefixo WEBHOOK_ pra tudo do
  módulo." A reunião optou por poder identificar a origem do erro pelo código
  (DEC-13).

## Consequências

### Positivas

- Nenhuma alteração no middleware de erro: basta o erro do módulo estender a
  classe de status para cair no ramo `err instanceof AppError`
  (`src/middlewares/error.middleware.ts`:15) e ganhar o envelope
  `{ error: { code, message, details? } }` sem código novo.
- O domínio novo entra na árvore de rotas por três pontos existentes e
  explícitos (`src/routes/index.ts`:13 e :21, `src/app.ts`:26) — sem decorator,
  sem container, sem varredura de diretório.
- Validação, paginação e formato de resposta vêm prontos
  (`src/middlewares/validate.middleware.ts`:11,
  `src/shared/http/response.ts`:22), o que reduz superfície nova de código exposta
  à revisão de segurança reservada para o fim da entrega (`[09:46] Sofia`).
- O prefixo `WEBHOOK_` torna a origem de qualquer erro do módulo legível no corpo
  da resposta, que já propaga `errorCode`
  (`src/middlewares/error.middleware.ts`:18).

### Negativas

- **"Seguir o padrão de módulos" não é instrução unívoca (DIV-09).** Há pelo
  menos dois precedentes divergentes no próprio repositório —
  `src/modules/auth/` sem repository (`src/modules/auth/auth.service.ts`:6) e
  `src/modules/orders/order.status.ts` como sexto arquivo. Quem implementar o
  módulo de webhooks escolhe qual precedente seguir, e essa escolha não está na
  ata: o custo é discussão de revisão, não previsibilidade.
- **Herdar "Pino no projeto inteiro" é herdar algo que não existe (DIV-13).** O
  módulo de webhooks precisa logar entrega, falha, retentativa e envio para a
  DLQ — e vai ser o primeiro service do projeto a logar. Os únicos precedentes de
  chamada são de infraestrutura (`src/server.ts`:4,
  `src/middlewares/error.middleware.ts`:5,
  `src/middlewares/request-logger.middleware.ts`:3), então o formato de log dentro
  de um service é convenção nova, decidida durante a implementação.
- O reuso só cobre a face HTTP. O worker de ADR-002 não serve HTTP, então nem
  `errorMiddleware` nem `validate` valem lá: a metade do "padrão" que o módulo
  herda não protege o caminho de entrega, que é justamente onde a feature falha
  em produção. Tratamento de erro e validação no worker são código novo.
- O prefixo `WEBHOOK_` (DEC-13) cria uma segunda convenção de nomeação de
  `errorCode` convivendo com a existente sem prefixo — `INSUFFICIENT_STOCK` e
  `INVALID_STATUS_TRANSITION` (`src/shared/errors/http-errors.ts`:59 e :49)
  continuam como estão. O projeto passa a ter duas regras, e a diferença entre
  elas é a data em que o código foi escrito.
- O `requestId` que correlaciona log e resposta é gerado no middleware HTTP
  (`src/middlewares/request-logger.middleware.ts`:6–8); o worker roda fora desse
  caminho, então a correlação entre o request que criou o evento e a entrega que
  o worker fez não existe de graça — é trabalho novo.
