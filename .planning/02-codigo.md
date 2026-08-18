# 02 — Mapa forense do código existente

Insumo direto de **FDD-5** (§Integração), **ADR-4** (ADR que referencia artefato
real), **TRK-4** (linhas de tracker com `Fonte=CODIGO`) e **GER-2** (nenhum
caminho inexistente em documento).

Todo caminho, número de linha e símbolo desta página veio de comando executado
nesta sessão sobre o work tree. Nada veio de memória nem do que a reunião disse.
Por construção **nenhum caminho aqui leva o marcador `(novo)`**: este artefato
descreve exclusivamente o que existe em disco.

## 0 · Proveniência

```
$ git rev-parse HEAD
ddd8dbc20e14d1d9f8cbf568cf5b608071f55d85

$ git ls-files | wc -l
76        # idêntico a $BASE; sobe para 78 com os dois artefatos deste bloco

$ ./scripts/verify.sh | head -2
verify.sh v2 — BASE=93e557087e6112aa8628f91024a80542b8af9a44
engine: /usr/bin/grep grep (GNU grep) 3.11

$ git status --porcelain
(vazio no momento da leitura do código)

$ git status --porcelain   # depois de escrever os dois artefatos
?? .planning/02-codigo.md
?? .planning/02-ganchos-verificados.md
```

A linha `engine:` é a mesma que `scripts/verify.sh` imprime, e fixa sob qual
engine de grep os comandos desta página foram validados: GNU grep 3.11 em
`/usr/bin/grep`.

Arquivos de `src/`, `prisma/` e `tests/` foram **lidos**, nunca escritos. O
`git status --porcelain` acima confirma que a leitura não deixou rastro.

---

## 1 · Pontos de acoplamento

### COD-01 · Mudança de status do pedido e ciclo de vida

- **Caminho:** `src/modules/orders/order.service.ts`, `src/modules/orders/order.status.ts`
- **Assinatura/estrutura:**

  `$ awk 'NR>=126 && NR<=158 {printf "%5d  %s\n", NR, $0}' src/modules/orders/order.service.ts`

  ```
    126    async changeStatus(
    127      id: string,
    128      input: UpdateOrderStatusInput,
    129      userId: string,
    130    ): Promise<OrderWithRelations> {
    131      return this.prisma.$transaction(async (tx) => {
    132        const order = await tx.order.findUnique({
    133          where: { id },
    134          include: { items: true },
    135        });
    136        if (!order) throw new NotFoundError('Order');
    137
    138        const from = order.status;
    139        const to = input.toStatus;
    140        if (from === to) {
    141          throw new ConflictError(
    142            `Order is already in ${to} status`,
    143            'INVALID_STATUS_TRANSITION',
    144            { from, to },
    145          );
    146        }
    147        if (!canTransition(from, to)) {
    148          throw new InvalidStatusTransitionError(from, to);
    149        }
    150
    151        if (shouldDebitStock(from, to)) {
    152          await this.debitStock(tx, order.items);
    153        }
    154        if (shouldReplenishStock(from, to)) {
    155          await this.replenishStock(tx, order.items);
    156        }
    157
    158        await tx.order.update({ where: { id }, data: { status: to } });
  ```

  `$ awk 'NR>=1 && NR<=14 {printf "%5d  %s\n", NR, $0}' src/modules/orders/order.status.ts`

  ```
      1  import { OrderStatus } from '@prisma/client';
      2
      3  const transitions: Readonly<Record<OrderStatus, ReadonlyArray<OrderStatus>>> = {
      4    [OrderStatus.PENDING]: [OrderStatus.PAID, OrderStatus.CANCELLED],
      5    [OrderStatus.PAID]: [OrderStatus.PROCESSING, OrderStatus.CANCELLED],
      6    [OrderStatus.PROCESSING]: [OrderStatus.SHIPPED, OrderStatus.CANCELLED],
      7    [OrderStatus.SHIPPED]: [OrderStatus.DELIVERED],
      8    [OrderStatus.DELIVERED]: [],
      9    [OrderStatus.CANCELLED]: [],
     10  };
     11
     12  export function canTransition(from: OrderStatus, to: OrderStatus): boolean {
     13    return transitions[from].includes(to);
     14  }
  ```

- **Padrão que estabelece:** a política de transição é **dados**, não `if`
  espalhado — mora numa tabela `transitions` num arquivo à parte
  (`src/modules/orders/order.status.ts`) e é consultada por funções puras
  (`canTransition`, `shouldDebitStock`, `shouldReplenishStock`). O service
  valida antes de escrever, e todo efeito colateral da transição fica dentro do
  callback de `$transaction`. Qualquer regra nova de ciclo de vida se escreve
  como predicado puro nesse arquivo, não como condicional dentro do service.
- **Gancho para webhooks:** o módulo novo se acopla dentro do callback de
  `this.prisma.$transaction` em `changeStatus`
  (`src/modules/orders/order.service.ts`:131–178), depois de
  `tx.orderStatusHistory.create` (linha 159) e antes do `return refreshed!`
  (linha 177) — é o único lugar do código onde `from` e `to` coexistem já
  validados. O filtro por status decidido na reunião tem símbolo natural em
  `src/modules/orders/order.status.ts`, ao lado de `shouldDebitStock`, mesma
  forma `(from, to) => boolean`. O `tx` do callback é o que permite que a
  escrita da outbox compartilhe atomicidade com o `update` da order.
- **ID:** COD-01

### COD-02 · Controle transacional

- **Caminho:** `src/modules/orders/order.service.ts`
- **Assinatura/estrutura:**

  `$ awk 'NR>=24 && NR<=31 {printf "%5d  %s\n", NR, $0}' src/modules/orders/order.service.ts`

  ```
     24  type TxClient = Prisma.TransactionClient;
     25
     26  export class OrderService {
     27    constructor(
     28      private readonly orders: OrderRepository,
     29      private readonly prisma: PrismaClient,
     30    ) {}
     31
  ```

  `$ awk 'NR>=33 && NR<=45 {printf "%5d  %s\n", NR, $0}' src/modules/orders/order.repository.ts`

  ```
     33    async list(filters: OrderListFilters): Promise<{ items: Order[]; total: number }> {
     34      const where = this.buildWhere(filters);
     35      const [items, total] = await this.prisma.$transaction([
     36        this.prisma.order.findMany({
     37          where,
     38          orderBy: { createdAt: 'desc' },
     39          skip: filters.skip,
     40          take: filters.take,
     41        }),
     42        this.prisma.order.count({ where }),
     43      ]);
     44      return { items, total };
     45    }
  ```

- **Padrão que estabelece:** existem duas formas de `$transaction` no projeto e
  elas não se misturam. A **interativa** (callback recebendo `tx`) só aparece no
  `OrderService`, em `create` (linha 58) e `changeStatus` (linha 131), e é a
  única com escrita multi-tabela; o `tx` é tipado como
  `Prisma.TransactionClient` via o alias local `TxClient` (linha 24) e é passado
  como primeiro parâmetro para os métodos privados (`debitStock`,
  `replenishStock`, `reserveOrderNumber`). A **batch** (array de promises)
  aparece só em repositories, para leitura paginada. Consequência: quem escreve
  em várias tabelas usa o service com `tx` explícito; o repository nunca abre
  transação de escrita. O `PrismaClient` chega ao service por injeção no
  construtor (linha 29), nunca por import do singleton.
- **Gancho para webhooks:** o `tx` já disponível em `changeStatus` é o gancho —
  o `TxClient` do arquivo (`src/modules/orders/order.service.ts`:24) é o tipo
  que qualquer função de escrita da outbox precisa aceitar para participar da
  mesma transação. Se a escrita da outbox for delegada a um repository próprio,
  ela quebra o padrão vigente, porque nenhum repository do projeto hoje aceita
  `tx`; a alternativa alinhada é um método privado do `OrderService` ou uma
  função que receba `TxClient` como primeiro argumento, exatamente como
  `debitStock` (linha 204).
- **ID:** COD-02

### COD-03 · Hierarquia de erros

- **Caminho:** `src/shared/errors/app-error.ts`, `src/shared/errors/http-errors.ts`, `src/shared/errors/index.ts`
- **Assinatura/estrutura:**

  `$ awk 'NR>=1 && NR<=16 {printf "%5d  %s\n", NR, $0}' src/shared/errors/app-error.ts`

  ```
      1  export type ErrorDetails = Record<string, unknown> | unknown[] | undefined;
      2
      3  export class AppError extends Error {
      4    public readonly statusCode: number;
      5    public readonly errorCode: string;
      6    public readonly details: ErrorDetails;
      7
      8    constructor(message: string, statusCode: number, errorCode: string, details?: ErrorDetails) {
      9      super(message);
     10      this.name = 'AppError';
     11      this.statusCode = statusCode;
     12      this.errorCode = errorCode;
     13      this.details = details;
     14      Error.captureStackTrace?.(this, this.constructor);
     15    }
     16  }
  ```

  `$ awk 'NR>=39 && NR<=63 {printf "%5d  %s\n", NR, $0}' src/shared/errors/http-errors.ts`

  ```
     39  export class UnprocessableEntityError extends AppError {
     40    constructor(message: string, code = 'UNPROCESSABLE_ENTITY', details?: ErrorDetails) {
     41      super(message, 422, code, details);
     42    }
     43  }
     44
     45  export class InvalidStatusTransitionError extends ConflictError {
     46    constructor(from: string, to: string) {
     47      super(
     48        `Invalid status transition from ${from} to ${to}`,
     49        'INVALID_STATUS_TRANSITION',
     50        { from, to },
     51      );
     52    }
     53  }
     54
     55  export class InsufficientStockError extends UnprocessableEntityError {
     56    constructor(unavailable: { sku: string; requested: number; available: number }[]) {
     57      super(
     58        'One or more products do not have enough stock',
     59        'INSUFFICIENT_STOCK',
     60        { unavailable },
     61      );
     62    }
     63  }
  ```

- **Padrão que estabelece:** hierarquia de três níveis. `AppError` carrega
  `statusCode` + `errorCode` + `details` e não é lançada diretamente em lugar
  nenhum do código de domínio; a camada intermediária é genérica por status HTTP
  (`BadRequestError` 400, `ValidationError` 400, `UnauthorizedError` 401,
  `ForbiddenError` 403, `NotFoundError` 404, `ConflictError` 409,
  `UnprocessableEntityError` 422); o terceiro nível é semântico de domínio e
  **estende a classe de status**, não `AppError` — `InvalidStatusTransitionError
  extends ConflictError`, `InsufficientStockError extends
  UnprocessableEntityError`. O `errorCode` é `SCREAMING_SNAKE_CASE` fixado no
  construtor da classe de domínio, e `details` transporta o contexto estruturado
  (`{ from, to }`, `{ unavailable }`). Todo consumo passa pelo barril
  `src/shared/errors/index.ts` — nenhum arquivo de `src/modules/` importa
  `http-errors` direto.
- **Gancho para webhooks:** o módulo novo declara suas classes de erro no mesmo
  barril `src/shared/errors/index.ts`, estendendo a classe de status apropriada
  de `src/shared/errors/http-errors.ts` (o precedente exato é
  `InsufficientStockError`, linha 55). Não estender `AppError` diretamente: isso
  é o que garante o mapeamento automático para o status HTTP no COD-04.
- **ID:** COD-03

### COD-04 · Envelope de resposta HTTP

- **Caminho:** `src/middlewares/error.middleware.ts`, `src/shared/http/response.ts`
- **Assinatura/estrutura:**

  `$ awk 'NR>=14 && NR<=37 {printf "%5d  %s\n", NR, $0}' src/middlewares/error.middleware.ts`

  ```
     14  export const errorMiddleware: ErrorRequestHandler = (err, req, res, _next) => {
     15    if (err instanceof AppError) {
     16      res.status(err.statusCode).json({
     17        error: {
     18          code: err.errorCode,
     19          message: err.message,
     20          ...(err.details !== undefined ? { details: err.details } : {}),
     21        },
     22      });
     23      return;
     24    }
     25
     26    if (err instanceof ZodError) {
     27      res.status(400).json({
     28        error: {
     29          code: 'VALIDATION_ERROR',
     30          message: 'Validation failed',
     31          details: formatZodIssues(err),
     32        },
     33      });
     34      return;
     35    }
     36
     37    if (err instanceof Prisma.PrismaClientKnownRequestError) {
  ```

  `$ awk 'NR>=8 && NR<=24 {printf "%5d  %s\n", NR, $0}' src/shared/http/response.ts`

  ```
      8  export type PaginatedResponse<T> = {
      9    data: T[];
     10    pagination: Pagination;
     11  };
     12
     13  export function buildPagination(page: number, pageSize: number, total: number): Pagination {
     14    return {
     15      page,
     16      pageSize,
     17      total,
     18      totalPages: pageSize === 0 ? 0 : Math.ceil(total / pageSize),
     19    };
     20  }
     21
     22  export function paginated<T>(data: T[], page: number, pageSize: number, total: number): PaginatedResponse<T> {
     23    return { data, pagination: buildPagination(page, pageSize, total) };
     24  }
  ```

- **Padrão que estabelece:** duas formas, assimétricas de propósito. **Erro** é
  sempre envelopado: `{ error: { code, message, details? } }`, com `details`
  omitido quando ausente (linha 20). **Sucesso** não é envelopado: o controller
  devolve a entidade crua (`res.status(200).json(order)` em
  `src/modules/orders/order.controller.ts`:23) e só a listagem tem envelope, o
  `{ data, pagination }` de `paginated`. A cadeia de `instanceof` do middleware
  é ordenada — `AppError` primeiro, `ZodError` depois, `Prisma.PrismaClientKnownRequestError`
  em terceiro, fallback 500 genérico ao final (linha 62). Nenhum controller
  formata erro: todos fazem `catch (err) { next(err) }`.
- **Gancho para webhooks:** nada precisa ser estendido em
  `src/middlewares/error.middleware.ts` — basta que os erros do módulo novo
  estendam `AppError` (COD-03) para caírem no primeiro ramo, linha 15. Endpoints
  de listagem do módulo novo usam `paginated` de `src/shared/http/response.ts`
  (linha 22); endpoints de recurso único devolvem a entidade crua, sem envelope,
  como faz `OrderController`.
- **ID:** COD-04

### COD-05 · Logger

- **Caminho:** `src/shared/logger/index.ts`
- **Assinatura/estrutura:**

  `$ awk 'NR>=13 && NR<=32 {printf "%5d  %s\n", NR, $0}' src/shared/logger/index.ts`

  ```
     13  export function createLogger(): Logger {
     14    return pino({
     15      level: env.LOG_LEVEL,
     16      redact: {
     17        paths: redactPaths,
     18        censor: '[REDACTED]',
     19      },
     20      base: { service: 'order-management-api', env: env.NODE_ENV },
     21      timestamp: pino.stdTimeFunctions.isoTime,
     22      transport:
     23        env.NODE_ENV === 'development'
     24          ? {
     25              target: 'pino-pretty',
     26              options: { colorize: true, singleLine: false, translateTime: 'HH:MM:ss.l' },
     27            }
     28          : undefined,
     29    });
     30  }
     31
     32  export const logger: Logger = createLogger();
  ```

- **Padrão que estabelece:** Pino, com uma **factory** exportada
  (`createLogger`) e um **singleton** derivado dela (`logger`, linha 32). Nível
  vem de `env.LOG_LEVEL`; `base` carimba `service` e `env` em toda linha;
  timestamp é ISO 8601. Chamada sempre no formato Pino de dois argumentos —
  objeto estruturado primeiro, mensagem-evento depois, em `snake_case`:
  `logger.info({ port, env }, 'server_started')` (`src/server.ts`:10),
  `logger.info({ signal }, 'shutdown_initiated')` (`src/server.ts`:14),
  `'http_request'` (`src/middlewares/request-logger.middleware.ts`:23). Há uma
  lista de `redactPaths` (linhas 4–11) cobrindo `authorization`, `cookie`,
  `*.password`, `*.token`, `*.accessToken`. O correlacionador é `requestId`,
  gerado por `uuidv4()` e devolvido no header `X-Request-Id`
  (`src/middlewares/request-logger.middleware.ts`:6–8).
- **Gancho para webhooks:** o módulo novo importa o singleton `logger` de
  `src/shared/logger/index.ts` e emite eventos em `snake_case`, no formato de
  dois argumentos. Um processo separado que precise de logger próprio chama a
  factory `createLogger` (linha 13) em vez do singleton. Qualquer segredo que o
  módulo novo manipule (um secret de assinatura, por exemplo) precisa entrar em
  `redactPaths` (linha 4) para não vazar no log — a lista atual não o cobre.
- **ID:** COD-05

### COD-06 · Schema Prisma e migrations

- **Caminho:** `prisma/schema.prisma`, `prisma/migrations/20260519182739_init/migration.sql`
- **Assinatura/estrutura:**

  `$ awk 'NR>=74 && NR<=97 {printf "%5d  %s\n", NR, $0}' prisma/schema.prisma`

  ```
     74  model Order {
     75    id             String      @id @default(uuid()) @db.Char(36)
     76    orderNumber    String      @unique @db.VarChar(20)
     77    customerId     String      @db.Char(36)
     78    status         OrderStatus @default(PENDING)
     79    subtotalCents  Int
     80    discountCents  Int         @default(0)
     81    totalCents     Int
     82    notes          String?     @db.Text
     83    createdById    String      @db.Char(36)
     84    createdAt      DateTime    @default(now())
     85    updatedAt      DateTime    @updatedAt
     86
     87    customer  Customer             @relation(fields: [customerId], references: [id])
     88    createdBy User                 @relation("OrderCreatedBy", fields: [createdById], references: [id])
     89    items     OrderItem[]
     90    history   OrderStatusHistory[]
     91
     92    @@index([customerId])
     93    @@index([status])
     94    @@index([createdAt])
     95    @@index([createdById])
     96    @@map("orders")
     97  }
  ```

  `$ awk 'NR>=116 && NR<=131 {printf "%5d  %s\n", NR, $0}' prisma/schema.prisma`

  ```
    116  model OrderStatusHistory {
    117    id           String       @id @default(uuid()) @db.Char(36)
    118    orderId      String       @db.Char(36)
    119    fromStatus   OrderStatus?
    120    toStatus     OrderStatus
    121    changedAt    DateTime     @default(now())
    122    changedById  String       @db.Char(36)
    123    reason       String?      @db.VarChar(500)
    124
    125    order     Order @relation(fields: [orderId], references: [id], onDelete: Cascade)
    126    changedBy User  @relation("StatusChangedBy", fields: [changedById], references: [id])
    127
    128    @@index([orderId])
    129    @@index([changedAt])
    130    @@map("order_status_history")
    131  }
  ```

- **Padrão que estabelece:** datasource MySQL (`prisma/schema.prisma`:6), com
  `shadowDatabaseUrl` separada (linha 8). Convenção de nomes **assimétrica**, e
  essa assimetria é o ponto: o **modelo** é `PascalCase`, a **tabela** é
  `snake_case` via `@@map` (`@@map("orders")`, `@@map("order_status_history")`),
  mas os **campos e colunas são `camelCase` nos dois lados** — o Prisma não tem
  `@map` de coluna em nenhum campo do arquivo, então `orderNumber`,
  `totalCents`, `stockQuantity` são o nome literal da coluna no MySQL
  (confirmado em `prisma/migrations/20260519182739_init/migration.sql`:52, 57 e
  38). Todo id de entidade de domínio é `String @id @default(uuid())
  @db.Char(36)`. Dinheiro é `Int` com sufixo `Cents`. Enum é enum do Prisma
  (`OrderStatus`, linha 16), materializado como `ENUM(...)` no MySQL. Toda FK
  ganha `@@index`. Migration é um único arquivo SQL gerado (125 linhas), com
  cabeçalhos `-- CreateTable` / `-- AddForeignKey`.
- **Gancho para webhooks:** tabelas novas se declaram em `prisma/schema.prisma`
  seguindo esse par de convenções — modelo `PascalCase` + `@@map` `snake_case`,
  colunas `camelCase`, id `@db.Char(36)` com `@default(uuid())` — e a migration
  correspondente entra sob `prisma/migrations/`, gerada pelo script `db:migrate`
  de `package.json` (linha 14). O relacionamento de uma outbox com o pedido tem
  precedente exato em `OrderStatusHistory` (linha 116): FK `orderId` com
  `@@index([orderId])` e um índice temporal (`@@index([changedAt])`).
- **ID:** COD-06

### COD-07 · Registro de rotas

- **Caminho:** `src/routes/index.ts`, `src/app.ts`, `src/modules/orders/order.routes.ts`
- **Assinatura/estrutura:**

  `$ awk 'NR>=21 && NR<=31 {printf "%5d  %s\n", NR, $0}' src/routes/index.ts`

  ```
     21  export function buildApiRouter(controllers: Controllers): Router {
     22    const router = Router();
     23
     24    router.use('/auth', buildAuthRouter(controllers.auth));
     25    router.use('/users', buildUserRouter(controllers.users));
     26    router.use('/customers', buildCustomerRouter(controllers.customers));
     27    router.use('/products', buildProductRouter(controllers.products));
     28    router.use('/orders', buildOrderRouter(controllers.orders));
     29
     30    return router;
     31  }
  ```

  `$ awk 'NR>=12 && NR<=26 {printf "%5d  %s\n", NR, $0}' src/modules/orders/order.routes.ts`

  ```
     12  export function buildOrderRouter(controller: OrderController): Router {
     13    const router = Router();
     14    router.use(authenticate);
     15
     16    router.get('/', validate({ query: listOrdersQuerySchema }), controller.list);
     17    router.get('/:id', validate({ params: orderIdParamSchema }), controller.getById);
     18    router.post('/', validate({ body: createOrderSchema }), controller.create);
     19    router.patch(
     20      '/:id/status',
     21      validate({ params: orderIdParamSchema, body: updateOrderStatusSchema }),
     22      controller.changeStatus,
     23    );
     24    router.delete('/:id', validate({ params: orderIdParamSchema }), controller.delete);
     25  ```

- **Padrão que estabelece:** três camadas de composição, todas por função
  `build*` e injeção explícita — sem decorator, sem container, sem varredura de
  diretório. (1) O módulo exporta `buildXRouter(controller)`; (2)
  `buildApiRouter` monta cada router sob seu prefixo e é o **único** lugar onde
  um domínio novo aparece na árvore de rotas; (3) `buildApp` monta tudo sob
  `/api/v1` (`src/app.ts`:67), depois de `/health` (linha 62) e antes do
  catch-all 404 (linha 69) e do `errorMiddleware` (linha 73). O tipo
  `Controllers` (`src/routes/index.ts`:13) é o contrato que obriga um domínio
  novo a ser declarado em três lugares: no tipo, em `buildControllers`
  (`src/app.ts`:26) e no `buildApiRouter`. Dentro do router, a ordem dos
  middlewares é fixa: auth → `validate` → handler do controller.
- **Gancho para webhooks:** um domínio novo entra por três símbolos existentes,
  todos nomeáveis: o tipo `Controllers` em `src/routes/index.ts`:13, a função
  `buildControllers` em `src/app.ts`:26 (onde repository/service/controller são
  instanciados na ordem e o `prisma` injetado) e `buildApiRouter` em
  `src/routes/index.ts`:21 (uma linha `router.use('/<prefixo>', ...)`). Um
  processo separado que não sirva HTTP não toca nenhum dos três.
- **ID:** COD-07

### COD-08 · Middleware de validação

- **Caminho:** `src/middlewares/validate.middleware.ts`, `src/modules/orders/order.schemas.ts`
- **Assinatura/estrutura:**

  `$ awk 'NR>=11 && NR<=24 {printf "%5d  %s\n", NR, $0}' src/middlewares/validate.middleware.ts`

  ```
     11  export function validate<S extends Sources>(schemas: S): RequestHandler {
     12    return (req, _res, next) => {
     13      try {
     14        if (schemas.body) {
     15          req.body = schemas.body.parse(req.body) as z.infer<NonNullable<S['body']>>;
     16        }
     17        if (schemas.query) {
     18          const parsedQuery = schemas.query.parse(req.query) as z.infer<NonNullable<S['query']>>;
     19          Object.assign(req.query, parsedQuery);
     20        }
     21        if (schemas.params) {
     22          req.params = schemas.params.parse(req.params) as z.infer<NonNullable<S['params']>>;
     23        }
     24        next();
  ```

- **Padrão que estabelece:** Zod como única fonte de validação de entrada.
  `validate({ body, query, params })` é uma factory de `RequestHandler` que faz
  `parse` (não `safeParse`) e **substitui** o valor da request pelo dado
  coagido — por isso `z.coerce.number()` e `.default()` nos schemas funcionam
  como conversão de fato. Erro de Zod aqui vira `ValidationError` com `details`
  no formato `{ path, message }` (linhas 26–32), nunca escapa cru. Os schemas
  ficam num arquivo `*.schemas.ts` por módulo, exportando o schema e o tipo
  inferido pareados (`export type CreateOrderInput = z.infer<typeof
  createOrderSchema>` em `src/modules/orders/order.schemas.ts`:32). Ids de path
  são sempre validados como `z.string().uuid()` (linha 4).
- **Gancho para webhooks:** rotas novas usam a mesma `validate` de
  `src/middlewares/validate.middleware.ts`:11 e declaram seus schemas num
  arquivo `*.schemas.ts` no diretório do módulo, com os tipos inferidos
  exportados junto — o precedente literal é `src/modules/orders/order.schemas.ts`.
  Uma lista de status a filtrar valida com `z.nativeEnum(OrderStatus)`, que já é
  o padrão usado em `updateOrderStatusSchema` (linha 19).
- **ID:** COD-08

### COD-09 · Middleware de auth e roles

- **Caminho:** `src/middlewares/auth.middleware.ts`
- **Assinatura/estrutura:**

  `$ awk 'NR>=49 && NR<=61 {printf "%5d  %s\n", NR, $0}' src/middlewares/auth.middleware.ts`

  ```
     49  export function requireRole(...roles: AuthUser['role'][]): RequestHandler {
     50    return (req, _res, next) => {
     51      if (!req.user) {
     52        next(new UnauthorizedError());
     53        return;
     54      }
     55      if (!roles.includes(req.user.role)) {
     56        next(new ForbiddenError('Insufficient permissions'));
     57        return;
     58      }
     59      next();
     60    };
     61  }
  ```

  `$ awk 'NR>=6 && NR<=17 {printf "%5d  %s\n", NR, $0}' src/middlewares/auth.middleware.ts`

  ```
      6  export type AuthUser = {
      7    id: string;
      8    email: string;
      9    role: 'ADMIN' | 'OPERATOR';
     10  };
     11
     12  declare module 'express-serve-static-core' {
     13    interface Request {
     14      user?: AuthUser;
     15      id?: string;
     16    }
     17  }
  ```

- **Padrão que estabelece:** dois middlewares separados e compostos em ordem.
  `authenticate` (linha 27) lê `Authorization: Bearer`, verifica com
  `jwt.verify(token, env.JWT_SECRET)` e popula `req.user` a partir do payload
  `{ sub, email, role }` (linha 42); `requireRole(...roles)` (linha 49) é uma
  factory variádica que assume `req.user` já populado. Nenhum dos dois responde
  — ambos chamam `next(err)` com `UnauthorizedError` / `ForbiddenError`,
  delegando o corpo da resposta ao COD-04. O universo de papéis é fechado em
  dois valores no tipo `AuthUser` (linha 9) e espelha o enum `UserRole` de
  `prisma/schema.prisma`:11. O aumento de `Request` (linha 12) é o mecanismo
  usado para anexar `user` e `id` à request.
- **Gancho para webhooks:** rotas administrativas do módulo novo compõem
  `authenticate` + `requireRole('ADMIN')` do mesmo arquivo
  (`src/middlewares/auth.middleware.ts`:27 e :49) — o precedente literal de uso
  é `src/modules/users/user.routes.ts`:14–15. Qualquer papel além de `ADMIN` e
  `OPERATOR` exige mexer no tipo `AuthUser` (linha 6) **e** no enum `UserRole`
  em `prisma/schema.prisma`:11; e qualquer autenticação que não seja o JWT de
  usuário interno não tem gancho aqui — `authenticate` só sabe verificar esse
  token (ver DIV-07).
- **ID:** COD-09

### COD-10 · Configuração de ambiente

- **Caminho:** `src/config/env.ts`, `src/config/database.ts`
- **Assinatura/estrutura:**

  `$ awk 'NR>=3 && NR<=12 {printf "%5d  %s\n", NR, $0}' src/config/env.ts`

  ```
      3  const envSchema = z.object({
      4    NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
      5    PORT: z.coerce.number().int().positive().default(3000),
      6    LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
      7    DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
      8    JWT_SECRET: z.string().min(16, 'JWT_SECRET must be at least 16 characters'),
      9    JWT_EXPIRES_IN: z.string().default('8h'),
     10  });
     11
     12  export type Env = z.infer<typeof envSchema>;
  ```

  `$ awk 'NR>=4 && NR<=10 {printf "%5d  %s\n", NR, $0}' src/config/database.ts`

  ```
      4  export function createPrismaClient(): PrismaClient {
      5    return new PrismaClient({
      6      log: env.NODE_ENV === 'development' ? ['warn', 'error'] : ['error'],
      7    });
      8  }
      9
     10  export const prisma: PrismaClient = createPrismaClient();
  ```

- **Padrão que estabelece:** configuração é um schema Zod único e **fail-fast** —
  `loadEnv` faz `safeParse` e, em falha, imprime as issues e chama
  `process.exit(1)` (`src/config/env.ts`:14–25) antes de qualquer conexão. O
  resto do código nunca lê `process.env`: importa a const `env` (linha 27), já
  tipada por `Env`. Mesma dupla factory-mais-singleton do logger em
  `src/config/database.ts`: `createPrismaClient()` para quem precisa de instância
  própria, `prisma` para o processo principal. O `.env.example` na raiz é o
  espelho manual do schema, e traz `SHADOW_DATABASE_URL` e as variáveis
  `MYSQL_*` do `docker-compose.yml`, que o schema Zod **não** valida.
- **Gancho para webhooks:** qualquer variável nova do módulo (secret de
  assinatura, timeout, intervalo de polling) entra no `envSchema` de
  `src/config/env.ts`:3 e no `.env.example`, com `.default()` quando puder ter
  padrão — só assim ela ganha tipagem e validação na subida. Um segundo processo
  Node reaproveita `env` do mesmo arquivo e chama `createPrismaClient()`
  (`src/config/database.ts`:4) em vez de importar o singleton `prisma`, que é o
  que o `src/server.ts` usa.
- **ID:** COD-10

---

## 2 · Inventário de símbolos citáveis

| ID (COD-NN) | Caminho | Símbolo (classe/método/tipo) | Linha | Comando que localizou |
|---|---|---|---|---|
| COD-01 | `src/modules/orders/order.service.ts` | `OrderService.changeStatus` (método) | 126 | `grep -n "async changeStatus" src/modules/orders/order.service.ts` |
| COD-01 | `src/modules/orders/order.status.ts` | `canTransition` (função) | 12 | `grep -n "export function canTransition" src/modules/orders/order.status.ts` |
| COD-01 | `src/modules/orders/order.status.ts` | `shouldDebitStock` (função) | 29 | `grep -n "export function shouldDebitStock" src/modules/orders/order.status.ts` |
| COD-02 | `src/modules/orders/order.service.ts` | `OrderService` (classe) | 26 | `grep -n "export class OrderService" src/modules/orders/order.service.ts` |
| COD-02 | `src/modules/orders/order.service.ts` | `this.prisma.$transaction` (chamada interativa em `changeStatus`) | 131 | `grep -n 'this.prisma.\$transaction' src/modules/orders/order.service.ts` |
| COD-03 | `src/shared/errors/app-error.ts` | `AppError` (classe) | 3 | `grep -n "export class AppError" src/shared/errors/app-error.ts` |
| COD-03 | `src/shared/errors/http-errors.ts` | `InvalidStatusTransitionError` (classe) | 45 | `grep -n "export class InvalidStatusTransitionError" src/shared/errors/http-errors.ts` |
| COD-03 | `src/shared/errors/http-errors.ts` | `InsufficientStockError` (classe) | 55 | `grep -n "export class InsufficientStockError" src/shared/errors/http-errors.ts` |
| COD-04 | `src/middlewares/error.middleware.ts` | `errorMiddleware` (const `ErrorRequestHandler`) | 14 | `grep -n "export const errorMiddleware" src/middlewares/error.middleware.ts` |
| COD-04 | `src/shared/http/response.ts` | `paginated` (função genérica) | 22 | `grep -n "export function paginated" src/shared/http/response.ts` |
| COD-05 | `src/shared/logger/index.ts` | `logger` (const `Logger` do Pino) | 32 | `grep -n "export const logger" src/shared/logger/index.ts` |
| COD-06 | `prisma/schema.prisma` | `OrderStatusHistory` (model) | 116 | `grep -n "model OrderStatusHistory" prisma/schema.prisma` |
| COD-06 | `prisma/schema.prisma` | `OrderStatus` (enum) | 16 | `grep -n "enum OrderStatus" prisma/schema.prisma` |
| COD-07 | `src/routes/index.ts` | `buildApiRouter` (função) | 21 | `grep -n "export function buildApiRouter" src/routes/index.ts` |
| COD-07 | `src/modules/orders/order.routes.ts` | `buildOrderRouter` (função) | 12 | `grep -n "export function buildOrderRouter" src/modules/orders/order.routes.ts` |
| COD-07 | `src/app.ts` | `buildApp` (função) | 55 | `grep -n "export function buildApp" src/app.ts` |
| COD-08 | `src/middlewares/validate.middleware.ts` | `validate` (factory genérica de `RequestHandler`) | 11 | `grep -n "export function validate" src/middlewares/validate.middleware.ts` |
| COD-09 | `src/middlewares/auth.middleware.ts` | `requireRole` (factory variádica) | 49 | `grep -n "export function requireRole" src/middlewares/auth.middleware.ts` |
| COD-09 | `src/middlewares/auth.middleware.ts` | `authenticate` (const `RequestHandler`) | 27 | `grep -n "export const authenticate" src/middlewares/auth.middleware.ts` |
| COD-10 | `src/config/env.ts` | `env` (const `Env`) | 27 | `grep -n "export const env" src/config/env.ts` |
| COD-10 | `src/config/database.ts` | `createPrismaClient` (função) | 4 | `grep -n "export function createPrismaClient" src/config/database.ts` |

**21 símbolos citáveis** — reserva de onde saem os ≥5 do TRK-4 e os ≥4 do FDD-5.

---

## 3 · Máquina de estados do pedido

**Estados** — enum `OrderStatus`, `prisma/schema.prisma`:16–23 e coluna
`ENUM(...)` em `prisma/migrations/20260519182739_init/migration.sql`:54:

`PENDING` · `PAID` · `PROCESSING` · `SHIPPED` · `DELIVERED` · `CANCELLED`

**Transições permitidas** — tabela `transitions`, `src/modules/orders/order.status.ts`:3–10:

| De | Para (permitido) | arquivo:linha |
|---|---|---|
| `PENDING` | `PAID`, `CANCELLED` | `src/modules/orders/order.status.ts`:4 |
| `PAID` | `PROCESSING`, `CANCELLED` | `src/modules/orders/order.status.ts`:5 |
| `PROCESSING` | `SHIPPED`, `CANCELLED` | `src/modules/orders/order.status.ts`:6 |
| `SHIPPED` | `DELIVERED` | `src/modules/orders/order.status.ts`:7 |
| `DELIVERED` | — (terminal) | `src/modules/orders/order.status.ts`:8 |
| `CANCELLED` | — (terminal) | `src/modules/orders/order.status.ts`:9 |

São **8 transições** possíveis no total. `isTerminal`
(`src/modules/orders/order.status.ts`:20) deriva o caráter terminal do tamanho
da lista, não de uma segunda tabela.

**Efeitos colaterais atrelados a transição específica:**

| Efeito | Condição | arquivo:linha |
|---|---|---|
| Débito de estoque | apenas `PENDING → PAID` | `src/modules/orders/order.status.ts`:24–31 (`STOCK_DEBIT_TRANSITION`, `shouldDebitStock`) |
| Reposição de estoque | `→ CANCELLED` vindo de `PAID` ou `PROCESSING` | `src/modules/orders/order.status.ts`:33–37 (`shouldReplenishStock`) |

Ou seja: em 8 transições, só 1 debita estoque e só 2 repõem; as outras 5
(`PAID→PROCESSING`, `PROCESSING→SHIPPED`, `SHIPPED→DELIVERED`,
`PENDING→CANCELLED` e — quando permitida — nenhuma outra) não tocam em produto.

**Entrada no estado inicial.** `PENDING` não é atingido por `changeStatus`: a
order nasce `PENDING` em `create`, que grava a primeira linha de histórico com
`fromStatus: null` (`src/modules/orders/order.service.ts`:106–113) fora do
caminho de `changeStatus`. Existe, portanto, um segundo ponto do código que
produz uma linha de `order_status_history` — ver DIV-11.

**Onde a reunião quer que o evento seja emitido.** A reunião fixou o evento
`order.status_changed` com filtro por status aplicado na inserção
(`.planning/02-transcricao.md` RF-09 e DEC-18) e recusou o disparo síncrono
(REC-01). No código isso corresponde a **toda transição executada por
`changeStatus`**, e a linha exata é dentro do callback de `$transaction` em
`src/modules/orders/order.service.ts`:131–178 — depois do
`tx.orderStatusHistory.create` (linha 159) e antes do `return refreshed!`
(linha 177). Os quatro status nomeados na reunião (`PAID`, `PROCESSING`,
`SHIPPED`, `DELIVERED` — GAN-31/GAN-32) todos existem no enum e são alvos de
transições reais; `PENDING` e `CANCELLED` existem no código e não foram citados
por ninguém na reunião (DIV-12).

Nenhum estado citado na reunião está ausente do código. O inverso ocorre e está
em §5.

---

## 4 · O que NÃO existe

Todo comando abaixo foi executado nesta sessão sobre `src/`, `prisma/`, `tests/`
e `package.json`, e retornou **saída vazia com código de saída 1** (nenhuma
correspondência). Esta seção é o que autoriza o FDD a marcar `(novo)` para a
estrutura da feature.

| Conceito | Comando | Saída | Veredito |
|---|---|---|---|
| outbox | `grep -rniE 'outbox' src/ prisma/ tests/ package.json` | vazia (rc=1) | não existe |
| fila / broker | `grep -rniE 'queue,bullmq,amqp,rabbit,kafka,sqs,redis' (alternação) em src/ prisma/ tests/ package.json` | vazia (rc=1) | não existe |
| worker | `grep -rniE 'worker' src/ prisma/ tests/ package.json` | vazia (rc=1) | não existe |
| scheduler / cron | `grep -rniE 'cron,scheduler,setInterval,node-cron,agenda' (alternação) em src/ prisma/ tests/ package.json` | vazia (rc=1) | não existe |
| HMAC / crypto | `grep -rniE 'hmac,crypto,createHmac,signature' (alternação) em src/ prisma/ tests/ package.json` | vazia (rc=1) | não existe |
| retry / backoff | `grep -rniE 'retry,retries,backoff' (alternação) em src/ prisma/ tests/ package.json` | vazia (rc=1) | não existe |
| dead-letter | `grep -rniE 'dead.?letter,dlq' (alternação) em src/ prisma/ tests/ package.json` | vazia (rc=1) | não existe |
| webhook | `grep -rniE 'webhook' src/ prisma/ tests/ package.json` | vazia (rc=1) | não existe |
| event | `grep -rniE 'event' src/ prisma/ tests/ package.json` | vazia (rc=1) | não existe |
| publisher / emissão | `grep -rniE 'publisher,publish,emit,eventbus' (alternação) em src/ prisma/ tests/ package.json` | vazia (rc=1) | não existe |
| idempotência | `grep -rniE 'idempot' src/ prisma/ tests/ package.json` | vazia (rc=1) | não existe |
| trigger de banco | `grep -rniE 'trigger' src/ prisma/ tests/ package.json` | vazia (rc=1) | não existe |

Onde a tabela escreve "alternação", o comando efetivamente executado usa o
separador `|` do ERE entre os termos listados; ele foi transcrito com vírgula
apenas porque `|` é o delimitador de célula do Markdown. O padrão `hmac|crypto`
não casa com `bcrypt` (`package.json`:27), que é a única dependência de
criptografia do projeto e serve exclusivamente ao hash de senha em
`src/modules/auth/auth.service.ts`:36.

Consequência: **toda** a estrutura da feature — tabela de outbox, tabela de
dead-letter, processo worker, assinatura de payload, política de retentativa,
chave de idempotência, registro de endpoints — é nova. Nenhum símbolo, arquivo
ou tabela existente pode ser apontado como ponto de partida parcial.

---

## 5 · Divergências transcrição × código

Divergência não é erro da reunião nem da leitura: é informação que o RFC e o FDD
precisam tratar explicitamente. Registradas, não conciliadas.

| ID (DIV-NN) | O que a reunião disse | Localização `[hh:mm] Nome` | O que o disco mostra | arquivo:linha | Gravidade |
|---|---|---|---|---|---|
| DIV-01 | "decrementa stock_quantity dos produtos do pedido" | `[09:04] Bruno` | O campo se chama `stockQuantity`; não há `@map` de coluna, então `stockQuantity` é também o nome literal da coluna no MySQL. `stock_quantity` não existe | `prisma/schema.prisma`:62 e `prisma/migrations/20260519182739_init/migration.sql`:38 | Média |
| DIV-02 | "order_id, order_number, from_status, to_status, customer_id" como campos do payload | `[09:43] Diego` | As colunas são `id`, `orderNumber`, `customerId` (camelCase); em `order_status_history` são `fromStatus` e `toStatus`. Nenhuma das cinco grafias snake_case existe no banco | `prisma/schema.prisma`:75–77 e :119–120; `prisma/migrations/20260519182739_init/migration.sql`:52–53, :90–91 | Média |
| DIV-03 | "os campos básicos da order tipo total_cents" | `[09:43] Diego` | O campo é `totalCents`, `Int`; existem ainda `subtotalCents` e `discountCents`, não citados | `prisma/schema.prisma`:79–81 e `prisma/migrations/20260519182739_init/migration.sql`:55–57 | Média |
| DIV-04 | "Hoje a transação faz update na order, insere no history e atualiza estoque." | `[09:40] Bruno` | Update e insert no history são incondicionais; a atualização de estoque é **condicional a transição específica**: debita só em `PENDING→PAID`, repõe só em `→CANCELLED` vindo de `PAID`/`PROCESSING`. Em 5 das 8 transições nenhum produto é tocado | `src/modules/orders/order.service.ts`:151–167; `src/modules/orders/order.status.ts`:29–37 | **Alta** |
| DIV-05 | "Trigger no banco a gente até tem, mas ela não notifica processo externo" | `[09:09] Diego` | Nenhum trigger no repositório. A migration tem só `CREATE TABLE`, `CREATE INDEX` e `ADD FOREIGN KEY`; `grep -rniE 'trigger' src/ prisma/ tests/ package.json` retorna vazio | `prisma/migrations/20260519182739_init/migration.sql` (125 linhas, nenhum `CREATE TRIGGER`) | Média |
| DIV-06 | "o pool de conexão do Prisma já tá lá" | `[09:29] Diego` | Não há configuração de pool em lugar nenhum: `createPrismaClient` passa apenas `log`, e nem `DATABASE_URL` no `.env.example` nem o `docker-compose.yml` trazem `connection_limit`. O pool existe por default do Prisma, não por configuração do projeto | `src/config/database.ts`:4–8 | Baixa |
| DIV-07 | "autenticado com JWT do nosso sistema. A gente tem usuários que representam o cliente" | `[09:32] Marcos` | Não há usuário que represente cliente. `UserRole` tem exatamente `ADMIN` e `OPERATOR`; `Customer` é um model sem senha, sem papel e sem relação com `User` — não tem como autenticar. A própria reunião se corrige em GAN-25 | `prisma/schema.prisma`:11–14 e :40–54; `src/middlewares/auth.middleware.ts`:9 | **Alta** |
| DIV-08 | "Hoje eles ficam batendo no GET /orders de tempos em tempos" (clientes) | `[09:00] Marcos` | A rota existe, mas todo o router de orders é precedido por `router.use(authenticate)`, que só aceita o JWT de usuário interno. Um cliente externo não tem credencial para chamá-la hoje | `src/modules/orders/order.routes.ts`:14–16; `src/middlewares/auth.middleware.ts`:41–42 | **Alta** |
| DIV-09 | "Cada domínio é um módulo em src/modules com controller, service, repository, routes e schemas." | `[09:27] Bruno` | Vale para `users`, `customers`, `products` e `orders`. O módulo `auth` **não tem repository** (usa o `UserRepository` de outro módulo), e `orders` tem um sexto arquivo fora da lista, `src/modules/orders/order.status.ts` | `src/modules/auth/` (4 arquivos); `src/modules/auth/auth.service.ts`:6; `src/modules/orders/order.status.ts` | Baixa |
| DIV-10 | "segue o padrão do resto do projeto. Tudo é uuid" | `[09:51] Larissa` | Vale para 6 dos 7 models. `OrderNumberSequence.id` é `Int @id @default(1)` — tabela de sequência com linha única, id 1 | `prisma/schema.prisma`:133–138 | Baixa |
| DIV-11 | "a alteração crítica é dentro do service de orders, no método changeStatus" (ponto único de mudança de status) | `[09:40] Bruno` | `changeStatus` não é o único produtor de linha em `order_status_history`: `create` grava a transição inicial `null → PENDING` num caminho separado. Um gancho instalado só em `changeStatus` não vê a criação do pedido | `src/modules/orders/order.service.ts`:106–113 vs. :159–167 | **Alta** |
| DIV-12 | Status citados na reunião: `PAID`, `PROCESSING`, `SHIPPED`, `DELIVERED` | `[09:12] Larissa`, `[09:33] Marcos` | O enum tem seis valores. `PENDING` e `CANCELLED` existem, participam de 4 das 8 transições e carregam o efeito de reposição de estoque — e não foram citados por ninguém. O RFC precisa dizer se emitem evento | `prisma/schema.prisma`:16–23; `src/modules/orders/order.status.ts`:3–10 | Média |
| DIV-13 | "E o logger, que é Pino, já tá no projeto inteiro." | `[09:29] Bruno` | Pino existe e é singleton, mas é importado em exatamente 3 arquivos — `src/server.ts`, `src/middlewares/error.middleware.ts` e `src/middlewares/request-logger.middleware.ts`. Nenhum service, controller ou repository loga | `grep -rn "shared/logger" src/` → 3 ocorrências | Baixa |
| DIV-14 | "Outbox no MySQL existente resolve." | `[09:07] Diego` | O MySQL existe (`provider = "mysql"`), mas a reunião presume transacionalidade de outbox sem que exista precedente: nenhum repository do projeto aceita `tx`, e a única escrita transacional multi-tabela vive dentro do `OrderService` | `prisma/schema.prisma`:6; `src/modules/orders/order.service.ts`:24 e :131 | Média |

**14 divergências registradas** (4 de gravidade Alta, 6 Média, 4 Baixa).
