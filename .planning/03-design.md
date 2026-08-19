# 03 — Design do pacote de documentos

> **Status: NORMATIVO.** As decisões deste documento foram tomadas no gate humano do
> Bloco 3 e não são reabertas pelos blocos seguintes. Onde um bloco posterior
> divergir daqui, ele PARA E REPORTA em vez de decidir sozinho.
>
> Insumos: `.planning/02-transcricao.md`, `.planning/02-recusa.md`,
> `.planning/02-ganchos-declarados.md`, `.planning/02-codigo.md`,
> `.planning/02-ganchos-verificados.md`.

---

## 1 · Contagens do Bloco 2

| Tabela | Linhas | Conceitual | Consumido por |
|---|---|---|---|
| DEC — decisões fechadas | 27 | 26 (DEC-15/16 é par dividido) | ADRs · PRD §Decisões e trade-offs |
| RF — requisitos funcionais | 13 | **11** (RF-09/10 e RF-11/12 são pares) | PRD §Requisitos funcionais |
| RNF — não funcionais e restrições | 27 | 27 | PRD §RNF · FDD |
| REC — descartado | 10 | 10 | RFC §Alternativas · PRD §Fora de escopo |
| REC — adiado | 5 | 5 | PRD §Fora de escopo |
| QA — ambíguo / não decidido | 4 | 4 | RFC §Questões em aberto |
| GAN — ganchos declarados | 34 | 34 | FDD §Integração · ADRs |

**Não há gap de requisitos funcionais.** 11 conceituais contra os 8 exigidos pelo
critério PRD-3. Nenhum RF precisa ser inferido, derivado ou completado para cota.

Os seis nomes de decisão citados pelo enunciado têm todos fala correspondente na
transcrição — nenhum marcado `[ausente na transcrição]`.

---

## 2 · Decisões normativas

| ID | Decisão | Justificativa | Custo aceito |
|---|---|---|---|
| **D-01** | Convenção de nome de ADR é a do enunciado: `ADR-NNN-titulo-em-kebab-case.md` | O critério de aceite cita o formato literalmente; o avaliador confere contra o enunciado, não contra o scaffolding | `docs/adrs/README.md` diverge (`NNNN-titulo-da-decisao.md`) e será reescrito — ver D-06 |
| **D-02** | **8 ADRs**, o teto do intervalo 5–8 | DEC-17/19/20 (autorização) têm trade-off explícito e ocupam ~5 min de reunião; empurrá-las para o FDD carrega o documento mais pesado | Não sobra slot. Se o review reprovar um ADR, a saída é **fortalecê-lo**, nunca somar um nono — 9 arquivos reprova ADR-1 |
| **D-03** | `.planning/` e `scripts/` permanecem versionados no repositório entregue | O README exige ≥2 iterações concretas; sem artefato em disco a afirmação é relato, não evidência | Dois diretórios fora da estrutura literal do enunciado, que termina em "demais arquivos do boilerplate" |
| **D-04** | QA-01 resolvida provisoriamente: `customer_id` vai no **path** — `POST /customers/:customerId/webhooks` | Coerente com `GET /orders/:id` já existente; torna o escopo do recurso explícito na URL | O FDD marca a escolha como provisória e referencia `RFC-QA-01`, que permanece aberta no RFC |
| **D-05** | QA-02 resolvida provisoriamente: `webhook.processor.ts` para a lógica de processamento; `src/worker.ts` para a entry-point (DEC-12) | "worker" já nomeia o processo; reusar no arquivo interno confunde processo com lógica | idem D-04 — `RFC-QA-02` permanece aberta |
| **D-06** | `docs/adrs/README.md` é **reescrito como índice**, não deletado | Deletar apaga a evidência de que a divergência de convenção foi vista e decidida | Um arquivo a mais na pasta; ADR-1 exclui `README.md` do denominador |
| **D-07** | Metadados do RFC: autor **Wesley Taumaturgo** · status **Em revisão** · data do commit · revisores **Bruno, Diego, Larissa, Marcos, Sofia** | O enunciado manda usar os participantes da reunião como revisores | — |
| **D-08** | Item da lista de recusa **nunca recebe ID de requisito** | Ver §3 — sem essa regra o INV-7 dispara em cima de conteúdo correto | Três itens da tabela RNF mudam de destino |

---

## 3 · Regra D-08 e a reclassificação dos RNFs

### O problema medido

`INV-7` varre linhas que casem `^\| *(PRD-FR|PRD-RNF|FDD-CONTRATO|FDD-ERR)-[0-9]{2} *\|`
procurando as âncoras de `.planning/02-recusa.md`. Três itens da tabela RNF, se
virarem linha `PRD-RNF-NN`, disparam o verificador em cima de conteúdo correto:

| RNF | Texto | Âncora que dispara | Recusa correspondente |
|---|---|---|---|
| RNF-06 | Arquivamento de linhas entregues após ~30 dias | REC-11 (`arquiva\|purga\|…` + `outbox\|linhas entregues`) | REC-11 · ADIADO |
| RNF-12 | Três retries em 30 minutos | REC-05 | REC-05 · DESCARTADO |
| RNF-16 | 500KB citado ao rejeitar truncamento | REC-07 (`\btrunca`) | REC-07 · DESCARTADO |

Não é defeito do verificador: os três **são** menções ao que foi recusado,
registradas na tabela errada da extração.

### A regra

> Item que consta de `.planning/02-recusa.md` aparece exclusivamente em
> `## Fora de escopo` do PRD (lista **sem ID**), em `## Alternativas consideradas`
> do RFC (`RFC-ALT-NN`) ou em `## Questões em aberto` do RFC (`RFC-QA-NN`).
> Jamais como `PRD-FR-NN`, `PRD-RNF-NN`, `FDD-CONTRATO-NN` ou `FDD-ERR-NN`.

`RFC-ALT-NN` e `RFC-QA-NN` estão fora do escopo varrido pelo INV-7 justamente
porque são os lugares onde a menção ao recusado é legítima.

### Destino dos 27 RNFs

| Destino | IDs | Forma no documento |
|---|---|---|
| **Requisito** → `PRD-RNF-NN` | 01, 02, 03, 04, 05, 07, 08, 09, 13, 14, 15, 17, 18, 19, 20, 21, 22, 26, 27 (19) | linha de tabela com ID |
| **Contexto / motivação** → sem ID | 10, 11, 23, 24, 25 (5) | prosa em PRD §Problema e motivação |
| **Recusa** → sem ID | 06, 12, 16 (3) | lista em PRD §Fora de escopo |

---

## 4 · Mapa decisão → ADR

Oito ADRs. Cobertura dos seis nomes do enunciado: **integral** (o critério exige 5).

| ADR | Arquivo | DEC cobertas | Alternativas reais | Ganchos de código |
|---|---|---|---|---|
| ADR-001 | `ADR-001-outbox-no-mysql.md` | DEC-01 | REC-01 síncrono · REC-02 Redis · REC-03 trigger de banco | GAN-09, 10, 11 |
| ADR-002 | `ADR-002-worker-processo-separado-polling.md` | DEC-02, 03, 12, 14 · consequência DEC-04 | worker no mesmo processo da API · notificação reativa por trigger | GAN-12, 13, 15, 33 |
| ADR-003 | `ADR-003-retry-backoff-e-dlq-em-tabela-separada.md` | DEC-05, 06 | REC-04 retry indefinido · REC-05 três tentativas · REC-06 "failed" na própria outbox | — |
| ADR-004 | `ADR-004-hmac-sha256-secret-por-endpoint.md` | DEC-07, 08, 09 | secret global da plataforma · entrega sem assinatura | GAN-22 |
| ADR-005 | `ADR-005-entrega-at-least-once-com-x-event-id.md` | DEC-10 | REC-08 exactly-once | — |
| ADR-006 | `ADR-006-reuso-dos-padroes-existentes.md` | DEC-11, 13, 15, 16 | módulo standalone fora de `src/modules` · hierarquia de erro própria | **GAN-16…23** |
| ADR-007 | `ADR-007-insercao-na-outbox-dentro-da-transacao.md` | DEC-18, 21, 22 | inserção após o commit · injeção do repository no OrderService | **GAN-02…08** |
| ADR-008 | `ADR-008-modelo-de-autorizacao-do-modulo.md` | DEC-17, 19, 20 | REC-09 `customer_id` derivado do JWT · CRUD restrito a ADMIN | GAN-24…27 |

**Critério ADR-4** (≥1 ADR referenciando código real) tem **dois** candidatos
independentes — ADR-006 e ADR-007. Margem dobrada de propósito: se o review
julgar a referência de um deles fraca, o outro sustenta o critério sozinho.

**Decisões que ficam apenas no FDD**, por autorização explícita do enunciado
("decisões técnicas secundárias… podem ficar apenas no FDD"):
DEC-23 (timeout de 10s) · DEC-24 (payload sem `items`) · DEC-26 (UUID como id) ·
DEC-27 (snapshot do payload na inserção).

---

## 5 · Fronteira RFC × FDD

O enunciado avisa que conteúdo duplicado entre documentos é sinal de que algo
está no lugar errado, e que o RFC é conciso (2–4 páginas). Esta é a linha:

| Assunto | RFC diz | FDD diz |
|---|---|---|
| Outbox | *que* existe uma outbox e *por que* no MySQL | DDL, colunas, índices, estados, transições |
| Worker | processo separado, consumo por polling | intervalo, tamanho de batch, query de leitura, marcação de estado |
| Retry | há política de retry finita terminando em DLQ | 1m/5m/30m/2h/12h, condição de falha, fluxo de replay |
| HMAC | assinatura por endpoint, com rotação | algoritmo, string canônica assinada, header, grace period |
| Endpoints | *quais capacidades* o cliente ganha — uma linha por capacidade | método, path, payload de request e response, headers, status codes |
| Erros | nada | matriz `WEBHOOK_*` completa |
| Integração | um parágrafo: acopla na transação do `changeStatus` | seção obrigatória, ≥4 caminhos reais, símbolo a símbolo |

### Invariante mecânico (INV-8)

```bash
wc -w docs/RFC.md                        # 900 ≤ n ≤ 2200
grep -cE 'WEBHOOK_[A-Z]|^```json|^\| *(GET|POST|PUT|PATCH|DELETE) ' docs/RFC.md
# esperado: 0
```

---

## 6 · Títulos canônicos das seções

Os verificadores conferem **header literal**. Qualquer variação de redação
reprova o critério de seções obrigatórias.

### `docs/PRD.md`

```
## Resumo e contexto
## Problema e motivação
## Público-alvo e cenários de uso
## Objetivos e métricas de sucesso
## Escopo
### Incluso no escopo
### Fora de escopo
## Requisitos funcionais
## Requisitos não funcionais
## Decisões e trade-offs principais
## Dependências
## Riscos e mitigação
## Critérios de aceitação
## Estratégia de testes e validação
```

### `docs/RFC.md`

```
## Metadados
## Resumo executivo (TL;DR)
## Contexto e problema
## Proposta técnica
## Alternativas consideradas
## Questões em aberto
## Impacto e riscos
## Decisões relacionadas
```

### `docs/FDD.md`

```
## Contexto e motivação técnica
## Objetivos técnicos
## Escopo e exclusões
## Fluxos detalhados
## Contratos públicos
## Matriz de erros
## Estratégias de resiliência
## Observabilidade
### Métricas
### Logs
### Tracing
## Dependências e compatibilidade
## Critérios de aceite técnicos
## Riscos e mitigação
## Integração com o sistema existente
```

`## Integração com o sistema existente` fica por último porque o enunciado a
introduz como *"Seção obrigatória adicional, específica deste desafio"* — é
apêndice, não item da lista de onze. A ordem das onze primeiras é a literal do
enunciado.

### `docs/adrs/ADR-NNN-*.md` — formato MADR

```
## Status
## Contexto
## Decisão
## Alternativas Consideradas
## Consequências
### Positivas
### Negativas
```

### `README.md`

```
## Sobre o desafio
## Ferramentas de IA utilizadas
## Workflow adotado
## Prompts customizados
## Iterações e ajustes
## Como navegar a entrega
```

---

## 7 · Convenções de marcação

| ID | Convenção | Verificador que depende |
|---|---|---|
| **C-1** | Caminho de arquivo que ainda não existe é escrito `` `caminho` `` seguido do marcador literal `(novo)`. Sem o marcador, o caminho é afirmação sobre o código existente e é conferido contra `git ls-files` | INV-5 · GER-2 |
| **C-2** | IDs inline em todo item rastreável: `PRD-FR-NN` · `PRD-RNF-NN` · `RFC-ALT-NN` · `RFC-QA-NN` · `FDD-CONTRATO-NN` · `FDD-ERR-NN` · `ADR-NNN`. O universo de "itens identificáveis" do tracker é o conjunto desses IDs | TRK-2 · INV-7 |
| **C-3** | Toda Localização de transcrição é `[hh:mm] Nome` copiado literalmente, conferível por `grep -F` em `TRANSCRICAO.md` | INV-6 · TRK-3 |
| **C-4** | Endpoint no FDD: header `### MÉTODO /path`, no mínimo dois fences ` ```json ` (request e response) e ao menos uma linha `**Status:** NNN` no bloco | FDD-3 |
| **C-5** | Código de erro no FDD: primeira coluna da matriz casa `WEBHOOK_[A-Z_]{3,}`; **zero** códigos de erro do módulo sem o prefixo | FDD-4 |
| **C-6** | Link para ADR no RFC é relativo ao diretório do documento: `](adrs/ADR-NNN-....md)` | RFC-5 |

---

## 8 · Verificações manuais

Nem tudo é automatizável. O que não for vira linha aqui, com dono e bloco — não
nota de rodapé.

| ID | O que verificar | Por que não automatiza | Onde | Bloco |
|---|---|---|---|---|
| **MAN-01** | REC-09 (`customer_id` derivado do JWT) não pode aparecer como decisão vigente | ERE não tem lookaround; nenhum padrão separa a adoção da negativa correta registrada em DEC-17 | `.planning/09-review.md` | 9 |

---

## 9 · Ordem de produção

Segue a ordem sugerida pelo enunciado. As inserções (contrato, design) não
invertem nada; o tracker no fim é escolha justificada.

| Bloco | Entrega | Ferramenta |
|---|---|---|
| 4 | 8 ADRs + `docs/adrs/README.md` reescrito + `verify.sh` v3 | Claude Code · Opus |
| 5 | `docs/RFC.md` + `verify.sh` v4 | Claude Code · Opus |
| 6 | `docs/FDD.md` + `verify.sh` v5 | Claude Code · Opus |
| 7 | `docs/PRD.md` + `verify.sh` v6 (INV-7) | Claude Code · Sonnet |
| 8 | `docs/TRACKER.md` + `verify.sh` v7 completo | Claude Code · Sonnet |
| 9 | Review adversarial | Claude Code · **janela nova** · Opus |
| 10 | Verificação externa | **Cursor** |
| 11 | `README.md` + auditoria de entrega + push | Claude Code · Sonnet |

O tracker fica no fim, e não em paralelo, porque varredura sobre texto congelado
é verificável; em paralelo produz drift entre tracker e documento.

---

## 10 · Precedência disco × fala (D-09) e roteamento das divergências

**D-09 — Onde a transcrição e o código divergirem, o documento segue o CÓDIGO e
nomeia a divergência.** O critério GER-1 reprova documento que contradiga a
transcrição *ou* o código; com os dois em conflito, a única saída que não
contradiz nenhum é afirmar o que o disco mostra e registrar o que foi dito.
Nenhuma divergência é silenciada, nenhuma é "conciliada" reescrevendo a fala.

**D-10 — Payload em snake_case, por decisão.** A reunião especificou `order_id`,
`order_number`, `total_cents` (RF-09, RF-10); o schema Prisma usa camelCase
(DIV-01, DIV-02, DIV-03). Não é contradição: o payload é contrato público e o
schema é interno. O FDD declara o mapeamento campo a campo em §Contratos
públicos. Nenhum documento afirma que a coluna se chama `total_cents`.

| DIV | Destino obrigatório | Como entra |
|---|---|---|
| DIV-01, 02, 03 | FDD §Contratos públicos + §Integração | tabela de mapeamento payload ↔ coluna Prisma, por D-10 |
| DIV-04 | ADR-007 §Contexto — feito | a transação não é uniforme; a inserção na outbox precisa ser incondicional |
| DIV-05 | ADR-001 §Alternativas — feito | a alternativa "trigger de banco" não existe no repo hoje |
| DIV-06 | ADR-002 §Consequências/Negativas — feito | o worker precisa de config que a reunião presumiu pronta |
| DIV-07 | ADR-008 §Contexto — feito | o código confirma DEC-17: `customer_id` não poderia vir do JWT |
| DIV-08 | PRD §Problema e motivação · já no RFC §Contexto | a premissa do polling, com a ressalva do disco |
| DIV-09 | ADR-006 §Contexto — feito | "reuso do padrão" tem exceção precedente (módulo auth) |
| DIV-10 | FDD §Dependências e compatibilidade | DEC-26 (UUID) vale para 6 de 7 models |
| DIV-11 | ADR-007 §Consequências/Negativas — feito | cobertura da feature tem buraco declarado |
| DIV-12 | FDD §Fluxos detalhados | DEC-18 filtra na inserção; o conjunto filtrável é o enum real de 6 valores |
| DIV-13 | ADR-006 §Contexto — feito | Pino está em 3 arquivos, não "no projeto inteiro" |
| DIV-14 | ADR-001 §Consequências/Negativas — feito | primeiro uso do padrão outbox no projeto |

As 14 divergências alimentam também o README §Iterações e ajustes, que exige ≥2
correções concretas — aqui há 14, cada uma com `arquivo:linha`.
