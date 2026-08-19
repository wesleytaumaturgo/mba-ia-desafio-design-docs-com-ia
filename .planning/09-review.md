# 09 — Review adversarial do pacote de documentos

Revisor externo. Saída padrão REPROVADO; APROVADO só se a tentativa de derrubar
falhar. `scripts/verify.sh` dá 34/34 — isso é o ponto de partida da desconfiança,
não uma credencial.

**Sessão.** Todos os comandos citados abaixo foram executados nesta sessão, na
raiz do repositório, com o work tree limpo antes e depois
(`git status --porcelain` vazio na abertura). Nenhum arquivo de `docs/`,
`README.md` ou `scripts/` foi alterado por este bloco.

**Escopo do que foi lido nesta sessão:** `TRANSCRICAO.md` (integral, 323 linhas),
`docs/PRD.md`, `docs/RFC.md`, `docs/FDD.md`, `docs/TRACKER.md`,
`docs/adrs/*.md` (9 arquivos), `README.md` (enunciado), `scripts/verify.sh`
(1276 linhas, os 34 checks), `.planning/01-matriz.md`, `.planning/02-transcricao.md`,
`.planning/02-recusa.md` (tabela de âncoras), `.planning/02-codigo.md` §4,
`.planning/04-cobertura.md` (tabela COB), e o código: `prisma/schema.prisma`,
`prisma/migrations/20260519182739_init/migration.sql`, `src/**` (arquivos citados
nos documentos), `tests/orders.test.ts`, `package.json`, `docker-compose.yml`.

---

## 1 · Veredito por critério de aceite

Vereditos: **PASSA** · **PASSA COM RESSALVA** · **FALHA** · **NÃO VERIFICÁVEL**.

| ID | Critério | Veredito | Evidência (comando + saída, ou arquivo:linha) |
|---|---|---|---|
| RA-1 | Código da aplicação intocado (restrição absoluta) | PASSA | `./scripts/verify.sh` → `INV-1 OK — 32 caminhos examinados (M/A/D/untracked), 0 fora do conjunto permitido`; `INV-2 OK — 323 linhas / 21011 bytes, sha256 == sha256 em $BASE [cdc56e0e…]`; `git status --porcelain` → vazio |
| RA-2 | Nada registrado nos documentos sem origem rastreável | **FALHA** | `comm -23` universo×tracker → `FDD-ERR-03 FDD-ERR-09 FDD-ERR-12 FDD-ERR-13`: quatro códigos de erro que o próprio tracker declara sem origem (`docs/TRACKER.md`:96–99) continuam na matriz do FDD (`docs/FDD.md`:556, 562, 565, 566) **sem nenhum marcador**, indistinguíveis dos nove com origem. A "Ação sugerida" do tracker ("registrar como decisão nova do FDD") não foi executada: `grep -ncE 'sem origem\|decisão nova' docs/FDD.md` → `2`, e as duas ocorrências são sobre outro assunto (`docs/FDD.md`:132 e :536). Some-se FDD-ERR-06, que **tem** origem declarada e ela é falsa (ver §2 e §6) |
| PRD-1 | Arquivo existe e está em Markdown | PASSA | `./scripts/verify.sh` → `PRD-1 OK — docs/PRD.md existe, 3184 palavras (mínimo 900), 0 placeholder(s)` |
| PRD-2 | Todas as seções obrigatórias do requisito 1 | PASSA | `PRD-2 OK — 13 headers canônicos conferidos (12 '## ' + '### Fora de escopo'), 0 ausentes` |
| PRD-3 | ≥8 requisitos funcionais discutidos na reunião | PASSA | `PRD-3 OK — 11 linhas '\| PRD-FR-NN \|'`; as 11 conferidas contra `.planning/02-transcricao.md` RF-01..RF-13 e contra a fala original |
| PRD-4 | ≥1 objetivo com métrica e meta quantitativa | PASSA COM RESSALVA | `PRD-4 OK — 3 linha(s) com meta quantitativa`. Duas das cinco linhas da tabela de objetivos (`docs/PRD.md`:76 e :79) não sustentam a leitura da fala de origem — ver §6, linhas "2 segundos" e "50 pedidos/min". O critério passa pela linha :75 ("abaixo de 10 segundos", `[09:02] Marcos`), que confere |
| PRD-5 | "Fora de escopo" com ≥2 itens descartados/adiados na reunião | PASSA | `PRD-5 OK — 15 itens de lista, 15 com '[hh:mm] Nome' conferível`; os 15 timestamps conferidos um a um por `grep -F` em `TRANSCRICAO.md`, todos existem e a fala sustenta o descarte/adiamento |
| PRD-6 | "Riscos" com ≥2 riscos com probabilidade, impacto e mitigação | PASSA COM RESSALVA | `PRD-6 OK — 5 linha(s) de risco com Probabilidade/Impacto/Mitigação preenchidos`. A mitigação do 5º risco (`docs/PRD.md`:197) afirma "com critério de aceite próprio"; `awk '/^## Critérios de aceitação/{f=1;next} /^## /{f=0} f' docs/PRD.md \| grep -niE 'redaç\|redact\|log'` → nenhuma linha. O PRD promete um critério de aceite que ele mesmo não tem |
| RFC-1 | Arquivo existe e está em Markdown | PASSA | `RFC-1 OK — docs/RFC.md existe, 2050 palavras (mínimo 900), 0 placeholder(s)` |
| RFC-2 | Todas as seções obrigatórias do requisito 2 | PASSA | `RFC-2 OK — 8 headers canônicos conferidos, 0 ausentes; 5 revisores em §Metadados achados por grep -F em TRANSCRICAO.md` |
| RFC-3 | ≥2 alternativas descartadas, cada uma com trade-off | PASSA | `RFC-3 OK — 6 blocos '### RFC-ALT-NN', 6 com trade-off preenchido`; as 6 conferidas contra as falas `[09:06]`, `[09:07]`, `[09:09]`, `[09:15]`, `[09:16]`, `[09:25]` |
| RFC-4 | ≥2 questões em aberto adiadas/não decididas | PASSA | `RFC-4 OK — 4 linhas '\| RFC-QA-NN \|'`; QA-01 (`[09:32] Larissa`) e QA-04 (`[09:12] Diego`) conferidas literalmente na transcrição |
| RFC-5 | Referencia ≥2 ADRs com link | PASSA | `RFC-5 OK — 8 links '](adrs/ADR-*.md)' distintos, 0 quebrado(s)` |
| RFC-6 | Documento conciso; não duplica o detalhamento do FDD | PASSA COM RESSALVA | `RFC-6 OK — 2050 palavras na faixa 900–2200, 0 linha(s) de detalhe de FDD em 3 padrões`. Os 3 padrões do check (`WEBHOOK_[A-Z]`, fence json, linha de tabela de endpoint) não cobrem o que de fato desceu de altura: `docs/RFC.md`:201–206 discute `snake_case` × `camelCase` do schema, `@map` de coluna e exceção de padrão de id — matéria de FDD dentro do RFC. Ver §5 |
| FDD-1 | Arquivo existe e está em Markdown | PASSA | `FDD-1 OK — docs/FDD.md existe, 6078 palavras (mínimo 1500), 0 placeholder(s)` |
| FDD-2 | Todas as seções obrigatórias do requisito 3 | PASSA | `FDD-2 OK — 12 headers canônicos conferidos, 0 ausentes` |
| FDD-3 | "Contratos públicos" com ≥4 endpoints, request/response e status codes | PASSA COM RESSALVA | `FDD-3 OK — 7 blocos '### MÉTODO /path', 7 com ≥2 fences json e ≥1 '**Status:** NNN'`. Em `DELETE /webhooks/:id` (`docs/FDD.md`:361–376) o "request" é `{}` e o "response" é o corpo de **erro**; a resposta 204 de sucesso não tem exemplo. Idem `POST /webhooks/:id/secret/rotate` e o replay, cujo request é `{}`. O check conta fences, não conteúdo |
| FDD-4 | Matriz de erros com prefixo `WEBHOOK_` | PASSA | `FDD-4 OK — 13 linhas '\| FDD-ERR-NN \|' com código WEBHOOK_[A-Z_]{3,}, 0 código(s) sem o prefixo` |
| FDD-5 | "Integração com o sistema existente" com ≥4 caminhos reais | PASSA | `FDD-5 OK — 13 caminhos distintos sem (novo) na §Integração, 13 presentes em git ls-files, 0 ausentes` |
| FDD-6 | "Observabilidade" cita métricas, logs e tracing | PASSA | `FDD-6 OK — 3 subseções conferidas, 18 itens de lista no total, mínimo 3 em cada` |
| FDD-7 | Invariante D-10: nenhum termo `snake_case` afirmado como coluna do schema | PASSA | `FDD-7 OK — 651 linhas varridas, 0 linha(s) nomeando os cinco termos como coluna`; confirmado contra `prisma/schema.prisma`:75–81 e :119–120, onde as colunas são de fato `camelCase` |
| ADR-1 | Pasta com 5–8 arquivos `ADR-NNN-titulo-em-kebab-case.md` | PASSA | `ADR-1 OK — 8 ADRs no formato (faixa 5–8), 9 arquivos .md, 8 esperados fora o README.md` |
| ADR-2 | Cada ADR com Status, Contexto, Decisão, Alternativas, Consequências | PASSA | `ADR-2 OK — 8 ADRs examinados, 7 seções conferidas em cada` |
| ADR-3 | Cobre ≥5 das 6 decisões principais | PASSA | `ADR-3 OK — 6 decisões principais examinadas, 6 cobertas: COB-1..COB-6`; cada COB reconferida à mão contra a §Decisão do ADR correspondente, não contra a §Alternativas |
| ADR-4 | ≥1 ADR referencia arquivos/módulos/classes do código base | PASSA | `ADR-4 OK — 8 ADRs, 57 caminhos distintos sem (novo) conferidos contra git ls-files, 8 ADR(s) com pelo menos um caminho real`; amostra de linhas reconferida no disco (ver §7, ADR-4) |
| EST-2 | `docs/adrs/` sem nada além de `ADR-NNN-*.md` e `README.md` | PASSA | `EST-2 OK — 9 entradas em docs/adrs, todas ADR-NNN-*.md ou README.md` |
| TRK-1 | Arquivo existe e segue o formato de tabela do requisito 5 | PASSA | `TRK-1 OK — header literal presente, 64 linha(s) de dados, todas com 6 campos` |
| TRK-2 | ≥80% dos itens identificáveis com linha correspondente | PASSA COM RESSALVA | `TRK-2 OK — universo=68 ID(s), cobertos=64`. O universo é apenas o que **tem ID**; afirmações com cara de requisito e sem ID ficam fora da conta por construção — 6 achados em §3 |
| TRK-3 | ≥70% das linhas com Fonte=TRANSCRICAO e timestamp válido | PASSA COM RESSALVA | `TRK-3 OK — 58/64 linha(s) com Fonte=TRANSCRICAO, todas as Localizações conferidas por grep -F (0 não encontrada)`. `grep -F` prova que o timestamp existe, não que a fala sustenta o resumo: 3 das 12 linhas sorteadas em §2 não sustentam |
| TRK-4 | ≥5 linhas com Fonte=CODIGO e caminho de arquivo real | PASSA COM RESSALVA | `TRK-4 OK — 6 linha(s) com Fonte=CODIGO, todos os caminhos presentes em git ls-files`. Três das seis (FDD-ERR-04/05/08) apontam para a **mesma** linha genérica `src/shared/errors/http-errors.ts`:27 (`NotFoundError`), que o próprio tracker declara insuficiente como origem (`docs/TRACKER.md`:88–92). Aplicada a regra do tracker a ele mesmo, sobram 3 < 5. Ver §8 |
| RME-1 | README com todas as seções do requisito 6 | **FALHA** | `grep -c '^## Sobre o desafio' README.md` → `0`. `sed -n '1,5p' README.md` → `# Da Reunião ao Documento: Design Docs Gerados por IA / ## Descrição` — o README ainda é o enunciado. Esperado neste momento (bloco 9 pendente), mas objetivamente reprovado hoje |
| RME-2 | Lista ≥1 ferramenta de IA utilizada | **FALHA** | idem — seção inexistente |
| RME-3 | Mostra ≥2 prompts customizados em blocos de código | **FALHA** | idem — seção inexistente |
| RME-4 | Descreve ≥2 iterações ou ajustes concretos | **FALHA** | idem — seção inexistente |
| GER-1 | Nada nos documentos contradiz a transcrição ou o código | **FALHA** | `docs/adrs/ADR-007-…`:25 "Em 5 das 8 transições possíveis nenhum produto é tocado" e `docs/FDD.md`:126 "participam de 4 das 8 transições" — a tabela `transitions` (`src/modules/orders/order.status.ts`:3–10) tem **7** transições (2+2+2+1+0+0), e as intocadas por estoque são **4**, não 5. Mais duas divergências semânticas em §6 (latência "mínima" → "no pior caso"; cenário de rajada → capacidade garantida) e a aritmética de retry em §6 |
| GER-2 | Nenhum arquivo de código mencionado é inexistente | PASSA | `GER-2 OK — 27 caminho(s) distinto(s) examinado(s) em README.md/docs/, 0 ausente(s) do índice do git`; reconferido caminho a caminho, mais os números de linha (que o check não confere) — ver §7 |
| EST-1 | Árvore obrigatória do entregável presente e com conteúdo real | PASSA COM RESSALVA | `find . -path ./node_modules -prune -o -type f -print` confirma `docs/{PRD,RFC,FDD,TRACKER}.md` e `docs/adrs/ADR-001..008` + `README.md`; o `README.md` da raiz existe mas ainda é o enunciado, não o documento de processo exigido pela árvore |
| MAN-01 | REC-09 (`customer_id` do JWT) não aparece como decisão vigente | PASSA | `grep -rniE 'customer_?id' docs/ \| grep -iE 'jwt\|token\|claim'` → 4 ocorrências, todas classificadas RECUSA CORRETA em §4 |

**Contagem:** PASSA **24** · PASSA COM RESSALVA **8** · FALHA **6** · NÃO VERIFICÁVEL **0**.

---

## 2 · Auditoria de rastreabilidade por amostragem

**Como sorteei.** Sorteio determinístico e reproduzível (sem depender do estado
do PRNG da máquina), sobre as 64 linhas de dados da tabela principal:

```
awk '/^## Referência cruzada/{f=1;next} /^## /{f=0} f' docs/TRACKER.md \
 | grep -E '^\| *((PRD-FR|PRD-RNF|RFC-ALT|RFC-QA|FDD-CONTRATO|FDD-ERR)-[0-9]{2}|ADR-[0-9]{3}) *\|' \
 | shuf -n 12 --random-source=<(yes) | sort
```

`--random-source=<(yes)` fixa a fonte de entropia: o mesmo comando devolve
sempre as mesmas 12 linhas. Para cada uma, `TRANSCRICAO.md` foi aberto no
timestamp declarado e a fala colada literalmente.

---

**1. `PRD-FR-07` — "Histórico expõe últimos 100 envios com detalhes" — `[09:34] Marcos`**

> [09:34] Marcos: Mais um: o cliente precisa conseguir ver o histórico de entregas. Tipo "esses são os últimos 100 webhooks que vocês mandaram pra mim, sucesso/falha, payload, response, tempo de resposta". GET /webhooks/:id/deliveries.

Veredito: **CONFERE**. Os quatro campos do resumo estão na fala.

**2. `PRD-RNF-01` — "Entrega em menos de 10 segundos" — `[09:02] Marcos`**

> [09:02] Marcos: Eu perguntei especificamente isso. Pra eles, qualquer coisa abaixo de 10 segundos já é "tempo real".

Veredito: **CONFERE**. A fala é a régua do cliente e o documento a trata como
tal (`docs/PRD.md`:145).

**3. `PRD-RNF-08` — "Janela total entre falha e última tentativa: ~15h" — `[09:17] Diego`**

> [09:17] Diego: Eu pensei em 1 minuto, 5 minutos, 30 minutos, 2 horas, 12 horas. Total de quase 15 horas entre primeira falha e última tentativa.

Veredito: **CONFERE** quanto à fala. (A aritmética dessa janela contra "5
tentativas" é problema do FDD, não do tracker — ver §6.)

**4. `PRD-RNF-10` — "URL de webhook precisa usar TLS" — `[09:23] Sofia`**

> [09:23] Sofia: TLS obrigatório. URL do webhook tem que ser https. Se o cliente cadastrar http, recusamos com erro de validação.

Veredito: **CONFERE**.

**5. `RFC-ALT-01` — "Disparo síncrono no service de pedidos, descartado" — `[09:06] Diego`**

> [09:06] Diego: Síncrono está fora de questão. Aliás, eu nem chamaria de "fila" — o que a gente quer aqui é um padrão outbox.

Veredito: **CONFERE**.

**6. `RFC-ALT-03` — "Trigger de banco como gatilho reativo, descartado" — `[09:09] Diego`**

> [09:09] Diego: MySQL não tem listener nativo tipo o NOTIFY/LISTEN do Postgres. Trigger no banco a gente até tem, mas ela não notifica processo externo, ela só executa SQL. […]

Veredito: **CONFERE**.

**7. `RFC-QA-04` — "Ordenação com mais de um worker, sem solução escolhida" — `[09:12] Diego`**

> [09:12] Diego: Depende. Se a gente tem um único worker rodando, ele processa em ordem de created_at do outbox. […] Se a gente escala pra múltiplos workers em paralelo no futuro, perde a garantia. Por enquanto, single-worker e ordering implícita por order_id.

Veredito: **CONFERE**.

**8. `FDD-ERR-01` — "`WEBHOOK_URL_NOT_HTTPS` — url sem TLS" — `[09:23] Sofia`**

> [09:23] Sofia: TLS obrigatório. URL do webhook tem que ser https. Se o cliente cadastrar http, recusamos com erro de validação. Isso na verdade nem é decisão arquitetural, é só uma validação no schema Zod.

Veredito: **CONFERE**.

**9. `ADR-005` — "Entrega at-least-once com X-Event-Id para dedup" — `[09:26] Larissa`**

> [09:26] Larissa: Beleza. At-least-once com X-Event-Id pra dedup do lado do cliente. Decisão.

Veredito: **CONFERE**.

**10. `ADR-002` — "Worker em processo separado, consumo por polling a cada 2s" — `[09:10] Larissa`**

> [09:10] Larissa: Vamos registrar isso como uma decisão. Worker em polling, 2s. A latência mínima vai ser 2 segundos no pior caso. Aceitamos.

Veredito: **RESUMO DISTORCE**. A fala de `[09:10]` fecha *polling de 2s* e nada
mais. "Processo separado" é decidido em `[09:11] Diego` ("Sim, mesmo banco,
mesma stack. Só não pode ser o mesmo processo."), e o próprio pacote sabe
disso: `docs/adrs/README.md`:19 lista quatro Localizações para o ADR-002
(`[09:10] Larissa` · `[09:11] Diego` · `[09:28] Diego` · `[09:30] Bruno`).
O tracker colapsou as quatro em uma e manteve o resumo das duas. Gravidade
Baixa — o conteúdo existe na transcrição, só não naquele timestamp.

**11. `ADR-003` — "Retry com backoff exponencial e DLQ em tabela separada" — `[09:17] Larissa`**

> [09:17] Larissa: Decidido: 5 tentativas, backoff 1m/5m/30m/2h/12h. Próximo: DLQ. Faz numa tabela separada ou marca como "failed" na própria outbox?

Veredito: **RESUMO DISTORCE**. Em `[09:17]` Larissa **abre** a pergunta sobre a
DLQ; a resposta vem em `[09:18] Diego` e é fechada por `[09:18] Bruno`
("Faz sentido."), exatamente como `.planning/02-transcricao.md` registra em
DEC-06 e como `docs/adrs/README.md`:20 registra. O tracker aponta a pergunta
como origem da resposta. Gravidade Baixa pelo mesmo motivo do item 10.

**12. `FDD-ERR-06` — "`WEBHOOK_ROTATION_IN_GRACE_PERIOD` — janela de 24h ainda aberta" — `[09:21] Sofia`**

> [09:21] Sofia: Sim. E a secret tem que ser rotacionável. Endpoint pro cliente conseguir pedir nova secret pela API. Quando ele rotaciona, a antiga fica válida por 24 horas em paralelo, pra ele ter tempo de migrar os sistemas dele. Depois disso, a antiga morre.

Veredito: **RESUMO DISTORCE — e é o achado desta seção.** A fala institui um
*grace period*. Ela **não** diz, nem sugere, que uma **nova rotação** seja
recusada enquanto a janela estiver aberta. O FDD, porém, cria um erro 409 com
exatamente essa semântica (`docs/FDD.md`:559 e :409–410: "nova rotação pedida
com a janela de 24 horas ainda aberta"), e o tracker atribui a regra a
`[09:21] Sofia`. Não há lastro no código tampouco: `grep -rniE
'hmac|crypto|createHmac|signature' src/ prisma/ tests/ package.json` → vazio
(rc=1), reconferido nesta sessão. É uma regra de negócio nova, com origem
declarada e falsa. `grep -F "[09:21] Sofia"` acha o timestamp; nenhum check
lê a fala. Gravidade **Alta**.

Consequência prática: a regra tem efeito de produto. Um cliente que suspeita de
vazamento e rotaciona duas vezes seguidas recebe 409 e fica **impedido de
revogar a secret comprometida por 24 horas** — o oposto do que a fala de Sofia,
motivada por vazamento de secret em log (`[09:22] Diego`), pretendia proteger.

---

**Resumo:** 12 linhas · **CONFERE 9** · **RESUMO DISTORCE 3** · **LOCALIZAÇÃO ERRADA 0**.

Nenhum timestamp inexistente ou com falante trocado — a disciplina de `grep -F`
funcionou. O que ela não pega é o item 12: timestamp verdadeiro, fala real,
resumo que a fala não sustenta.

---

## 3 · Caça a requisito sem origem

Varredura de `docs/PRD.md` e `docs/FDD.md` procurando número, limite,
comportamento ou garantia **sem ID** — portanto invisível para o universo do
TRK-2 (`comm -23` confirmou que os únicos IDs sem linha no tracker são
FDD-ERR-03/09/12/13; tudo abaixo está fora dessa conta por não ter ID nenhum).

| Onde (arquivo:linha) | Afirmação | Tem origem? | Gravidade |
|---|---|---|---|
| `docs/PRD.md`:197 | "Inclusão da secret e do header de assinatura na lista de redação de log é item de escopo desta feature, **com critério de aceite próprio**" | **Não.** É um item de escopo criado pelos documentos: nenhuma fala menciona `redactPaths`, e o código só prova a ausência (`src/shared/logger/index.ts`:4–11, seis entradas). Pior, o critério de aceite prometido não existe no PRD (`grep` na §Critérios de aceitação → nada sobre log/redação). E ele vira mudança em arquivo existente no FDD (`docs/FDD.md`:836) | **Alta** |
| `docs/PRD.md`:77 e :27 | Objetivo com meta: "Data de disponibilidade em produção — **até o fim de novembro**" (origem citada: `RNF-23`) | Parcial. A fala existe (`[09:45] Marcos`: "A Atlas quer pra fim de novembro"), mas `RNF-23` é ID de `.planning/02-transcricao.md`, **não** existe no tracker. Uma meta de produto datada sem linha de rastreabilidade | Média |
| `docs/PRD.md`:24 e :26; `docs/RFC.md`:31 e :33; `docs/adrs/ADR-001`:8–11 | Três clientes nomeados (`RNF-25`) e ameaça de churn (`RNF-24`) | Parcial, mesmo caso: falas reais em `[09:00] Marcos`, IDs que não existem no tracker. São a *motivação inteira* do PRD e não têm linha | Média |
| `docs/FDD.md`:209–213 | "Ele **cria uma linha nova** em `webhook_outbox` a partir do snapshot guardado, com `attempts` zerado, em vez de ressuscitar a linha antiga" | **Não.** `[09:18] Diego` diz apenas "Recoloca na outbox como pendente". Linha nova × ressuscitar é decisão de implementação nova, sem ID e sem marcador | Média |
| `docs/FDD.md`:150 e :189–191 | "Payload acima de 64KB é falha **terminal**, não retentável: […] vai direto para a dead-letter queue" | **Não.** `[09:24] Larissa` fecha "64KB de limite, erro caso ultrapasse" — nada sobre ser terminal nem sobre pular o retry. É comportamento novo, e ele contradiz a política geral de retry sem dizer que a contradiz por decisão | Média |
| `docs/FDD.md`:384–386 | "durante a janela, cada entrega leva a assinatura calculada com a **secret nova**, e o cliente pode aceitar qualquer uma das duas enquanto migra" | **Não**, e é auto-contraditório: se a plataforma nunca assina com a secret anterior, o critério de aceite do próprio FDD (`docs/FDD.md`:754, "uma assinatura calculada com a secret anterior continua verificável pelo cliente por 24 horas") descreve um cenário que o sistema nunca produz | Média |
| `docs/PRD.md`:203–204 | "A secret […] só é exposta em texto claro no momento da criação e no momento de uma rotação — **nunca nas demais consultas**" | **Não.** A fala (`[09:31] Marcos`) diz que a secret é devolvida na criação; a proibição nas demais consultas é regra nova, sem ID | Baixa |
| `docs/FDD.md`:291–294, :422–425, :446 | Paginação com `page: 1`, `pageSize: 20`, envelope `pagination` nos endpoints de listagem e no histórico | Origem em código (`src/shared/http/response.ts`:22), sem ID. Além disso convive mal com o teto de 100 do RF-07: `docs/FDD.md`:414 diz "limitado aos últimos 100 envios" e o exemplo devolve `totalPages`, sem dizer como as duas regras se compõem | Baixa |
| `docs/FDD.md`:268 | Secret de exemplo com prefixo `whsec_` | **Não.** Formato inspirado em terceiro (Stripe), sem fala e sem código. É exemplo, mas exemplo em FDD vira contrato na implementação | Baixa |

Observação de método: o tracker tem uma seção honesta de "Itens sem origem
identificável" (`docs/TRACKER.md`:84–99) e ela cobre **só o que tem ID**. Nada
acima entra lá, porque nada acima recebeu ID. O gargalo é a atribuição de ID,
não a disciplina do tracker.

---

## 4 · MAN-01 — verificação manual obrigatória

Comando executado nesta sessão (o filtro amplo sugerido em `.planning/01-matriz.md`:116):

```
grep -rniE 'customer_?id' docs/ | grep -iE 'jwt|token|claim'
```

Saída — 4 ocorrências, todas classificadas abaixo. Foi feita também a varredura
larga `grep -rniE '\bjwt\b|\btoken\b' docs/` (33 ocorrências) para não perder
menção que o filtro estreito descartasse; as demais são `Authorization: Bearer
<jwt>` em headers de contrato e `*.token` na lista de `redactPaths`, sem relação
com a origem do `customer_id`.

**Ocorrência 1 — `docs/PRD.md`:61**

> "…não existe, no modelo de dados atual, uma identidade de cliente que se autentique diretamente (DIV-07 — o JWT confirma DEC-17: o `customer_id` não pode ser derivado dele)."

Classificação: **RECUSA CORRETA**. Nega explicitamente a derivação. Nota de
redação: "o JWT confirma DEC-17" é frouxo — quem confirma é o código
(`prisma/schema.prisma`:11–14 e :40–54), não o token; mas o sentido é
inequivocamente de recusa.

**Ocorrência 2 — `docs/adrs/ADR-008-modelo-de-autorizacao-do-modulo.md`:25–26**

> "Ou seja: derivar o `customer_id` de um JWT seria derivá-lo de um token que não carrega cliente nenhum — o disco não deixa a alternativa em pé."

Classificação: **RECUSA CORRETA**. Recusa reforçada por evidência de código.

**Ocorrência 3 — `docs/adrs/ADR-008-…`:62 (título de subseção)**

> "### `customer_id` derivado implicitamente do JWT"

Classificação: **RECUSA CORRETA**. É header de bloco dentro de
`## Alternativas Consideradas`, cujo corpo termina em "**Motivo do descarte:**
`[09:32] Larissa` — 'Não vem do JWT.'" (linha 69). Contexto de descarte
explícito, não de adoção.

**Ocorrência 4 — `docs/adrs/ADR-008-…`:64**

> "O cliente se autenticaria com um token próprio e o `customer_id` sairia do payload, sem aparecer no contrato do endpoint."

Classificação: **RECUSA CORRETA**. Verbo no futuro do pretérito, dentro do mesmo
bloco de alternativa descartada.

**Ocorrências de adoção positiva (o que reprovaria):** nenhuma.

**Contra-prova.** A decisão vigente aparece afirmativamente nos três documentos
de contrato, sempre no sentido correto: `docs/FDD.md`:28 e :222–225 (o
`customerId` vai no **path**), `docs/RFC.md`:170 (RFC-QA-01: "a fala fecha
apenas o que ele **não** é"), `docs/PRD.md`:114 (item de §Fora de escopo:
"Derivar o identificador do cliente implicitamente do token de autenticação […]
descartado, `[09:32] Larissa`"), `docs/adrs/ADR-008-…`:43–47 (DEC-17).

**MAN-01: PASSA.** Zero vazamentos, zero ambíguas.

---

## 5 · Fronteira entre documentos

### 5.1 · O RFC contém frase que só serve para quem vai codar?

Sim, três blocos:

- `docs/RFC.md`:73–75 — "Essa gravação acontece **dentro** da transação que muda
  o status, em `src/modules/orders/order.service.ts`, por uma função que **recebe
  o handle transacional em vez de um repositório injetado**." A escolha entre
  handle e repository é assinatura de função: é ADR-007 e §Integração do FDD.
- `docs/RFC.md`:184–185 — a mesma informação **de novo**, na §Impacto e riscos:
  "mantém o acoplamento numa função que recebe o handle transacional, sem
  inverter dependências do serviço de pedidos". Duas vezes no mesmo documento.
- `docs/RFC.md`:201–206 — o pior: "O vocabulário de campo que a reunião falou é
  o do **contrato público**, que fica em snake_case por decisão; o schema interno
  é camelCase (DIV-01, DIV-02, DIV-03). […] o padrão de identificador do projeto
  não é universal (DIV-10) — vale para quase todos os modelos, não para todos, e
  é o FDD que registra a exceção." Um RFC que explica convenção de nomenclatura
  de coluna e exceção de tipo de chave primária está fazendo o trabalho do FDD, e
  ele próprio admite isso ao dizer "é o FDD que registra a exceção".

Menor, mas na mesma direção: `docs/RFC.md`:77–78 nomeia o arquivo de entrada do
worker (`src/worker.ts` (novo)) — decidido em ADR-002 e detalhado no FDD.

### 5.2 · O FDD §Integração repete o ADR-007 ou o complementa?

**Complementa, com duas repetições que contradizem a declaração de não repetir.**

O FDD abre a seção declarando (`docs/FDD.md`:784–788): "A **localização exata da
inserção dentro da transação** está em [ADR-007] e não é repetida aqui; o que
segue é o que o ADR não tem — assinatura da função nova, campos da linha gravada,
comportamento em caso de erro e o delta por arquivo."

Comparação lado a lado:

| Conteúdo | ADR-007 | FDD §Integração | Veredito |
|---|---|---|---|
| Ponto exato da inserção (depois da linha 159, antes do `return` da 177) | Sim (`ADR-007`:30–35) | Não | Complementa |
| Assinatura `publishWebhookEvent(tx, input): Promise<number>` | Não | Sim (`FDD`:793–803) | Complementa |
| Campos da linha de `webhook_outbox` e índices | Não | Sim (`FDD`:810–815) | Complementa |
| Delta arquivo a arquivo (12 caminhos) | Não | Sim (`FDD`:823–836) | Complementa |
| **`TxClient` como 1º argumento, "exatamente como `debitStock`" (linha 204)** | Sim (`ADR-007`:48–50) | Sim (`FDD`:806–808) | **Repete** |
| **Construtor do `OrderService` (linhas 27–30) intocado, sem repository novo** | Sim (`ADR-007`:50–51) | Sim (`FDD`:825) | **Repete** |
| Rollback conjunto se a escrita falhar | Sim (`ADR-007`:46–48) | Sim (`FDD`:817–821) | Repete com acréscimo (o FDD acrescenta que a resposta do `PATCH` vira erro) |

Saldo: a seção é majoritariamente complementar e bem-feita, mas as duas linhas
marcadas repetem literalmente o que o ADR decide, dentro de um parágrafo que
promete não repetir. Gravidade Baixa; é fronteira borrada, não duplicação de
documento.

### 5.3 · O PRD desce a detalhe de implementação?

Sim, em quatro pontos:

- `docs/PRD.md`:197 — "porque a lista de campos redigidos hoje não cobre esse
  valor". `redactPaths` é detalhe de `src/shared/logger/index.ts`; o PRD é o
  documento de produto.
- `docs/PRD.md`:193 — "A gravação do evento é isolada numa função dedicada, sem
  inverter dependências do serviço de pedidos (ADR-007)". Mitigação escrita em
  vocabulário de assinatura de função.
- `docs/PRD.md`:228 — "os testes de integração já existentes para esse fluxo
  (`tests/orders.test.ts`) são o precedente de cobertura a manter passando sem
  alteração de expectativa". Caminho de arquivo de teste em PRD.
- `docs/PRD.md`:33–35 — "todo o roteador de `orders` está atrás de um middleware
  de autenticação que hoje só aceita o token do usuário interno". Middleware e
  roteador em §Problema e motivação.

Contrapartida honesta: o PRD declara a intenção certa em `docs/PRD.md`:13–18
("O PRD não repete arquitetura nem contrato"), e as tabelas de FR/RNF respeitam
a altura. O desvio está concentrado em §Riscos e §Estratégia de testes.

### 5.4 · Conteúdo verbatim em três documentos? (DIV-08)

DIV-08 aparece em `docs/adrs/ADR-001-outbox-no-mysql.md`:17–25,
`docs/RFC.md`:40–50 (e de novo em :189) e `docs/PRD.md`:31–41.

**Não é verbatim.** Nenhum n-grama longo se repete; a única frase quase idêntica
é a negativa central, escrita de três formas diferentes:

- ADR-001:22 — "Um cliente externo **não tem credencial** para chamar `GET /orders` hoje"
- RFC:45 — "**não há hoje credencial** que um cliente externo possa usar para chamá-la"
- PRD:35 — "**não existe**, no sistema como ele é, **uma credencial** que um cliente externo possa usar para chamar essa rota"

O que **se repete** é a estrutura de três partes — (a) a rota existe, (b) está
atrás de `authenticate`, (c) `authenticate` só aceita JWT interno — nos três
documentos, em três alturas. Avaliação:

- **PRD** é o lugar certo: ele converte a constatação em consequência de produto
  ("a alternativa a este produto não é 'o cliente continua consultando', é 'o
  cliente continua sem visibilidade nenhuma'", :40–41). Legítimo.
- **RFC** é a duplicação de fato: `docs/RFC.md`:42–50 é uma paráfrase do
  parágrafo do PRD sem acrescentar nada de arquitetura, e a mesma constatação
  volta em :189. Duas vezes no RFC + uma no PRD, sem delta.
- **ADR-001** é o menos justificável dos três: DIV-08 não é consequência da
  decisão "outbox no MySQL", e o próprio ADR admite ("Isso não muda a decisão
  desta ADR", :23–24). O lugar natural é ADR-008 (modelo de autorização), onde
  DIV-07 já mora e onde a falta de credencial de cliente é consequência direta.

Contradição interna adicional, encontrada aqui: `docs/RFC.md`:21–22 (TL;DR)
afirma **sem qualquer ressalva** que "O público é o cliente B2B integrador, que
hoje só descobre mudança de status consultando a API repetidamente" — a premissa
que o mesmo documento derruba vinte linhas abaixo. Quem lê só o TL;DR sai com a
premissa errada.

---

## 6 · Contradições com a transcrição ou o código

Todo número que aparece nos documentos, conferido contra a fala original ou
contra o disco. Fonte da fala: `TRANSCRICAO.md` lido nesta sessão.

| Número no documento | Onde | Fala original / disco | Localização | Confere? |
|---|---|---|---|---|
| 10 segundos ("tempo real") | `PRD`:145, `RFC`:36–37, `FDD`:164, `ADR-001`:14–15 | "qualquer coisa abaixo de 10 segundos" | `[09:02] Marcos` | **Sim** |
| 2 segundos (polling) | `PRD`:146, `FDD`:145 e :584, `ADR-002`:11–12 | "A cada 2 segundos, busca os eventos pendentes mais antigos" | `[09:09] Diego` | **Sim** |
| 2 segundos ("latência aceita **no pior caso**") | `PRD`:76 e :147, `FDD`:585 | "A latência **mínima** vai ser 2 segundos no pior caso. Aceitamos." | `[09:10] Larissa` | **NÃO** — ver nota A |
| 5 tentativas | `PRD`:150, `FDD`:174 e :579, `ADR-003`:30 | "Decidido: 5 tentativas" | `[09:17] Larissa` | **Sim** |
| 1m/5m/30m/2h/12h | `PRD`:151, `FDD`:174 e :580 | "1 minuto, 5 minutos, 30 minutos, 2 horas, 12 horas" | `[09:17] Diego` | **Sim** |
| ~15 horas (janela total) | `PRD`:152, `FDD`:176 e :581, `ADR-003`:97 | "Total de quase 15 horas entre primeira falha e última tentativa" | `[09:17] Diego` | **Sim** na cópia — ver nota B |
| 12 a 24 horas (janela alvo) | `FDD`:176–177, `ADR-003`:16 | "Cinco já dá pra cobrir uma janela de até 12 ou 24 horas" | `[09:15] Diego` | **Sim** |
| 2 horas (indisponibilidade real) | `FDD`:177–178, `ADR-003`:14–15 e :84–85 | "Já tinha cliente nosso com indisponibilidade de duas horas em manutenção planejada" | `[09:16] Diego` | **Sim** |
| 3 tentativas / 30 minutos (opção rejeitada) | `PRD`:110, `RFC`:146–154, `ADR-003`:65–67 | "3 é pouco. […] retentaria três vezes em 30 minutos e mataria." | `[09:16] Diego` | **Sim** |
| 24 horas (grace period) | `PRD`:153, `FDD`:384 e :583, `ADR-004`:26–27 | "a antiga fica válida por 24 horas em paralelo" | `[09:21] Sofia` | **Sim** |
| 64KB (limite de payload) | `PRD`:156, `FDD`:48, :150, :582, :596 | "64KB de limite, erro caso ultrapasse." | `[09:24] Larissa` | **Sim** |
| 500KB (tamanho anômalo citado) | `PRD`:112, `FDD`:76–77 | "Se por algum motivo o evento tiver 500KB, a gente não envia." | `[09:23] Sofia` | **Sim** |
| 100 envios (histórico) | `PRD`:135 e :158, `FDD`:414 e :586 | "esses são os últimos 100 webhooks que vocês mandaram pra mim" | `[09:34] Marcos` | **Sim** |
| 50 pedidos/min | `PRD`:79 e :160, `FDD`:607–609, `ADR-001`:130–131, `ADR-002`:115–117 | "**Se** o cliente tem 50 pedidos mudando de status em um minuto, a gente bombardeia ele com 50 chamadas?" | `[09:38] Diego` | **NÃO** — ver nota C |
| 10 segundos (timeout do worker) | `PRD`:161, `FDD`:44, :152, :578, `ADR-005`:17 | "10 segundos. Cliente lento que não responde em 10s a gente trata como falha" | `[09:42] Diego` | **Sim** |
| 3 sprints | `PRD`:162, `FDD`:780 | "Três sprints com a revisão da Sofia incluída no fim." | `[09:47] Larissa` | **Sim** |
| 2 dias úteis (revisão de segurança) | `PRD`:78 e :163, `FDD`:780, `ADR-004`:121–122 | "Reservem pelo menos dois dias úteis pra eu revisar o código de segurança antes do deploy." | `[09:46] Sofia` | **Sim** |
| 30 dias (arquivamento) | `ADR-001`:123–124 (citação literal) | "Linhas entregues a gente arquiva depois de 30 dias ou assim, fora do escopo dessa feature." | `[09:08] Diego` | **Sim** — e corretamente mantido fora do escopo no PRD/FDD |
| fim de novembro (prazo) | `PRD`:27 e :77 | "A Atlas quer pra fim de novembro." | `[09:45] Marcos` | **Sim** (mas sem linha no tracker — §3) |
| **8 transições** possíveis | `ADR-007`:25 e :133, `FDD`:126 | `transitions` em `src/modules/orders/order.status.ts`:3–10 → PENDING 2 + PAID 2 + PROCESSING 2 + SHIPPED 1 + DELIVERED 0 + CANCELLED 0 = **7** | disco | **NÃO** — ver nota D |
| **5 das 8** transições sem toque em estoque | `ADR-007`:25 | Tocam estoque: PENDING→PAID (`shouldDebitStock`, :29–31) e →CANCELLED vindo de PAID/PROCESSING (`shouldReplenishStock`, :33–37) = 3. Intocadas = 7 − 3 = **4** | disco | **NÃO** — ver nota D |
| 4 das 8 transições com PENDING/CANCELLED | `FDD`:126, `ADR-007`:133 | PENDING→PAID, PENDING→CANCELLED, PAID→CANCELLED, PROCESSING→CANCELLED = **4 de 7** | disco | Numerador **sim**, denominador **não** |
| 53 linhas (`changeStatus`) | `ADR-007`:144–145 | `order.service.ts`:126–178 → 53 linhas | disco | **Sim** |
| 125 linhas (migration) | `FDD`:695, `ADR-001`:88 | `wc -l prisma/migrations/20260519182739_init/migration.sql` → `125` | disco | **Sim** |
| 6 entradas em `redactPaths` | `FDD`:654, `ADR-004`:113–116, `PRD`:197 | `src/shared/logger/index.ts`:4–11 → 6 entradas | disco | **Sim** |
| 6 dos 7 models com UUID | `FDD`:699–707 | 7 models; 6 com `@default(uuid()) @db.Char(36)` (`schema.prisma`:26, 41, 57, 75, 100, 117); exceção `OrderNumberSequence` (:133–138) | disco | **Sim** |
| 3 arquivos importam o logger | `ADR-006`:143–147, `FDD`:616–617 | `grep -rln "shared/logger" src/ tests/` → `error.middleware.ts`, `request-logger.middleware.ts`, `server.ts` | disco | **Sim** |
| 12 padrões varridos sem resultado | `FDD`:6–11 | `.planning/02-codigo.md` §4 tem 12 linhas e **todas** reconferidas nesta sessão retornam rc=1/0 hits; mas a frase do FDD **enumera 10** e diz "todos os doze" | disco | Fato **sim**, enumeração **não** — ver nota E |
| 12 caminhos na §Integração | `FDD`:784 | tabela de `FDD`:823–836 → 12 linhas; `FDD-5 OK — 13 caminhos distintos` (13 porque `.env.example` é citado em prosa) | disco | **Sim** |
| 13 códigos de erro / 13 classes novas | `FDD`:552–566, :827–828 | 13 linhas na matriz | interno | **Sim** |
| 7 endpoints | `FDD`:232–240 | 7 linhas / 7 blocos (`FDD-3 OK — 7 blocos`) | interno | **Sim** |
| `CREATE INDEX` na migration | `ADR-001`:87–89 | `grep -cE '^CREATE INDEX' …/migration.sql` → `0`; os índices são cláusulas `INDEX` **dentro** de `CREATE TABLE` (linhas 11, 26–27, 43–45, 63–67, 81–82, 96–97) | disco | **NÃO** — ver nota F |

**Conferidos: 32 números. Divergentes: 6** (notas A a F, contando as duas linhas
de "8 transições" como uma família).

---

**Nota A — a inversão de "latência mínima" para "latência no pior caso".**
Larissa disse *mínima*: o polling de 2s impõe um piso de latência. O pacote fez
duas coisas diferentes com isso. Os ADRs citam literalmente e preservam o
sentido — `ADR-001`:119–121 ("a latência **mínima** é o intervalo de polling") e
`ADR-002`:15–16. O PRD e o FDD viraram a frase: `docs/PRD.md`:147 registra
"A latência de entrega **aceita, no pior caso,** é de 2 segundos" e
`docs/PRD.md`:76 promove isso a **objetivo com meta** ("Latência de entrega no
pior caso | até 2 segundos"). É falso pelo desenho do próprio pacote: com 5
tentativas e backoff até 12h, o pior caso de entrega é da ordem de horas, não de
2 segundos. `docs/FDD.md`:162 preserva a palavra "mínima" mas a mistura com "no
pior caso" na mesma frase, e `docs/FDD.md`:585 tabula só "Latência aceita no
pior caso". Um objetivo de produto que o sistema não cumpre por construção é
FALHA de GER-1.

**Nota B — a aritmética do retry não fecha, e o FDD escolhe três leituras
incompatíveis.** No mesmo documento:

- `docs/FDD.md`:174 — "São **5 tentativas**, na progressão 1m, 5m, 30m, 2h, 12h";
- `docs/FDD.md`:181–183 (diagrama) — "tentativa 5 falha → **+12h** → DLQ",
  isto é, espera 12 horas **depois** da última tentativa para não fazer nada;
- `docs/FDD.md`:746 — critério de aceite: "Os **intervalos entre tentativas
  consecutivas** são 1m, 5m, 30m, 2h e 12h, nessa ordem" — cinco intervalos
  entre tentativas consecutivas exigem **seis** tentativas.

Com 5 tentativas e 4 intervalos consumidos (1m+5m+30m+2h), a última tentativa
cai **2h36min** após a primeira falha, não "quase 15 horas" (`docs/FDD.md`:176,
RNF-09). As três leituras não podem ser todas verdadeiras. A ambiguidade nasce
na própria transcrição (Diego dá 5 tentativas, 5 degraus e 15h na mesma janela),
mas o FDD é o documento cujo trabalho era resolvê-la para quem vai codar, e ele
a propagou multiplicada. Gravidade **Alta**: um desenvolvedor não consegue
implementar `nextAttemptAt` a partir deste texto.

**Nota C — cenário citado virou capacidade garantida.** A fala de `[09:38]
Diego` é uma **pergunta retórica** para justificar a discussão de rate limiting,
que foi então **tirada do escopo** (`[09:39] Diego`, REC-15/QA-03). A extração
forense registra isso com honestidade: `.planning/02-transcricao.md` RNF-21 diz
"**Cenário de carga citado**". O PRD converteu em requisito e em meta:
`docs/PRD.md`:160 — "O sistema **suporta, sem perda de evento**, um cliente com
até 50 pedidos mudando de status em um minuto" — e `docs/PRD.md`:79 lista isso
como objetivo com "Cenário de carga tolerado sem descarte". Ninguém dimensionou,
mediu ou decidiu isso. O FDD é mais cuidadoso (`docs/FDD.md`:607–609: "isso é
fila, não perda: o atraso cresce"), o que evidencia que o PRD extrapolou
sozinho. Gravidade **Alta** — é uma garantia de capacidade oferecida a três
clientes B2B com base em uma pergunta.

**Nota D — 8 transições que não existem.** `src/modules/orders/order.status.ts`:3–10
declara 7 transições. Dois documentos afirmam 8, e o ADR-007 ainda erra o
numerador ("5 das 8" quando são 4 de 7). O erro é o mais direto de todo o
pacote: contradiz o código, que é a segunda fonte de verdade do desafio, e vive
justamente na frase que o ADR usa para provar que leu o código com cuidado.
Gravidade **Alta**.

**Nota E — "doze padrões" com dez enumerados.** `docs/FDD.md`:7–10 lista
`outbox`, `worker`, `webhook`, `hmac`, `retry`, `dead-letter`, `event`,
`idempot`, `cron`, `trigger` (10) e conclui "em todos os **doze** padrões". A
tabela de origem (`.planning/02-codigo.md` §4) tem 12 linhas — faltaram
"fila/broker" e "publisher/emissão". Os doze foram reexecutados nesta sessão e
os doze retornam vazio, então o **fato** está certo; a frase é que não fecha.
Gravidade Baixa.

**Nota F — `CREATE INDEX` que não existe.** `ADR-001`:87–89 usa a composição da
migration como prova de que não há trigger no repositório. A prova funciona (não
há trigger), mas a descrição está errada: a migration tem 7 `CREATE TABLE` e 6
`ALTER TABLE … ADD CONSTRAINT`, e **nenhum** `CREATE INDEX` isolado. Gravidade
Baixa — a conclusão sobrevive, a evidência é imprecisa.

---

## 7 · O que os checks deixam passar

Para cada um dos 34 checks, uma entrada errada plausível que passaria. A última
coluna diz se o defeito **ocorre** nesta entrega.

| Check | Entrada errada que passaria | Isso ocorre na entrega? |
|---|---|---|
| INV-1 | `scripts/verify.sh` está **dentro** da lista de permissão. Enfraquecer o próprio verificador (baixar um piso, remover uma perna de check) não é violação de INV-1 — o medidor é editável pelo medido | Não. `git diff` de `scripts/` conferido; mas é o buraco estrutural do arranjo |
| INV-2 | Só protege `TRANSCRICAO.md`. Um `docs/` inteiro apagado e recriado com lixo passa (INV-1 permite `docs/*`) | Não |
| INV-3 | As 5 sondas são fixas. Uma regra `.gitignore` sobre `docs/adrs/ADR-00*.md` seria pega, mas uma sobre `*.png` ou `docs/anexos/` não — e o check só prova que a *criação* não está bloqueada, não que o conteúdo existe | Não |
| INV-4 | Higiene do índice por 5 padrões. Um `.env.local`, um `coverage/` ou um `*.log` versionado passa | Não |
| ADR-1 | Conta arquivos e nomes, não conteúdo. 8 ADRs idênticos, ou 8 ADRs sobre a decisão errada, passam | Não |
| ADR-2 | Exige os 7 headers e **uma linha não vazia** em Positivas/Negativas. `### Negativas` com "- n/a" passa | Não — as 16 subseções têm conteúdo real |
| ADR-3 | A âncora é procurada no **conjunto** dos ADRs, sem exigir que caia na §Decisão. Uma decisão documentada como **descartada** (dentro de `## Alternativas Consideradas`) satisfaz a âncora. E `COB-6` = `reuso.{0,40}padr[õo]e?s` casaria com "descartamos o reuso dos padrões" | Não. Reconferido à mão: as 6 caem na §Decisão do ADR mapeado |
| ADR-4 | Confere só a **existência do caminho**; o número de linha depois da crase é descartado por `tr -d '\`'`. `src/config/env.ts`:9999 passa | **Não** — as ~57 referências foram reconferidas no disco nesta sessão e batem. Mas o check não teria pego se não batessem |
| EST-2 | Só olha nomes de entrada em `docs/adrs/`. Um `ADR-009-vazio.md` com 1 byte passa em EST-2 (e reprovaria só em ADR-1, por contagem) | Não |
| RFC-1 | `wc -w ≥ 900` + ausência de dois placeholders específicos. 900 palavras de prosa genérica passam; `<!-- TODO -->` passa (o padrão só pega "a ser elaborado"/"será preenchido") | Não |
| RFC-2 | Headers literais + ≥3 nomes que existem em `TRANSCRICAO.md`. Uma §Metadados com "Revisores: Bruno, Diego, Larissa" e o resto do documento vazio de conteúdo passa; e qualquer nome da transcrição serve, mesmo em papel errado | Não |
| RFC-3 | Exige a linha `**Trade-off do descarte:**` com **qualquer** conteúdo depois. "**Trade-off do descarte:** vários." passa em 6 blocos | Não |
| RFC-4 | Conta linhas `\| RFC-QA-NN \|`. Uma questão inventada, que ninguém levantou na reunião, passa — não há cruzamento com a transcrição | Não. As 4 conferidas em `[09:32]`, `[09:28]`, `[09:39]`, `[09:12]` |
| RFC-5 | Links resolvem para arquivo existente. Um link para o ADR **errado** (texto "at-least-once" apontando para ADR-001) passa | Não |
| RFC-6 | Mede 3 padrões de "detalhe de FDD": `WEBHOOK_[A-Z]`, fence ```json, linha de tabela de endpoint. **Prosa** com detalhe de implementação não casa nenhum dos três | **SIM.** `docs/RFC.md`:201–206 (snake_case × camelCase do schema, exceção de padrão de id) e :73–75 (handle transacional × repository injetado). Ver §5.1 |
| FDD-1 | `wc -w ≥ 1500`. Um FDD de 6000 palavras repetitivas passa igual a um denso | Não |
| FDD-2 | 12 headers literais. Uma seção presente e com um parágrafo vazio de substância passa | Não |
| FDD-3 | Conta **2 fences json** + 1 linha `**Status:** NNN` por bloco. Dois fences `{}` seguidos satisfazem "request e response" | **SIM (parcial).** `DELETE /webhooks/:id` usa `{}` como request e o corpo de **erro** como response; `rotate` e `replay` usam `{}` como request |
| FDD-4 | Exige ≥8 códigos `WEBHOOK_*` e zero `SCREAMING_SNAKE` sem prefixo **na seção**. Um código com prefixo certo e semântica inventada passa; um código sem prefixo em **outra** seção passa | **SIM.** FDD-ERR-06 (`WEBHOOK_ROTATION_IN_GRACE_PERIOD`) tem prefixo perfeito e regra sem origem — §2, item 12 |
| FDD-5 | Confere existência do caminho, não o número de linha nem a afirmação sobre ele. "`src/app.ts` — nada muda" e "`src/app.ts` — reescrito inteiro" passam igual | Não (as 12 linhas do delta foram reconferidas), mas ver ADR-4 |
| FDD-6 | ≥3 itens de lista por subseção. Três bullets vagos ("- logs", "- métricas", "- tracing") passam | Não |
| FDD-7 | Proíbe os 5 termos a ≤40 caracteres de "coluna\|campo do schema\|no banco". Escrever "a tabela guarda `total_cents`" (sem nenhuma das 3 palavras-gatilho) passa; ou colocar 41 caracteres entre os dois | Não |
| PRD-1 | idem RFC-1 | Não |
| PRD-2 | 12 headers + `### Fora de escopo`. Seção presente e vazia de conteúdo passa (o check não mede corpo, só header) | Não |
| PRD-3 | ≥8 linhas `\| PRD-FR-NN \|`. Requisitos inventados passam — não há cruzamento com a transcrição neste check | Não. As 11 conferidas contra RF-01..RF-13 |
| PRD-4 | ≥1 linha com `[0-9]+ *(%\|ms\|s\|min\|segundos?)` na §Objetivos. "Reduzir 100% dos problemas" passa. E a métrica pode **contradizer** o desenho | **SIM.** `docs/PRD.md`:76 ("pior caso: 2 segundos") e :79 ("50 pedidos/min") — notas A e C |
| PRD-5 | Exige `[hh:mm] Nome` em **formato**, sem `grep -F` contra `TRANSCRICAO.md`. Um item "descartado, `[09:99] Fulano`" passa | Não — os 15 timestamps foram conferidos à mão nesta sessão e todos existem |
| PRD-6 | ≥2 linhas com 3 células não vazias. "Média / Médio / A definir" passa | **SIM (parcial).** O 5º risco promete "critério de aceite próprio" que não existe no PRD (§1, PRD-6) |
| INV-7 | A âncora de recusa só é procurada em **linhas que começam com ID de requisito em tabela** (`^\| PRD-FR-…`). Um item recusado que reaparece como **bullet** em §Objetivos técnicos, §Critérios de aceite ou §Escopo do FDD é invisível | Não — varredura manual de §Escopo e §Objetivos técnicos não achou reaparecimento; mas o furo é largo |
| TRK-1 | Header literal + 6 campos. Uma tabela com 64 linhas de conteúdo trocado, mas bem formatada, passa | Não |
| TRK-2 | O universo é o conjunto de **IDs**. Afirmação sem ID nunca entra no denominador — quanto menos IDs você atribuir, mais fácil passar | **SIM.** 9 afirmações de grau de requisito sem ID em §3 |
| TRK-3 | `grep -F` prova que o **timestamp existe**, não que a fala sustenta o resumo. Qualquer resumo colado a um timestamp real passa | **SIM.** 3 das 12 linhas sorteadas em §2, com FDD-ERR-06 como caso grave |
| TRK-4 | Confere que o **caminho** existe; não confere linha, nem se o arquivo tem relação com o item. Cinco linhas apontando para `package.json` passam | **SIM.** FDD-ERR-04/05/08 apontam para a mesma linha genérica `http-errors.ts`:27, que o próprio tracker declara insuficiente (§8) |
| GER-2 | Extrai caminho em crase com extensão conhecida e confere no índice. Não confere número de linha, não pega caminho **sem** extensão (`src/modules/webhooks/`), não pega caminho sem crase | Não hoje (linhas reconferidas), mas é o mesmo furo de ADR-4/FDD-5 |

**Os três furos que mais importam** (ver §9): TRK-3 (`grep -F` de timestamp),
TRK-4 (caminho existe ≠ caminho é origem) e TRK-2 (o universo é o que tem ID).
Os três protegem exatamente o critério que o enunciado chama de central — RA-2,
"não é permitido inventar requisitos […] sem origem identificável" — e os três
são satisfeitos por forma, não por conteúdo.

---

## 8 · Itens em aberto herdados

### 8.1 · `WEBHOOK_SIGNATURE_UNAVAILABLE` (FDD-ERR-13) tem lastro?

**Não.** Verificado nas duas fontes admissíveis:

- **Transcrição:** o bloco de secret/rotação é `[09:20]`–`[09:22] Sofia` e
  `[09:32] Diego`. Nenhuma fala trata de "endpoint sem secret utilizável no
  momento do envio". A única borda discutida é a inversa — a secret **antiga**
  continuar valendo por 24h.
- **Código:** `grep -rniE 'hmac|crypto|createHmac|signature' src/ prisma/ tests/ package.json`
  → vazia (rc=1), reexecutado nesta sessão. Não há primitiva, campo ou classe
  para herdar.

O tracker já sabe disso e registra em `docs/TRACKER.md`:99, com a ação sugerida
"tratar como decisão nova do FDD […] e registrar quem a decidiu". **A ação não
foi executada.** No FDD (`docs/FDD.md`:566) a linha é apresentada exatamente
como as outras doze, sem marcador, sem dono e sem data.

**Deve sair do FDD ou ganhar justificativa explícita?** Ganhar justificativa —
mas a decisão de fundo é maior do que o erro isolado. Existe um cenário real por
trás dele: se o grace period expira e não há secret vigente, o worker precisa de
um comportamento definido. Só que esse cenário **não decorre** do desenho
descrito: pela rotação de `docs/FDD.md`:384–386, sempre há uma secret nova
vigente, e a antiga é a que expira. Ou seja, hoje FDD-ERR-13 descreve um estado
que o próprio FDD torna inalcançável.

Recomendação, em ordem de preferência:

1. **Remover** FDD-ERR-13 e a menção correspondente. É o caminho que o enunciado
   sugere literalmente ("Ajuste ou remova", README:288), e o estado que ele
   cobre não existe no desenho atual.
2. Se for mantido, marcá-lo **na própria matriz** como decisão nova do FDD, com
   dono e data — e, junto, descrever o cenário que o produz (por exemplo:
   endpoint cujo material de assinatura foi invalidado por incidente).

E o mesmo tratamento vale para os outros três órfãos, pela mesma razão: hoje
**FDD-ERR-03, -09, -12 e -13** aparecem em `docs/FDD.md`:556, :562, :565 e :566
indistinguíveis dos nove com origem. Um leitor do FDD — que é o público-alvo,
o desenvolvedor — não tem como saber que quatro dos treze foram inventados. A
honestidade do pacote está no tracker e não chega ao documento que será usado
para codar. Isso é o núcleo da FALHA de RA-2.

### 8.2 · Alguma linha `Fonte = CODIGO` está mal classificada, para mais ou para menos?

O tracker tem 6 linhas CODIGO contra o mínimo de 5 — uma folga de exatamente 1.
Duas famílias de problema, com evidência:

**(a) Três CODIGO que a própria regra do tracker não sustentaria.**
FDD-ERR-04, FDD-ERR-05 e FDD-ERR-08 apontam todas para
`src/shared/errors/http-errors.ts`:27 — que é a classe genérica `NotFoundError`
(conferida no disco: linhas 27–31, `super(\`${resource} not found\`, 404,
'NOT_FOUND')`). O tracker declara, em `docs/TRACKER.md`:88–92, que a hierarquia
genérica de classes de erro é "comum a qualquer código HTTP do módulo e por isso
insuficiente para apontar como origem de um item específico" — e usa exatamente
esse argumento para mandar FDD-ERR-03 (`ConflictError`) para a seção de órfãos.
A regra é aplicada a um item e não aos outros três. Aplicada de forma
consistente, sobrariam **3 linhas CODIGO** e **TRK-4 reprovaria** (mínimo 5).

**(b) Dois CODIGO que o próprio pacote classifica como TRANSCRICAO.**
`ADR-006` (Fonte=CODIGO, `src/shared/errors/app-error.ts`:3) e `ADR-007`
(Fonte=CODIGO, `src/modules/orders/order.service.ts`:131) são decisões fechadas
**em reunião**: `docs/adrs/README.md`:23 dá ao ADR-006 as origens
`[09:28] Diego` · `[09:29] Larissa` · `[09:30] Larissa` (DEC-11/13/15/16), e a
linha :24 dá ao ADR-007 `[09:34] Diego` · `[09:41] Diego` (DEC-18/21/22). O
índice do próprio pacote contradiz o tracker. O código é onde a decisão **cai**,
não de onde ela **vem**.

Somando (a) e (b): das 6 linhas CODIGO, **1 é inequivocamente legítima**
(FDD-ERR-02 → `prisma/schema.prisma`:16, o enum `OrderStatus`, que é de fato a
origem do erro de filtro inválido), 3 são genéricas demais pela regra do próprio
tracker e 2 têm origem melhor na transcrição.

**E o inverso — algo marcado TRANSCRICAO com origem legítima em código?** Sim,
dois candidatos com evidência:

- **FDD-CONTRATO-01 e FDD-CONTRATO-02** (`docs/TRACKER.md`:59–60), marcados
  TRANSCRICAO em `[09:31] Marcos` e `[09:33] Bruno`. As falas dão o **verbo** e
  os campos, não a **forma do path**. O path `/customers/:customerId/webhooks` é
  justificado no próprio pacote por precedente de código:
  `docs/adrs/ADR-008-…`:48–50 — "a resolução provisória adotada no pacote é o
  path […] **por coerência com o `GET /orders/:id` já existente**
  (`src/modules/orders/order.routes.ts`:17)". Origem mista, declarada como
  transcrição pura.
- **FDD-CONTRATO-03/04/05** (`PATCH /webhooks/:id`, `DELETE /webhooks/:id`,
  `POST /webhooks/:id/secret/rotate`): a reunião dá os verbos
  ("PATCH pra editar, DELETE pra remover") e a capacidade de rotação, nunca os
  paths. A forma vem do padrão de roteamento do projeto
  (`src/routes/index.ts`:21–28).

Contraste útil: FDD-CONTRATO-06 e -07 estão **corretos** como TRANSCRICAO — os
paths `GET /webhooks/:id/deliveries` e
`POST /admin/webhooks/dead-letter/:id/replay` foram ditados literalmente em
`[09:34] Marcos` e `[09:18] Diego`.

Reclassificar honestamente as origens mistas **não** resolve o problema de
contagem de (a): a folga de 1 linha desaparece assim que a regra do próprio
tracker é aplicada de forma consistente. Corrigir isso exige acrescentar linhas
CODIGO com origem específica de verdade — e elas existem (por exemplo:
`ADR-006` → `src/shared/errors/http-errors.ts`:55 `InsufficientStockError`, o
precedente literal de herança; `ADR-008` → `src/middlewares/auth.middleware.ts`:49
`requireRole`; `FDD-CONTRATO-*` → `src/shared/http/response.ts`:22 `paginated`).

---

## 9 · Veredito final

# REPROVADO

O pacote é, em execução, muito acima da média: 34/34 no verificador, 63 linhas
de tracker com timestamps que existem de verdade, 8 ADRs em MADR com
alternativas e consequências reais, divergências entre reunião e código
levantadas e nomeadas (DIV-01 a DIV-14), e uma seção de "itens sem origem
identificável" que a maioria das entregas não teria a coragem de escrever.
Nada disso salva a entrega hoje, por três motivos independentes:

1. **RA-2 falha.** Quatro requisitos sem origem continuam vigentes no FDD sem
   marcador, e um quinto (FDD-ERR-06) tem origem **falsa** no tracker. O
   critério que o enunciado chama de central — "não é permitido inventar
   requisitos, decisões ou restrições sem origem identificável" — está aberto.
2. **GER-1 falha.** Números que contradizem o código (7 transições viraram 8) e
   a transcrição (latência mínima virou pior caso; cenário retórico virou
   capacidade garantida), mais uma progressão de retry que não fecha com o
   número de tentativas em três leituras incompatíveis dentro do mesmo FDD.
3. **README não reescrito.** Quatro critérios de aceite abertos. Está previsto
   para o bloco 9 e não é surpresa — mas é critério obrigatório e hoje reprova.

Nenhum desses três é visível pelo `scripts/verify.sh`, e isso não é acidente: os
34 checks medem forma (header existe, timestamp existe, caminho existe, contagem
bate) e a entrega falha em conteúdo (a fala sustenta o resumo? o número bate com
o código? a garantia foi decidida por alguém?).

### O que precisa mudar, em ordem

| # | O quê | Onde | Gravidade | Custo de corrigir | Dispara re-verificação de quê? |
|---|---|---|---|---|---|
| 1 | Remover ou marcar explicitamente como **decisão nova do FDD** (dono + data) os 4 códigos sem origem, e mover FDD-ERR-06 para a seção de órfãos ou apagar a regra de bloqueio de re-rotação | `docs/FDD.md`:556, 559, 562, 565, 566 (+ :409–410 e :384–386); `docs/TRACKER.md`:70 e :94–99 | **Bloqueante** (RA-2) | Médio — 1 tabela e 3 parágrafos, mais a decisão editorial "remove ou assume" | TRK-2 (universo cai de 68), TRK-3 (58/64 → 57/63), FDD-4 (contagem de códigos, hoje 13 ≥ 8 — só reprova se cair abaixo de 8), INV-7 e §2 desta revisão |
| 2 | Corrigir "8 transições" para 7, e "5 das 8" para "4 de 7" | `docs/adrs/ADR-007-…`:25 e :133; `docs/FDD.md`:126 | **Bloqueante** (GER-1) | Baixo — 3 números | Nada mecânico (nenhum check lê números). Re-verificação manual contra `src/modules/orders/order.status.ts`:3–10 |
| 3 | Desfazer a inversão "latência mínima" → "latência no pior caso": retirar a linha da tabela de objetivos ou reescrevê-la como "latência mínima imposta pelo polling: 2s" | `docs/PRD.md`:76 e :147; `docs/FDD.md`:162 e :585 | **Bloqueante** (GER-1) | Baixo — 4 frases | **PRD-4** (a linha :76 é uma das 3 que satisfazem o check; conferir que sobra ≥1 meta quantitativa válida — a de 10s, linha :75, basta) |
| 4 | Resolver a aritmética do retry: fixar "5 tentativas + 4 intervalos (última tentativa em 2h36)" **ou** "1 entrega + 5 retries (6 tentativas, ~14h36)", e ajustar diagrama, critério de aceite e a citação de RNF-09 para a leitura escolhida | `docs/FDD.md`:173–183, :581, :744, :746; reflexo em `docs/PRD.md`:150–152 e `docs/adrs/ADR-003-…`:30 e :97 | **Alta** | Médio — decisão técnica + 8 pontos de texto. Como a transcrição é ambígua, a escolha vira **decisão nova**, e precisa de linha própria no tracker | Nada mecânico. Dispara re-verificação de §6 nota B e do item 1 (a decisão nova entra no tracker, mexendo em TRK-2/TRK-3) |
| 5 | Rebaixar "50 pedidos/min" de requisito/objetivo para cenário citado, alinhando o PRD ao que a extração e o FDD já dizem | `docs/PRD.md`:79 e :160; `docs/TRACKER.md`:45 | **Alta** | Baixo — 2 linhas de tabela + 1 do tracker | **PRD-4** (linha :79 é uma das 3 metas contadas) e **PRD-3/TRK-2** se PRD-RNF-16 for removido em vez de reescrito (universo de IDs muda) |
| 6 | Reclassificar as linhas `Fonte = CODIGO`: aplicar a regra da §Itens sem origem de forma consistente e substituir as 3 genéricas (`http-errors.ts`:27) e as 2 de origem transcrita (ADR-006, ADR-007) por origens específicas de verdade | `docs/TRACKER.md`:68–69, 72, 80–81 | **Alta** | Médio — exige achar 3–5 origens de código específicas (candidatos já mapeados em §8.2) | **TRK-4 direto** (hoje 6 ≥ 5; qualquer remoção sem reposição reprova) e **TRK-3** (a razão TRANSCRICAO/total muda nos dois sentidos) |
| 7 | Atribuir ID e linha de tracker às afirmações de grau de requisito hoje sem ID — em especial o item de escopo de `redactPaths`, o prazo de novembro e a garantia de exposição da secret | `docs/PRD.md`:197, :77, :203–204; `docs/FDD.md`:209–213, :189–191, :384–386, :836 | **Alta** | Alto — são 9 achados; cada um vira linha de tracker com origem defensável (ou sai do documento) | **TRK-2** (universo cresce; a razão 80% precisa ser refeita), **TRK-3** e **TRK-4** (a distribuição TRANSCRICAO/CODIGO muda) |
| 8 | Acrescentar ao PRD o critério de aceite de redação de log que a mitigação do 5º risco promete (ou retirar a promessa) | `docs/PRD.md`:197 e §Critérios de aceitação (:199–220) | Média | Baixo — 1 bullet | **PRD-6** (a linha de risco continua com os 3 campos; nenhum check quebra, mas a promessa passa a ser verdadeira) |
| 9 | Tirar do RFC o detalhe que é do FDD: schema/`snake_case`×`camelCase`/exceção de id, e a repetição do "handle transacional"; qualificar o TL;DR, que hoje afirma a premissa de polling que o próprio RFC derruba | `docs/RFC.md`:21–22, :73–75, :184–185, :201–206 | Média | Baixo — 4 trechos, e o RFC ganha folga de palavras | **RFC-6** (2050 palavras hoje; a faixa é 900–2200 — cortar é seguro, o piso é o risco) e **RFC-1** (mínimo 900) |
| 10 | Mover a nota DIV-08 de ADR-001 para ADR-008, onde ela é consequência da decisão, e enxugar a repetição RFC×PRD | `docs/adrs/ADR-001-…`:17–25; `docs/RFC.md`:40–50 e :189; `docs/PRD.md`:31–41 | Média | Médio — reescrita de 3 parágrafos em documentos diferentes | **ADR-4** (ADR-001 perde as citações de `order.routes.ts`/`auth.middleware.ts`; conferir que ele mantém ≥1 caminho real — mantém, `prisma/schema.prisma`:6 e `docker-compose.yml`:2–3), **GER-2** (conjunto de caminhos citados muda) |
| 11 | Reescrever o `README.md` da raiz com as 6 seções do requisito 6 | `README.md` | **Bloqueante** se a entrega for hoje; **planejado** para o bloco 9 | Alto — é um documento inteiro | **RME-1..RME-4** (nenhum é coberto por `verify.sh` hoje — os 4 checks precisam ser escritos), **INV-1** (README.md está na lista de permissão, sem impacto) e **GER-2** (o README passa a citar caminhos; a varredura inclui `README.md`) |
| 12 | Corrigir "todos os doze padrões" (enumera 10) e a descrição da migration ("CREATE INDEX" não existe como statement) | `docs/FDD.md`:6–11; `docs/adrs/ADR-001-…`:87–89 | Baixa | Baixo — 2 frases | Nada. Re-verificação manual contra `.planning/02-codigo.md` §4 e `grep -cE '^CREATE INDEX' …/migration.sql` |
| 13 | Dar exemplo de response de sucesso aos endpoints cujo corpo hoje é `{}` ou corpo de erro | `docs/FDD.md`:361–376, :392–394, :461–465 | Baixa | Baixo — 3 fences | **FDD-3** (conta ≥2 fences ```json por bloco; acrescentar fence não quebra, remover quebraria) |

**Nota final ao autor.** As correções 1 a 7 mexem em tracker e, portanto, nos
denominadores de TRK-2, TRK-3 e TRK-4 ao mesmo tempo. TRK-4 é o mais frágil:
hoje ele passa com 6 linhas contra um mínimo de 5, e três dessas 6 não
sobrevivem à regra que o próprio tracker escreveu. Corrija o item 6 **antes** do
item 1, ou a entrega sai de "34/34 com defeitos invisíveis" para "33/34 com
defeitos visíveis" — o que é mais honesto, mas provavelmente não é o que se quer
no momento do push.
