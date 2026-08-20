# 13 — Auditoria externa da entrega

Veredito: **REPROVADO**. Eu não aprovaria a entrega no estado atual. Pelo
enunciado original há **31**, não 27, checkboxes: 29 passam e 2 falham
(Tracker/cobertura e Consistência geral). Como todos são obrigatórios, a
contagem alta não compensa as duas falhas centrais.

Base da avaliação: `git show 93e5570:README.md`. Verificador reexecutado:
`bash scripts/verify.sh` → `38/38 OK`; esse resultado foi tratado como prova de
forma, não de conteúdo.

## 1. O README é verdadeiro?

| Afirmação do README | Confere? | Evidência |
|---|---|---|
| A reunião tem cinco participantes e vai de `[09:00]` a `[09:53]` | Sim | `TRANSCRICAO.md:7-12,16,322`; intervalo nominal de 53 minutos |
| A aplicação não tinha notificação externa | Sim | `rg -i 'webhook|outbox|dead.?letter|createHmac' src prisma tests package.json` não encontra implementação; `Glob src/**` encontrou só o probe `src/modules/webhooks/probe.ts`, sem feature |
| Claude Opus 5 foi a ferramenta principal | Parcialmente verificável | `git log --format='%h %s%n%b' 93e5570..HEAD` contém 14 trailers `Co-Authored-By: Claude Opus 5`; o grau de participação descrito em `README.md:21-25` é [não verificado] |
| Claude Sonnet 5 produziu PRD, Tracker e README | Parcialmente verificável | O mesmo comando contém 3 trailers `Co-Authored-By: Claude Sonnet 5`; a atribuição arquivo a arquivo é [não verificado] |
| Cursor foi segunda opinião independente | [não verificado] | Não há trailer, log de ferramenta ou artefato público que prove o fornecedor/modelo alegado em `README.md:36-42` |
| Ordem: transcrição antes do código; depois ADRs → RFC → FDD → PRD → Tracker → review → correções → lacunas → README | Sim para a ordem dos commits | `git log --reverse --format='%h %s' 93e5570..HEAD`: `5979e2e` (transcrição), `e44ef31` (código), `89bb51c` (ADRs), `9224e2c` (RFC), `a30529c` (FDD), `918793f` (PRD), `fc830a4` (Tracker), `99ca4a1` (review), `f21df3d` (correções), `5277c61` (lacunas), `7c687fd` (README) |
| A transcrição foi lida em sessão isolada, sem código aberto | [não verificado] | A ordem dos commits sustenta precedência, mas Git não registra quais arquivos estavam abertos na sessão (`README.md:51-58`) |
| O cruzamento revelou 14 divergências | Sim quanto à contagem documentada | Extração independente dos IDs nos documentos encontrou `DIV-01` a `DIV-14`; exemplos confirmados no código: `DIV-04` em `src/modules/orders/order.service.ts:151-167`, `DIV-07` em `prisma/schema.prisma:11-14,40-54` e `DIV-11` em `src/modules/orders/order.service.ts:95-113` |
| O verificador cresceu de 34 para 38 checks | Sim | `git show 99ca4a1:scripts/verify.sh \| awk -F= '/^total=/'` → `34`; o mesmo em `7c687fd` → `38`; execução atual → `38/38 OK` |
| O script era executado “a cada bloco” | [não verificado] | O histórico prova versões do script, não cada execução (`README.md:63-76`) |
| Cada check recebeu teste negativo | Parcialmente verificável | `scripts/verify.sh:7-99` referencia testes negativos por versão; a cobertura individual de todos os 38 checks não foi reexecutada nesta auditoria |
| Todo arquivo novo citado usa `(novo)` | Sim no universo reconhecido pelo verificador | `bash scripts/verify.sh` → `GER-2 OK — 30 caminhos ... 0 ausentes`; o check está em `scripts/verify.sh:1247-1283` |
| Houve seis commits com prefixo `fix` | Sim | `git log --format='%h %s' --grep='^fix' 93e5570..HEAD` → `3c33050`, `ac22b16`, `ddd8dbc`, `b56919b`, `a248b35`, `f21df3d`; total 6 |
| Os seis itens de “Iterações e ajustes” são esses seis commits | **Não** | Os itens 4, 5 e 6 não correspondem a três commits `fix` distintos: as 14 divergências entraram em `e44ef31` (`docs(planning)`), enquanto os itens 5 e 6 convergem em `f21df3d`; os commits `3c33050`, `ac22b16` e `a248b35` não são descritos como itens próprios. Compare `README.md:141-188` com o log acima |
| O review achou “8” em vez de 7 transições e retry incompatível | Sim | `git show f21df3d --format=fuller --stat`; corpo do commit registra A1/A2; código real em `src/modules/orders/order.status.ts:3-10` soma 7 transições |
| A revisão externa achou a incompatibilidade das classes de erro | Sim quanto ao defeito; autoria [não verificado] | `src/shared/errors/http-errors.ts:9-31` fixa códigos em três bases e `src/shared/errors/app-error.ts:5` é `readonly`; o achado entrou em `f21df3d` |

O README é majoritariamente fiel ao histórico observável, mas exagera a
correspondência “seis iterações = seis commits” e apresenta detalhes de sessão e
de autoria que o repositório não permite confirmar.

## 2. As correções quebraram alguma coisa?

O hash do review adversarial é `99ca4a14f1d5aa67bf6f5fc9bc34a6decfa7d711`
(`git show --format=fuller --stat 99ca4a1`). A premissa fornecida não confere:
`git diff --stat 99ca4a1..HEAD -- docs/ README.md` mostra **11 documentos**,
561 inserções e 409 remoções, não seis documentos. Depois do review há três
commits (`f21df3d`, `5277c61`, `7c687fd`), mas `f21df3d` declara 16 correções e
`5277c61` acrescenta lacunas; a expressão “26 edições em 6 documentos” não é
reproduzível pelo Git.

| Onde | O que mudou | Efeito colateral | Gravidade |
|---|---|---|---|
| `docs/FDD.md:223-244`, `docs/FDD.md:46`; `docs/PRD.md:148` | Retry corrigido para 5 chamadas e 4 intervalos | Ficaram frases “Retentar entrega falha 5 vezes” e “Uma entrega é retentada até 5 vezes”, que significam 5 retries além da chamada inicial, em conflito com “5 chamadas no total” | Alta |
| `docs/FDD.md:269-279,605,930-935` | Replay passou a preservar `event_id` em nova linha | A lista de campos de `webhook_outbox` não contém `eventId`; uma linha com novo `id` não consegue copiar outro identificador. `git show f21df3d^:docs/FDD.md` e `git show f21df3d:docs/FDD.md` mostram que a preservação foi adicionada, mas o schema textual não ganhou o campo | Alta |
| `docs/PRD.md:145`; `docs/FDD.md:213-215,669`; ADR-001:119-121 | “Pior caso de 2s” virou “latência mínima imposta pelo polling” | Polling de 2s impõe espera de agendamento entre quase 0 e 2s; 2s é o máximo desse componente, não o mínimo da entrega. A correção eliminou um erro e introduziu outro | Média |
| `docs/FDD.md:88-136` versus `docs/FDD.md:200-205,223-226,646-650` | Bloco de dez lacunas foi acrescentado | “Classificação de falha” é declarada não decidida, mas o fluxo já decide que todo não-2xx é retryable; replay concorrente é declarado não decidido, mas o contrato já exige 409 e “segunda tentativa recusada” | Alta |
| `docs/FDD.md:422-445` versus `docs/FDD.md:116-124` | Lifecycle do DELETE entrou na lista de lacunas | O contrato já determina remoção e preservação do histórico, resolvendo parte da linha que afirma que soft delete/hard delete/preservação ainda não foram escolhidos | Média |
| `README.md:141-188` | README final resumiu as correções | A narrativa não mapeia os seis itens aos seis commits `fix`, tornando falsa a contagem de iterações descrita na própria entrega | Média |

Não encontrei link Markdown quebrado: `bash scripts/verify.sh` confirmou oito
links de ADR no RFC e 30 caminhos reais; o dano pós-correção é semântico.

## 3. Você aprovaria?

Não. O enunciado em `git show 93e5570:README.md` contém **31 checkboxes**
(6 PRD + 5 RFC + 6 FDD + 4 ADR + 4 Tracker + 4 README + 2 gerais), não 27.

| Grupo / # | Veredito | Evidência independente |
|---|---|---|
| PRD-1 — arquivo Markdown | PASSA | `docs/PRD.md:1`; arquivo existente |
| PRD-2 — seções obrigatórias | PASSA | `docs/PRD.md:3,20,49,71,79,123,139,166,179,190,201,226` |
| PRD-3 — ≥8 RFs | PASSA | `docs/PRD.md:127-137`: 11 linhas `PRD-FR-*` |
| PRD-4 — objetivo quantitativo | PASSA | `docs/PRD.md:73-77`: menos de 10s e 2 dias úteis |
| PRD-5 — ≥2 fora de escopo | PASSA | `docs/PRD.md:102-121`: 15 itens com falas correspondentes em `TRANSCRICAO.md:44-234` |
| PRD-6 — ≥2 riscos completos | PASSA | `docs/PRD.md:192-199`: 6 linhas com probabilidade, impacto e mitigação |
| RFC-1 — arquivo Markdown | PASSA | `docs/RFC.md:1`; arquivo existente |
| RFC-2 — seções obrigatórias | PASSA | `docs/RFC.md:3,13,28,50,98,162,182,212` |
| RFC-3 — ≥2 alternativas reais | PASSA | `docs/RFC.md:100-160`: 6 alternativas; falas em `TRANSCRICAO.md:44-154` |
| RFC-4 — ≥2 questões abertas | PASSA | `docs/RFC.md:164-176`: 11 linhas; QA-01 a QA-05 têm base em `TRANSCRICAO.md:166-228` |
| RFC-5 — ≥2 links de ADR | PASSA | `docs/RFC.md:67-90,214-223`: 8 links; `bash scripts/verify.sh` → RFC-5 OK |
| FDD-1 — arquivo Markdown | PASSA | `docs/FDD.md:1`; arquivo existente |
| FDD-2 — seções obrigatórias | PASSA | Headers em `docs/FDD.md:3,34,59,138,284,613,658,695,775,825,862,879` |
| FDD-3 — ≥4 contratos completos | PASSA | `docs/FDD.md:308-552`: 7 endpoints; requests, responses e status codes |
| FDD-4 — erros `WEBHOOK_*` | PASSA | `docs/FDD.md:636-650`: 13 códigos com prefixo |
| FDD-5 — ≥4 caminhos reais | PASSA | `docs/FDD.md:943-958`; conferidos em `git ls-files`; verificador contou 18 |
| FDD-6 — métricas, logs e tracing | PASSA | `docs/FDD.md:703-773`: 6 métricas, 7 logs e tracing |
| ADR-1 — 5 a 8 ADRs no padrão | PASSA COM RISCO DE LEITURA | `Glob docs/adrs/*.md` → 8 `ADR-NNN-*.md` + `README.md`. Pela expressão literal do padrão, são 8 e passa. Avaliador que conte a pasta inteira verá 9 Markdown e poderá reprovar; o índice não é um ADR, mas o enunciado não explicita essa exceção |
| ADR-2 — seções MADR | PASSA | Leitura dos 8 arquivos; `bash scripts/verify.sh` → ADR-2 OK, 7 seções em cada |
| ADR-3 — ≥5/6 decisões | PASSA | ADR-001 a ADR-006 cobrem as seis decisões listadas; `docs/adrs/README.md:18-23` |
| ADR-4 — referência ao código | PASSA | Todos referenciam código; exemplos em `ADR-006:15-27` e `ADR-007:9-35` |
| Tracker-1 — formato obrigatório | PASSA | `docs/TRACKER.md:17-18`; 65 linhas na tabela principal, seis campos |
| Tracker-2 — cobertura ≥80% | **FALHA** | Critério independente: todo ID explícito nos documentos (`\b[A-Z]{2,}(?:-[A-Z]+)*-\d{2,3}\b`). Script Python sobre PRD/RFC/FDD/ADRs → universo 171; primeira coluna de todas as tabelas do Tracker → 78 cobertos, **45,6%**. Faltam como itens próprios 27 `DEC-*`, 14 `DIV-*`, 13 `RF-*`, 24 `RNF-*`, 11 `REC-*`, 2 `COD-*` e 2 `GAN-*`. O critério estreito do script escolhe só 78 IDs canônicos e mede 65/78 na tabela principal (83,3%); essa escolha exclui justamente os IDs adicionais usados pela entrega |
| Tracker-3 — ≥70% TRANSCRICAO | PASSA | Tabela principal: 57/65 = 87,7%; timestamps existem em `TRANSCRICAO.md` |
| Tracker-4 — ≥5 CODIGO reais | PASSA | `docs/TRACKER.md:49,62-66,70,72`: 8 linhas; caminhos conferidos por `git ls-files` |
| README-1 — seções | PASSA | `README.md:3,19,44,87,139,190` |
| README-2 — ≥1 ferramenta | PASSA | `README.md:21-42`: 4 itens |
| README-3 — ≥2 prompts | PASSA | `README.md:93-113,120-137`: 2 blocos |
| README-4 — ≥2 ajustes | PASSA formalmente | `README.md:141-188`: 6 itens; a veracidade da equivalência com commits falha na seção 1 desta auditoria |
| Geral-1 — nenhuma contradição/invenção | **FALHA** | Retry órfão (`FDD:46` × `FDD:223-226`), `event_id` sem campo (`FDD:605` × `FDD:930-935`), decisões sem origem mantidas como contrato (`FDD:640,643,646,649-650`) e “não decidido” já decidido em outro trecho (`FDD:129-132` × `FDD:205,223`) |
| Geral-2 — nenhum caminho inexistente | PASSA | `bash scripts/verify.sh` → GER-2 OK, 30 caminhos distintos e 0 ausentes; novos estão marcados `(novo)` |

**Soma:** 29 PASSA (incluindo ADR-1 com ressalva) · 2 FALHA · total 31.

O Tracker cai abaixo de 80% porque a própria entrega introduziu um segundo
vocabulário de IDs (`DEC`, `DIV`, `RF`, `RNF`, `REC`, `COD`, `GAN`) sem dar a
esses itens linhas próprias. Contá-los não é ampliar o escopo arbitrariamente:
eles aparecem como identificadores formais em documentos entregues, mas sua
definição depende de `.planning/`, que não faz parte da navegação pública.

## 4. O que eu tiraria nota por

1. **Invenção declarada continua sendo invenção.** Marcar
   `WEBHOOK_DUPLICATE_URL`, bloqueio de nova rotação, replay único, retry de todo
   não-2xx, `WEBHOOK_SIGNATURE_UNAVAILABLE` e sigilo da secret como “sem origem”
   é honesto, mas não satisfaz “não é permitido inventar”. Evidência:
   `docs/FDD.md:475-480,640-650`; `docs/PRD.md:164,205-208`;
   `TRANSCRICAO.md:126-144` não fecha essas regras.

2. **O FDD não é implementável apesar do volume.** Tem 7.640 palavras
   (`bash scripts/verify.sh`), mas declara que o schema de três models não é
   escrevível (`docs/FDD.md:120-124`) e deixa dez decisões para antes da
   implementação (`docs/FDD.md:88-136`). Densidade não substitui fechamento.

3. **Altura errada.** O PRD contém middleware, JWT, `redactPaths`, transação e
   arquivos de teste (`docs/PRD.md:31-41,57-64,194-199,228-243`). O RFC encosta
   no teto artificial de 2.200 palavras — 2.191 no verificador — e repete oito
   decisões que os ADRs já registram (`docs/RFC.md:65-90,212-223`).

4. **Redundância.** A falta de credencial externa aparece no PRD
   (`:31-41`), RFC (`:41-48,189-194`) e ADR-001 (`:17-23`), embora o próprio
   ADR diga que isso não muda sua decisão. As alternativas síncrono/Redis/trigger
   também são repetidas em PRD, RFC e ADR-001.

5. **Referências opacas a artefatos internos.** `DEC-*`, `DIV-*`, `REC-*`,
   `GAN-*` e `COD-*` são usados sem definição no pacote navegável; o próprio FDD
   aponta para `.planning/02-codigo.md` (`docs/FDD.md:7-19`). Isso faz o pacote
   depender da memória de produção em vez de ser autocontido.

6. **Fluxo impossível para o público declarado.** O payload omite `items`
   porque o cliente “busca o detalhe depois em `GET /orders/:id`”
   (`docs/FDD.md:554-558`), mas PRD e RFC provam que o cliente externo não tem
   credencial (`docs/PRD.md:31-41`; `src/modules/orders/order.routes.ts:12-17`;
   `prisma/schema.prisma:40-54`).

7. **Garantia de latência sem desenho de capacidade.** O objetivo é primeira
   tentativa abaixo de 10s (`docs/PRD.md:75`), mas worker serial/concorrente e
   batch não foram definidos (`docs/FDD.md:195-211`); cada chamada pode ocupar
   10s (`:203`). O critério de aceite enfraquece a meta para “na maioria dos
   casos” (`docs/PRD.md:211-212`), expressão ausente da reunião.

### “Não decidido na reunião”

A seção não preserva integralmente as lacunas:

- **Classificação de falha** é chamada de não decidida em
  `docs/FDD.md:129-132`, mas `:205,223-226,649` decide que qualquer não-2xx é
  falha retentável.
- **Concorrência de replay** é chamada de não decidida em `:125-128`, mas
  `:278-279,552,646` exige item marcado como reprocessado e segunda tentativa
  recusada. Falta mecanismo, mas a semântica já foi inventada.
- **Lifecycle de DELETE** é declarado aberto em `:116-119`, porém o contrato
  decide remover o endpoint e preservar entregas em `:420-445`.

Não há “recomenda-se” ou default numérico dentro dos dez bullets. O problema é
mais sério: três linhas são contraditas por decisões afirmativas em outras
seções do mesmo FDD.

## 5. A entrega parece escrita por alguém que pensou no problema?

**Onde parece pensado:**

- A leitura cruzada descobriu que o cliente externo não possui identidade nem
  acesso ao polling presumido, e transformou isso em consequência de produto:
  “a alternativa [...] é ‘o cliente continua sem visibilidade nenhuma’”
  (`docs/PRD.md:29-41`), sustentado por
  `src/middlewares/auth.middleware.ts:6-46` e `prisma/schema.prisma:40-54`.
- A entrega encontrou a incompatibilidade real da hierarquia de erros:
  `docs/FDD.md:622-634` distingue bases configuráveis das bases com código fixo;
  isso confere com `src/shared/errors/http-errors.ts:3-43` e
  `src/shared/errors/app-error.ts:3-13`.
- A análise de ordering percebeu que backoff quebra ordem mesmo com um worker
  (`docs/adrs/ADR-002-...md:118-131`), inferência que não foi dita na reunião.

**Onde parece copiado/compilado:**

- A frase da reunião “latência mínima [...] 2 segundos” foi preservada sem
  teste do conceito (`TRANSCRICAO.md:68`; `docs/FDD.md:213-215`; ADR-001:119-121).
  Polling periódico não cria piso de 2s; cria atraso variável até 2s.
- O FDD copia a orientação de buscar `GET /orders/:id` da fala
  (`TRANSCRICAO.md:254-256`; `docs/FDD.md:554-558`) mesmo depois de o pacote
  demonstrar que o cliente não pode chamar essa rota (`docs/PRD.md:31-41`).
- O PRD reproduz 15 descartes/adiamentos com timestamps (`docs/PRD.md:102-121`)
  e o RFC reproduz seis alternativas (`docs/RFC.md:98-160`), que voltam a ser
  narradas nos ADRs. Há filtragem, mas pouca edição entre alturas.

Minha leitura é mista: houve reflexão técnica forte na inspeção do código, mas o
pacote foi consolidado por acumulação. Os melhores achados convivem com frases
da transcrição que não passaram por teste semântico e com repetição excessiva.

## 6. O que os anteriores não pegaram

Esta seção foi escrita somente depois das cinco anteriores. Arquivos comparados:
`.planning/09-review.md`, `.planning/10-externo.md` e
`.planning/12-auditoria.md`.

### Achados desta auditoria ausentes dos três

1. **README não mapeia suas seis iterações aos seis commits `fix`.** Os reviews
   09/10 antecedem o README; a auditoria 12 só contou itens. Nenhum confrontou
   `README.md:141-188` com o histórico.
2. **A correção do replay criou um schema impossível.** O review 10 encontrou a
   quebra original de dedup (`.planning/10-externo.md:152-155`), mas ninguém
   conferiu o efeito da correção: preservar `event_id` exige um campo separado
   que continua ausente de `docs/FDD.md:930-935`.
3. **A correção do retry deixou linguagem órfã de “5 retries”.** Os anteriores
   encontraram a aritmética original, mas a auditoria 12 aceitou a correção sem
   cruzar `docs/FDD.md:46` e `docs/PRD.md:148` com “5 chamadas” em
   `docs/FDD.md:223-226`.
4. **“Latência mínima de 2s” continua tecnicamente falsa.** O review 09 propôs
   justamente essa redação (`.planning/09-review.md:688`); o review 10 observou
   que 2s não é teto de entrega (`:50`), mas nenhum registrou que a espera do
   polling varia de aproximadamente 0 a 2s.
5. **Cobertura ampla quantificada em 45,6%.** O review 09 já identificava a
   cegueira a itens sem ID (`.planning/09-review.md:197-219,536-539`), mas não
   contou as famílias formais que a versão final usa. O comando independente
   encontrou 171 IDs e apenas 78 como primeira coluna do Tracker.
6. **O diff pós-review não corresponde à premissa “26 edições/6 documentos”.**
   `git diff --stat 99ca4a1..HEAD -- docs/ README.md` lista 11 documentos. Os
   relatórios anteriores não auditam essa afirmação.

### Pontos anteriores que considero falso positivo ou gravidade inflada

- `.planning/09-review.md:45,524` trata `{}` em requests sem body e o corpo de
  erro do DELETE 204 como deficiência. Não é: 204 não pode ter corpo, e `{}` é
  uma representação inequívoca de “sem body”. O próprio review externo corrige
  essa leitura em `.planning/10-externo.md:211-213`.
- `.planning/10-externo.md:22,25,27` classifica como “trava” a ausência de
  concorrência/default de batch, backend de métricas e escolha de cliente HTTP.
  São decisões relevantes, mas não impedem começar migration, CRUD e publisher;
  a gravidade correta é “atrasa” ou risco de operação, salvo se o FDD prometesse
  um SLO verificável sob carga.
- `.planning/10-externo.md:171-175` trata o alias local `TxClient` como trava.
  O fato técnico é verdadeiro, mas `docs/FDD.md:910-917` já oferece
  `Prisma.TransactionClient` diretamente, solução sem alteração arquitetural.
  É detalhe de compilação, não bloqueio de design.

### O que estava correto e a auditoria interna perdeu

A auditoria 12 marca consistência como “PASSA COM RESSALVA”
(`.planning/12-auditoria.md:81`) com três buscas pontuais. Isso é falso negativo:
as contradições pós-correção desta auditoria não casam aqueles três padrões. Em
especial, nenhuma busca da auditoria verificou a existência de um campo
`eventId`, distinguiu chamadas de retries ou comparou “não decidido” com os
contratos afirmativos do próprio FDD.
