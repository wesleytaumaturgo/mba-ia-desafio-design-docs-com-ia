# 02 — Extração forense da TRANSCRICAO.md

## Procedência

| Item | Valor |
|---|---|
| Comando de leitura | leitura integral do arquivo (`Read` sobre `TRANSCRICAO.md`, linhas 1–324, sem `offset`/`limit`) |
| `wc -l TRANSCRICAO.md` | `323 TRANSCRICAO.md` |
| `sha256sum TRANSCRICAO.md` | `cdc56e0e86430ce966ffac71229b6968137f943c465ea7d957117fd229f20f14  TRANSCRICAO.md` |
| Hash esperado (enunciado do bloco) | `cdc56e0e86430ce966ffac71229b6968137f943c465ea7d957117fd229f20f14` |
| Conferência | **BATE** |
| Janela coberta | `[09:00]` – `[09:53]` |
| Participantes | Bruno, Diego, Larissa, Marcos, Sofia |
| Arquivos de `src/`, `prisma/`, `tests/` lidos nesta sessão | **nenhum** (restrição do bloco) |

## Nota de método

Cinco convenções foram aplicadas de forma mecânica e valem para todas as tabelas
abaixo:

1. **Fechamento por acenos curtos.** Várias decisões são fechadas por uma fala de
   uma palavra (`"Faz."`, `"Beleza."`, `"Concordo."`, `"Bom."`, `"Faz sentido."`).
   A regra do bloco manda que a Localização seja a da fala que **fecha** — então é
   essa fala curta que aparece na coluna "Fala (literal)". O conteúdo da decisão
   fica na coluna de resumo, que é a coluna de paráfrase. Nenhuma fala foi
   estendida para "ficar mais informativa".
2. **Corte de 20 palavras.** Onde a fala original excede 20 palavras, a linha foi
   **dividida em duas linhas com IDs distintos** (marcadas `(1/2)` e `(2/2)`),
   nunca parafraseada. Isso infla a contagem bruta de linhas de RF e DEC em
   relação à contagem de requisitos conceituais; ver contagens ao fim.
3. **Sobreposição DEC × RNF é intencional.** O bloco exige que a tabela de RNF
   contenha *todo número dito em voz alta*, e a tabela de DEC contenha *tudo que
   foi decidido*. Números que também foram explicitamente fechados (2s, 5
   tentativas, 24h, 10s, 3 sprints) aparecem nas duas tabelas, com IDs distintos.
   Isso é duplicação deliberada, não erro de classificação.
4. **RF ficou com o que a reunião listou como comportamento de endpoint/contrato
   de saída.** Validações e limites numéricos que a própria reunião rebaixou a
   "não é decisão arquitetural, é requisito não funcional" (`[09:24] Larissa`)
   ou a "só uma validação no schema Zod" (`[09:23] Sofia`) foram para RNF, não
   para RF. Nenhum RF foi criado para atingir cota.
5. **Descartado × Adiado.** A separação segue exclusivamente o que foi dito. Onde
   a mesma coisa foi tratada nos dois registros (rate limiting, escala de
   workers), ela aparece em `## Adiado` **e** em `## Ambíguo`, com referência
   cruzada, porque a transcrição literalmente a rotulou das duas formas
   ("ponto em aberto" + "implementa se virar problema").

---

## Decisões fechadas

| ID | Decisão em uma linha | Fala (literal) | Localização | Quem fechou |
|---|---|---|---|---|
| DEC-01 | Eventos vão para uma tabela outbox no MySQL já existente, não para infra nova | "Tá decidido então: outbox em MySQL." | `[09:08] Larissa` | Larissa |
| DEC-02 | Worker consome a outbox por polling em loop, a cada 2 segundos | "Vamos registrar isso como uma decisão. Worker em polling, 2s." | `[09:10] Larissa` | Larissa |
| DEC-03 | Worker roda como processo separado da API, no mesmo banco e mesma stack | "Sim, mesmo banco, mesma stack. Só não pode ser o mesmo processo." | `[09:11] Diego` | Diego (registrado por Larissa em `[09:12] Larissa`) |
| DEC-04 | Single-worker: sem garantia de ordering global, só por order_id, e a limitação é documentada | "Documentamos como limitação conhecida. Não é garantia de ordering global, só por order_id e enquanto for single-worker." | `[09:13] Larissa` | Larissa |
| DEC-05 | Retry com backoff exponencial: 5 tentativas, progressão 1m/5m/30m/2h/12h, depois DLQ | "Decidido: 5 tentativas, backoff 1m/5m/30m/2h/12h." | `[09:17] Larissa` | Larissa |
| DEC-06 | DLQ em tabela separada `webhook_dead_letter`, com payload, motivo da falha e timestamp | "Faz sentido." | `[09:18] Bruno` | Bruno (proposta de Diego na mesma janela; ratificada por Larissa em `[09:48] Larissa`) |
| DEC-07 | Assinatura HMAC-SHA256 calculada sobre o corpo do request | "Decidido: HMAC-SHA256 sobre o corpo do request" | `[09:22] Sofia` | Sofia |
| DEC-08 | Secret única por endpoint de webhook, não global da plataforma | "secret por endpoint" | `[09:22] Sofia` | Sofia |
| DEC-09 | Secret rotacionável, com a antiga válida em paralelo por 24h | "suporte a rotação com grace period de 24h" | `[09:22] Sofia` | Sofia |
| DEC-10 | Entrega at-least-once, com dedup pelo cliente via header X-Event-Id | "At-least-once com X-Event-Id pra dedup do lado do cliente. Decisão." | `[09:26] Larissa` | Larissa |
| DEC-11 | Webhooks viram um módulo `src/modules/webhooks` no mesmo padrão dos demais domínios | "Faz." | `[09:28] Diego` | Diego (proposta de Bruno em `[09:27] Bruno`) |
| DEC-12 | `src/worker.ts` como entry-point separada; lógica de processamento em arquivo dentro do módulo | "Beleza." | `[09:28] Diego` | Diego (proposta de Bruno na mesma janela) |
| DEC-13 | Todos os códigos de erro do módulo levam prefixo `WEBHOOK_` | "Prefixo WEBHOOK_ pra tudo do módulo." | `[09:29] Larissa` | Larissa |
| DEC-14 | Worker instancia PrismaClient próprio, mesma DATABASE_URL, por ser outro processo Node | "Separado. PrismaClient é por processo." | `[09:30] Bruno` | Bruno |
| DEC-15 | Reuso máximo do que já existe (1/2): AppError, Pino, error middleware, padrão de módulos | "Decisão: reuso máximo do que já existe. AppError, Pino, error middleware, padrão de módulos" | `[09:30] Larissa` | Larissa |
| DEC-16 | Reuso máximo do que já existe (2/2): padrão de schemas Zod e de códigos de erro | "padrão de schemas Zod, padrão de códigos de erro." | `[09:30] Larissa` | Larissa |
| DEC-17 | Endpoint de cadastro é autenticado normal e o customer_id NÃO é derivado do JWT | "Então é endpoint autenticado normal, e o customer_id é passado no body ou no path. Não vem do JWT." | `[09:32] Larissa` | Larissa |
| DEC-18 | O filtro de status é aplicado na inserção do outbox, não na hora do envio | "Concordo." | `[09:34] Diego` | Diego (proposta de Bruno na mesma janela) |
| DEC-19 | Replay de DLQ exige role ADMIN e reaproveita o `requireRole` existente | "Decidido, role ADMIN obrigatório no replay e a gente reaproveita o requireRole que já existe." | `[09:36] Larissa` | Larissa |
| DEC-20 | CRUD de configuração de webhook fica aberto a qualquer role autenticada por enquanto | "Por enquanto sim." | `[09:37] Sofia` | Sofia |
| DEC-21 | Inserção na `webhook_outbox` acontece dentro da mesma transação do changeStatus, com rollback se falhar | "Essencial. Se ficar fora da transação, perde a garantia toda." | `[09:41] Diego` | Diego (proposta de Bruno em `[09:40] Bruno`) |
| DEC-22 | Integração via função que recebe o tx da transação, sem injetar repository no OrderService | "Boa, função pura recebendo o tx. Não precisa injetar repository inteiro." | `[09:41] Diego` | Diego |
| DEC-23 | Timeout de 10 segundos no HTTP call do worker; estouro vira falha e vai pra retry | "Bom." | `[09:42] Sofia` | Sofia (número proposto por Diego na mesma janela) |
| DEC-24 | Payload enxuto: não carrega items; cliente busca detalhe depois no GET /orders/:id | "Bom, mantém payload enxuto." | `[09:44] Bruno` | Bruno |
| DEC-25 | Prazo estimado de três sprints, já com a revisão de segurança da Sofia no fim | "Combinado. Três sprints com a revisão da Sofia incluída no fim." | `[09:47] Larissa` | Larissa |
| DEC-26 | Id da outbox é UUID, seguindo o padrão do resto do projeto | "UUID, segue o padrão do resto do projeto. Tudo é uuid." | `[09:51] Larissa` | Larissa |
| DEC-27 | Outbox guarda o payload já renderizado (snapshot no momento da inserção) | "Beleza, snapshot. Decidido." | `[09:52] Bruno` | Bruno (preferência de Larissa em `[09:52] Larissa`, concordância de Diego em `[09:52] Diego`) |

---

## Requisitos funcionais

| ID | Requisito | Fala (literal) | Localização |
|---|---|---|---|
| RF-01 | Cliente cadastra webhook por endpoint POST, informando a url | "O cliente precisa cadastrar webhook. Endpoint POST. Campos: url" | `[09:31] Marcos` |
| RF-02 | A secret é gerada pela plataforma e devolvida na resposta da criação | "secret é gerada pela gente e devolvida na criação" | `[09:31] Marcos` |
| RF-03 | Editar (PATCH), remover (DELETE) e listar por customer (GET) os webhooks | "PATCH pra editar, DELETE pra remover, GET pra listar os webhooks de um customer." | `[09:33] Bruno` |
| RF-04 | Cada endpoint define a lista de status que quer ouvir | "Filtro de eventos é uma lista dos status que o webhook quer ouvir." | `[09:33] Marcos` |
| RF-05 | Cliente pede nova secret pela API (rotação) | "Endpoint pro cliente conseguir pedir nova secret pela API." | `[09:21] Sofia` |
| RF-06 | Consulta do histórico de entregas de um webhook | "GET /webhooks/:id/deliveries." | `[09:34] Marcos` |
| RF-07 | O histórico expõe os últimos 100 envios com sucesso/falha, payload, response e tempo de resposta | "esses são os últimos 100 webhooks que vocês mandaram pra mim, sucesso/falha, payload, response, tempo de resposta" | `[09:34] Marcos` |
| RF-08 | Replay manual de item da DLQ por endpoint admin, recolocando o evento na outbox como pendente | "Manual via endpoint admin. Tipo um POST /admin/webhooks/dead-letter/:id/replay. Recoloca na outbox como pendente." | `[09:18] Diego` |
| RF-09 | Payload JSON do evento (1/2): identificação, tipo, timestamp e chaves do pedido | "JSON com event_id, event_type tipo "order.status_changed", timestamp ISO 8601, order_id, order_number, from_status, to_status, customer_id" | `[09:43] Diego` |
| RF-10 | Payload JSON do evento (2/2): campos básicos da order, sem items | "e os campos básicos da order tipo total_cents. Não manda items pra não inflar." | `[09:43] Diego` |
| RF-11 | Headers do request de entrega (1/2): identificação, assinatura e timestamp de envio | "X-Event-Id com o UUID, X-Signature com o HMAC, X-Timestamp com o timestamp do envio" | `[09:44] Diego` |
| RF-12 | Headers do request de entrega (2/2): content type | "Content-Type application/json." | `[09:44] Diego` |
| RF-13 | Header X-Webhook-Id com o id do endpoint cadastrado, para cliente com vários webhooks | "Adiciona um X-Webhook-Id também, com o id do endpoint webhook" | `[09:44] Sofia` |

> Contagem conceitual: 13 linhas, das quais RF-09/RF-10 e RF-11/RF-12 são pares
> divididos pelo corte de 20 palavras. Nenhuma linha foi criada para completar
> cota; nenhum requisito foi inferido de "faria sentido ter".

---

## Requisitos não funcionais e restrições

| ID | Item | Tipo | Fala (literal) | Localização |
|---|---|---|---|---|
| RNF-01 | Definição de "tempo real" pelos clientes: abaixo de 10 segundos | performance | "qualquer coisa abaixo de 10 segundos" | `[09:02] Marcos` |
| RNF-02 | Intervalo de polling do worker: 2 segundos | performance | "A cada 2 segundos, busca os eventos pendentes mais antigos, processa, marca." | `[09:09] Diego` |
| RNF-03 | Latência de entrega aceita: 2 segundos no pior caso | performance | "A latência mínima vai ser 2 segundos no pior caso. Aceitamos." | `[09:10] Larissa` |
| RNF-04 | Índices exigidos na outbox: campo de status e created_at | performance | "A tabela tem índice no campo de status (pendente, processando, falhou, entregue) e em created_at." | `[09:08] Diego` |
| RNF-05 | Worker lê apenas pendentes, em batch pequeno | performance | "Worker lê só os pendentes em batch pequeno, processa, marca como entregue." | `[09:08] Diego` |
| RNF-06 | Arquivamento de linhas entregues após ~30 dias — fora do escopo desta feature (ver REC-11) | operação | "Linhas entregues a gente arquiva depois de 30 dias ou assim, fora do escopo dessa feature." | `[09:08] Diego` |
| RNF-07 | Número de tentativas antes da DLQ: 5 | operação | "Decidido: 5 tentativas, backoff 1m/5m/30m/2h/12h." | `[09:17] Larissa` |
| RNF-08 | Progressão do backoff: 1 minuto, 5 minutos, 30 minutos, 2 horas, 12 horas | operação | "Eu pensei em 1 minuto, 5 minutos, 30 minutos, 2 horas, 12 horas." | `[09:17] Diego` |
| RNF-09 | Janela total entre primeira falha e última tentativa: quase 15 horas | operação | "Total de quase 15 horas entre primeira falha e última tentativa." | `[09:17] Diego` |
| RNF-10 | Cobertura pretendida da janela de retry: 12 a 24 horas | operação | "Cinco já dá pra cobrir uma janela de até 12 ou 24 horas." | `[09:15] Diego` |
| RNF-11 | Premissa histórica: cliente já teve indisponibilidade de duas horas em manutenção planejada | operação | "Já tinha cliente nosso com indisponibilidade de duas horas em manutenção planejada." | `[09:16] Diego` |
| RNF-12 | Cenário citado ao rejeitar 3 tentativas: três retries em 30 minutos (ver REC-05) | operação | "a gente retentaria três vezes em 30 minutos e mataria" | `[09:16] Diego` |
| RNF-13 | Grace period da secret antiga após rotação: 24 horas | segurança | "a antiga fica válida por 24 horas em paralelo" | `[09:21] Sofia` |
| RNF-14 | TLS obrigatório: url do webhook precisa ser https | segurança | "TLS obrigatório. URL do webhook tem que ser https." | `[09:23] Sofia` |
| RNF-15 | Cadastro com http é recusado com erro de validação, no schema Zod | segurança | "Se o cliente cadastrar http, recusamos com erro de validação." | `[09:23] Sofia` |
| RNF-16 | Tamanho anômalo citado como motivação do limite: 500KB | operação | "Se por algum motivo o evento tiver 500KB, a gente não envia." | `[09:23] Sofia` |
| RNF-17 | Limite de tamanho de payload: 64KB, com erro caso ultrapasse | operação | "64KB de limite, erro caso ultrapasse." | `[09:24] Larissa` |
| RNF-18 | Contrato at-least-once: o cliente tem que suportar receber o mesmo evento duas vezes | compatibilidade | "Pode acontecer de o cliente receber o mesmo evento duas vezes." | `[09:24] Diego` |
| RNF-19 | Histórico de entregas exposto: últimos 100 envios | operação | "esses são os últimos 100 webhooks" | `[09:34] Marcos` |
| RNF-20 | Auditoria: o endpoint admin registra quem executou o replay | segurança | "o endpoint de admin tem que logar quem fez o replay, pra auditoria" | `[09:36] Sofia` |
| RNF-21 | Cenário de carga citado: 50 pedidos mudando de status em um minuto para um cliente | performance | "Se o cliente tem 50 pedidos mudando de status em um minuto" | `[09:38] Diego` |
| RNF-22 | Timeout do HTTP call do worker: 10 segundos | performance | "10 segundos. Cliente lento que não responde em 10s a gente trata como falha" | `[09:42] Diego` |
| RNF-23 | Prazo comercial: entrega para fim de novembro | operação | "A Atlas quer pra fim de novembro." | `[09:45] Marcos` |
| RNF-24 | Pressão de negócio: risco de migração para o concorrente se não entregar até fim do trimestre | operação | "se a gente não entregar isso até fim do trimestre, eles podem migrar pro nosso concorrente" | `[09:00] Marcos` |
| RNF-25 | Demanda originada de três clientes B2B nomeados | operação | "um pedido formal de três clientes B2B: Atlas Comercial, MaxDistribuição e Nova Cargo" | `[09:00] Marcos` |
| RNF-26 | Estimativa de esforço: três sprints, revisão de segurança incluída | operação | "Três sprints com a revisão da Sofia incluída no fim." | `[09:47] Larissa` |
| RNF-27 | Reserva de pelo menos dois dias úteis para revisão de segurança antes do deploy | segurança | "Reservem pelo menos dois dias úteis pra eu revisar o código de segurança antes do deploy." | `[09:46] Sofia` |

---

## Descartado

| ID | Item | Motivo dito | Fala (literal) | Localização | Termo-âncora |
|---|---|---|---|---|---|
| REC-01 | Disparo síncrono do webhook dentro do service de orders | Transação de mudança de status já é pesada e cliente lento travaria os outros pedidos; e não daria pra dar rollback se o cliente estivesse fora do ar (`[09:04] Bruno`) | "Síncrono está fora de questão." | `[09:06] Diego` | `Síncrono` |
| REC-02 | Redis Streams / Redis Cluster como transporte dos eventos | Exigiria subir mais infra e é overengineering para um time pequeno | "Exato, e a gente é um time pequeno. Subir Redis Cluster pra isso é overengineering." | `[09:07] Diego` | `Redis` |
| REC-03 | Trigger de banco para notificar o worker de forma reativa | MySQL não tem listener nativo; a trigger só executa SQL e não avisa processo externo | "MySQL não tem listener nativo tipo o NOTIFY/LISTEN do Postgres." | `[09:09] Diego` | `trigger do banco` |
| REC-04 | Retry indefinido com backoff | Evento ficaria pendurado para sempre se o cliente sumisse | "Algumas pessoas defendem retry indefinido com backoff, mas isso traz o problema de evento ficar pendurado" | `[09:15] Diego` | `retry indefinido` |
| REC-05 | Limite de 3 tentativas de entrega | Cobriria só 30 minutos e mataria o evento antes de indisponibilidades reais | "3 é pouco. Se o cliente teve indisponibilidade de manhã, a gente retentaria três vezes em 30 minutos e mataria." | `[09:16] Diego` | `3 é pouco` |
| REC-06 | Marcar falha permanente como "failed" na própria outbox, sem tabela de DLQ | Tabela separada mantém a leitura da outbox principal mais limpa e serve de evidence para debug e reprocessamento | "Eu fazia uma tabela webhook_dead_letter separada, com a payload, motivo da falha e timestamp." | `[09:18] Diego` | `"failed" na própria outbox` |
| REC-07 | Truncar o payload que ultrapassa o limite de tamanho | Se chegou nesse tamanho, tem algo errado — melhor errar | "Trunca? Erra? Eu sou a favor de erra." | `[09:23] Sofia` | `Trunca` |
| REC-08 | Garantia de entrega exactly-once | Exigiria coordenação dos dois lados e ficaria muito mais complexo | "Garantir exactly-once exigiria coordenação dos dois lados e fica muito mais complexo." | `[09:25] Diego` | `exactly-once` |
| REC-09 | customer_id derivado implicitamente do JWT | O JWT atual é do usuário operador, não do cliente (`[09:32] Bruno`) | "Não vem do JWT." | `[09:32] Larissa` | `implícito do JWT` |
| REC-10 | Dashboard/painel visual para o cliente acompanhar os webhooks | É projeto separado do time de frontend; a entrega desta feature é só endpoints | "Não, agora não. Só endpoints. Painel é projeto separado do time de frontend." | `[09:40] Larissa` | `Painel` |

> Classificação de REC-10: a fala em `[09:40] Larissa` mistura sinal temporal
> ("agora não") com atribuição a outro time. O desempate veio do resumo
> ratificado da própria reunião, que separa explicitamente os dois casos —
> "Email como fallback fica pra próxima fase. […] Dashboard visual fora de
> escopo." (`[09:48] Larissa`), confirmado em `[09:49] Diego`. Descartado,
> portanto, por texto da transcrição e não por julgamento do analista.

## Adiado para fase futura

| ID | Item | Motivo dito | Fala (literal) | Localização | Termo-âncora |
|---|---|---|---|---|---|
| REC-11 | Arquivamento das linhas já entregues da outbox | Declarado fora do escopo desta feature | "Linhas entregues a gente arquiva depois de 30 dias ou assim, fora do escopo dessa feature." | `[09:08] Diego` | `arquiva` |
| REC-12 | Escalar para múltiplos workers, particionando por order_id ou usando lock pessimista | É problema do futuro, não de agora | "Aí dá pra particionar por order_id, ou usar lock pessimista. Mas isso é problema do futuro, não agora." | `[09:13] Diego` | `lock pessimista` |
| REC-13 | Aviso por email ao cliente quando o webhook dele falha | Fora de escopo desta fase; talvez na próxima, depois de medir o impacto | "Não. Email tá fora de escopo dessa fase. Talvez próxima fase, depois que a gente medir o impacto." | `[09:37] Larissa` | `Email` |
| REC-14 | Endurecimento do controle de acesso do CRUD de configuração | Por enquanto qualquer role autenticada serve; endurece mais pra frente | "Por enquanto sim. Mais pra frente a gente pode endurecer." | `[09:37] Sofia` | `endurecer` |
| REC-15 | Rate limiting de envio para o cliente | Observa e implementa se virar problema (também registrado como ponto em aberto — ver QA-03) | "Eu acho que não. A gente observa e implementa se virar problema." | `[09:39] Diego` | `rate limiting` |

## Ambíguo ou não decidido

| ID | Ponto | Por que ficou aberto | Fala (literal) | Localização |
|---|---|---|---|---|
| QA-01 | Se o customer_id vai no body ou no path da requisição de cadastro | A fala fecha apenas o que ele NÃO é (não vem do JWT) e oferece as duas alternativas sem escolher | "o customer_id é passado no body ou no path" | `[09:32] Larissa` |
| QA-02 | Nome do arquivo que abriga a lógica de processamento do worker | Bruno oferece dois nomes e o fechamento é um aceno genérico, sem eleger um | "tipo src/modules/webhooks/webhook.worker.ts ou webhook.processor.ts" | `[09:28] Bruno` |
| QA-03 | Rate limiting de envio para o cliente | A própria reunião pediu que ficasse registrado como ponto em aberto, além de tirá-lo do escopo (ver REC-15) | "Mas vale registrar como ponto em aberto." | `[09:39] Diego` |
| QA-04 | Garantia de ordering quando houver mais de um worker | A perda da garantia foi reconhecida e a solução foi empurrada para o futuro sem escolha entre particionamento e lock (ver REC-12) | "Se a gente escala pra múltiplos workers em paralelo no futuro, perde a garantia." | `[09:12] Diego` |

---

## Confronto com os seis nomes do enunciado

| Nome do enunciado | Encontrado? | ID correspondente ou [ausente na transcrição] | Localização |
|---|---|---|---|
| Padrão Outbox no MySQL | Sim | DEC-01 (e DEC-21 para a atomicidade com o changeStatus) | `[09:08] Larissa` |
| Retry com backoff e DLQ | Sim | DEC-05 (retry/backoff) e DEC-06 (DLQ em tabela separada) | `[09:17] Larissa` · `[09:18] Bruno` |
| HMAC-SHA256 com secret por endpoint | Sim | DEC-07 (HMAC-SHA256) e DEC-08 (secret por endpoint); DEC-09 acrescenta rotação com grace de 24h | `[09:22] Sofia` |
| At-least-once com X-Event-Id | Sim | DEC-10 | `[09:26] Larissa` |
| Worker em processo separado em polling | Sim | DEC-03 (processo separado) e DEC-02 (polling de 2s); DEC-12 define a entry-point | `[09:11] Diego` · `[09:10] Larissa` |
| Reuso dos padrões existentes do projeto | Sim | DEC-15 e DEC-16 (par dividido); reforçado por DEC-11, DEC-13 e DEC-19 | `[09:30] Larissa` |

Os seis nomes têm fala correspondente na transcrição — nenhum precisou ser
marcado como `[ausente na transcrição]`.

Decisões fechadas na transcrição que **não** estão entre os seis nomes do
enunciado, registradas normalmente acima: DEC-04 (limitação de ordering),
DEC-14 (PrismaClient por processo), DEC-17 (customer_id fora do JWT), DEC-18
(filtro na inserção do outbox), DEC-19 (role ADMIN no replay), DEC-20 (CRUD
aberto a qualquer role autenticada), DEC-22 (`publishWebhookEvent` recebendo o
tx), DEC-23 (timeout de 10s), DEC-24 (payload sem items), DEC-25 (três
sprints), DEC-26 (UUID como id da outbox) e DEC-27 (snapshot do payload na
inserção).

---

## Validação de Localização

Toda Localização citada nos três artefatos deste bloco
(`02-transcricao.md`, `02-recusa.md`, `02-ganchos-declarados.md`) foi conferida
contra o arquivo com `grep -cF "<localização>" TRANSCRICAO.md`. Saída literal do
comando:

```
grep -ohE '\[[0-9]{2}:[0-9]{2}\] (Bruno|Diego|Larissa|Marcos|Sofia)' \
  .planning/02-transcricao.md .planning/02-recusa.md .planning/02-ganchos-declarados.md \
  | sort -u | while IFS= read -r loc; do echo "$loc  $(grep -cF "$loc" TRANSCRICAO.md)"; done
```

72 localizações distintas. **Nenhuma com zero ocorrências.**

| Localização | ocorrências |
|---|---|
| `[09:00] Marcos` | 1 |
| `[09:02] Marcos` | 2 |
| `[09:03] Larissa` | 1 |
| `[09:04] Bruno` | 2 |
| `[09:06] Diego` | 2 |
| `[09:07] Diego` | 1 |
| `[09:08] Diego` | 1 |
| `[09:08] Larissa` | 1 |
| `[09:09] Diego` | 2 |
| `[09:10] Larissa` | 1 |
| `[09:11] Bruno` | 1 |
| `[09:11] Diego` | 2 |
| `[09:11] Larissa` | 1 |
| `[09:12] Diego` | 1 |
| `[09:12] Larissa` | 1 |
| `[09:13] Diego` | 1 |
| `[09:13] Larissa` | 1 |
| `[09:15] Diego` | 2 |
| `[09:16] Diego` | 1 |
| `[09:17] Diego` | 1 |
| `[09:17] Larissa` | 1 |
| `[09:18] Bruno` | 1 |
| `[09:18] Diego` | 2 |
| `[09:21] Sofia` | 2 |
| `[09:22] Sofia` | 1 |
| `[09:23] Sofia` | 2 |
| `[09:24] Diego` | 2 |
| `[09:24] Larissa` | 1 |
| `[09:25] Diego` | 2 |
| `[09:26] Larissa` | 1 |
| `[09:27] Bruno` | 1 |
| `[09:28] Bruno` | 2 |
| `[09:28] Diego` | 2 |
| `[09:29] Bruno` | 1 |
| `[09:29] Diego` | 1 |
| `[09:29] Larissa` | 1 |
| `[09:30] Bruno` | 1 |
| `[09:30] Larissa` | 1 |
| `[09:31] Marcos` | 1 |
| `[09:32] Bruno` | 1 |
| `[09:32] Larissa` | 1 |
| `[09:32] Marcos` | 1 |
| `[09:33] Bruno` | 1 |
| `[09:33] Marcos` | 1 |
| `[09:34] Diego` | 2 |
| `[09:34] Marcos` | 1 |
| `[09:35] Larissa` | 2 |
| `[09:36] Larissa` | 1 |
| `[09:36] Sofia` | 1 |
| `[09:37] Larissa` | 1 |
| `[09:37] Sofia` | 1 |
| `[09:38] Diego` | 1 |
| `[09:39] Diego` | 1 |
| `[09:40] Bruno` | 1 |
| `[09:40] Larissa` | 1 |
| `[09:41] Bruno` | 1 |
| `[09:41] Diego` | 2 |
| `[09:42] Diego` | 1 |
| `[09:42] Sofia` | 2 |
| `[09:43] Diego` | 1 |
| `[09:44] Bruno` | 1 |
| `[09:44] Diego` | 1 |
| `[09:44] Sofia` | 1 |
| `[09:45] Marcos` | 1 |
| `[09:46] Sofia` | 1 |
| `[09:47] Larissa` | 2 |
| `[09:48] Larissa` | 1 |
| `[09:49] Diego` | 1 |
| `[09:51] Larissa` | 1 |
| `[09:52] Bruno` | 1 |
| `[09:52] Diego` | 1 |
| `[09:52] Larissa` | 1 |

Critério de parada do bloco: zero ocorrências em qualquer linha exigiria PARAR e REPORTAR. Não ocorreu — o menor valor da coluna é 1.

