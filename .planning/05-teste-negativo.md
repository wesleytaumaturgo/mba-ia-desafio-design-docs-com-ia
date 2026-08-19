# 05 — Teste negativo dos checks RFC-1..RFC-6

Cada check novo de `scripts/verify.sh` v4 foi sabotado uma vez, de forma isolada,
para provar que **falha quando deve falhar**. Sem isso um check verde não
distingue "o documento está correto" de "o check não mede nada".

## Método

Todas as sabotagens são não destrutivas para o repositório: rodam sobre **cópias
sob `/tmp/rfc-neg-05/`**, e o `verify.sh` as recebe por `RFC_FILE`, a mesma
parametrização que `ADR_DIR` já tinha no bloco 4. `docs/RFC.md` não foi tocado em
nenhum dos oito casos — `git status` permanece limpo durante a bateria.

Ambiente: `engine: /usr/bin/grep grep (GNU grep) 3.11` · `BASE =
93e557087e6112aa8628f91024a80542b8af9a44` · linha de base `docs/RFC.md` com 2013
palavras e `15/15 OK`.

Filtro de saída usado nos recortes abaixo (mostra da primeira linha `RFC-1` em
diante, incluindo as linhas indentadas de motivo e o total):

```bash
run() { RFC_FILE="$1" ./scripts/verify.sh 2>&1 | awk '/^RFC-1 |^ERRO/{f=1} f'; }
```

## Montagem das oito cópias

```bash
SP=/tmp/rfc-neg-05; rm -rf "$SP"; mkdir -p "$SP"

# S1  — trunca para ~300 palavras, por linhas, preservando o topo do documento
awk '{ n += NF; print; if (n >= 300) exit }' docs/RFC.md > "$SP/S1-RFC.md"

# S2  — remove o header '## Questões em aberto' (a tabela RFC-QA continua lá)
grep -vxF '## Questões em aberto' docs/RFC.md > "$SP/S2-RFC.md"

# S3  — apaga a linha de trade-off do bloco RFC-ALT-01, e só desse bloco
awk 'BEGIN{alvo=0} /^### RFC-ALT-01/{alvo=1} /^### RFC-ALT-02/{alvo=0} \
     { if(alvo==1 && index($0,"**Trade-off do descarte:**")==1) next; print }' \
     docs/RFC.md > "$SP/S3-RFC.md"

# S4  — reduz a tabela de questões em aberto a uma única linha RFC-QA
grep -vE '^\| *RFC-QA-(02|03|04) *\|' docs/RFC.md > "$SP/S4-RFC.md"

# S5  — troca o link de ADR-004 por um alvo inexistente
sed 's#](adrs/ADR-004-hmac-sha256-secret-por-endpoint.md)#](adrs/ADR-999-inexistente.md)#' \
    docs/RFC.md > "$SP/S5-RFC.md"

# S6a — acrescenta um bloco ```json
cp docs/RFC.md "$SP/S6a-RFC.md"
printf '\n```json\n{ "event_id": "uuid" }\n```\n' >> "$SP/S6a-RFC.md"

# S6b — acrescenta uma linha com código de erro do módulo
cp docs/RFC.md "$SP/S6b-RFC.md"
printf '\nErro WEBHOOK_TIMEOUT quando o cliente nao responde.\n' >> "$SP/S6b-RFC.md"

# S6c — controle: cópia limpa, sem sabotagem
cp docs/RFC.md "$SP/S6c-RFC.md"
```

---

## S1 · RFC-1 — arquivo truncado para 300 palavras

Sabotagem: o documento é cortado no ponto em que acumula 300 palavras.
**Esperado: RFC-1 FALHA.**

```
RFC-1 FALHA — 309 palavras (mínimo 900) e 0 placeholder(s) '<!-- ... a ser elaborado / será preenchido ... -->' (exigido: 0) em /tmp/rfc-neg-05/S1-RFC.md
RFC-2 FALHA — 8 headers conferidos, 5 revisor(es) conferível(is) em TRANSCRICAO.md (mínimo 3): Bruno Diego Larissa Marcos Sofia
  header ausente: '## Proposta técnica'
  header ausente: '## Alternativas consideradas'
  header ausente: '## Questões em aberto'
  header ausente: '## Impacto e riscos'
  header ausente: '## Decisões relacionadas'
RFC-3 FALHA — 0 blocos '### RFC-ALT-NN' examinados, 0 íntegro(s) (mínimo 2)
RFC-4 FALHA — 0 linha(s) '| RFC-QA-NN |' em /tmp/rfc-neg-05/S1-RFC.md (mínimo 2)
RFC-5 FALHA — 0 link(s) distinto(s) (mínimo 2), 0 quebrado(s) contra docs/:
RFC-6 FALHA — 309 palavras (faixa 900–2200) e 0 linha(s) de detalhe de FDD (exigido: 0) em /tmp/rfc-neg-05/S1-RFC.md

9/15 OK
```

**FALHOU COMO ESPERADO.** São 309 e não 300 porque o corte é por linha inteira,
não no meio da linha — a linha que cruza o limiar entra completa. Os outros cinco
checks caem junto porque a truncagem leva embora cinco seções, os seis blocos de
alternativa, a tabela de questões e todos os links: é consequência da sabotagem,
não ruído. O que este caso isola é a perna de tamanho mínimo do RFC-1.

## S2 · RFC-2 — header `## Questões em aberto` removido

Sabotagem: apaga só a linha do header; a tabela `RFC-QA` continua no arquivo.
**Esperado: RFC-2 FALHA nomeando o header.**

```
RFC-1 OK — /tmp/rfc-neg-05/S2-RFC.md existe, 2009 palavras (mínimo 900), 0 placeholder(s) do esqueleto
RFC-2 FALHA — 8 headers conferidos, 5 revisor(es) conferível(is) em TRANSCRICAO.md (mínimo 3): Bruno Diego Larissa Marcos Sofia
  header ausente: '## Questões em aberto'
RFC-3 OK — 6 blocos '### RFC-ALT-NN' examinados, 6 com trade-off do descarte preenchido (mínimo 2)
RFC-4 OK — 4 linhas '| RFC-QA-NN |' em /tmp/rfc-neg-05/S2-RFC.md (mínimo 2)
RFC-5 OK — 8 links '](adrs/ADR-*.md)' distintos (mínimo 2), 0 quebrado(s), resolvidos contra docs/
RFC-6 OK — 2009 palavras na faixa 900–2200, 0 linha(s) de detalhe de FDD em 3 padrões conferidos

14/15 OK
```

**FALHOU COMO ESPERADO**, e nomeia o header exato. Os outros cinco continuam OK:
a sabotagem é cirúrgica e a falha não vaza para checks vizinhos. RFC-4 seguir
verde é o comportamento correto — ele conta linhas de tabela, não seções, e a
tabela não foi tocada.

## S3 · RFC-3 — linha de trade-off apagada de uma alternativa

Sabotagem: remove `**Trade-off do descarte:**` de RFC-ALT-01 e só dele; as outras
cinco alternativas ficam íntegras. **Esperado: RFC-3 FALHA.**

```
RFC-1 OK — /tmp/rfc-neg-05/S3-RFC.md existe, 1999 palavras (mínimo 900), 0 placeholder(s) do esqueleto
RFC-2 OK — 8 headers canônicos conferidos, 0 ausentes; 5 revisores em §Metadados achados por grep -F em TRANSCRICAO.md (mínimo 3): Bruno Diego Larissa Marcos Sofia
RFC-3 FALHA — 6 blocos '### RFC-ALT-NN' examinados, 5 íntegro(s) (mínimo 2)
  RFC-ALT-01 — sem a linha '**Trade-off do descarte:**'
RFC-4 OK — 4 linhas '| RFC-QA-NN |' em /tmp/rfc-neg-05/S3-RFC.md (mínimo 2)
RFC-5 OK — 8 links '](adrs/ADR-*.md)' distintos (mínimo 2), 0 quebrado(s), resolvidos contra docs/
RFC-6 OK — 1999 palavras na faixa 900–2200, 0 linha(s) de detalhe de FDD em 3 padrões conferidos

14/15 OK
```

**FALHOU COMO ESPERADO.** Este é o caso que prova a leitura correta do critério:
sobraram 5 blocos íntegros, muito acima do mínimo de 2, e mesmo assim o check
falha — a exigência é **por bloco**, não uma contagem agregada. Um check que
tivesse parado no `>= 2` teria imprimido OK aqui.

## S4 · RFC-4 — tabela reduzida a uma linha RFC-QA

Sabotagem: apaga as linhas de RFC-QA-02, 03 e 04. **Esperado: RFC-4 FALHA.**

```
RFC-1 OK — /tmp/rfc-neg-05/S4-RFC.md existe, 1840 palavras (mínimo 900), 0 placeholder(s) do esqueleto
RFC-2 OK — 8 headers canônicos conferidos, 0 ausentes; 5 revisores em §Metadados achados por grep -F em TRANSCRICAO.md (mínimo 3): Bruno Diego Larissa Marcos Sofia
RFC-3 OK — 6 blocos '### RFC-ALT-NN' examinados, 6 com trade-off do descarte preenchido (mínimo 2)
RFC-4 FALHA — 1 linha(s) '| RFC-QA-NN |' em /tmp/rfc-neg-05/S4-RFC.md (mínimo 2)
RFC-5 OK — 8 links '](adrs/ADR-*.md)' distintos (mínimo 2), 0 quebrado(s), resolvidos contra docs/
RFC-6 OK — 1840 palavras na faixa 900–2200, 0 linha(s) de detalhe de FDD em 3 padrões conferidos

14/15 OK
```

**FALHOU COMO ESPERADO** — 1 é o valor imediatamente abaixo do mínimo, que é a
fronteira que interessa testar.

## S5 · RFC-5 — link de ADR trocado por alvo inexistente

Sabotagem: `](adrs/ADR-004-....md)` vira `](adrs/ADR-999-inexistente.md)`.
**Esperado: RFC-5 FALHA.**

```
RFC-1 OK — /tmp/rfc-neg-05/S5-RFC.md existe, 2013 palavras (mínimo 900), 0 placeholder(s) do esqueleto
RFC-2 OK — 8 headers canônicos conferidos, 0 ausentes; 5 revisores em §Metadados achados por grep -F em TRANSCRICAO.md (mínimo 3): Bruno Diego Larissa Marcos Sofia
RFC-3 OK — 6 blocos '### RFC-ALT-NN' examinados, 6 com trade-off do descarte preenchido (mínimo 2)
RFC-4 OK — 4 linhas '| RFC-QA-NN |' em /tmp/rfc-neg-05/S5-RFC.md (mínimo 2)
RFC-5 FALHA — 8 link(s) distinto(s) (mínimo 2), 1 quebrado(s) contra docs/: ADR-001-outbox-no-mysql.md ADR-002-worker-processo-separado-polling.md ADR-003-retry-backoff-e-dlq-em-tabela-separada.md ADR-005-entrega-at-least-once-com-x-event-id.md ADR-006-reuso-dos-padroes-existentes.md ADR-007-insercao-na-outbox-dentro-da-transacao.md ADR-008-modelo-de-autorizacao-do-modulo.md ADR-999-inexistente.md(QUEBRADO)
RFC-6 OK — 2013 palavras na faixa 900–2200, 0 linha(s) de detalhe de FDD em 3 padrões conferidos

14/15 OK
```

**FALHOU COMO ESPERADO**, marcando qual link quebrou. Aqui também há um segundo
critério provado: sete links continuam resolvendo, muito acima do mínimo de 2, e
ainda assim o check falha — a exigência de **zero quebrados** é independente da
contagem mínima. E, porque a resolução é sempre contra `docs/` e não contra o
diretório da cópia, a única variável entre este caso e o controle S6c é o link.

## S6a · RFC-6 — bloco ```json acrescentado

Sabotagem: acrescenta um fence `json` ao fim do documento. **Esperado: RFC-6
FALHA.**

```
RFC-1 OK — /tmp/rfc-neg-05/S6a-RFC.md existe, 2019 palavras (mínimo 900), 0 placeholder(s) do esqueleto
RFC-2 OK — 8 headers canônicos conferidos, 0 ausentes; 5 revisores em §Metadados achados por grep -F em TRANSCRICAO.md (mínimo 3): Bruno Diego Larissa Marcos Sofia
RFC-3 OK — 6 blocos '### RFC-ALT-NN' examinados, 6 com trade-off do descarte preenchido (mínimo 2)
RFC-4 OK — 4 linhas '| RFC-QA-NN |' em /tmp/rfc-neg-05/S6a-RFC.md (mínimo 2)
RFC-5 OK — 8 links '](adrs/ADR-*.md)' distintos (mínimo 2), 0 quebrado(s), resolvidos contra docs/
RFC-6 FALHA — 2019 palavras (faixa 900–2200) e 1 linha(s) de detalhe de FDD (exigido: 0) em /tmp/rfc-neg-05/S6a-RFC.md
  223:```json

14/15 OK
```

**FALHOU COMO ESPERADO**, imprimindo a linha ofensora. As 2019 palavras seguem
dentro da faixa: a falha vem só da perna de detalhe de FDD, que é o que este caso
isola.

## S6b · RFC-6 — linha com código de erro do módulo

Sabotagem: acrescenta uma linha contendo `WEBHOOK_TIMEOUT`. **Esperado: RFC-6
FALHA.**

```
RFC-1 OK — /tmp/rfc-neg-05/S6b-RFC.md existe, 2020 palavras (mínimo 900), 0 placeholder(s) do esqueleto
RFC-2 OK — 8 headers canônicos conferidos, 0 ausentes; 5 revisores em §Metadados achados por grep -F em TRANSCRICAO.md (mínimo 3): Bruno Diego Larissa Marcos Sofia
RFC-3 OK — 6 blocos '### RFC-ALT-NN' examinados, 6 com trade-off do descarte preenchido (mínimo 2)
RFC-4 OK — 4 linhas '| RFC-QA-NN |' em /tmp/rfc-neg-05/S6b-RFC.md (mínimo 2)
RFC-5 OK — 8 links '](adrs/ADR-*.md)' distintos (mínimo 2), 0 quebrado(s), resolvidos contra docs/
RFC-6 FALHA — 2020 palavras (faixa 900–2200) e 1 linha(s) de detalhe de FDD (exigido: 0) em /tmp/rfc-neg-05/S6b-RFC.md
  223:Erro WEBHOOK_TIMEOUT quando o cliente nao responde.

14/15 OK
```

**FALHOU COMO ESPERADO.** S6a e S6b existem separados porque o RFC-6 tem três
padrões de detecção com origens distintas (fence `json`, código de erro do módulo
e tabela de endpoint); sabotar um só de cada vez prova qual deles disparou.

## S6c · Controle — cópia limpa

Sabotagem: nenhuma. **Esperado: PASSAR.** Sem este caso, os sete anteriores não
distinguem "o check detecta a sabotagem" de "o check falha sempre".

```
RFC-1 OK — /tmp/rfc-neg-05/S6c-RFC.md existe, 2013 palavras (mínimo 900), 0 placeholder(s) do esqueleto
RFC-2 OK — 8 headers canônicos conferidos, 0 ausentes; 5 revisores em §Metadados achados por grep -F em TRANSCRICAO.md (mínimo 3): Bruno Diego Larissa Marcos Sofia
RFC-3 OK — 6 blocos '### RFC-ALT-NN' examinados, 6 com trade-off do descarte preenchido (mínimo 2)
RFC-4 OK — 4 linhas '| RFC-QA-NN |' em /tmp/rfc-neg-05/S6c-RFC.md (mínimo 2)
RFC-5 OK — 8 links '](adrs/ADR-*.md)' distintos (mínimo 2), 0 quebrado(s), resolvidos contra docs/
RFC-6 OK — 2013 palavras na faixa 900–2200, 0 linha(s) de detalhe de FDD em 3 padrões conferidos

15/15 OK
```

**PASSOU COMO ESPERADO** — ausência de falso positivo provada, inclusive quando o
arquivo medido está fora do repositório.

---

## Resumo

| Caso | Check alvo | Sabotagem | Esperado | Resultado |
|---|---|---|---|---|
| S1 | RFC-1 | trunca para ~300 palavras | FALHAR | FALHOU (309 palavras < 900) |
| S2 | RFC-2 | remove o header `## Questões em aberto` | FALHAR nomeando o header | FALHOU, header nomeado |
| S3 | RFC-3 | apaga `**Trade-off do descarte:**` de RFC-ALT-01 | FALHAR | FALHOU (5 de 6 blocos íntegros) |
| S4 | RFC-4 | reduz a uma linha RFC-QA | FALHAR | FALHOU (1 < 2) |
| S5 | RFC-5 | link para `adrs/ADR-999-inexistente.md` | FALHAR | FALHOU, link nomeado |
| S6a | RFC-6 | acrescenta bloco ```json | FALHAR | FALHOU, linha 223 |
| S6b | RFC-6 | acrescenta linha com `WEBHOOK_TIMEOUT` | FALHAR | FALHOU, linha 223 |
| S6c | todos | nenhuma (controle) | PASSAR | PASSOU, 15/15 |

**8 casos · 7 falhas exigidas, 7 obtidas · 1 passagem exigida, 1 obtida.**

## Passagem vazia

Além das oito sabotagens, o caminho de "não mediu nada" foi conferido: com
`RFC_FILE` apontando para arquivo inexistente, RFC-1 imprime FALHA (a
inexistência **é** o critério dele) e a bateria sai imediatamente com
`ERRO DE VERIFICAÇÃO` e código 2, em vez de deixar RFC-2..RFC-6 medirem o vazio.

```
$ RFC_FILE=/tmp/rfc-neg-05/nao-existe.md ./scripts/verify.sh | tail -2; echo "rc=${PIPESTATUS[0]}"
RFC-1 FALHA — /tmp/rfc-neg-05/nao-existe.md não existe
ERRO DE VERIFICAÇÃO — RFC-2..RFC-6 não têm o que medir: /tmp/rfc-neg-05/nao-existe.md ausente
rc=2
```
