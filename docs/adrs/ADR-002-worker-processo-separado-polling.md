# ADR-002 — Worker em processo separado consumindo a outbox por polling

## Status
Aceito — 2026-08-19 · decidido em reunião técnica de [09:00]–[09:53]

## Contexto

Decidida a outbox (ADR-001), a pergunta seguinte foi quem lê a tabela e entrega o
evento ao cliente. Diego desenhou o consumo na mesma janela em que a outbox foi
fechada: `[09:08] Diego` — "Worker lê só os pendentes em batch pequeno, processa,
marca como entregue." — e cravou o ritmo em `[09:09] Diego`: "A cada 2 segundos,
busca os eventos pendentes mais antigos, processa, marca."

O custo dessa forma de consumo foi colocado na mesa e aceito explicitamente na
reunião, não descoberto depois: `[09:10] Larissa` — "A latência mínima vai ser 2
segundos no pior caso. Aceitamos." A régua do cliente é de 10 segundos
(`[09:02] Marcos`), então 2 segundos cabem com folga.

A segunda pergunta foi onde esse loop roda. O projeto tem hoje uma única
entry-point HTTP, `src/server.ts`:6 (`bootstrap`), que sobe o servidor
(`src/server.ts`:9) e trata `SIGINT`/`SIGTERM` (`src/server.ts`:20–21) — é o
modelo disponível para uma segunda entry-point. O acesso ao banco já tem a forma
pronta para dois processos: `src/config/database.ts` exporta a factory
`createPrismaClient` (linha 4) e o singleton `prisma` (linha 10), e a
`DATABASE_URL` é obrigatória no schema Zod de ambiente (`src/config/env.ts`:7),
espelhada em `prisma/schema.prisma`:7 e em `.env.example`. Não existe hoje
nenhum processo de background no repositório: `grep -rniE 'worker' src/ prisma/
tests/ package.json` e a busca por `cron|scheduler|setInterval` retornam ambas
vazias.

## Decisão

O consumo da outbox é feito por um worker em processo separado da API, em polling de 2 segundos, lendo apenas os pendentes mais antigos em batch pequeno e marcando
o resultado na própria linha. Mesmo banco e mesma stack da API — o que não pode
é ser o mesmo processo. A entry-point é `src/worker.ts` (novo), espelhando
`src/server.ts`:6; a lógica de processamento fica num arquivo dentro do módulo,
`src/modules/webhooks/webhook.processor.ts` (novo) — o nome do arquivo é a
resolução provisória de `RFC-QA-02`, que a reunião deixou em aberto ao oferecer
dois nomes sem eleger um (`[09:28] Bruno`). O worker instancia o próprio
`PrismaClient` pela factory `createPrismaClient` (`src/config/database.ts`:4),
com a mesma `DATABASE_URL`, em vez de importar o singleton usado pela API.

Falas que fecham:

- `[09:10] Larissa` — "Vamos registrar isso como uma decisão. Worker em polling,
  2s." — **DEC-02**.
- `[09:11] Diego` — "Sim, mesmo banco, mesma stack. Só não pode ser o mesmo
  processo." — **DEC-03**.
- `[09:28] Diego` — "Beleza." (entry-point separada e lógica em arquivo do
  módulo) — **DEC-12**.
- `[09:30] Bruno` — "Separado. PrismaClient é por processo." — **DEC-14**.

## Alternativas Consideradas

### Worker no mesmo processo da API

Rodar o loop de entrega dentro do processo HTTP, por `setInterval` ou
equivalente, sem segunda entry-point nem segundo deploy.

- Quem levantou e quando: a transcrição não registra defesa dessa opção; ela é
  nomeada na própria fala que a exclui, `[09:11] Diego`.
- **Motivo do descarte:** `[09:11] Diego` — "Sim, mesmo banco, mesma stack. Só
  não pode ser o mesmo processo." O trade-off registrado é isolamento: no mesmo
  processo, o loop de entrega e o tráfego HTTP disputam o mesmo event loop e caem
  juntos.

### Notificação reativa por trigger de banco

Em vez de o worker perguntar de dois em dois segundos, o banco avisaria quando
uma linha nova entrasse na outbox — eliminando a latência de polling.

- Quem levantou e quando: `[09:09] Diego`, na mesma janela em que o polling foi
  desenhado.
- **Motivo do descarte:** `[09:09] Diego` — "MySQL não tem listener nativo tipo o
  NOTIFY/LISTEN do Postgres." (REC-03; ver também a nota DIV-05 em ADR-001, que
  registra que a trigger citada como já existente não existe no repositório).

### Worker consumindo em batch grande, com intervalo maior

Ler muitos eventos por ciclo, com um intervalo mais longo entre leituras, para
reduzir o número de queries contra o MySQL.

- `(alternativa plausível, não discutida na reunião)`
- **Motivo do descarte:** contraria diretamente o desenho dito em
  `[09:08] Diego` — "Worker lê só os pendentes em batch pequeno, processa, marca
  como entregue." — e aumentaria a latência acima dos 2 segundos aceitos em
  `[09:10] Larissa`.

## Consequências

### Positivas

- A transação de mudança de status termina sem esperar rede: um cliente lento ou
  fora do ar não segura o pedido, que era exatamente o custo do disparo síncrono
  recusado em ADR-001.
- O worker sobe, cai e é reiniciado sem tocar na API, e vice-versa — processos
  independentes, mesma stack e mesmo banco (`[09:11] Diego`).
- Nenhuma dependência nova: o processo reaproveita `env`
  (`src/config/env.ts`:27), a factory `createPrismaClient`
  (`src/config/database.ts`:4) e o runtime já declarado em `package.json`:8
  (`"node": ">=20"`), com `"type": "module"` em `package.json`:6.
- A factory `createLogger` (`src/shared/logger/index.ts`:13) já existe
  exatamente para o caso de um processo que precisa do próprio logger, em vez do
  singleton.

### Negativas

- **Perda da garantia de ordering global — a limitação que a reunião mandou
  documentar (DEC-04).** `[09:13] Larissa` — "Documentamos como limitação
  conhecida. Não é garantia de ordering global, só por order_id e enquanto for
  single-worker." A ordem por `order_id` vale enquanto houver um único worker; o
  cenário que a expõe foi descrito em `[09:12] Diego` — "Se a gente escala pra
  múltiplos workers em paralelo no futuro, perde a garantia." (registrado como
  ponto em aberto `RFC-QA-04`). O custo prático: com um worker só, a vazão de
  entrega é o teto da feature, e o cenário citado na reunião —
  `[09:38] Diego`, "Se o cliente tem 50 pedidos mudando de status em um minuto" —
  é atendido em série, não em paralelo.
- **A configuração de pool que a reunião presumiu não existe (DIV-06).**
  `[09:29] Diego` — "o pool de conexão do Prisma já tá lá". O disco mostra outra
  coisa: `createPrismaClient` passa apenas `log` ao `PrismaClient`
  (`src/config/database.ts`:4–8) e não há `connection_limit` ou configuração de
  pool em `src/`, `prisma/`, `.env.example` ou `docker-compose.yml`. O pool
  existe por default do Prisma, não por decisão do projeto. Consequência: subir
  um segundo processo Node dobra o número de conexões default contra o MySQL sem
  que ninguém tenha dimensionado o limite — o dimensionamento vira trabalho novo,
  não herdado.
- Latência mínima de 2 segundos mesmo com tudo saudável, e polling constante
  contra o MySQL mesmo quando não há evento nenhum para entregar: o custo de
  leitura é pago por ciclo, não por evento.
- Um segundo processo para empacotar, subir, supervisionar e observar. O
  repositório não tem precedente disso — nem scheduler, nem worker, nem
  supervisor: as buscas por `worker` e por `cron|scheduler|setInterval` em
  `src/`, `prisma/`, `tests/` e `package.json` retornam vazias. Scripts de
  execução, healthcheck e política de restart do worker são trabalho novo de
  operação.
