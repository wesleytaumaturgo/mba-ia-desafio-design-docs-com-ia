# PRD — Sistema de webhooks para eventos de mudança de status de pedido

## Resumo e contexto

Este documento consolida, em nível de produto, a proposta já detalhada em
[docs/RFC.md](RFC.md) (a arquitetura) e em [docs/FDD.md](FDD.md) (o contrato
técnico): um sistema de webhooks que notifica clientes B2B integradores sempre
que um pedido muda de status. O evento nasce dentro da transação que já altera o
status do pedido, é persistido numa tabela outbox no MySQL que o projeto já usa
e é entregue por um processo separado, assinado e com política de retry finita
antes de cair numa fila de eventos mortos com replay administrativo.

O PRD não repete arquitetura nem contrato: ele existe para responder, para quem
aprova a feature e não para quem a implementa, três perguntas — por que isso
importa agora, o que exatamente entra e não entra no primeiro corte, e como
saberemos que funcionou. As decisões estruturantes já foram tomadas e estão
documentadas nos ADRs referenciados abaixo; este documento aponta para elas em
vez de reabri-las.

## Problema e motivação

A demanda não nasceu de iniciativa técnica interna. Ela chegou como pedido
formal de três clientes B2B nomeados — Atlas Comercial, MaxDistribuição e Nova
Cargo (RNF-25, `[09:00] Marcos`) — e carrega peso comercial explícito: "se a
gente não entregar isso até fim do trimestre, eles podem migrar pro nosso
concorrente" (RNF-24, `[09:00] Marcos`). O prazo combinado com a área comercial
é o fim de novembro (PRD-RNF-21, `[09:45] Marcos`).

Hoje esses clientes só descobrem que um pedido mudou de status voltando a
perguntar — a premissa declarada na reunião é que eles "ficam batendo no GET
/orders de tempos em tempos" (`[09:00] Marcos`). **Ressalva registrada
(DIV-08):** o produto que existe hoje não oferece essa consulta ao cliente
externo. Não há credencial que um cliente de fora possa usar; a verificação
técnica dessa afirmação está em [docs/RFC.md](RFC.md) §Contexto e problema e em
[ADR-008](adrs/ADR-008-modelo-de-autorizacao-do-modulo.md). O problema real é,
portanto, mais forte do que o narrado: não há hoje nenhum caminho de
auto-atendimento para esses clientes, e a reunião projetou o comportamento de
polling a partir de uma capacidade que o sistema não oferece. Essa divergência
não invalida a demanda — só muda a régua de comparação: a alternativa a este
produto não é "o cliente continua consultando", é "o cliente continua sem
visibilidade nenhuma".

A régua de aceitação de latência foi dada pelos próprios clientes e é
generosa: "qualquer coisa abaixo de 10 segundos" já conta como tempo real para
eles (RNF-01, `[09:02] Marcos`). É essa folga que torna viável resolver o
problema sem subir infraestrutura de mensageria nova, usando o banco que o
projeto já opera.

## Público-alvo e cenários de uso

O consumidor direto da capacidade é o cliente B2B integrador — hoje, os três
clientes nomeados que fizeram o pedido, mas o desenho não é fechado a eles.
Esse público consome a feature via API: cadastra um ou mais endpoints,
declara os status de pedido que quer ouvir, recebe entregas assinadas e
consulta o histórico recente quando precisa investigar uma falha.

Há um segundo público, interno, que a reunião não nomeou explicitamente mas
que a leitura do sistema atual expõe: quem hoje opera o cadastro de configuração
de webhook em nome do cliente é um usuário da própria plataforma, porque o
produto ainda não tem uma identidade de cliente que se autentique diretamente
(DIV-07, que confirma DEC-17 — o identificador do cliente não pode ser derivado
da autenticação; evidência em
[ADR-008](adrs/ADR-008-modelo-de-autorizacao-do-modulo.md)). Na prática,
portanto, o cenário de uso imediato é: um operador interno cadastra e mantém a
configuração de webhook em nome do cliente integrador, enquanto o cliente
integrador é quem recebe e consome as entregas.
Cenários cobertos: cadastro inicial de um endpoint por cliente; edição de
filtro de status conforme o cliente muda o que quer acompanhar; rotação de
secret por política de segurança do próprio cliente; consulta do histórico de
entregas para diagnosticar uma integração que parou de responder; e replay
administrativo de um evento que esgotou as tentativas de entrega.

## Objetivos e métricas de sucesso

| Objetivo | Métrica | Meta | Origem |
|---|---|---|---|
| Eliminar a necessidade de o cliente consultar a API repetidamente para saber de mudanças de status | Tempo entre a transição de status e a primeira tentativa de entrega | abaixo de 10 segundos | RNF-01, `[09:02] Marcos` |
| Cumprir o compromisso comercial assumido com os três clientes que pediram a feature | Data de disponibilidade em produção | até o fim de novembro | PRD-RNF-21, `[09:45] Marcos` |
| Não sacrificar segurança pela pressão de prazo | Janela reservada para revisão de segurança antes do deploy | pelo menos 2 dias úteis | RNF-27, `[09:46] Sofia` |

## Escopo

### Incluso no escopo

- Cadastro, edição, remoção e listagem de endpoints de webhook por cliente, com
  filtro configurável de quais status de pedido cada endpoint quer ouvir.
- Emissão da secret na criação do endpoint e rotação de secret sob demanda,
  pela API.
- Entrega assinada de cada evento de mudança de status, com garantia
  at-least-once e identificador de evento para o cliente deduplicar do seu
  lado.
- Política de retentativa finita para entregas que falham, com uma fila de
  eventos que esgotaram as tentativas e replay manual dessa fila por um
  endpoint administrativo.
- Consulta ao histórico recente de entregas de um endpoint, para o cliente ou
  o operador diagnosticarem uma integração com problema.

### Fora de escopo

Nenhum item desta lista carrega ID de requisito — cada um foi explicitamente
recusado ou adiado na reunião que originou este produto, e reaparecer como
requisito vigente contradiria a própria decisão registrada.

Descartados nesta fase:

- Disparo síncrono do webhook dentro da transação de mudança de status do pedido — descartado, `[09:06] Diego`.
- Redis Streams (ou qualquer broker externo) como transporte dos eventos — descartado, `[09:07] Diego`.
- Gatilho de banco de dados (trigger) para notificar o processo de entrega de forma reativa, no lugar do intervalo de leitura — descartado, `[09:09] Diego`.
- Retry sem teto de tentativas, prolongado indefinidamente — descartado, `[09:15] Diego`.
- Teto de apenas 3 tentativas de entrega antes de desistir do evento, cenário citado ao rejeitar essa opção (RNF-12) — descartado, `[09:16] Diego`.
- Registrar a falha permanente na própria tabela de eventos pendentes, sem uma fila separada para eventos mortos — descartado, `[09:18] Diego`.
- Encurtar (truncar) o payload que ultrapassa o tamanho máximo permitido em vez de recusar o envio, tamanho anômalo citado como motivação do limite (RNF-16) — descartado, `[09:23] Sofia`.
- Garantia de entrega exatamente uma vez, sem possibilidade de duplicata — descartado, `[09:25] Diego`.
- Derivar o identificador do cliente implicitamente do token de autenticação, em vez de recebê-lo explícito na requisição — descartado, `[09:32] Larissa`.
- Painel ou dashboard visual para o cliente acompanhar as entregas dos seus webhooks — descartado, `[09:40] Larissa`.

Adiados para fase futura:

- Arquivamento ou expurgo das linhas já entregues da fila de eventos, depois de um período de retenção (RNF-06) — adiado, `[09:08] Diego`.
- Escala horizontal do processo de entrega para múltiplos workers, com particionamento ou lock de concorrência — adiado, `[09:13] Diego`.
- Aviso por e-mail ao cliente quando a entrega de um webhook dele começa a falhar — adiado, `[09:37] Larissa`.
- Endurecimento do controle de acesso ao cadastro e à edição de configuração de webhook, hoje aberto a qualquer usuário autenticado da plataforma — adiado, `[09:37] Sofia`.
- Limitação de taxa (rate limiting) de envio por cliente, para conter rajada de eventos — adiado, `[09:39] Diego`.

## Requisitos funcionais

| ID | Requisito | Origem |
|---|---|---|
| PRD-FR-01 | Cliente cadastra um endpoint de webhook via POST, informando a url de destino | RF-01, `[09:31] Marcos` |
| PRD-FR-02 | A secret de assinatura é gerada pela plataforma e devolvida na resposta da criação do endpoint | RF-02, `[09:31] Marcos` |
| PRD-FR-03 | Cliente edita, remove e lista os endpoints de webhook cadastrados para si | RF-03, `[09:33] Bruno` |
| PRD-FR-04 | Cada endpoint declara a lista de status de pedido que quer ouvir | RF-04, `[09:33] Marcos` |
| PRD-FR-05 | Cliente solicita, pela API, uma nova secret para um endpoint (rotação) | RF-05, `[09:21] Sofia` |
| PRD-FR-06 | Cliente consulta o histórico de entregas de um endpoint específico | RF-06, `[09:34] Marcos` |
| PRD-FR-07 | O histórico expõe os últimos 100 envios de um endpoint, com resultado (sucesso ou falha), payload enviado, resposta recebida e tempo de resposta | RF-07, `[09:34] Marcos` |
| PRD-FR-08 | Um endpoint administrativo permite o replay manual de um evento que esgotou as tentativas de entrega, recolocando-o como pendente | RF-08, `[09:18] Diego` |
| PRD-FR-09 | O evento entregue traz identificação, tipo, timestamp e as chaves do pedido que mudou (identificador, número, status anterior, status novo e cliente), além do valor total do pedido | RF-09, RF-10, `[09:43] Diego` |
| PRD-FR-10 | Toda entrega leva, nos headers do request, o identificador do evento, a assinatura da entrega e o timestamp do envio, além do tipo de conteúdo | RF-11, RF-12, `[09:44] Diego` |
| PRD-FR-11 | Toda entrega identifica o endpoint de origem no header, para o cliente que mantém mais de um webhook distinguir de qual endpoint veio o evento | RF-13, `[09:44] Sofia` |

## Requisitos não funcionais

| ID | Requisito | Tipo | Origem |
|---|---|---|---|
| PRD-RNF-01 | Evento chega ao cliente em menos de 10 segundos, na definição de "tempo real" dada pelos próprios clientes | performance | RNF-01, `[09:02] Marcos` |
| PRD-RNF-02 | O intervalo entre leituras de eventos pendentes é de 2 segundos | performance | RNF-02, `[09:09] Diego` |
| PRD-RNF-03 | O intervalo de polling acrescenta até 2 segundos de espera de agendamento antes da primeira tentativa de entrega — 2s é o teto desse componente, não um piso da entrega | performance | RNF-03, `[09:10] Larissa` (a ata formulou o ponto de forma ambígua; ver FDD §Processamento pelo worker) |
| PRD-RNF-04 | A fila de eventos pendentes é indexada por status e por data de criação, para leitura eficiente | performance | RNF-04, `[09:08] Diego` |
| PRD-RNF-05 | A leitura de eventos pendentes processa apenas os ainda não entregues, em lotes pequenos | performance | RNF-05, `[09:08] Diego` |
| PRD-RNF-06 | Uma entrega tem até 5 tentativas de entrega no total (1 inicial + 4 retentativas) antes de ser movida para a fila de eventos mortos | operação | RNF-07, `[09:17] Larissa` |
| PRD-RNF-07 | A progressão entre as 5 tentativas de entrega tem 4 intervalos: 1 minuto, 5 minutos, 30 minutos e 2 horas | operação | DEC-05, `[09:17] Larissa` (interpretação — a ata é ambígua, ver RFC-QA-05) |
| PRD-RNF-08 | O intervalo total entre a primeira falha e a última tentativa de entrega é de 2 horas e 36 minutos | operação | derivado de PRD-RNF-06 e PRD-RNF-07; ver RFC-QA-05 |
| PRD-RNF-09 | Após rotação de secret, a secret anterior permanece válida em paralelo por 24 horas | segurança | RNF-13, `[09:21] Sofia` |
| PRD-RNF-10 | A url de um endpoint de webhook precisa usar TLS | segurança | RNF-14, `[09:23] Sofia` |
| PRD-RNF-11 | Cadastro ou edição com url insegura é recusado com erro de validação | segurança | RNF-15, `[09:23] Sofia` |
| PRD-RNF-12 | Um payload de evento que ultrapassa 64KB gera erro em vez de ser enviado | operação | RNF-17, `[09:24] Larissa` |
| PRD-RNF-13 | A garantia de entrega é de pelo menos uma vez; o cliente precisa suportar receber o mesmo evento mais de uma vez | compatibilidade | RNF-18, `[09:24] Diego` |
| PRD-RNF-14 | O histórico de entregas exposto ao cliente cobre os últimos 100 envios de cada endpoint | operação | RNF-19, `[09:34] Marcos` |
| PRD-RNF-15 | Toda execução do endpoint administrativo de replay registra quem a executou, para fins de auditoria | segurança | RNF-20, `[09:36] Sofia` |
| PRD-RNF-16 | Cenário de carga **citado**, não dimensionado nem contratado: um cliente com 50 pedidos mudando de status em um minuto. A fala é a pergunta retórica que abriu um assunto tirado de escopo em seguida (ver RFC-QA-03); nenhuma capacidade foi medida ou prometida | performance | RNF-21, `[09:38] Diego` |
| PRD-RNF-17 | Uma tentativa de entrega que não recebe resposta em 10 segundos é tratada como falha | performance | RNF-22, `[09:42] Diego` |
| PRD-RNF-18 | O esforço estimado de entrega é de três sprints, já incluindo a revisão de segurança | operação | RNF-26, `[09:47] Larissa` |
| PRD-RNF-19 | Pelo menos dois dias úteis do cronograma são reservados para revisão de segurança antes do deploy | segurança | RNF-27, `[09:46] Sofia` |
| PRD-RNF-20 | A secret de assinatura e o header que a transporta entram na lista de campos redigidos em log | segurança | `src/shared/logger/index.ts:4` — a lista atual não cobre esses valores; sem origem na reunião |
| PRD-RNF-21 | A data combinada de disponibilidade em produção é o fim de novembro | prazo | RNF-23, `[09:45] Marcos` |
| PRD-RNF-22 | A secret nunca é devolvida em texto claro fora da criação e da rotação | segurança | **sem origem na reunião** — a fala cobre a devolução na criação, não a proibição nas demais consultas; ratificação pedida em RFC-QA-13 |

## Decisões e trade-offs principais

| ADR | O que decide |
|---|---|
| [ADR-001](adrs/ADR-001-outbox-no-mysql.md) | O evento nasce como linha de uma tabela de eventos pendentes no MySQL já existente, sem infraestrutura de mensageria nova. |
| [ADR-002](adrs/ADR-002-worker-processo-separado-polling.md) | O consumo é feito por um processo separado da API, lendo eventos pendentes em intervalos curtos. |
| [ADR-003](adrs/ADR-003-retry-backoff-e-dlq-em-tabela-separada.md) | Falha de entrega segue uma política de retentativa finita com espaçamento crescente e termina numa fila de eventos mortos própria. |
| [ADR-004](adrs/ADR-004-hmac-sha256-secret-por-endpoint.md) | Toda entrega é assinada com uma secret exclusiva por endpoint, com suporte a rotação. |
| [ADR-005](adrs/ADR-005-entrega-at-least-once-com-x-event-id.md) | A garantia contratada é de pelo menos uma entrega; a deduplicação é responsabilidade do cliente, por identificador de evento. |
| [ADR-006](adrs/ADR-006-reuso-dos-padroes-existentes.md) | O módulo nasce dentro dos padrões já existentes do projeto — erro, log, validação, estrutura — sem convenção própria. |
| [ADR-007](adrs/ADR-007-insercao-na-outbox-dentro-da-transacao.md) | O registro do evento acontece dentro da mesma transação que muda o status do pedido, sem alterar a forma como o serviço de pedidos é montado. |
| [ADR-008](adrs/ADR-008-modelo-de-autorizacao-do-modulo.md) | A gestão de endpoints segue a autenticação já existente; o replay administrativo exige papel elevado. |

## Dependências

A feature depende do que já existe em produção: o banco MySQL onde o projeto
grava seus dados, a transação de mudança de status de pedido (ponto de origem
do evento) e a infraestrutura de autenticação e autorização já em uso, sem a
qual não haveria como restringir o replay administrativo. Depende também de
disponibilidade da revisão de segurança de Sofia dentro do cronograma de três
sprints (RNF-26, RNF-27), já que o deploy não deve ocorrer antes dela. Não
depende de nenhum serviço de terceiros nem de infraestrutura de mensageria
nova — essa é, aliás, uma das decisões estruturantes do desenho (ADR-001).

## Riscos e mitigação

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Um defeito no registro do evento derruba a própria mudança de status do pedido, porque os dois passam a ser atômicos por desenho | Média | Alto — atinge fluxo de produção já existente, não só a feature nova | O produto aceita o acoplamento porque a alternativa é o pedido mudar de status e o evento se perder em silêncio; a forma de isolar a gravação e a cobertura desse caminho estão em [ADR-007](adrs/ADR-007-insercao-na-outbox-dentro-da-transacao.md) |
| O processo de entrega opera com uma única instância, sem garantia de ordenação global entre pedidos diferentes | Alta | Médio — cliente pode ver eventos de pedidos distintos fora de ordem se o sistema escalar sem planejamento | Limitação documentada como parte do contrato; escalar para mais de uma instância é decisão explicitamente adiada, não silenciosa |
| A cobertura de eventos nasce com uma lacuna: nem toda transição de status do pedido passa pelo caminho que dispara o evento | Alta | Médio — cliente pode não ser notificado de uma transição específica | Lacuna registrada nos documentos técnicos; decisão sobre cobrir esse caminho fica pendente antes da implementação, não assumida por omissão |
| O cadastro e a edição de configuração de webhook ficam abertos a qualquer usuário autenticado da plataforma, sem controle por dono, nesta primeira fase | Média | Médio — um operador poderia alterar a configuração de um cliente que não é o seu | Endurecimento do controle de acesso já está registrado como item adiado, com decisão explícita de revisitar; não é lacuna não vista |
| Dez decisões técnicas de segurança e de resiliência não foram tomadas na reunião — entre elas como a secret é guardada em repouso, que restrições a url do cliente sofre além de exigir TLS, e o que acontece com um evento cujo envio é interrompido no meio. Estão listadas em [docs/FDD.md](FDD.md) §Não decidido na reunião | Alta | **Alto** — decidir cada uma consome tempo de arquitetura e de segurança que o prazo de três sprints (DEC-25, `[09:47] Larissa`) não reservou, e duas delas afetam garantias já anunciadas ao cliente | Nenhuma foi preenchida por conta própria: a lista é a pauta que precisa ser fechada antes da implementação começar. A revisão de segurança de dois dias úteis já reservada (`[09:46] Sofia`) não substitui essas decisões — ela pressupõe que já tenham sido tomadas |
| A secret de assinatura do webhook pode vazar em log, porque a redação de log da plataforma hoje não cobre esse valor | Média | Alto — comprometeria a verificação de origem de todas as entregas de um endpoint | Cobrir a secret e o header de assinatura na redação de log é item de escopo desta feature, rastreado como PRD-RNF-20 e com critério de aceite próprio; o ponto exato da mudança está em [docs/FDD.md](FDD.md) §Observabilidade |

## Critérios de aceitação

- Um cliente cadastrado consegue criar, editar, remover e listar seus
  endpoints de webhook.
- A secret de um endpoint só é exposta em texto claro no momento da criação e
  no momento de uma rotação — nunca nas demais consultas (PRD-RNF-22).
- A secret de assinatura e o header que a transporta não aparecem em texto claro
  em nenhuma linha de log (PRD-RNF-20).
- Um cliente que assina apenas parte dos status de pedido só recebe eventos
  desses status, não dos demais.
- Uma mudança de status com pelo menos um endpoint interessado resulta numa
  tentativa de entrega em até 10 segundos — a régua que os clientes deram
  (PRD-RNF-01, `[09:02] Marcos`), sem condição atenuante: nenhuma foi acordada
  na reunião.
- Uma entrega que falha é retentada automaticamente, sem intervenção manual,
  seguindo a progressão combinada.
- Um evento que esgota as tentativas de entrega fica visível para replay
  administrativo, e o replay recoloca o evento como pendente de nova entrega.
- Toda entrega chega ao cliente assinada, e o cliente consegue validar que a
  origem é legítima.
- O histórico de entregas de um endpoint mostra, para cada envio, o
  resultado, o payload, a resposta recebida e o tempo de resposta.
- Uma falha ao registrar o evento impede a própria mudança de status de ser
  concluída — não existe cenário em que o pedido muda de status e o evento se
  perde silenciosamente.
- Um cadastro ou edição de endpoint com url insegura (sem TLS) é recusado.

## Estratégia de testes e validação

A validação combina dois eixos. O primeiro é a garantia de que a feature nova
não regride o que já existe: a mudança de status de pedido é fluxo de produção,
e a cobertura de integração que ele já tem é o piso a manter passando sem
alteração de expectativa — se ela quebrar, o acoplamento novo vazou para fora do
que foi desenhado. Qual arquivo de teste é esse está em
[docs/FDD.md](FDD.md) §Critérios de aceite técnicos.
O segundo eixo é específico da feature: cobertura de integração para o ciclo
completo — cadastro de endpoint, publicação de evento, entrega, retentativa, e o
caminho de erro de falha esgotada até a fila de eventos mortos e o replay
administrativo.

Antes do deploy, o cronograma reserva pelo menos dois dias úteis para revisão
de segurança dedicada, conduzida por Sofia (RNF-27, `[09:46] Sofia`), com foco
declarado em assinatura de entrega e em redação de log — os dois pontos em que
um vazamento de secret comprometeria a garantia de origem que todo o desenho
depende. Essa revisão entra no fim do cronograma de três sprints, como
combinado (RNF-26), e é pré-condição de deploy, não um passo opcional.
