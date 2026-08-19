# ADR-008 — Modelo de autorização do módulo de webhooks

## Status
Aceito — 2026-08-19 · decidido em reunião técnica de [09:00]–[09:53]

## Contexto

Definidos os endpoints de cadastro, edição, listagem e replay, faltava dizer
quem pode chamá-los e de onde sai o `customer_id` do webhook. Marcos partiu da
premissa de que o cliente se autenticaria como ele mesmo: `[09:32] Marcos` —
"autenticado com JWT do nosso sistema. A gente tem usuários que representam o
cliente".

Bruno corrigiu a premissa na mesma janela — o JWT atual é do usuário operador, e
não do cliente (`[09:32] Bruno`) — e o repositório confirma a correção de forma
mais dura do que a reunião registrou (**DIV-07**, gravidade Alta): não existe
usuário que represente cliente. O enum `UserRole` tem exatamente `ADMIN` e
`OPERATOR` (`prisma/schema.prisma`:11–14), e `Customer`
(`prisma/schema.prisma`:40–54) é um model sem senha, sem papel e sem qualquer
relação com `User` — não há por onde autenticar um cliente. O `authenticate`
(`src/middlewares/auth.middleware.ts`:27) só sabe verificar o JWT interno,
assinado em `src/modules/auth/auth.service.ts`:49 com o payload
`{ sub, email, role }`, e o tipo `AuthUser`
(`src/middlewares/auth.middleware.ts`:9) fecha o universo de papéis nos mesmos
dois valores. Ou seja: derivar o `customer_id` de um JWT seria derivá-lo de um
token que não carrega cliente nenhum — o disco não deixa a alternativa em pé.

Do lado do que já existe para reusar, a autorização por papel está pronta:
`requireRole` é uma factory variádica em
`src/middlewares/auth.middleware.ts`:49, com uso literal hoje em
`src/modules/users/user.routes.ts`:15, e nenhum dos dois middlewares responde
diretamente — ambos delegam o corpo do erro ao middleware central
(`src/middlewares/error.middleware.ts`:14). Larissa levantou explicitamente a
pergunta do papel exigido no replay em `[09:35] Larissa`, e Sofia trouxe o
requisito de auditoria: `[09:36] Sofia` — "o endpoint de admin tem que logar quem
fez o replay, pra auditoria".

## Decisão

O módulo usa o mecanismo de autenticação que já existe, sem papel novo e sem
identidade de cliente:

- Os endpoints de configuração de webhook são autenticados normalmente pelo JWT
  interno, e o `customer_id` é informado explicitamente na requisição — nunca
  derivado do token. **DEC-17**, fechada por `[09:32] Larissa`: "Então é endpoint
  autenticado normal, e o customer_id é passado no body ou no path. Não vem do
  JWT." Entre body e path a reunião não escolheu (`RFC-QA-01` permanece aberta);
  a resolução provisória adotada no pacote é o path,
  `POST /customers/:customerId/webhooks`, por coerência com o
  `GET /orders/:id` já existente (`src/modules/orders/order.routes.ts`:17).
- O replay de item da DLQ exige papel `ADMIN` e reaproveita o helper existente:
  `requireRole('ADMIN')` (`src/middlewares/auth.middleware.ts`:49) composto
  depois de `authenticate` (linha 27), como já se faz em
  `src/modules/users/user.routes.ts`:15. **DEC-19**, fechada por
  `[09:36] Larissa`: "Decidido, role ADMIN obrigatório no replay e a gente
  reaproveita o requireRole que já existe."
- O CRUD de configuração de webhook fica aberto a qualquer role autenticada por
  enquanto. **DEC-20**, fechada por `[09:37] Sofia`: "Por enquanto sim."

## Alternativas Consideradas

### `customer_id` derivado implicitamente do JWT

O cliente se autenticaria com um token próprio e o `customer_id` sairia do
payload, sem aparecer no contrato do endpoint.

- Quem levantou e quando: `[09:32] Marcos` — "autenticado com JWT do nosso
  sistema. A gente tem usuários que representam o cliente".
- **Motivo do descarte:** `[09:32] Larissa` — "Não vem do JWT." A razão dita foi
  a correção de Bruno na mesma janela: o JWT atual é do usuário operador, não do
  cliente (`[09:32] Bruno`). O código sustenta o descarte de forma independente
  (DIV-07): `UserRole` só tem `ADMIN` e `OPERATOR`
  (`prisma/schema.prisma`:11–14) e `Customer` não tem senha nem relação com
  `User` (`prisma/schema.prisma`:40–54), então não existe token de cliente de
  onde derivar o campo (REC-09).

### CRUD de configuração restrito a `ADMIN`

Exigir papel administrativo também para criar, editar, listar e remover webhook,
e não apenas para o replay.

- Quem levantou e quando: `[09:35] Larissa`, ao perguntar qual papel seria
  exigido; respondido por Sofia em `[09:37]`.
- **Motivo do descarte:** `[09:37] Sofia` — "Por enquanto sim. Mais pra frente a
  gente pode endurecer." O endurecimento do controle de acesso do CRUD foi
  adiado, não adotado (REC-14).

### Papel novo no sistema para representar o cliente

Acrescentar um terceiro valor ao universo de papéis, com credencial emitida para
o cliente externo.

- `(alternativa plausível, não discutida na reunião)`
- **Motivo do descarte:** o custo está fora do módulo: qualquer papel além de
  `ADMIN` e `OPERATOR` obriga a mexer no tipo `AuthUser`
  (`src/middlewares/auth.middleware.ts`:6) **e** no enum `UserRole`
  (`prisma/schema.prisma`:11), com migration, além de dar identidade autenticável
  ao `Customer`, que hoje não tem senha (`prisma/schema.prisma`:40–54).

## Consequências

### Positivas

- Zero código novo de autenticação e autorização: `authenticate`
  (`src/middlewares/auth.middleware.ts`:27) e `requireRole`
  (`src/middlewares/auth.middleware.ts`:49) já existem e têm precedente literal
  de composição em `src/modules/users/user.routes.ts`:15.
- Os erros de acesso do módulo saem no mesmo envelope do resto da API, porque
  ambos os middlewares chamam `next(err)` com `UnauthorizedError` /
  `ForbiddenError` e o corpo é montado por
  `src/middlewares/error.middleware.ts`:14.
- O `customer_id` explícito no contrato deixa o escopo do recurso legível na
  própria requisição, sem depender de um token que não carrega essa informação
  (DEC-17 sustentado por DIV-07).
- O replay administrativo pode registrar o autor sem nada novo: `req.user` já
  está populado pelo `authenticate`
  (`src/middlewares/auth.middleware.ts`:12–17 e :42), que é o dado exigido pela
  auditoria pedida em `[09:36] Sofia`.

### Negativas

- Qualquer usuário autenticado — `ADMIN` ou `OPERATOR`, os dois únicos papéis de
  `src/middlewares/auth.middleware.ts`:9 — pode criar, editar, listar e remover
  webhook de **qualquer** customer, porque o `customer_id` vem do request e não
  do token, e não há no modelo nada que ligue o usuário autenticado a um cliente
  (`prisma/schema.prisma`:40–54). Não existe autorização por dono nesta entrega,
  e o endurecimento foi explicitamente adiado (`[09:37] Sofia`, REC-14).
- A secret devolvida na criação do webhook fica visível para qualquer role
  autenticada que chame o endpoint de cadastro daquele customer — o material
  sensível de ADR-004 herda exatamente o mesmo controle de acesso frouxo desta
  decisão.
- O cliente final não consegue operar a própria configuração: sem credencial de
  cliente no sistema (DIV-07), tanto o cadastro quanto o pedido de nova secret
  (`[09:21] Sofia`: "Endpoint pro cliente conseguir pedir nova secret pela API.")
  passam por um usuário interno. A leitura self-service que a fala de
  `[09:32] Marcos` presumia não existe hoje, e esta ADR não a cria.
- A auditoria do replay (`[09:36] Sofia`) depende de log dentro do módulo, e
  nenhum service do projeto loga hoje — o singleton de
  `src/shared/logger/index.ts`:32 é importado em três arquivos de
  infraestrutura apenas (DIV-13). O requisito de auditoria não tem precedente de
  implementação para copiar.
