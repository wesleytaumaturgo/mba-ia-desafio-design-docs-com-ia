# 04 — Denominador do critério ADR-3: as seis decisões principais

## Por que este arquivo existe

O critério do enunciado é: *"o conjunto de ADRs cobre no mínimo 5 das 6 decisões
principais discutidas na reunião"*. Um critério de cobertura só tem valor se o
**denominador for externo ao que está sendo medido**. O ADR-3 da `verify.sh` v3
não tinha isso:

- a perna de DEC lia o mapa decisão→ADR de `.planning/03-design.md` §4 e conferia
  esses IDs contra os ADRs — mas o mapa foi escrito no mesmo movimento em que os
  ADRs foram planejados, então ele mede consistência interna do pacote, não
  cobertura das decisões da reunião;
- a perna dos seis nomes usava seis regex **digitadas dentro do próprio script**,
  sem prova de discriminância: nenhuma delas passou por T1/T2, e a linha de OK
  somava as duas pernas numa contagem só (`22 DEC ... 6/6 nomes`), o que escondia
  qual das duas estava sustentando o verde.

Este arquivo é o denominador, digitado à mão a partir do enunciado. Nenhuma das
seis linhas foi extraída dos ADRs, de `.planning/03-design.md` ou de
`.planning/02-transcricao.md` — a coluna `DEC de origem` é procedência
informativa, não fonte do denominador. O ADR-3 reescrito lê **esta tabela** e
mais nada.

## Procedência

| Item | Valor |
|---|---|
| Engine normativo | `/usr/bin/grep` — GNU grep 3.11, o mesmo que `scripts/verify.sh` resolve |
| Modo de busca | `grep -iE` (case-insensitive, ERE) |
| Corpus de T1 | `docs/adrs/ADR-*.md` — os 8 ADRs, sem alteração nenhuma neste patch |
| Corpus de T2 | `$TMP/t2-controle.md`, arquivo de 14 linhas escrito para este teste |
| Portabilidade | as 6 âncoras foram rodadas também sob ugrep 7.5.0, que é o `grep` do shell interativo desta máquina |

## Notas de leitura da tabela

1. **O `\|` na coluna de âncora é escape de markdown, não parte do regex.** As
   âncoras usam alternância ERE e um `|` cru quebraria a célula. O consumidor
   desescapa (`sed 's/\\|/|/g'`) antes de usar o padrão — round-trip provado
   adiante. Mesma convenção de `.planning/02-recusa.md`.
2. A âncora casa o **conceito**, não o título do arquivo: o `grep` roda sobre o
   conteúdo, e em toda linha de T1 há pelo menos um hit fora da linha do `#`.
3. Um hit sozinho não basta para chamar a decisão de coberta na revisão humana —
   o check é mecânico e mede presença. Hit em ADR não relacionado é âncora ampla
   demais e foi tratado como defeito da âncora, não como cobertura.

## Tabela

| ID (COB-N) | Decisão principal (texto do enunciado) | Âncora (regex ERE) | ADR esperado | DEC de origem |
|---|---|---|---|---|
| COB-1 | Padrão Outbox no MySQL | `outbox.{0,60}mysql\|mysql.{0,60}outbox` | ADR-001 | DEC-01 |
| COB-2 | Política de retry com backoff e DLQ | `backoff.{0,80}(dlq\|dead[_ -]?letter)\|(dlq\|dead[_ -]?letter).{0,80}backoff` | ADR-003 | DEC-05, DEC-06 |
| COB-3 | Autenticação HMAC-SHA256 com secret por endpoint | `hmac-sha256.{0,80}secret( única)? por endpoint\|secret( única)? por endpoint.{0,80}hmac-sha256` | ADR-004 | DEC-07, DEC-08, DEC-09 |
| COB-4 | Garantia at-least-once com X-Event-Id | `at-least-once.{0,60}x-event-id\|x-event-id.{0,60}at-least-once` | ADR-005 | DEC-10 |
| COB-5 | Worker em processo separado em polling | `worker em processo separado.{0,60}polling\|polling.{0,60}worker em processo separado` | ADR-002 | DEC-02, DEC-03 |
| COB-6 | Reuso dos padrões existentes do projeto | `reuso.{0,40}padr[õo]e?s` | ADR-006 | DEC-15, DEC-16 |

**Totais:** 6 decisões principais · 6 com âncora discriminante provada · 0
marcadas `[sem âncora viável]`. Cada âncora casa em **exatamente um** ADR, e é o
ADR esperado.

---

## Prova de discriminância

**T1** roda a âncora contra os 8 ADRs: todo hit é classificado ESPERADO
(está no ADR que registra a decisão) ou INDEVIDO (está em ADR não relacionado —
âncora ampla demais, refina). **T2** roda a âncora contra um arquivo que menciona
os termos isolados em contexto alheio e **não** registra nenhuma das seis
decisões: não pode casar.

`$TMP` é o diretório de scratch desta sessão sob `/tmp`. O arquivo de controle:

```
$ cat $TMP/t2-controle.md
# Nota de operação — não registra nenhuma das seis decisões principais

O banco de produção é MySQL 8.0, com backup diário e uma réplica de leitura.
A fila de e-mails do suporte tem uma outbox própria, mantida pelo time de CRM.
O cliente HTTP do gateway tem retry simples de duas tentativas, sem backoff.
Mensagens não roteadas caem na dead letter do broker corporativo de mensageria.
O login administrativo usa HMAC-SHA256 para assinar o cookie de sessão.
A secret do JWT vive no cofre e é rotacionada por endpoint de conveniência.
O relatório noturno roda como worker de ETL, no mesmo processo do agendador.
O painel de status faz polling da API a cada 30 segundos, sem worker dedicado.
Entrega duplicada é normal em at-least-once de qualquer broker de mensageria.
O header X-Event-Id do sistema legado é um inteiro sequencial, não um UUID.
O reuso de componentes de UI segue o guia da equipe de design.
Os padrões de código do projeto estão no eslintrc, não neste documento.
```

O controle é adversarial de propósito: **todos** os termos das seis âncoras
aparecem nele — `MySQL`, `outbox`, `backoff`, `dead letter`, `HMAC-SHA256`,
`secret`, `por endpoint`, `worker`, `polling`, `at-least-once`, `X-Event-Id`,
`reuso`, `padrões` —, sempre em linha separada e em contexto que não é a decisão.
Uma âncora de termo único casaria em todas elas.

### Termos isolados por ADR

As classificações de T1 abaixo afirmam onde cada termo aparece **sozinho**. A
base dessas afirmações, medida e não lembrada (a saída lista os ADRs em que o
termo ocorre, pelo número do ADR):

```
$ for t in outbox 'dlq|dead[_ -]?letter' backoff 'at-least-once' secret worker polling reuso hmac 'x-event-id' mysql; do
    printf '%-24s : ' "$t"
    /usr/bin/grep -rilE "$t" docs/adrs/ADR-*.md | sed 's|docs/adrs/ADR-\([0-9]*\).*|\1|' | tr '\n' ' '
    echo
  done
outbox                   : 001 002 003 007
dlq|dead[_ -]?letter     : 003 005 006 008
backoff                  : 003
at-least-once            : 003 005
secret                   : 004 008
worker                   : 001 002 003 005 006 007
polling                  : 001 002 003
reuso                    : 006
hmac                     : 004 005
x-event-id               : 005
mysql                    : 001 002
```

Nenhum termo isolado tem distribuição de um ADR só, exceto `backoff`, `reuso` e
`x-event-id` — e mesmo esses três não bastam: uma âncora de termo único não
distingue "a decisão está registrada aqui" de "a palavra foi citada aqui", que é
o defeito que T1 existe para pegar.

### COB-1 — Padrão Outbox no MySQL

Âncora: `outbox.{0,60}mysql|mysql.{0,60}outbox` · tentativa 1

**T1 — 4 hits, todos em ADR-001**

```
$ /usr/bin/grep -rniE 'outbox.{0,60}mysql|mysql.{0,60}outbox' docs/adrs/ADR-*.md
docs/adrs/ADR-001-outbox-no-mysql.md:1:# ADR-001 — Outbox de eventos no MySQL já existente
docs/adrs/ADR-001-outbox-no-mysql.md:42:Todo evento de mudança de status de pedido é gravado como linha de uma tabela outbox no MySQL já existente do projeto — nenhuma infraestrutura nova entra na
docs/adrs/ADR-001-outbox-no-mysql.md:51:Fecha a decisão `[09:08] Larissa`: "Tá decidido então: outbox em MySQL."
docs/adrs/ADR-001-outbox-no-mysql.md:110:  `[09:07] Diego`: "Outbox no MySQL existente resolve." O MySQL existe
```

Linha 1 é o título, 42 é a `## Decisão`, 51 é a fala que fecha (DEC-01) e 110 é a
consequência DIV-14 — **4 ESPERADOS, 0 INDEVIDOS**. `outbox` sozinho aparece
também em ADR-002, ADR-003 e ADR-007, e `mysql` sozinho em ADR-002 — inclusive os
dois no mesmo arquivo (ADR-002); a exigência de co-ocorrência a menos de 60
caracteres é o que mantém o hit dentro de ADR-001.

**T2 — não pode casar**

```
$ /usr/bin/grep -niE 'outbox.{0,60}mysql|mysql.{0,60}outbox' $TMP/t2-controle.md; echo "rc=$?"
rc=1
```

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### COB-2 — Política de retry com backoff e DLQ

Âncora: `backoff.{0,80}(dlq|dead[_ -]?letter)|(dlq|dead[_ -]?letter).{0,80}backoff` · tentativa 1

**T1 — 2 hits, ambos em ADR-003**

```
$ /usr/bin/grep -rniE 'backoff.{0,80}(dlq|dead[_ -]?letter)|(dlq|dead[_ -]?letter).{0,80}backoff' docs/adrs/ADR-*.md
docs/adrs/ADR-003-retry-backoff-e-dlq-em-tabela-separada.md:1:# ADR-003 — Retry com backoff exponencial e DLQ em tabela separada
docs/adrs/ADR-003-retry-backoff-e-dlq-em-tabela-separada.md:21:`retry|retries|backoff` e por `dead.?letter|dlq` em `src/`, `prisma/`, `tests/`
```

Linha 1 é o título e 21 é o `## Contexto`, onde o ADR registra que nenhuma das
duas coisas existe hoje no repositório — **2 ESPERADOS, 0 INDEVIDOS**. `dlq` ou
`dead letter` sozinho aparece também em ADR-005, ADR-006 e ADR-008 (replay,
log de entrega, autorização do replay); a co-ocorrência com `backoff` é o que
discrimina.

**T2 — não pode casar**

```
$ /usr/bin/grep -niE 'backoff.{0,80}(dlq|dead[_ -]?letter)|(dlq|dead[_ -]?letter).{0,80}backoff' $TMP/t2-controle.md; echo "rc=$?"
rc=1
```

O controle tem `backoff` (linha 6) e `dead letter` (linha 7) em linhas
diferentes, que é exatamente o falso positivo que esta âncora precisa evitar.

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### COB-3 — Autenticação HMAC-SHA256 com secret por endpoint

Âncora: `hmac-sha256.{0,80}secret( única)? por endpoint|secret( única)? por endpoint.{0,80}hmac-sha256` · tentativa 1

**T1 — 2 hits, ambos em ADR-004**

```
$ /usr/bin/grep -rniE 'hmac-sha256.{0,80}secret( única)? por endpoint|secret( única)? por endpoint.{0,80}hmac-sha256' docs/adrs/ADR-*.md
docs/adrs/ADR-004-hmac-sha256-secret-por-endpoint.md:1:# ADR-004 — Assinatura HMAC-SHA256 com secret por endpoint
docs/adrs/ADR-004-hmac-sha256-secret-por-endpoint.md:37:Toda entrega leva assinatura HMAC-SHA256 calculada sobre o corpo do request, com uma secret única por endpoint de webhook cadastrado — não uma secret global da
```

Linha 1 é o título, 37 é a `## Decisão` — **2 ESPERADOS, 0 INDEVIDOS**. A palavra
`secret` sozinha aparece também em ADR-008, e `hmac` sozinho em ADR-005
(`X-Signature com o HMAC`, dentro da fala de RF-11); exigir `por endpoint` junto
de `HMAC-SHA256` é o que amarra o hit à decisão.

**T2 — não pode casar**

```
$ /usr/bin/grep -niE 'hmac-sha256.{0,80}secret( única)? por endpoint|secret( única)? por endpoint.{0,80}hmac-sha256' $TMP/t2-controle.md; echo "rc=$?"
rc=1
```

O controle tem `HMAC-SHA256` (linha 8) e `secret ... por endpoint` (linha 9) em
linhas separadas — o par exato que a âncora precisa recusar.

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### COB-4 — Garantia at-least-once com X-Event-Id

Âncora: `at-least-once.{0,60}x-event-id|x-event-id.{0,60}at-least-once` · tentativa 1

**T1 — 2 hits, ambos em ADR-005**

```
$ /usr/bin/grep -rniE 'at-least-once.{0,60}x-event-id|x-event-id.{0,60}at-least-once' docs/adrs/ADR-*.md
docs/adrs/ADR-005-entrega-at-least-once-com-x-event-id.md:1:# ADR-005 — Entrega at-least-once com X-Event-Id para dedup no cliente
docs/adrs/ADR-005-entrega-at-least-once-com-x-event-id.md:36:Fecha a decisão `[09:26] Larissa`: "At-least-once com X-Event-Id pra dedup do
```

Linha 1 é o título e 36 é a fala que fecha (DEC-10) — **2 ESPERADOS, 0
INDEVIDOS**. `at-least-once` sozinho aparece também em ADR-003, como referência
cruzada; a exigência do header impede que essa referência conte como cobertura.

**T2 — não pode casar**

```
$ /usr/bin/grep -niE 'at-least-once.{0,60}x-event-id|x-event-id.{0,60}at-least-once' $TMP/t2-controle.md; echo "rc=$?"
rc=1
```

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### COB-5 — Worker em processo separado em polling

Âncora: `worker em processo separado.{0,60}polling|polling.{0,60}worker em processo separado` · **tentativa 2**

Tentativa 1 — rejeitada pelo engine, não pelo resultado:

```
tentativa 1: (worker.{0,40}processo separado|processo separado.{0,40}worker).{0,60}polling|polling.{0,60}(worker.{0,40}processo separado|processo separado.{0,40}worker)
  -> ugrep: "error at position 334 ... exceeds complexity limits"
```

Sob GNU grep 3.11 a tentativa 1 funcionava, mas `.planning/02-recusa.md` já fixou
que uma âncora precisa passar nos dois engines — o shell interativo desta máquina
resolve `grep` para ugrep. A tentativa 2 troca os dois grupos aninhados pela
frase literal da decisão e passa nos dois.

**T1 — 2 hits, ambos em ADR-002**

```
$ /usr/bin/grep -rniE 'worker em processo separado.{0,60}polling|polling.{0,60}worker em processo separado' docs/adrs/ADR-*.md
docs/adrs/ADR-002-worker-processo-separado-polling.md:1:# ADR-002 — Worker em processo separado consumindo a outbox por polling
docs/adrs/ADR-002-worker-processo-separado-polling.md:33:O consumo da outbox é feito por um worker em processo separado da API, em polling de 2 segundos, lendo apenas os pendentes mais antigos em batch pequeno e marcando
```

Linha 1 é o título, 33 é a `## Decisão` — **2 ESPERADOS, 0 INDEVIDOS**. `worker`
sozinho aparece também em ADR-001, ADR-003, ADR-005, ADR-006 e ADR-007, e
`polling` em ADR-001 e ADR-003 — ADR-001 e ADR-003 têm os dois termos e mesmo
assim não casam, porque nenhum dos dois registra a decisão.

**T2 — não pode casar**

```
$ /usr/bin/grep -niE 'worker em processo separado.{0,60}polling|polling.{0,60}worker em processo separado' $TMP/t2-controle.md; echo "rc=$?"
rc=1
```

O controle tem `worker ... no mesmo processo` (linha 10) e `polling ... sem
worker dedicado` (linha 11) — as duas armadilhas naturais desta âncora.

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### COB-6 — Reuso dos padrões existentes do projeto

Âncora: `reuso.{0,40}padr[õo]e?s` · tentativa 1

**T1 — 2 hits, ambos em ADR-006**

```
$ /usr/bin/grep -rniE 'reuso.{0,40}padr[õo]e?s' docs/adrs/ADR-*.md
docs/adrs/ADR-006-reuso-dos-padroes-existentes.md:1:# ADR-006 — Reuso dos padrões existentes do projeto no módulo de webhooks
docs/adrs/ADR-006-reuso-dos-padroes-existentes.md:50:O módulo de webhooks é escrito por reuso máximo dos padrões que já existem no projeto, e não por invenção de estrutura própria. Concretamente:
```

Linha 1 é o título, 50 é a `## Decisão` — **2 ESPERADOS, 0 INDEVIDOS**. A palavra
`reuso` só aparece em ADR-006; os reusos pontuais de ADR-002 e ADR-008
(`createPrismaClient`, `requireRole`) usam outra forma verbal e por isso nem
entram na conta. O risco real desta âncora é interno ao próprio ADR-006, onde a
fala de DEC-15 ("reuso máximo do que já existe. AppError, Pino, error middleware,
padrão de módulos") tem 58 caracteres entre `reuso` e `padrão` — fora da janela
de 40, então ela não conta como hit: os dois hits são o título e a Decisão.

**T2 — não pode casar**

```
$ /usr/bin/grep -niE 'reuso.{0,40}padr[õo]e?s' $TMP/t2-controle.md; echo "rc=$?"
rc=1
```

O controle tem `O reuso de componentes de UI...` (linha 13) e `Os padrões de
código...` (linha 14) em linhas vizinhas, e não casa.

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

---

## Portabilidade entre engines

As seis âncoras da tabela, na forma final e lidas do próprio arquivo, rodadas sob
o `grep` do shell interativo (ugrep 7.5.0) contra os 8 ADRs:

```
$ while IFS=$'\t' read -r cob anc; do timeout 25 grep -rqiE "$anc" docs/adrs/ADR-*.md; echo "$cob ugrep rc=$?"; done < $TMP/extraidas.txt
COB-1 ugrep rc=0
COB-2 ugrep rc=0
COB-3 ugrep rc=0
COB-4 ugrep rc=0
COB-5 ugrep rc=0
COB-6 ugrep rc=0
```

`rc=0` = casou. Nenhuma âncora foi recusada por limite de complexidade — o
defeito que derrubou a tentativa 1 do COB-5.

## Round-trip do escape

O extrator do `verify.sh` lê a terceira coluna e desescapa `\|` → `|`.
`$TMP/testadas.txt` são as seis âncoras **como foram digitadas** nos comandos de
T1 e T2 acima, uma por linha, no formato `COB-N<TAB>âncora`; `$TMP/extraidas.txt`
é o que o extrator devolve lendo a tabela. Os dois têm que ser idênticos:

```
$ sed -nE 's/^\| *(COB-[0-9]) *\|[^|]*\| *`(.*)` *\| *(ADR-[0-9]{3}).*/\1\t\2/p' .planning/04-cobertura.md | sed 's/\\|/|/g' > $TMP/extraidas.txt
$ diff $TMP/testadas.txt $TMP/extraidas.txt && echo "ROUND-TRIP OK — as 6 âncoras extraídas são byte-a-byte as testadas"
ROUND-TRIP OK — as 6 âncoras extraídas são byte-a-byte as testadas
```

## Itens sem âncora viável

Nenhum. As seis decisões principais têm âncora discriminante provada, então
**não há MAN-02**: nada deste critério foi empurrado para verificação manual.

Se uma âncora futura esgotar as duas tentativas de refino, a linha recebe
`[sem âncora viável]` na coluna de âncora — o consumidor a pula, **conta a
decisão como não coberta** e ela vira MAN-02 em
`.planning/01-matriz.md` §Verificações manuais. Não coberta por padrão, nunca
coberta por omissão.
