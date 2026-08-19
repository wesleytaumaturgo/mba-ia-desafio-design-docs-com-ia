# 07 — Teste negativo dos checks PRD-1..PRD-6 e INV-7

Cada check novo de `scripts/verify.sh` v6 foi sabotado uma vez, de forma isolada,
para provar que **falha quando deve falhar**. Sem isso um check verde não
distingue "o documento está correto" de "o check não mede nada".

## Método

Todas as sabotagens são não destrutivas para o repositório: rodam sobre **cópias
sob `/tmp/prd-neg-07/`**, e o `verify.sh` as recebe por `PRD_FILE`, a mesma
parametrização que `ADR_DIR` (bloco 4), `RFC_FILE` (bloco 5) e `FDD_FILE`
(bloco 6) já tinham. Para o INV-7c a variável usada é `INV7_RECUSA`, também já
prevista na especificação de `.planning/02-recusa.md` §INV-7 v2. `docs/PRD.md`
não foi tocado em nenhum dos oito casos — `git status` permanece com os mesmos
arquivos modificados durante a bateria inteira.

Ambiente: `engine: /usr/bin/grep grep (GNU grep) 3.11` · `BASE =
93e557087e6112aa8628f91024a80542b8af9a44` · linha de base `docs/PRD.md` com
3184 palavras e `29/29 OK`.

Filtro de saída usado nos recortes abaixo (mostra da primeira linha `PRD-1` em
diante, incluindo `ERRO DE VERIFICAÇÃO` quando ocorre):

```bash
run() { PRD_FILE="$1" ./scripts/verify.sh 2>&1 | awk '/^PRD-1 |^ERRO/{f=1} f'; }
```

## Montagem das oito cópias

```bash
SP=/tmp/prd-neg-07; rm -rf "$SP"; mkdir -p "$SP"

# N1 — trunca para ~500 palavras, por linhas, preservando o topo do documento
awk '{ n += NF; print; if (n >= 500) exit }' docs/PRD.md > "$SP/N1-PRD.md"

# N2 — remove o header '### Fora de escopo' (o conteúdo da lista continua lá)
grep -vxF '### Fora de escopo' docs/PRD.md > "$SP/N2-PRD.md"

# N3 — reduz para 7 linhas PRD-FR (remove PRD-FR-08..PRD-FR-11)
grep -vE '^\| PRD-FR-(08|09|10|11) \|' docs/PRD.md > "$SP/N3-PRD.md"

# N4 — remove toda meta numérica dentro de §Objetivos e métricas de sucesso
awk '
  /^## Objetivos e métricas de sucesso$/ { insec=1; print; next }
  /^## / { insec=0 }
  insec==1 { gsub(/[0-9]+ *(%|ms|s|min|segundos?)/, "diversas unidades") }
  { print }
' docs/PRD.md > "$SP/N4-PRD.md"

# N5 — deixa 1 item só em §Fora de escopo
awk '
  /^### Fora de escopo$/ { print; insec=1; kept=0; next }
  /^#/ { insec=0 }
  insec==1 && /^[-*] / { kept++; if (kept==1) { print; next } else { next } }
  { print }
' docs/PRD.md > "$SP/N5-PRD.md"

# N6 — esvazia a coluna Mitigação de todos os riscos em §Riscos e mitigação
awk -F'|' 'BEGIN{OFS="|"}
  /^## Riscos e mitigação$/ { insec=1; print; next }
  /^## / { insec=0 }
  insec==1 && /^\|/ && NF>=6 && $2 !~ /Risco/ && $2 !~ /^-+ *$/ { $5=" "; print; next }
  { print }
' docs/PRD.md > "$SP/N6-PRD.md"

# INV-7a — acrescenta PRD-RNF-99 que reencarna REC-11 (arquivamento da outbox)
cp docs/PRD.md "$SP/INV7a-PRD.md"
sed -i '/^| PRD-RNF-19 |/a | PRD-RNF-99 | Arquivar linhas entregues da outbox após 30 dias | operação | inserida para teste negativo |' \
  "$SP/INV7a-PRD.md"

# INV-7b — acrescenta PRD-FR-99 que reencarna REC-13 (email de alerta ao cliente)
cp docs/PRD.md "$SP/INV7b-PRD.md"
sed -i '/^| PRD-FR-11 |/a | PRD-FR-99 | Enviar email de alerta ao cliente quando o webhook falha | inserida para teste negativo |' \
  "$SP/INV7b-PRD.md"

# INV-7c — controle: 02-recusa.md vazio (cópia, o arquivo real não é tocado)
: > "$SP/02-recusa-vazio.md"
```

---

## N1 · PRD-1 — arquivo truncado para 500 palavras

Sabotagem: o documento é cortado no ponto em que acumula 500 palavras.
**Esperado: PRD-1 FALHA.**

```
PRD-1 FALHA — 500 palavras (mínimo 900) e 0 placeholder(s) '<!-- ... a ser elaborado / será preenchido ... -->' (exigido: 0) em /tmp/prd-neg-07/N1-PRD.md
PRD-2 FALHA — 13 headers conferidos:
  header ausente: '## Objetivos e métricas de sucesso'
  header ausente: '## Escopo'
  header ausente: '## Requisitos funcionais'
  header ausente: '## Requisitos não funcionais'
  header ausente: '## Decisões e trade-offs principais'
  header ausente: '## Dependências'
  header ausente: '## Riscos e mitigação'
  header ausente: '## Critérios de aceitação'
  header ausente: '## Estratégia de testes e validação'
  header ausente: '### Fora de escopo'
PRD-3 FALHA — 0 linha(s) '| PRD-FR-NN |' em /tmp/prd-neg-07/N1-PRD.md (mínimo 8)
ERRO DE VERIFICAÇÃO — PRD-4 encontrou a seção '## Objetivos e métricas de sucesso' vazia (ou ausente) em /tmp/prd-neg-07/N1-PRD.md
```

**FALHOU COMO ESPERADO.** Os checks vizinhos caem junto porque a truncagem leva
embora dez seções e todos os requisitos: é consequência da sabotagem, não
ruído. A bateria termina em `ERRO DE VERIFICAÇÃO` porque a §Objetivos deixou de
existir e PRD-4 se recusa a medir o vazio — a guarda de passagem vazia,
comportamento já usado nos blocos 5 e 6. O que este caso isola é a perna de
tamanho mínimo do PRD-1.

## N2 · PRD-2 — header `### Fora de escopo` removido

Sabotagem: apaga só a linha do header; a lista de itens descartados/adiados
continua no arquivo. **Esperado: PRD-2 FALHA nomeando o header.**

```
PRD-1 OK — /tmp/prd-neg-07/N2-PRD.md existe, 3180 palavras (mínimo 900), 0 placeholder(s) do esqueleto
PRD-2 FALHA — 13 headers conferidos:
  header ausente: '### Fora de escopo'
PRD-3 OK — 11 linhas '| PRD-FR-NN |' em /tmp/prd-neg-07/N2-PRD.md (mínimo 8)
PRD-4 OK — 3 linha(s) com meta quantitativa (%, ms, s, min, segundo(s)) na §Objetivos e métricas de sucesso (mínimo 1)
ERRO DE VERIFICAÇÃO — PRD-5 encontrou a seção '### Fora de escopo' vazia (ou ausente) em /tmp/prd-neg-07/N2-PRD.md
```

**FALHOU COMO ESPERADO**, e nomeia o header exato — um único ausente entre os
treze do denominador de PRD-2. A bateria termina em `ERRO DE VERIFICAÇÃO`
porque, sem o header, a seção que PRD-5 recorta é vazia — mesmo acoplamento
deliberado já visto em FDD-2/FDD-4 (bloco 6): o header **é** o delimitador da
seção.

## N3 · PRD-3 — reduzido a 7 linhas PRD-FR

Sabotagem: remove `PRD-FR-08` a `PRD-FR-11`, deixando 7 das 11 linhas de
requisito funcional. **Esperado: PRD-3 FALHA.**

```
PRD-1 OK — /tmp/prd-neg-07/N3-PRD.md existe, 3053 palavras (mínimo 900), 0 placeholder(s) do esqueleto
PRD-2 OK — 13 headers canônicos conferidos em /tmp/prd-neg-07/N3-PRD.md (12 '## ' + '### Fora de escopo'), 0 ausentes
PRD-3 FALHA — 7 linha(s) '| PRD-FR-NN |' em /tmp/prd-neg-07/N3-PRD.md (mínimo 8)
PRD-4 OK — 3 linha(s) com meta quantitativa (%, ms, s, min, segundo(s)) na §Objetivos e métricas de sucesso (mínimo 1)
PRD-5 OK — 15 itens de lista em §Fora de escopo (mínimo 2), 15 com '[hh:mm] Nome' conferível (todos)
PRD-6 OK — 5 linha(s) de risco com Probabilidade/Impacto/Mitigação preenchidos na §Riscos e mitigação (mínimo 2)
INV-7 — 15 item(ns) na lista de recusa, 14 com âncora aplicável, alvos: /tmp/prd-neg-07/N3-PRD.md docs/FDD.md
INV-7 OK — nenhum item recusado reaparece como requisito

28/29 OK
```

**FALHOU COMO ESPERADO**, isolado: só PRD-3 cai, os demais checks continuam OK
porque nada além da contagem de linhas `PRD-FR-NN` foi tocado.

## N4 · PRD-4 — meta numérica removida de §Objetivos e métricas de sucesso

Sabotagem: dentro da seção, toda ocorrência do padrão `[0-9]+ *(%|ms|s|min|
segundos?)` é substituída por `diversas unidades`. **Esperado: PRD-4 FALHA.**

```
PRD-1 OK — /tmp/prd-neg-07/N4-PRD.md existe, 3184 palavras (mínimo 900), 0 placeholder(s) do esqueleto
PRD-2 OK — 13 headers canônicos conferidos em /tmp/prd-neg-07/N4-PRD.md (12 '## ' + '### Fora de escopo'), 0 ausentes
PRD-3 OK — 11 linhas '| PRD-FR-NN |' em /tmp/prd-neg-07/N4-PRD.md (mínimo 8)
PRD-4 FALHA — 0 linha(s) com meta quantitativa na §Objetivos e métricas de sucesso (mínimo 1)
PRD-5 OK — 15 itens de lista em §Fora de escopo (mínimo 2), 15 com '[hh:mm] Nome' conferível (todos)
PRD-6 OK — 5 linha(s) de risco com Probabilidade/Impacto/Mitigação preenchidos na §Riscos e mitigação (mínimo 2)
INV-7 — 15 item(ns) na lista de recusa, 14 com âncora aplicável, alvos: /tmp/prd-neg-07/N4-PRD.md docs/FDD.md
INV-7 OK — nenhum item recusado reaparece como requisito

28/29 OK
```

**FALHOU COMO ESPERADO**, isolado: a seção continua presente e com as 5 linhas
de objetivo, só sem número com unidade — exatamente o que PRD-4 mede.

## N5 · PRD-5 — apenas 1 item em §Fora de escopo

Sabotagem: mantém só o primeiro item de lista da seção, remove os outros 14.
**Esperado: PRD-5 FALHA.**

```
PRD-1 OK — /tmp/prd-neg-07/N5-PRD.md existe, 2892 palavras (mínimo 900), 0 placeholder(s) do esqueleto
PRD-2 OK — 13 headers canônicos conferidos em /tmp/prd-neg-07/N5-PRD.md (12 '## ' + '### Fora de escopo'), 0 ausentes
PRD-3 OK — 11 linhas '| PRD-FR-NN |' em /tmp/prd-neg-07/N5-PRD.md (mínimo 8)
PRD-4 OK — 3 linha(s) com meta quantitativa (%, ms, s, min, segundo(s)) na §Objetivos e métricas de sucesso (mínimo 1)
PRD-5 FALHA — 1 item(ns) de lista em §Fora de escopo (mínimo 2), 1 com '[hh:mm] Nome' conferível (exigido: todos)
PRD-6 OK — 5 linha(s) de risco com Probabilidade/Impacto/Mitigação preenchidos na §Riscos e mitigação (mínimo 2)
INV-7 — 15 item(ns) na lista de recusa, 14 com âncora aplicável, alvos: /tmp/prd-neg-07/N5-PRD.md docs/FDD.md
INV-7 OK — nenhum item recusado reaparece como requisito

28/29 OK
```

**FALHOU COMO ESPERADO**: 1 item é menor que o mínimo de 2, e o check nomeia os
dois números — itens totais e itens com Localização — mesmo com o único item
restante carregando `[hh:mm] Nome` válido.

## N6 · PRD-6 — coluna Mitigação esvaziada em todos os riscos

Sabotagem: dentro de §Riscos e mitigação, o 4º campo de cada linha de tabela de
risco (Mitigação) é substituído por um espaço em branco. **Esperado: PRD-6
FALHA.**

```
PRD-1 OK — /tmp/prd-neg-07/N6-PRD.md existe, 3073 palavras (mínimo 900), 0 placeholder(s) do esqueleto
PRD-2 OK — 13 headers canônicos conferidos em /tmp/prd-neg-07/N6-PRD.md (12 '## ' + '### Fora de escopo'), 0 ausentes
PRD-3 OK — 11 linhas '| PRD-FR-NN |' em /tmp/prd-neg-07/N6-PRD.md (mínimo 8)
PRD-4 OK — 3 linha(s) com meta quantitativa (%, ms, s, min, segundo(s)) na §Objetivos e métricas de sucesso (mínimo 1)
PRD-5 OK — 15 itens de lista em §Fora de escopo (mínimo 2), 15 com '[hh:mm] Nome' conferível (todos)
PRD-6 FALHA — 0 linha(s) de risco com os 3 campos preenchidos na §Riscos e mitigação (mínimo 2)
INV-7 — 15 item(ns) na lista de recusa, 14 com âncora aplicável, alvos: /tmp/prd-neg-07/N6-PRD.md docs/FDD.md
INV-7 OK — nenhum item recusado reaparece como requisito

28/29 OK
```

**FALHOU COMO ESPERADO**: as 5 linhas de risco continuam com Probabilidade e
Impacto preenchidos, mas a contagem cai a 0 porque a exigência é dos 3 campos
simultaneamente.

## INV-7a · vazamento de RNF — `PRD-RNF-99` reencarna REC-11

Sabotagem: acrescenta, logo após `PRD-RNF-19`, uma linha `PRD-RNF-99` que
readota o arquivamento de linhas entregues da outbox — item ADIADO em
`.planning/02-recusa.md` (REC-11). **Esperado: INV-7 FALHA apontando REC-11.**

```
PRD-1 OK — /tmp/prd-neg-07/INV7a-PRD.md existe, 3203 palavras (mínimo 900), 0 placeholder(s) do esqueleto
PRD-2 OK — 13 headers canônicos conferidos em /tmp/prd-neg-07/INV7a-PRD.md (12 '## ' + '### Fora de escopo'), 0 ausentes
PRD-3 OK — 11 linhas '| PRD-FR-NN |' em /tmp/prd-neg-07/INV7a-PRD.md (mínimo 8)
PRD-4 OK — 3 linha(s) com meta quantitativa (%, ms, s, min, segundo(s)) na §Objetivos e métricas de sucesso (mínimo 1)
PRD-5 OK — 15 itens de lista em §Fora de escopo (mínimo 2), 15 com '[hh:mm] Nome' conferível (todos)
PRD-6 OK — 5 linha(s) de risco com Probabilidade/Impacto/Mitigação preenchidos na §Riscos e mitigação (mínimo 2)
INV-7 — 15 item(ns) na lista de recusa, 14 com âncora aplicável, alvos: /tmp/prd-neg-07/INV7a-PRD.md docs/FDD.md
INV-7 FALHA — 1 vazamento(s):
  VAZAMENTO  REC-11 -> PRD-RNF-99  (/tmp/prd-neg-07/INV7a-PRD.md:164)
             | PRD-RNF-99 | Arquivar linhas entregues da outbox após 30 dias | operação | inserida para teste 

28/29 OK
```

**FALHOU COMO ESPERADO**, apontando exatamente `REC-11 -> PRD-RNF-99`, o
arquivo e a linha — todos os outros PRD-RNF-NN legítimos (inclusive os que
citam `outbox` em contexto correto) não disparam.

## INV-7b · vazamento de FR — `PRD-FR-99` reencarna REC-13

Sabotagem: acrescenta, logo após `PRD-FR-11`, uma linha `PRD-FR-99` que
readota o aviso por e-mail ao cliente quando o webhook falha — item ADIADO em
`.planning/02-recusa.md` (REC-13). **Esperado: INV-7 FALHA apontando REC-13.**

```
PRD-1 OK — /tmp/prd-neg-07/INV7b-PRD.md existe, 3203 palavras (mínimo 900), 0 placeholder(s) do esqueleto
PRD-2 OK — 13 headers canônicos conferidos em /tmp/prd-neg-07/INV7b-PRD.md (12 '## ' + '### Fora de escopo'), 0 ausentes
PRD-3 OK — 12 linhas '| PRD-FR-NN |' em /tmp/prd-neg-07/INV7b-PRD.md (mínimo 8)
PRD-4 OK — 3 linha(s) com meta quantitativa (%, ms, s, min, segundo(s)) na §Objetivos e métricas de sucesso (mínimo 1)
PRD-5 OK — 15 itens de lista em §Fora de escopo (mínimo 2), 15 com '[hh:mm] Nome' conferível (todos)
PRD-6 OK — 5 linha(s) de risco com Probabilidade/Impacto/Mitigação preenchidos na §Riscos e mitigação (mínimo 2)
INV-7 — 15 item(ns) na lista de recusa, 14 com âncora aplicável, alvos: /tmp/prd-neg-07/INV7b-PRD.md docs/FDD.md
INV-7 FALHA — 1 vazamento(s):
  VAZAMENTO  REC-13 -> PRD-FR-99  (/tmp/prd-neg-07/INV7b-PRD.md:140)
             | PRD-FR-99 | Enviar email de alerta ao cliente quando o webhook falha | inserida para teste negativ

28/29 OK
```

**FALHOU COMO ESPERADO**, apontando `REC-13 -> PRD-FR-99`. PRD-3 até sobe para
12 (a linha plantada também casa `PRD-FR-NN`), o que reforça por que a
contagem bruta de PRD-3 nunca poderia substituir o INV-7: uma linha a mais que
passa na contagem pode ainda assim ser um requisito recusado disfarçado.

## INV-7c · guarda de denominador — `02-recusa.md` vazio

Sabotagem: aponta `INV7_RECUSA` para um arquivo vazio, simulando lista de
recusa corrompida ou apagada. `docs/PRD.md` real não é tocado.
**Esperado: exit 2, nunca `OK`.**

```bash
$ INV7_RECUSA=/tmp/prd-neg-07/02-recusa-vazio.md ./scripts/verify.sh; echo "rc=$?"
...
PRD-6 OK — 5 linha(s) de risco com Probabilidade/Impacto/Mitigação preenchidos na §Riscos e mitigação (mínimo 2)
ERRO DE VERIFICAÇÃO — INV-7 carregou 0 âncora(s) de /tmp/prd-neg-07/02-recusa-vazio.md — mínimo 14 (guarda contra denominador vazio ou truncado)
rc=2
```

**FALHOU COMO ESPERADO** — `exit 2`, não `exit 0` nem `exit 1`. Sem a guarda
`[ "$inv7_n_anc" -ge 14 ]`, um `02-recusa.md` vazio zeraria o laço de busca de
vazamento e o check imprimiria `INV-7 OK` por vacuidade: exatamente o defeito
que a guarda de `.planning/02-recusa.md` §INV-7 v2 existe para eliminar.

## Controle · repositório limpo

Sem nenhuma sabotagem, contra `docs/PRD.md` real:

```
$ ./scripts/verify.sh
...
PRD-1 OK — docs/PRD.md existe, 3184 palavras (mínimo 900), 0 placeholder(s) do esqueleto
PRD-2 OK — 13 headers canônicos conferidos em docs/PRD.md (12 '## ' + '### Fora de escopo'), 0 ausentes
PRD-3 OK — 11 linhas '| PRD-FR-NN |' em docs/PRD.md (mínimo 8)
PRD-4 OK — 3 linha(s) com meta quantitativa (%, ms, s, min, segundo(s)) na §Objetivos e métricas de sucesso (mínimo 1)
PRD-5 OK — 15 itens de lista em §Fora de escopo (mínimo 2), 15 com '[hh:mm] Nome' conferível (todos)
PRD-6 OK — 5 linha(s) de risco com Probabilidade/Impacto/Mitigação preenchidos na §Riscos e mitigação (mínimo 2)
INV-7 — 15 item(ns) na lista de recusa, 14 com âncora aplicável, alvos: docs/PRD.md docs/FDD.md
INV-7 OK — nenhum item recusado reaparece como requisito

29/29 OK
```

**29/29 OK.** Nenhuma sabotagem tocou `docs/PRD.md`; todas as oito rodaram
contra cópias sob `/tmp/prd-neg-07/` e/ou uma `INV7_RECUSA` apontada para fora
do repositório.
