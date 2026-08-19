# ADR-001 — Outbox de eventos no MySQL já existente

## Status
Aceito — 2026-08-19 · decidido em reunião técnica de [09:00]–[09:53]

## Contexto

A demanda entrou por três clientes B2B nomeados, com prazo comercial e ameaça de
churn: `[09:00] Marcos` — "um pedido formal de três clientes B2B: Atlas
Comercial, MaxDistribuição e Nova Cargo" e "se a gente não entregar isso até fim
do trimestre, eles podem migrar pro nosso concorrente". O que esses clientes
fazem hoje para saber que um pedido mudou de status é polling na API:
`[09:00] Marcos` — "Hoje eles ficam batendo no GET /orders de tempos em tempos".
A régua de "tempo real" que eles usam foi dita em voz alta: `[09:02] Marcos` —
"qualquer coisa abaixo de 10 segundos".

O disco qualifica essa premissa em um ponto que o desenho precisa absorver
(DIV-08, gravidade Alta): a rota existe (`src/modules/orders/order.routes.ts`:16),
mas todo o router de orders é precedido por `router.use(authenticate)`
(`src/modules/orders/order.routes.ts`:14), e `authenticate` só aceita o JWT de
usuário interno (`src/middlewares/auth.middleware.ts`:41–42). Um cliente externo
não tem credencial para chamar `GET /orders` hoje — o polling descrito na
reunião passa por um usuário interno, não pelo cliente final. Isso não muda a
decisão desta ADR; muda quem é o consumidor real do que for entregue, e por isso
está registrado aqui (ver ADR-008 para o modelo de autorização).

A primeira ideia foi disparar o webhook dentro do próprio service de orders, de
forma síncrona — `[09:03] Larissa` levantou o desenho e `[09:04] Bruno` mostrou o
custo: a transação de mudança de status já é pesada, um cliente lento travaria os
outros pedidos e não haveria rollback se o cliente estivesse fora do ar. Com o
síncrono fora, sobrou a pergunta de onde o evento fica guardado entre a mudança
de status e a entrega, e com que infraestrutura.

A restrição de operação foi dita pelo time: `[09:07] Diego` — "Exato, e a gente é
um time pequeno. Subir Redis Cluster pra isso é overengineering." O MySQL, esse
já existe e já é operado: `prisma/schema.prisma`:6 declara
`provider = "mysql"` e o serviço `mysql` (imagem `mysql:8.0`) está em
`docker-compose.yml`:2–3.

## Decisão

Todo evento de mudança de status de pedido é gravado como linha de uma tabela outbox no MySQL já existente do projeto — nenhuma infraestrutura nova entra na
feature. A tabela nova é declarada em `prisma/schema.prisma` seguindo as
convenções vigentes (modelo `PascalCase` + `@@map` `snake_case`, colunas
`camelCase`, id `@db.Char(36)` com `@default(uuid())`), e a migration
correspondente é gerada pelo script `db:migrate` de `package.json`:14 — o
precedente literal de relacionamento com o pedido é o model
`OrderStatusHistory` (`prisma/schema.prisma`:116), com FK `orderId` indexada e um
índice temporal.

Fecha a decisão `[09:08] Larissa`: "Tá decidido então: outbox em MySQL."
— **DEC-01**.

## Alternativas Consideradas

### Disparo síncrono do webhook dentro do service de orders

Chamar o endpoint do cliente na hora, dentro da transação que muda o status do
pedido. Levantada por `[09:03] Larissa` e contestada por `[09:04] Bruno` na
sequência: a transação de mudança de status já é pesada, um cliente lento
seguraria os demais pedidos e uma falha do cliente não teria rollback.

- **Motivo do descarte:** `[09:06] Diego` — "Síncrono está fora de questão." O
  custo dito é acoplar a disponibilidade do pedido à disponibilidade do cliente
  (REC-01).

### Redis Streams / Redis Cluster como transporte dos eventos

Usar uma fila dedicada em Redis entre a API e o processo de entrega.

- **Motivo do descarte:** `[09:07] Diego` — "Exato, e a gente é um time pequeno.
  Subir Redis Cluster pra isso é overengineering." O trade-off dito é operação:
  mais um componente para subir, monitorar e manter (REC-02).

### Trigger de banco notificando o worker de forma reativa

Em vez de alguém ler a tabela, o próprio MySQL avisaria o processo de entrega
quando uma linha entrasse.

- **Motivo do descarte:** `[09:09] Diego` — "MySQL não tem listener nativo tipo o
  NOTIFY/LISTEN do Postgres." Uma trigger executa SQL e não notifica processo
  externo (REC-03).
- **Nota de divergência (DIV-05).** A reunião discutiu essa alternativa partindo
  de uma premissa que o repositório não sustenta — `[09:09] Diego`: "Trigger no
  banco a gente até tem, mas ela não notifica processo externo". Não há trigger
  nenhuma no repositório: `grep -rniE 'trigger' src/ prisma/ tests/ package.json`
  retorna vazio, e `prisma/migrations/20260519182739_init/migration.sql` tem
  apenas `CREATE TABLE`, `CREATE INDEX` e `ADD FOREIGN KEY` em 125 linhas
  (GAN-11, veredito `[ausente no código]`). O descarte continua válido pela razão
  dita; o que não é fato é o "a gente até tem".

## Consequências

### Positivas

- Nenhum componente novo de infraestrutura para operar: o transporte é a mesma
  instância MySQL que já roda em `docker-compose.yml`:2–3 e já é acessada pelo
  `PrismaClient` do projeto (`src/config/database.ts`:4).
- O evento fica durável no mesmo store transacional do pedido, o que torna
  possível a atomicidade entre mudança de status e emissão do evento — mecânica
  detalhada em ADR-007.
- A tabela nova cai no caminho de migration já existente
  (`prisma/migrations/20260519182739_init/migration.sql` é o único precedente, e
  o script `db:migrate` de `package.json`:14 é o gerador), sem ferramenta nova.

### Negativas

- **Primeiro uso do padrão, sem precedente transacional em repository (DIV-14).**
  A reunião tratou a outbox como resolvida pela existência do banco —
  `[09:07] Diego`: "Outbox no MySQL existente resolve." O MySQL existe
  (`prisma/schema.prisma`:6), mas a transacionalidade presumida não tem
  precedente: nenhum repository do projeto aceita um `tx`, e a única escrita
  transacional multi-tabela vive dentro do `OrderService`
  (`src/modules/orders/order.service.ts`:24 e :131). Quem implementar a escrita
  da outbox não tem padrão de repository para copiar — inventa a colocação ou
  segue o desvio decidido em ADR-007. O custo é concreto: a primeira revisão de
  código da feature discute arquitetura, não implementação.
- A entrega passa a depender de leitura periódica da tabela, e não de
  notificação: a latência mínima é o intervalo de polling, aceita em
  `[09:10] Larissa` — "A latência mínima vai ser 2 segundos no pior caso.
  Aceitamos." (custo detalhado em ADR-002).
- A outbox cresce sem limpeza automática. O arquivamento das linhas já entregues
  foi declarado fora do escopo desta feature — `[09:08] Diego`: "Linhas entregues
  a gente arquiva depois de 30 dias ou assim, fora do escopo dessa feature."
  (REC-11). O banco de produção acumula uma tabela de crescimento monotônico, e
  quem opera herda esse crescimento sem rotina definida.
- Carga adicional de escrita na mesma instância MySQL que serve a API: cada
  transição de status filtrada vira `INSERT`, no mesmo banco que já responde as
  queries de pedidos. O cenário de carga citado na reunião foi
  `[09:38] Diego` — "Se o cliente tem 50 pedidos mudando de status em um minuto".
