# ADR-007 — Inserção na outbox dentro da transação do `changeStatus`

## Status
Aceito — 2026-08-19 · decidido em reunião técnica de [09:00]–[09:53]

## Contexto

O bloco final da reunião tratou do ponto de integração com o código existente.
Bruno o localizou por nome: `[09:40] Bruno` — "a alteração crítica é dentro do
service de orders, no método changeStatus". O disco confirma o alvo:
`OrderService` está em `src/modules/orders/order.service.ts`:26 e é instanciado
em `src/app.ts`:43; o método `changeStatus` começa em
`src/modules/orders/order.service.ts`:126 e todo o seu corpo roda dentro de um
`this.prisma.$transaction` interativo (linha 131), cujo `tx` é tipado pelo alias
local `TxClient = Prisma.TransactionClient` (linha 24).

A descrição que a reunião fez dessa transação, porém, é mais larga do que o
código (**DIV-04**, gravidade Alta). `[09:40] Bruno` — "Hoje a transação faz
update na order, insere no history e atualiza estoque." No repositório, o
`update` na order (`src/modules/orders/order.service.ts`:158) e o insert no
histórico (linha 159) são incondicionais, mas a mexida em estoque é condicional a
transição específica: `shouldDebitStock` só é verdadeiro em `PENDING → PAID` e
`shouldReplenishStock` só em `→ CANCELLED` vindo de `PAID` ou `PROCESSING`
(`src/modules/orders/order.status.ts`:29 e :33, chamados em
`src/modules/orders/order.service.ts`:151 e :154). Em 4 das 7 transições
possíveis nenhum produto é tocado. Isso importa aqui porque define o que está
realmente garantido pela transação em toda transição — e é `order` +
`order_status_history`, não estoque.

O lugar exato onde a escrita da outbox cabe é, por consequência, dentro do
callback de `$transaction` (`src/modules/orders/order.service.ts`:131–178),
depois de `tx.orderStatusHistory.create` (linha 159) e antes do
`return refreshed!` (linha 177): é o único ponto do código em que `from` e `to`
coexistem já validados por `canTransition`
(`src/modules/orders/order.status.ts`:12).

A forma de chamada também foi discutida: injetar um repository de webhooks no
`OrderService` ou passar o `tx` para uma função. O padrão vigente pesa nessa
escolha — nenhum repository do projeto aceita `tx`; a única `$transaction` de
escrita multi-tabela vive no `OrderService`, e os métodos privados recebem o `tx`
como primeiro argumento, como `debitStock`
(`src/modules/orders/order.service.ts`:204).

## Decisão

A linha da outbox é escrita dentro da mesma transação do `changeStatus`, pelo
`tx` do callback: se a escrita da outbox falhar, a mudança de status sofre
rollback junto. A chamada é feita por uma função que recebe o `TxClient` como
primeiro argumento, no formato de `debitStock`
(`src/modules/orders/order.service.ts`:204), sem injetar repository novo no
construtor do `OrderService` (`src/modules/orders/order.service.ts`:27–30). O
filtro por status decidido para a feature é aplicado **na inserção**, não na hora
do envio: só vira linha de outbox a transição que algum endpoint cadastrado quer
ouvir.

Falas que fecham:

- `[09:41] Diego` — "Essencial. Se ficar fora da transação, perde a garantia
  toda." (proposta de `[09:40] Bruno`) — **DEC-21**.
- `[09:41] Diego` — "Boa, função pura recebendo o tx. Não precisa injetar
  repository inteiro." — **DEC-22**.
- `[09:34] Diego` — "Concordo." (filtro aplicado na inserção, proposta de Bruno
  na mesma janela) — **DEC-18**.

## Alternativas Consideradas

### Inserir na outbox depois do commit da transação

Fechar a transação de mudança de status e, logo em seguida, gravar o evento —
mantendo a transação atual intocada.

- Quem levantou e quando: `[09:40] Bruno`, ao abrir o ponto de integração.
- **Motivo do descarte:** `[09:41] Diego` — "Essencial. Se ficar fora da
  transação, perde a garantia toda." O trade-off dito é a janela entre commit e
  insert: um crash ali muda o status do pedido sem emitir o evento, e o cliente
  nunca fica sabendo.

### Injetar um repository de webhooks no `OrderService`

Passar o repository novo pelo construtor do service e chamá-lo de dentro da
transação, como se faz com `orders` (`src/modules/orders/order.service.ts`:28).

- Quem levantou e quando: `[09:41] Diego`, ao comparar as duas formas.
- **Motivo do descarte:** `[09:41] Diego` — "Boa, função pura recebendo o tx. Não
  precisa injetar repository inteiro." O código reforça a razão dita: nenhum
  repository do projeto aceita `tx` hoje — `src/modules/orders/order.repository.ts`
  usa `$transaction` na forma de array e só para leitura paginada (linhas 33–45)
  — então injetar um repository aqui criaria o primeiro repository transacional
  do projeto só para essa chamada.

### Aplicar o filtro de status na hora do envio, e não na inserção

Gravar toda transição na outbox e deixar o worker decidir, no momento da entrega,
quais endpoints querem aquele status.

- Quem levantou e quando: `[09:34] Diego`, ao fechar a proposta de Bruno da mesma
  janela.
- **Motivo do descarte:** `[09:34] Diego` — "Concordo." A ata registra a escolha
  pela inserção (DEC-18), sem razão adicional dita; o efeito direto é que a
  outbox só recebe o que tem destinatário.

## Consequências

### Positivas

- Atomicidade real entre a mudança de status e a emissão do evento: os dois
  commitam juntos ou nenhum commita (`[09:41] Diego`).
- Nenhuma mudança de construtor e nenhum repository novo: a função recebe
  `TxClient` (`src/modules/orders/order.service.ts`:24) como primeiro argumento,
  exatamente como `debitStock` (linha 204) — o padrão transacional do projeto
  fica intacto.
- O filtro na inserção mantém a outbox proporcional ao que alguém quer receber, e
  não ao volume de transições do sistema (DEC-18).
- O predicado de filtro tem lugar natural em
  `src/modules/orders/order.status.ts`, ao lado de `shouldDebitStock` (linha 29)
  e com a mesma forma `(from, to) => boolean`, onde a política de transição já é
  dado e não `if` espalhado pelo service — (colocação proposta por esta ADR, não
  decidida na reunião).

### Negativas

- **`changeStatus` não é o único produtor de linha de histórico (DIV-11,
  gravidade Alta).** A reunião presumiu ponto único — `[09:40] Bruno`: "a
  alteração crítica é dentro do service de orders, no método changeStatus" — mas
  `OrderService.create` grava a primeira linha de `order_status_history`, com
  `fromStatus: null`, num caminho separado
  (`src/modules/orders/order.service.ts`:106–113), fora do método
  `OrderService.changeStatus` (`src/modules/orders/order.service.ts`:126). Um
  gancho instalado apenas em `changeStatus` não enxerga a criação do pedido: a
  cobertura da feature nasce com um buraco declarado — nenhum evento é emitido
  quando a order entra em `PENDING`. A reunião não decidiu nada sobre isso porque
  `PENDING` e `CANCELLED` não foram citados por ninguém (DIV-12), embora existam
  no enum (`prisma/schema.prisma`:16–23) e participem de 4 das 7 transições.
- A transação de `changeStatus` ganha mais uma escrita. Ela já era o ponto
  pesado do fluxo — foi esse o argumento que matou o disparo síncrono
  (`[09:04] Bruno`, REC-01) — e agora segura o lock da order também durante o
  insert da outbox. Lentidão na escrita da outbox vira lentidão da mudança de
  status, e falha na outbox vira falha do `PATCH /orders/:id/status`
  (`src/modules/orders/order.routes.ts`:19–23).
- Acoplamento novo entre módulos: `src/modules/orders/order.service.ts` passa a
  importar um símbolo do módulo de webhooks. Hoje só existe um cruzamento assim
  no projeto — `src/modules/auth/auth.service.ts`:6 reusando o `UserRepository` —
  então este é o segundo, e ele aponta do domínio antigo para o novo.
- O ponto de integração fica dentro de um método já denso, de 53 linhas
  (`src/modules/orders/order.service.ts`:126–178), cujo comportamento hoje é
  fixado por testes de integração que batem em `PATCH /orders/:id/status`
  (`tests/orders.test.ts`:59, :89, :109 e :134). Toda mudança futura no fluxo de
  status passa a ter que considerar também a emissão do evento, e esses testes
  passam a exercitar a escrita da outbox sem terem sido escritos para isso.
