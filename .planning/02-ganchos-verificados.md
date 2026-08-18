# 02 — Ganchos declarados, verificados contra o disco

Veredito das 34 linhas de `.planning/02-ganchos-declarados.md`, que permanece
**congelado**: nada foi corrigido lá atrás. As colunas `ID`, `O que foi dito` e
`Localização` são cópia fiel do arquivo declarado; as duas últimas são o
resultado da leitura forense.

Proveniência da verificação — `git rev-parse HEAD` = `ddd8dbc20e14d1d9f8cbf568cf5b608071f55d85`,
`git ls-files | wc -l` = 76, engine `/usr/bin/grep grep (GNU grep) 3.11`. Todo
número de linha veio de comando executado nesta sessão; os comandos e os
recortes literais estão em `.planning/02-codigo.md`.

Vocabulário dos vereditos:

- **CONFIRMADO** — o artefato existe no disco como declarado.
- **DIVERGENTE (DIV-NN)** — existe, mas não como declarado; a diferença está
  registrada em `.planning/02-codigo.md` §5.
- **[ausente no código]** — a busca não encontrou nada.
- **[não é código]** — menção conceitual, sem alvo no repositório.

| ID | O que foi dito | Localização | Veredito | Evidência (arquivo:linha) |
|---|---|---|---|---|
| GAN-01 | Rota `GET /orders`, hoje usada pelos clientes em polling | `[09:00] Marcos` | DIVERGENTE (DIV-08) | Rota existe: `src/modules/orders/order.routes.ts`:16, montada em `/api/v1/orders` por `src/routes/index.ts`:28 e `src/app.ts`:67. Mas o router inteiro exige JWT interno: `src/modules/orders/order.routes.ts`:14 e `src/middlewares/auth.middleware.ts`:41 |
| GAN-02 | Tabela/entidade `orders`, atualizada na mudança de status | `[09:04] Bruno` | CONFIRMADO | `prisma/schema.prisma`:96 (`@@map("orders")`), `prisma/migrations/20260519182739_init/migration.sql`:50; update em `src/modules/orders/order.service.ts`:158 |
| GAN-03 | Tabela `order_status_history`, alimentada na mesma transação | `[09:04] Bruno` | CONFIRMADO | `prisma/schema.prisma`:130 (`@@map("order_status_history")`), `prisma/migrations/20260519182739_init/migration.sql`:87; insert dentro do `$transaction` em `src/modules/orders/order.service.ts`:159 |
| GAN-04 | Campo `stock_quantity` dos produtos, decrementado na mesma transação | `[09:04] Bruno` | DIVERGENTE (DIV-01) | Campo é `stockQuantity`: `prisma/schema.prisma`:62 e coluna homônima em `prisma/migrations/20260519182739_init/migration.sql`:38; decremento em `src/modules/orders/order.service.ts`:228 |
| GAN-05 | Existe um "service de orders" onde o disparo entraria | `[09:03] Larissa` | CONFIRMADO | `src/modules/orders/order.service.ts`:26 (`export class OrderService`) |
| GAN-06 | Método `changeStatus` como ponto de integração crítico | `[09:40] Bruno` | CONFIRMADO | `src/modules/orders/order.service.ts`:126 |
| GAN-07 | Objeto/arquivo `order.service` que chamaria a nova função | `[09:41] Bruno` | CONFIRMADO | `src/modules/orders/order.service.ts`:26; instanciado em `src/app.ts`:43 |
| GAN-08 | Transação atual do changeStatus faz update na order, insere no history e atualiza estoque | `[09:40] Bruno` | DIVERGENTE (DIV-04) | Update e history incondicionais: `src/modules/orders/order.service.ts`:158 e :159. Estoque é condicional: `src/modules/orders/order.service.ts`:151 e :154, com os predicados em `src/modules/orders/order.status.ts`:29 e :33 |
| GAN-09 | Banco MySQL já existente, reaproveitado para a outbox | `[09:07] Diego` | CONFIRMADO | `prisma/schema.prisma`:6 (`provider = "mysql"`); serviço `mysql` em `docker-compose.yml`:2–3 (`image: mysql:8.0`) |
| GAN-10 | MySQL não tem listener nativo tipo NOTIFY/LISTEN do Postgres | `[09:09] Diego` | [não é código] | Afirmação sobre capacidade do SGBD; nenhum artefato do repositório a implementa ou a contradiz |
| GAN-11 | Suporte a trigger no banco já existe hoje | `[09:09] Diego` | [ausente no código] | `grep -rniE 'trigger' src/ prisma/ tests/ package.json` retorna vazio (rc=1); `prisma/migrations/20260519182739_init/migration.sql` tem só `CREATE TABLE`, `CREATE INDEX` e `ADD FOREIGN KEY` em 125 linhas. Registrado como DIV-05 |
| GAN-12 | Entry-point `src/server.ts` já existente, usada como modelo para a nova entry | `[09:11] Larissa` | CONFIRMADO | `src/server.ts`:6 (`async function bootstrap`), :9 (`app.listen`), :20–21 (handlers de SIGINT/SIGTERM) |
| GAN-13 | Prisma client já em uso, a ser reaproveitado pelo worker | `[09:11] Bruno` | CONFIRMADO | `src/config/database.ts`:4 (`createPrismaClient`) e :10 (singleton `prisma`); injetado em `src/app.ts`:43 |
| GAN-14 | Pool de conexão do Prisma já configurado no projeto | `[09:29] Diego` | DIVERGENTE (DIV-06) | `src/config/database.ts`:5–7 passa apenas `log` ao `PrismaClient`; nenhuma ocorrência de `connection_limit`/`pool` em `src/`, `prisma/`, `.env.example` ou `docker-compose.yml` |
| GAN-15 | Variável `DATABASE_URL` compartilhada entre API e worker | `[09:30] Bruno` | CONFIRMADO | `src/config/env.ts`:7 (obrigatória no schema Zod); `prisma/schema.prisma`:7 (`env("DATABASE_URL")`); `.env.example`:5 |
| GAN-16 | Padrão de módulos em `src/modules`, cada domínio com controller, service, repository, routes e schemas | `[09:27] Bruno` | DIVERGENTE (DIV-09) | Vale para users/customers/products/orders; `src/modules/auth/` tem 4 arquivos e nenhum repository — reusa `UserRepository` (`src/modules/auth/auth.service.ts`:6), e orders tem o arquivo extra `src/modules/orders/order.status.ts` |
| GAN-17 | Classe `AppError` já existente | `[09:28] Bruno` | CONFIRMADO | `src/shared/errors/app-error.ts`:3; reexportada em `src/shared/errors/index.ts`:1 |
| GAN-18 | Classes de erro específicas `InsufficientStockError` e `InvalidStatusTransitionError` | `[09:28] Bruno` | CONFIRMADO | `src/shared/errors/http-errors.ts`:55 e :45; usadas em `src/modules/orders/order.service.ts`:223 e :148 |
| GAN-19 | Convenção de códigos de erro `INSUFFICIENT_STOCK`, `INVALID_STATUS_TRANSITION` | `[09:28] Bruno` | CONFIRMADO | `src/shared/errors/http-errors.ts`:59 e :49; o código é propagado ao corpo da resposta em `src/middlewares/error.middleware.ts`:18 |
| GAN-20 | Logger Pino já presente no projeto inteiro | `[09:29] Bruno` | DIVERGENTE (DIV-13) | Pino existe: `src/shared/logger/index.ts`:14 e :32, dependência em `package.json`:30. Mas `grep -rn "shared/logger" src/` devolve 3 arquivos — `src/server.ts`:4, `src/middlewares/error.middleware.ts`:5, `src/middlewares/request-logger.middleware.ts`:3. Nenhum service, controller ou repository loga |
| GAN-21 | Middleware de erro centralizado que já trata AppError, Zod e Prisma | `[09:29] Bruno` | CONFIRMADO | `src/middlewares/error.middleware.ts`:14 (handler), :15 (`AppError`), :26 (`ZodError`), :37 (`Prisma.PrismaClientKnownRequestError`), :62 (fallback 500); registrado por último em `src/app.ts`:73 |
| GAN-22 | Validação por schema Zod já é o padrão do projeto | `[09:23] Sofia` | CONFIRMADO | `src/middlewares/validate.middleware.ts`:11; aplicado em todas as rotas de orders, `src/modules/orders/order.routes.ts`:16–24 |
| GAN-23 | Padrão de schemas Zod e de códigos de erro citados como reuso | `[09:30] Larissa` | CONFIRMADO | Schemas por módulo com tipo inferido pareado: `src/modules/orders/order.schemas.ts`:18 e :33; códigos de erro em `src/shared/errors/http-errors.ts`:49 e :59 |
| GAN-24 | Autenticação por JWT do sistema, com usuários que representam o cliente | `[09:32] Marcos` | DIVERGENTE (DIV-07) | JWT existe: `src/middlewares/auth.middleware.ts`:41, emitido em `src/modules/auth/auth.service.ts`:49. Não há usuário-cliente: `prisma/schema.prisma`:11–14 (`UserRole` = ADMIN, OPERATOR) e :40 (`Customer` sem senha e sem relação com `User`) |
| GAN-25 | JWT atual é do usuário operador, não do cliente | `[09:32] Bruno` | CONFIRMADO | `src/middlewares/auth.middleware.ts`:9 (`role: 'ADMIN' \| 'OPERATOR'`); payload assinado em `src/modules/auth/auth.service.ts`:49 |
| GAN-26 | Role `ADMIN` no JWT | `[09:35] Larissa` | CONFIRMADO | `src/middlewares/auth.middleware.ts`:9 e :42; `prisma/schema.prisma`:12; uso real em `src/modules/users/user.routes.ts`:15 |
| GAN-27 | Helper `requireRole` já existente, a ser reaproveitado | `[09:36] Larissa` | CONFIRMADO | `src/middlewares/auth.middleware.ts`:49; único ponto de uso hoje em `src/modules/users/user.routes.ts`:15 |
| GAN-28 | Rota `GET /orders/:id` para o cliente buscar detalhes do pedido | `[09:43] Diego` | DIVERGENTE (DIV-08) | Rota existe: `src/modules/orders/order.routes.ts`:17 → `src/modules/orders/order.controller.ts`:19. Mas está atrás de `authenticate` (`src/modules/orders/order.routes.ts`:14), que só aceita JWT de usuário interno |
| GAN-29 | Campos `order_number` e `total_cents` da order | `[09:43] Diego` | DIVERGENTE (DIV-02) | Colunas são `orderNumber` e `totalCents`: `prisma/schema.prisma`:76 e :81, `prisma/migrations/20260519182739_init/migration.sql`:52 e :57. Idem `from_status`/`to_status` → `fromStatus`/`toStatus` em `prisma/schema.prisma`:119–120 |
| GAN-30 | Campo `total_cents` citado como campo básico da order | `[09:43] Diego` | DIVERGENTE (DIV-03) | Campo é `totalCents Int`: `prisma/schema.prisma`:81 e `prisma/migrations/20260519182739_init/migration.sql`:57; existem também `subtotalCents` e `discountCents` (`prisma/schema.prisma`:79–80) |
| GAN-31 | Status de pedido PAID, PROCESSING, SHIPPED | `[09:12] Larissa` | CONFIRMADO | `prisma/schema.prisma`:18–20; a sequência PAID → PROCESSING → SHIPPED é permitida em `src/modules/orders/order.status.ts`:5–6 |
| GAN-32 | Status de pedido SHIPPED e DELIVERED | `[09:33] Marcos` | CONFIRMADO | `prisma/schema.prisma`:20–21; transição SHIPPED → DELIVERED em `src/modules/orders/order.status.ts`:7, e DELIVERED é terminal em :8 |
| GAN-33 | Runtime Node, com processo separado implicando nova instância de client | `[09:30] Bruno` | CONFIRMADO | `package.json`:8 (`"node": ">=20"`), :6 (`"type": "module"`), :11–13 (scripts `dev`/`start`); factory disponível para instância própria em `src/config/database.ts`:4 |
| GAN-34 | Padrão de id do projeto: tudo é uuid | `[09:51] Larissa` | DIVERGENTE (DIV-10) | 6 de 7 models usam `String @id @default(uuid()) @db.Char(36)` (`prisma/schema.prisma`:26, 41, 57, 75, 100, 117). `OrderNumberSequence.id` é `Int @id @default(1)` (`prisma/schema.prisma`:134) |

## Contagem por veredito

| Veredito | Quantidade |
|---|---|
| CONFIRMADO | 21 |
| DIVERGENTE | 11 |
| [ausente no código] | 1 |
| [não é código] | 1 |
| **Total** | **34** |

**CONFIRMADO (21):** GAN-02, 03, 05, 06, 07, 09, 12, 13, 15, 17, 18, 19, 21, 22, 23, 25, 26, 27, 31, 32, 33.

**DIVERGENTE (11):** GAN-01 (DIV-08), GAN-04 (DIV-01), GAN-08 (DIV-04), GAN-14 (DIV-06), GAN-16 (DIV-09), GAN-20 (DIV-13), GAN-24 (DIV-07), GAN-28 (DIV-08), GAN-29 (DIV-02), GAN-30 (DIV-03), GAN-34 (DIV-10).

**[ausente no código] (1):** GAN-11.

**[não é código] (1):** GAN-10.

As divergências DIV-11 (segundo produtor de `order_status_history`), DIV-12
(`PENDING` e `CANCELLED` não citados na reunião) e DIV-14 (ausência de
precedente transacional em repository) não derivam de um gancho declarado — são
achados da leitura do código e vivem só em `.planning/02-codigo.md` §5.
