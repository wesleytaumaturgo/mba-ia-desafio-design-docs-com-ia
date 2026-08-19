# 12 — Teste negativo dos checks RME-1..RME-4

Cada check novo de `scripts/verify.sh` v8 foi sabotado uma vez (RME-1, duas
vezes, por ter duas condições independentes), para provar que **falha quando
deve falhar**. Sem isso um check verde não distingue "o README está correto" de
"o check não mede nada".

## Método

Sabotagens não destrutivas: rodam sobre **cópias sob `/tmp/rme-neg-12/`**, e o
`verify.sh` as recebe por `README_FILE` — a mesma parametrização que
`TRACKER_FILE`, `RFC_FILE`, `FDD_FILE` e `PRD_FILE` já tinham. `README.md` real
não foi tocado em nenhum dos cinco casos, exceto pela correção de um defeito
real do próprio check RME-4 encontrado durante esta bateria (ver §Achado).

Ambiente: `engine: /usr/bin/grep grep (GNU grep) 3.11` · `BASE =
93e557087e6112aa8628f91024a80542b8af9a44` · `README.md` real com as 6 seções e
`38/38 OK`.

Filtro de saída usado nos recortes abaixo:

```bash
run() { README_FILE="$1" ./scripts/verify.sh 2>&1 | awk '/^RME-1 |^RME-2 |^RME-3 |^RME-4 |^ERRO/{f=1} f'; }
```

## Montagem das cinco cópias

```bash
SP=/tmp/rme-neg-12; rm -rf "$SP"; mkdir -p "$SP"

# N1a — RME-1 (headers): renomeia "## Workflow adotado"
sed 's/^## Workflow adotado$/## Fluxo de trabalho adotado/' README.md > "$SP/N1a-README.md"

# N1b — RME-1 (resquício): reinsere menção literal a "Repositório base"
awk '1; /^## Sobre o desafio$/ && !x { print ""; print "Ver também a seção Repositório base do enunciado original."; x=1 }' README.md > "$SP/N1b-README.md"

# N2 — RME-2: zera os itens de lista de §Ferramentas de IA utilizadas
awk '
  /^## Ferramentas de IA utilizadas$/ { print; print ""; print "Usamos Claude e Cursor ao longo do processo, sem lista detalhada."; skip=1; next }
  /^## Workflow adotado$/ { skip=0 }
  skip && /^- / { next }
  { print }
' README.md > "$SP/N2-README.md"

# N3 — RME-3: remove o segundo bloco de código de §Prompts customizados
# (script Python que localiza os 4 fences da seção e apaga o segundo par)

# N4 — RME-4: reduz §Iterações e ajustes a 1 item sem arquivo nem número
```

## N1a — RME-1, header ausente

```
RME-1 FALHA — header(s) ausente(s) (0 esperado):
  ## Workflow adotado
  resquício do enunciado: 0 ocorrência(s) (0 esperado)
RME-2 OK — 4 item(ns) de lista em §Ferramentas de IA utilizadas (mínimo 1)
RME-3 OK — 2 bloco(s) de código em §Prompts customizados (mínimo 2), 4 fence(s) ao todo
RME-4 OK — 6 item(ns) em §Iterações e ajustes (mínimo 2), todos citando arquivo ou número

37/38 OK
```

Isola corretamente: só RME-1 cai, os outros três continuam OK.

## N1b — RME-1, resquício do enunciado sobrevive

```
RME-1 FALHA — header(s) ausente(s) (0 esperado):
  resquício do enunciado: 1 ocorrência(s) (0 esperado)
RME-2 OK — 4 item(ns) de lista em §Ferramentas de IA utilizadas (mínimo 1)
RME-3 OK — 2 bloco(s) de código em §Prompts customizados (mínimo 2), 4 fence(s) ao todo
RME-4 OK — 6 item(ns) em §Iterações e ajustes (mínimo 2), todos citando arquivo ou número

37/38 OK
```

Prova que RME-1 pega não só header ausente, mas também a sobrevivência de um
resquício do enunciado (a segunda condição do check), mesmo com os 6 headers
intactos.

## N2 — RME-2, seção sem item de lista

```
RME-1 OK — 6 headers canônicos conferidos, 0 ausentes; 0 resquício de 'Critérios de Aceite'/'Área de entrega'/'Repositório base'
RME-2 FALHA — 0 item(ns) de lista em §Ferramentas de IA utilizadas (mínimo 1)
RME-3 OK — 2 bloco(s) de código em §Prompts customizados (mínimo 2), 4 fence(s) ao todo
RME-4 OK — 6 item(ns) em §Iterações e ajustes (mínimo 2), todos citando arquivo ou número

37/38 OK
```

## N3 — RME-3, só um bloco de código na seção de prompts

```
RME-1 OK — 6 headers canônicos conferidos, 0 ausentes; 0 resquício de 'Critérios de Aceite'/'Área de entrega'/'Repositório base'
RME-2 OK — 4 item(ns) de lista em §Ferramentas de IA utilizadas (mínimo 1)
RME-3 FALHA — 1 bloco(s) de código em §Prompts customizados (mínimo 2, a partir de 2 fence(s))
RME-4 OK — 6 item(ns) em §Iterações e ajustes (mínimo 2), todos citando arquivo ou número

37/38 OK
```

## N4 — RME-4, item sem arquivo nem número

```
RME-1 OK — 6 headers canônicos conferidos, 0 ausentes; 0 resquício de 'Critérios de Aceite'/'Área de entrega'/'Repositório base'
RME-2 OK — 4 item(ns) de lista em §Ferramentas de IA utilizadas (mínimo 1)
RME-3 OK — 2 bloco(s) de código em §Prompts customizados (mínimo 2), 4 fence(s) ao todo
RME-4 FALHA — 1 item(ns) em §Iterações e ajustes (mínimo 2); 1 sem arquivo nem número:
  Ajustamos vários detalhes ao longo do processo, sempre que algo parecia errado.

37/38 OK
```

## Achado durante a bateria — defeito real em RME-4, corrigido

A primeira versão do check tinha dois defeitos, achados nesta própria bateria:

1. **O marcador da lista numerada satisfazia trivialmente "cita número".** A
   primeira implementação extraía cada item por linha física começando em
   `^[0-9]+\. ` e testava a linha inteira — inclusive o próprio prefixo `1. `,
   `2. ` etc. — contra `[0-9]`. Como toda linha de lista numerada começa com um
   dígito, **todo item passava**, mesmo sem citar arquivo nem número de
   verdade. A sabotagem N4 só expôs isso depois que o prefixo passou a ser
   descartado do texto testado.
2. **Item de várias linhas físicas era lido só pela primeira.** Depois de
   corrigir (1), a extração ainda testava só a primeira linha física de cada
   item — e no `README.md` real, a citação de arquivo de vários itens de
   §Iterações e ajustes está numa linha de continuação, não na primeira. Com
   isso, o `README.md` real (correto) passou a reprovar em RME-4
   (`0 item(ns)`, depois `6 item(ns); 3 sem arquivo nem número`) por defeito do
   check, não do documento. Corrigido juntando as linhas físicas de cada item
   num só campo (as quebras internas viram espaço) antes de testar conteúdo.

Depois da segunda correção, `README.md` real volta a `38/38` e as cinco
sabotagens desta bateria continuam isolando exatamente o check pretendido, sem
efeito colateral nos outros três. `git status --porcelain` mostra só
`README.md` e `scripts/verify.sh` modificados durante toda a bateria — nenhum
arquivo de `docs/` foi tocado.
