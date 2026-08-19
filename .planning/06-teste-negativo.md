# 06 — Teste negativo dos checks FDD-1..FDD-7

Cada check novo de `scripts/verify.sh` v5 foi sabotado uma vez, de forma isolada,
para provar que **falha quando deve falhar**. Sem isso um check verde não
distingue "o documento está correto" de "o check não mede nada".

## Método

Todas as sabotagens são não destrutivas para o repositório: rodam sobre **cópias
sob `/tmp/fdd-neg-06/`**, e o `verify.sh` as recebe por `FDD_FILE`, a mesma
parametrização que `ADR_DIR` (bloco 4) e `RFC_FILE` (bloco 5) já tinham.
`docs/FDD.md` não foi tocado em nenhum dos oito casos — `git status` permanece com
os mesmos dois arquivos modificados durante a bateria inteira.

Ambiente: `engine: /usr/bin/grep grep (GNU grep) 3.11` · `awk` = `mawk 1.3.4
20240123` · `BASE = 93e557087e6112aa8628f91024a80542b8af9a44` · linha de base
`docs/FDD.md` com 6078 palavras e `22/22 OK`.

Filtro de saída usado nos recortes abaixo (mostra da primeira linha `FDD-1` em
diante, incluindo as linhas indentadas de motivo e o total):

```bash
run() { FDD_FILE="$1" ./scripts/verify.sh 2>&1 | awk '/^FDD-1 |^ERRO/{f=1} f'; }
```

## Montagem das oito cópias

```bash
SP=/tmp/fdd-neg-06; rm -rf "$SP"; mkdir -p "$SP"

# N1 — trunca para ~800 palavras, por linhas, preservando o topo do documento
awk '{ n += NF; print; if (n >= 800) exit }' docs/FDD.md > "$SP/N1-FDD.md"

# N2 — remove o header '## Matriz de erros' (a tabela FDD-ERR continua lá)
grep -vxF '## Matriz de erros' docs/FDD.md > "$SP/N2-FDD.md"

# N3 — apaga o primeiro fence ```json de FDD-CONTRATO-01, deixando um só
awk 'BEGIN{alvo=0;del=0;done=0}
 /^### POST \/customers\/:customerId\/webhooks/{alvo=1}
 /^### GET \/customers\/:customerId\/webhooks/{alvo=0}
 { if(alvo==1 && done==0 && $0=="```json"){del=1; next}
   if(del==1){ if($0=="```"){del=0; done=1} next }
   print }' docs/FDD.md > "$SP/N3-FDD.md"

# N4 — acrescenta linha de matriz com código sem o prefixo WEBHOOK_
sed '/^| FDD-ERR-13 |/a | FDD-ERR-14 | DELIVERY_FAILED | 422 | `UnprocessableEntityError` | linha sabotada | nenhuma |' \
    docs/FDD.md > "$SP/N4-FDD.md"

# N5 — troca um caminho real da §Integração por um inexistente, sem (novo)
sed 's#| `src/modules/orders/order.status.ts` |#| `src/modules/webhooks/webhook.service.ts` |#' \
    docs/FDD.md > "$SP/N5-FDD.md"

# N6 — reduz '### Tracing' a 2 itens de lista
awk 'BEGIN{sec=0;n=0;drop=0}
 /^### Tracing$/{sec=1;print;next}
 sec==1 && /^## /{sec=0;drop=0}
 { if(sec==1){ if($0 ~ /^- /){n++; if(n>=3) drop=1} if(drop==1) next } print }' \
   docs/FDD.md > "$SP/N6-FDD.md"

# N7 — afirma nome de coluna fora da subseção de mapeamento
cp docs/FDD.md "$SP/N7-FDD.md"
printf '\nNa migration, a coluna total_cents da order alimenta o payload.\n' >> "$SP/N7-FDD.md"

# N8 — controle: cópia limpa, sem sabotagem
cp docs/FDD.md "$SP/N8-FDD.md"
```

---

## N1 · FDD-1 — arquivo truncado para 800 palavras

Sabotagem: o documento é cortado no ponto em que acumula 800 palavras.
**Esperado: FDD-1 FALHA.**

```
FDD-1 FALHA — 801 palavras (mínimo 1500) e 0 placeholder(s) '<!-- ... a ser elaborado / será preenchido ... -->' (exigido: 0) em /tmp/fdd-neg-06/N1-FDD.md
FDD-2 FALHA — 12 headers conferidos, 8 ausente(s):
  header ausente: '## Contratos públicos'
  header ausente: '## Matriz de erros'
  header ausente: '## Estratégias de resiliência'
  header ausente: '## Observabilidade'
  header ausente: '## Dependências e compatibilidade'
  header ausente: '## Critérios de aceite técnicos'
  header ausente: '## Riscos e mitigação'
  header ausente: '## Integração com o sistema existente'
FDD-3 FALHA — 0 blocos '### MÉTODO /path' examinados, 0 íntegro(s) (mínimo 4)
ERRO DE VERIFICAÇÃO — FDD-4 encontrou a seção '## Matriz de erros' vazia (ou ausente) em /tmp/fdd-neg-06/N1-FDD.md
rc=2
```

**FALHOU COMO ESPERADO.** São 801 e não 800 porque o corte é por linha inteira,
não no meio da linha. Os checks vizinhos caem junto porque a truncagem leva embora
oito seções e todos os endpoints: é consequência da sabotagem, não ruído. A
bateria termina em `ERRO DE VERIFICAÇÃO` porque a §Matriz de erros deixou de
existir e FDD-4 se recusa a medir o vazio — comportamento desejado da guarda de
passagem vazia. O que este caso isola é a perna de tamanho mínimo do FDD-1.

## N2 · FDD-2 — header `## Matriz de erros` removido

Sabotagem: apaga só a linha do header; a tabela `FDD-ERR` continua no arquivo.
**Esperado: FDD-2 FALHA nomeando o header.**

```
FDD-1 OK — /tmp/fdd-neg-06/N2-FDD.md existe, 6074 palavras (mínimo 1500), 0 placeholder(s) do esqueleto
FDD-2 FALHA — 12 headers conferidos, 1 ausente(s):
  header ausente: '## Matriz de erros'
FDD-3 OK — 7 blocos '### MÉTODO /path' examinados, 7 com ≥2 fences ```json e ≥1 '**Status:** NNN' (mínimo 4)
ERRO DE VERIFICAÇÃO — FDD-4 encontrou a seção '## Matriz de erros' vazia (ou ausente) em /tmp/fdd-neg-06/N2-FDD.md
rc=2
```

**FALHOU COMO ESPERADO**, e nomeia o header exato — um único ausente entre os
doze, contra os oito de N1. A bateria termina em `ERRO DE VERIFICAÇÃO` pelo mesmo
motivo de N1: sem o header, a seção que FDD-4 recorta é vazia, e um check que não
mediu nada não pode imprimir OK nem FALHA. Este é o único acoplamento entre dois
checks do bloco, e ele é deliberado: o header **é** o delimitador da seção.

## N3 · FDD-3 — um dos dois fences ```json apagado

Sabotagem: remove o bloco de request de `FDD-CONTRATO-01` e só dele; os outros
seis endpoints ficam íntegros. **Esperado: FDD-3 FALHA.**

```
FDD-1 OK — /tmp/fdd-neg-06/N3-FDD.md existe, 6062 palavras (mínimo 1500), 0 placeholder(s) do esqueleto
FDD-2 OK — 12 headers canônicos conferidos em /tmp/fdd-neg-06/N3-FDD.md, 0 ausentes
FDD-3 FALHA — 7 blocos '### MÉTODO /path' examinados, 6 íntegro(s) (mínimo 4)
  POST /customers/:customerId/webhooks — 1 fence(s) ```json (mínimo 2)
FDD-4 OK — 13 linhas '| FDD-ERR-NN |' com código WEBHOOK_[A-Z_]{3,} na §Matriz de erros (mínimo 8), 0 código(s) sem o prefixo
FDD-5 OK — 13 caminhos distintos sem (novo) na §Integração, 13 presentes em git ls-files (mínimo 4), 0 ausentes
FDD-6 OK — 3 subseções de §Observabilidade conferidas, 18 itens de lista no total, mínimo 3 em cada
FDD-7 OK — 651 linhas varridas fora de '### Mapeamento payload ↔ schema' e de fences, 0 linha(s) nomeando os cinco termos como coluna do schema

21/22 OK
```

**FALHOU COMO ESPERADO**, nomeando o endpoint. Este é o caso que prova a leitura
correta do critério: sobraram 6 blocos íntegros, acima do mínimo de 4, e mesmo
assim o check falha — a exigência é **por bloco**, não uma contagem agregada. Um
check que tivesse parado no `>= 4` teria imprimido OK aqui. Os outros seis seguem
verdes: a sabotagem é cirúrgica e não vaza.

## N4 · FDD-4 — código de erro sem o prefixo

Sabotagem: acrescenta à matriz uma linha com o código `DELIVERY_FAILED`, sem o
prefixo `WEBHOOK_`. **Esperado: FDD-4 FALHA.**

```
FDD-1 OK — /tmp/fdd-neg-06/N4-FDD.md existe, 6092 palavras (mínimo 1500), 0 placeholder(s) do esqueleto
FDD-2 OK — 12 headers canônicos conferidos em /tmp/fdd-neg-06/N4-FDD.md, 0 ausentes
FDD-3 OK — 7 blocos '### MÉTODO /path' examinados, 7 com ≥2 fences ```json e ≥1 '**Status:** NNN' (mínimo 4)
FDD-4 FALHA — 13 linha(s) com código WEBHOOK_ (mínimo 8) e 1 código(s) sem o prefixo (exigido: 0) na §Matriz de erros de /tmp/fdd-neg-06/N4-FDD.md
  sem prefixo: DELIVERY_FAILED
FDD-5 OK — 13 caminhos distintos sem (novo) na §Integração, 13 presentes em git ls-files (mínimo 4), 0 ausentes
FDD-6 OK — 3 subseções de §Observabilidade conferidas, 18 itens de lista no total, mínimo 3 em cada
FDD-7 OK — 652 linhas varridas fora de '### Mapeamento payload ↔ schema' e de fences, 0 linha(s) nomeando os cinco termos como coluna do schema

21/22 OK
```

**FALHOU COMO ESPERADO**, imprimindo o código ofensor. As 13 linhas com prefixo
continuam muito acima do mínimo de 8, e ainda assim o check falha — a exigência de
**zero códigos sem prefixo** é independente da contagem mínima, e é ela que
implementa DEC-13 de verdade. Um check que só contasse ocorrências de `WEBHOOK_`
teria imprimido OK aqui.

## N5 · FDD-5 — caminho inexistente sem o marcador `(novo)`

Sabotagem: na tabela da §Integração, `src/modules/orders/order.status.ts` vira
`src/modules/webhooks/webhook.service.ts`, que não existe no índice do git e não
leva o marcador `(novo)` exigido por C-1. **Esperado: FDD-5 FALHA.**

```
FDD-1 OK — /tmp/fdd-neg-06/N5-FDD.md existe, 6078 palavras (mínimo 1500), 0 placeholder(s) do esqueleto
FDD-2 OK — 12 headers canônicos conferidos em /tmp/fdd-neg-06/N5-FDD.md, 0 ausentes
FDD-3 OK — 7 blocos '### MÉTODO /path' examinados, 7 com ≥2 fences ```json e ≥1 '**Status:** NNN' (mínimo 4)
FDD-4 OK — 13 linhas '| FDD-ERR-NN |' com código WEBHOOK_[A-Z_]{3,} na §Matriz de erros (mínimo 8), 0 código(s) sem o prefixo
FDD-5 FALHA — 13 caminho(s) distinto(s) sem (novo), 12 presente(s) em git ls-files (mínimo 4):
  ausente do índice do git e sem o marcador (novo): src/modules/webhooks/webhook.service.ts
FDD-6 OK — 3 subseções de §Observabilidade conferidas, 18 itens de lista no total, mínimo 3 em cada
FDD-7 OK — 651 linhas varridas fora de '### Mapeamento payload ↔ schema' e de fences, 0 linha(s) nomeando os cinco termos como coluna do schema

21/22 OK
```

**FALHOU COMO ESPERADO**, nomeando o caminho. Doze caminhos continuam resolvendo,
três vezes o mínimo de 4, e o check falha assim mesmo: **zero ausentes** é
condição independente da contagem. É exatamente o caso que o marcador `(novo)`
existe para separar — o mesmo caminho, escrito `` `…webhook.service.ts` (novo) ``,
seria descartado da varredura e não falharia.

## N6 · FDD-6 — `### Tracing` reduzido a 2 itens

Sabotagem: apaga itens de `### Tracing` até restarem 2; `### Métricas` e
`### Logs` ficam intactos. **Esperado: FDD-6 FALHA.**

```
FDD-1 OK — /tmp/fdd-neg-06/N6-FDD.md existe, 5944 palavras (mínimo 1500), 0 placeholder(s) do esqueleto
FDD-2 OK — 12 headers canônicos conferidos em /tmp/fdd-neg-06/N6-FDD.md, 0 ausentes
FDD-3 OK — 7 blocos '### MÉTODO /path' examinados, 7 com ≥2 fences ```json e ≥1 '**Status:** NNN' (mínimo 4)
FDD-4 OK — 13 linhas '| FDD-ERR-NN |' com código WEBHOOK_[A-Z_]{3,} na §Matriz de erros (mínimo 8), 0 código(s) sem o prefixo
FDD-5 OK — 13 caminhos distintos sem (novo) na §Integração, 13 presentes em git ls-files (mínimo 4), 0 ausentes
FDD-6 FALHA — 3 subseções conferidas em /tmp/fdd-neg-06/N6-FDD.md:
  '### Tracing' — 2 item(ns) de lista (mínimo 3)
FDD-7 OK — 640 linhas varridas fora de '### Mapeamento payload ↔ schema' e de fences, 0 linha(s) nomeando os cinco termos como coluna do schema

21/22 OK
```

**FALHOU COMO ESPERADO**, nomeando a subseção e a contagem. O header continua
presente — a sabotagem tira conteúdo, não título — o que prova que o check mede
itens e não a existência do header. `### Métricas` e `### Logs` seguem verdes: a
exigência é por subseção. 2 é o valor imediatamente abaixo do mínimo, que é a
fronteira que interessa testar.

## N7 · FDD-7 — nome de coluna afirmado fora do mapeamento

Sabotagem: acrescenta ao fim do documento a frase "Na migration, a coluna
total_cents da order alimenta o payload", fora da subseção
`### Mapeamento payload ↔ schema` e fora de qualquer fence. **Esperado: FDD-7
FALHA.**

```
FDD-1 OK — /tmp/fdd-neg-06/N7-FDD.md existe, 6088 palavras (mínimo 1500), 0 placeholder(s) do esqueleto
FDD-2 OK — 12 headers canônicos conferidos em /tmp/fdd-neg-06/N7-FDD.md, 0 ausentes
FDD-3 OK — 7 blocos '### MÉTODO /path' examinados, 7 com ≥2 fences ```json e ≥1 '**Status:** NNN' (mínimo 4)
FDD-4 OK — 13 linhas '| FDD-ERR-NN |' com código WEBHOOK_[A-Z_]{3,} na §Matriz de erros (mínimo 8), 0 código(s) sem o prefixo
FDD-5 OK — 13 caminhos distintos sem (novo) na §Integração, 13 presentes em git ls-files (mínimo 4), 0 ausentes
FDD-6 OK — 3 subseções de §Observabilidade conferidas, 18 itens de lista no total, mínimo 3 em cada
FDD-7 FALHA — 1 linha(s) afirmando que a coluna do schema se chama por um dos cinco termos snake_case (exigido: 0) em /tmp/fdd-neg-06/N7-FDD.md:
  854:Na migration, a coluna total_cents da order alimenta o payload.
```

**FALHOU COMO ESPERADO**, com a linha e o número de linha. Repare no que o check
**não** fez disparar no mesmo arquivo: as nove linhas da tabela de mapeamento, que
contêm os cinco termos ao lado da palavra "schema" por dever de ofício, e as
dezenas de ocorrências de `total_cents`, `order_number`, `from_status` e
`to_status` dentro dos fences ```json do payload. A discriminância vem das duas
exclusões — subseção de mapeamento e conteúdo de fence — mais a exigência de
proximidade de 40 caracteres com uma das três construções `coluna`,
`campo do schema` ou `no banco`.

**Não houve MAN-03.** O check foi obtido na primeira tentativa, sem falso positivo
sobre o documento limpo (N8, abaixo), então a rota de escape prevista pelo bloco —
registrar o invariante como verificação manual em `.planning/01-matriz.md` — não
foi usada.

## N8 · Controle — cópia limpa

Sabotagem: nenhuma. **Esperado: PASSAR.** Sem este caso, os sete anteriores não
distinguem "o check detecta a sabotagem" de "o check falha sempre".

```
FDD-1 OK — /tmp/fdd-neg-06/N8-FDD.md existe, 6078 palavras (mínimo 1500), 0 placeholder(s) do esqueleto
FDD-2 OK — 12 headers canônicos conferidos em /tmp/fdd-neg-06/N8-FDD.md, 0 ausentes
FDD-3 OK — 7 blocos '### MÉTODO /path' examinados, 7 com ≥2 fences ```json e ≥1 '**Status:** NNN' (mínimo 4)
FDD-4 OK — 13 linhas '| FDD-ERR-NN |' com código WEBHOOK_[A-Z_]{3,} na §Matriz de erros (mínimo 8), 0 código(s) sem o prefixo
FDD-5 OK — 13 caminhos distintos sem (novo) na §Integração, 13 presentes em git ls-files (mínimo 4), 0 ausentes
FDD-6 OK — 3 subseções de §Observabilidade conferidas, 18 itens de lista no total, mínimo 3 em cada
FDD-7 OK — 651 linhas varridas fora de '### Mapeamento payload ↔ schema' e de fences, 0 linha(s) nomeando os cinco termos como coluna do schema

22/22 OK
```

**PASSOU COMO ESPERADO** — ausência de falso positivo provada, inclusive quando o
arquivo medido está fora do repositório.

---

## Resumo

| Caso | Check alvo | Sabotagem | Esperado | Resultado |
|---|---|---|---|---|
| N1 | FDD-1 | trunca para ~800 palavras | FALHAR | FALHOU (801 palavras < 1500) |
| N2 | FDD-2 | remove o header `## Matriz de erros` | FALHAR nomeando o header | FALHOU, header nomeado |
| N3 | FDD-3 | apaga um dos dois fences ```json de FDD-CONTRATO-01 | FALHAR | FALHOU (6 de 7 blocos íntegros) |
| N4 | FDD-4 | acrescenta código `DELIVERY_FAILED` sem prefixo | FALHAR | FALHOU, código nomeado |
| N5 | FDD-5 | troca caminho por `src/modules/webhooks/webhook.service.ts` sem `(novo)` | FALHAR | FALHOU, caminho nomeado |
| N6 | FDD-6 | reduz `### Tracing` a 2 itens | FALHAR | FALHOU (2 < 3) |
| N7 | FDD-7 | acrescenta "a coluna total_cents da order" fora do mapeamento | FALHAR | FALHOU, linha 854 |
| N8 | todos | nenhuma (controle) | PASSAR | PASSOU, 22/22 |

**8 casos · 7 falhas exigidas, 7 obtidas · 1 passagem exigida, 1 obtida.**

## Passagem vazia

Além das oito sabotagens, o caminho de "não mediu nada" foi conferido: com
`FDD_FILE` apontando para arquivo inexistente, FDD-1 imprime FALHA (a inexistência
**é** o critério dele) e a bateria sai imediatamente com `ERRO DE VERIFICAÇÃO` e
código 2, em vez de deixar FDD-2..FDD-7 medirem o vazio.

```
$ FDD_FILE=/tmp/fdd-neg-06/nao-existe.md ./scripts/verify.sh | tail -2; echo "rc=${PIPESTATUS[0]}"
FDD-1 FALHA — /tmp/fdd-neg-06/nao-existe.md não existe
ERRO DE VERIFICAÇÃO — FDD-2..FDD-7 não têm o que medir: /tmp/fdd-neg-06/nao-existe.md ausente
rc=2
```

As outras três guardas de passagem vazia do bloco saem pelo mesmo caminho:
§Matriz de erros vazia (provada em N1 e N2), §Integração sem nenhum caminho em
crase, e varredura do FDD-7 que consumisse o documento inteiro por exclusão.

## Nota de portabilidade

O `awk` desta máquina é `mawk 1.3.4 20240123` e **não implementa o intervalo
`{n,}`** em expressão regular: `$3 ~ /^WEBHOOK_[A-Z_]{3,}$/` casou zero linhas de
uma matriz com treze códigos válidos, e o FDD-4 imprimiu FALHA por um defeito do
check, não do documento. A forma escrita no script é
`^WEBHOOK_[A-Z_][A-Z_][A-Z_]+$`, equivalente e portável. As demais expressões do
bloco 6 rodam em `$GREP` (GNU grep 3.11), onde `{n,m}` funciona — o problema é
específico do awk.
