# RFC — Sistema de webhooks para eventos de mudança de status de pedido

## Metadados

| Campo | Valor |
|---|---|
| Autor | Wesley Taumaturgo |
| Status | Em revisão |
| Data | 2026-08-19 |
| Revisores | Bruno, Diego, Larissa, Marcos, Sofia |
| Origem | reunião técnica `[09:00]`–`[09:53]` |

## Resumo executivo (TL;DR)

Propomos entregar notificação de mudança de status de pedido como um módulo novo
do próprio backend, sem infraestrutura adicional. O evento nasce dentro da
transação que já altera o status, é gravado numa tabela outbox no MySQL que o
projeto já usa e é entregue por um worker em processo separado, que consome a
outbox por polling e assina cada envio. Falha de entrega entra numa política de
retry finita; esgotadas as tentativas, o evento vai para uma dead-letter queue
com replay administrativo. O público é o cliente B2B integrador — que hoje,
ressalve-se, não descobre mudança de status de forma nenhuma: a consulta
repetida que a reunião pressupôs não está aberta a ele (DIV-08, abaixo).

Em uma frase: **outbox transacional no banco que já temos, consumida por um
worker separado que entrega assinado, com retry finito e DLQ.**

## Contexto e problema

A demanda não é iniciativa técnica. Ela chegou como pedido formal de clientes, e
a reunião abre com isso — `[09:00] Marcos`: "um pedido formal de três clientes
B2B: Atlas Comercial, MaxDistribuição e Nova Cargo" (RNF-25). O prazo tem peso
comercial explícito, ainda `[09:00] Marcos`: "se a gente não entregar isso até
fim do trimestre, eles podem migrar pro nosso concorrente" (RNF-24).

O que esses clientes querem é saber, sem perguntar, quando um pedido muda de
estado. A régua de "tempo real" foi dada por eles e é generosa — `[09:02]
Marcos`: "qualquer coisa abaixo de 10 segundos". Isso é o que torna a proposta
viável sem infraestrutura nova.

A premissa declarada do problema é que os clientes hoje resolvem isso por
consulta repetida à API de pedidos — `[09:00] Marcos`: "Hoje eles ficam batendo
no GET /orders de tempos em tempos". **Ressalva registrada (DIV-08):** o disco
não sustenta essa premissa — nenhum cliente externo tem credencial para chamar
a rota, e o modelo de dados não tem identidade de cliente (DIV-07); a
consequência de produto está no PRD e a de autorização, em
[ADR-008](adrs/ADR-008-modelo-de-autorizacao-do-modulo.md). Isso não invalida a
demanda; muda o baseline com que ela é comparada.

## Proposta técnica

```
  changeStatus (uma transação)                worker (processo separado)
  ┌───────────────────────────┐
  │ atualiza o pedido         │
  │ grava o histórico         ├──► outbox ──polling──► assina ──HTTP──► cliente
  │ publica o evento          │    (MySQL)                 │
  └───────────────────────────┘       ▲                    │ falha
        rollback conjunto             │                    ▼
                                      │             retry com backoff
                                      │                    │ esgotou
                                      └── replay (admin) ── DLQ
```

Cada decisão estruturante em uma frase, com o ADR que a detalha:

- O evento é persistido como linha de uma tabela outbox no MySQL já existente, em
  vez de trafegar por infraestrutura de mensageria nova —
  [ADR-001](adrs/ADR-001-outbox-no-mysql.md).
- Essa gravação acontece **dentro** da transação que muda o status, de modo que
  o rollback do status implique o rollback do evento —
  [ADR-007](adrs/ADR-007-insercao-na-outbox-dentro-da-transacao.md).
- O consumo é feito por um worker em processo separado da API, com entry-point
  própria em `src/worker.ts` (novo) e cliente de banco próprio, lendo a outbox
  por polling —
  [ADR-002](adrs/ADR-002-worker-processo-separado-polling.md).
- Entrega que falha entra numa política de retry finita com backoff exponencial e
  termina numa DLQ em tabela separada, com replay manual —
  [ADR-003](adrs/ADR-003-retry-backoff-e-dlq-em-tabela-separada.md).
- Toda entrega vai assinada em HMAC-SHA256, com secret única por endpoint
  cadastrado e suporte a rotação —
  [ADR-004](adrs/ADR-004-hmac-sha256-secret-por-endpoint.md).
- A garantia contratada é at-least-once, com identificador de evento em header
  para o cliente deduplicar —
  [ADR-005](adrs/ADR-005-entrega-at-least-once-com-x-event-id.md).
- O módulo nasce dentro do padrão de módulos do projeto e reusa erro, log,
  validação e convenções existentes, sem estrutura própria —
  [ADR-006](adrs/ADR-006-reuso-dos-padroes-existentes.md).
- Gestão de endpoints fica atrás da autenticação já existente e o replay da DLQ
  exige role administrativa, reaproveitando o guarda de papel do projeto —
  [ADR-008](adrs/ADR-008-modelo-de-autorizacao-do-modulo.md).

Capacidades que o cliente ganha, uma linha por capacidade: cadastrar um endpoint
de webhook e receber a secret na criação; editar, remover e listar seus
endpoints; declarar quais status quer ouvir; pedir rotação da secret; consultar o
histórico recente de entregas. Formato de requisição, resposta e erro são
matéria do FDD.

## Alternativas consideradas

### RFC-ALT-01 — Disparo síncrono no service de pedidos

Chamar o endpoint do cliente diretamente dentro da transação de mudança de
status, sem intermediário. É a opção mais simples e a primeira colocada na mesa.
Levantada em `[09:03] Larissa` e contestada em `[09:04] Bruno`; descartada em
`[09:06] Diego`: "Síncrono está fora de questão."

**Trade-off do descarte:** a transação de mudança de status já é pesada, e um
cliente lento passaria a travar mudanças de status de outros pedidos; além
disso, não haveria como dar rollback se o cliente estivesse fora do ar.

### RFC-ALT-02 — Redis Streams como transporte dos eventos

Publicar o evento num Redis Streams e ter o worker consumindo de lá — a solução
convencional de fila, com melhor latência e escala horizontal natural.
Levantada em `[09:07] Larissa`, descartada em `[09:07] Diego`.

**Trade-off do descarte:** exigiria subir infraestrutura nova para um time
pequeno — "Exato, e a gente é um time pequeno. Subir Redis Cluster pra isso é
overengineering." (`[09:07] Diego`).

### RFC-ALT-03 — Trigger de banco como gatilho reativo

Em vez de polling, uma trigger no MySQL avisaria o worker no momento do insert,
eliminando a latência do intervalo de leitura. Levantada em `[09:09] Bruno`,
descartada em `[09:09] Diego`.

**Trade-off do descarte:** "MySQL não tem listener nativo tipo o NOTIFY/LISTEN do
Postgres" (`[09:09] Diego`) — a trigger só executa SQL e não notifica processo
externo, então avisar o worker exigiria improviso. Registre-se que nem trigger
existe hoje no repositório (DIV-05).

### RFC-ALT-04 — Retry indefinido com backoff

Nunca desistir de um evento: retentar para sempre, com o backoff crescendo.
Elimina a decisão arbitrária de onde parar. Levantada e descartada na mesma
fala, `[09:15] Diego`.

**Trade-off do descarte:** o evento ficaria pendurado para sempre se o cliente
sumisse — "isso traz o problema de evento ficar pendurado" (`[09:15] Diego`),
sem ponto de corte que permita tratar a falha como falha.

### RFC-ALT-05 — Teto de três tentativas

Um teto baixo de tentativas, que fecharia o ciclo de retry em menos de uma hora e
manteria a fila curta. Descartado em `[09:16] Diego`.

**Trade-off do descarte:** cobriria janela curta demais e mataria o evento antes
de indisponibilidades reais já observadas em clientes — "3 é pouco. Se o cliente
teve indisponibilidade de manhã, a gente retentaria três vezes em 30 minutos e
mataria." (`[09:16] Diego`).

### RFC-ALT-06 — Garantia de entrega exactly-once

Entregar cada evento exatamente uma vez, poupando o cliente de implementar
deduplicação. Descartada em `[09:25] Diego`.

**Trade-off do descarte:** "Garantir exactly-once exigiria coordenação dos dois
lados e fica muito mais complexo" (`[09:25] Diego`); o custo recai sobre o
protocolo inteiro para resolver o que uma dedup por identificador resolve no
cliente.

## Questões em aberto

| ID | Questão | Por que ficou aberta | Quem levantou | Impacto se não resolver antes de codar |
|---|---|---|---|---|
| RFC-QA-01 | O identificador do cliente no cadastro de webhook vai no corpo ou no path da requisição | A fala fecha apenas o que ele **não** é (não vem do token) e oferece as duas formas sem eleger uma | `[09:32] Larissa` | Contrato público muda de forma; refazer depois é breaking change para os três clientes. **O FDD adota o path provisoriamente** (D-04) e a escolha continua aberta aqui |
| RFC-QA-02 | Nome do arquivo que abriga a lógica de processamento do worker | Dois nomes foram oferecidos e o fechamento foi um aceno genérico, sem eleger um | `[09:28] Bruno` | Baixo tecnicamente, alto em confusão: o nome errado mistura processo e lógica. **O FDD adota um nome provisoriamente** (D-05) e a escolha continua aberta aqui |
| RFC-QA-03 | Se haverá limitação de taxa de envio por cliente | A reunião tirou do escopo e, no mesmo movimento, pediu que ficasse registrado como ponto em aberto | `[09:39] Diego` | Um cliente com pico de mudanças de status pode ser inundado; sem decisão, o comportamento sob rajada é acidental, não projetado |
| RFC-QA-04 | Garantia de ordenação quando houver mais de um worker | A perda da garantia foi reconhecida e a solução empurrada para o futuro, sem escolher entre particionamento e lock | `[09:12] Diego` | A limitação precisa estar documentada no contrato desde já; se não estiver, escalar workers vira quebra silenciosa de expectativa do cliente |
| RFC-QA-05 | Qual é a política de retentativa, já que a ata tem três leituras incompatíveis | `[09:17] Larissa` fecha "5 tentativas"; `[09:17] Diego` enumera cinco intervalos (1m/5m/30m/2h/12h) e soma "quase 15 horas" — 5 chamadas têm 4 intervalos, e as três não fecham | `[09:17] Larissa` · `[09:17] Diego` | **O pacote adota 5 chamadas e 4 intervalos (1m/5m/30m/2h), última tentativa em 2h36min.** A leitura precisa de ratificação: ela reduz a cobertura de ~15h para 2h36min e deixa só 36 min de margem sobre a indisponibilidade de 2h de `[09:16] Diego` |

`RFC-QA-01` e `RFC-QA-02` são as duas que o FDD resolve para poder escrever o
contrato. Em ambos os casos a escolha do FDD é **provisória** e não fecha esta
seção: se a revisão preferir a outra forma, o FDD muda e o RFC não.

## Impacto e riscos

O que muda no sistema existente é pontual e crítico: a transação de mudança de
status ganha mais uma escrita. Esse é o ponto de acoplamento e também o principal
risco — um defeito ali não degrada webhooks, derruba mudança de status de pedido.
A mitigação é a decisão de ADR-007, que isola a gravação numa função dedicada
sem inverter dependências do serviço de pedidos.

O segundo risco é de premissa, não de código. A reunião trabalhou sobre um
retrato do repositório que o disco só confirma em parte: a rota de consulta que
os clientes usariam está fechada a usuário interno (DIV-08) e não há usuário que
represente o cliente (DIV-07). Nenhuma das duas coisas bloqueia esta proposta,
mas as duas afetam quem consegue usar o resultado, e a resposta não está neste
documento.

Terceiro, a mudança de status não é o único ponto que produz transição no
histórico do pedido: a criação do pedido grava a transição inicial por um
caminho separado (DIV-11), e o enum de status tem valores que ninguém citou na
reunião (DIV-12). O pacote de eventos, portanto, precisa dizer explicitamente
quais transições emitem evento — o padrão silencioso seria emitir menos do que o
cliente espera.

Os pontos restantes não são defeito, são fronteira: divergências de vocabulário
e de convenção entre o que a reunião falou e o que o schema usa (DIV-01, DIV-02,
DIV-03, DIV-10). Nenhuma pede decisão de arquitetura, e todas são resolvidas
campo a campo no FDD.

A equipe assume: que o volume cabe em um worker único; que polling num banco
relacional atende a régua de dez segundos; e que o cliente implementa
deduplicação do seu lado, que é o contrato at-least-once.

## Decisões relacionadas

| ADR | Título | O que fecha |
|---|---|---|
| [ADR-001](adrs/ADR-001-outbox-no-mysql.md) | Outbox de eventos no MySQL já existente | Onde o evento nasce e por que não há infraestrutura nova |
| [ADR-002](adrs/ADR-002-worker-processo-separado-polling.md) | Worker em processo separado consumindo a outbox por polling | Quem consome, em que processo e por que polling |
| [ADR-003](adrs/ADR-003-retry-backoff-e-dlq-em-tabela-separada.md) | Retry com backoff exponencial e DLQ em tabela separada | O que acontece quando a entrega falha e onde ela morre |
| [ADR-004](adrs/ADR-004-hmac-sha256-secret-por-endpoint.md) | Assinatura HMAC-SHA256 com secret por endpoint | Como o cliente prova que o request veio de nós |
| [ADR-005](adrs/ADR-005-entrega-at-least-once-com-x-event-id.md) | Entrega at-least-once com X-Event-Id para dedup no cliente | Qual garantia de entrega é contratada e de quem é a dedup |
| [ADR-006](adrs/ADR-006-reuso-dos-padroes-existentes.md) | Reuso dos padrões existentes do projeto no módulo de webhooks | Que o módulo não inventa estrutura, erro nem log próprios |
| [ADR-007](adrs/ADR-007-insercao-na-outbox-dentro-da-transacao.md) | Inserção na outbox dentro da transação do `changeStatus` | A atomicidade entre mudar o status e registrar o evento |
| [ADR-008](adrs/ADR-008-modelo-de-autorizacao-do-modulo.md) | Modelo de autorização do módulo de webhooks | Quem pode gerir endpoints e quem pode disparar replay |
