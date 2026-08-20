# 14 — Teste negativo do TRK-2 sobre o universo amplo de identificadores

Contexto: a auditoria externa (`.planning/13-auditoria-externa.md` §3) reprovou
o critério Tracker-2 com 45,6%. O check TRK-2 media a cobertura contra uma lista
fechada de prefixos canônicos — 76 IDs — enquanto os documentos entregues citam
também `DEC-NN`, `RF-NN`, `RNF-NN`, `REC-NN`, `DIV-NN`, `COD-NN` e `GAN-NN`,
definidos apenas em `.planning/`, que não faz parte da entrega. O universo real
que um avaliador enxerga é de **169 identificadores distintos**.

A correção foi dupla: o padrão do check virou o amplo
`\b[A-Z]{2,4}(-[A-Z]+)*-[0-9]{2,3}\b` aplicado a
`docs/PRD.md docs/RFC.md docs/FDD.md docs/adrs/*.md README.md`, e `docs/TRACKER.md`
ganhou 93 linhas novas, passando a funcionar também como glossário: qualquer
identificador citado nos entregáveis tem ali conteúdo e origem.

Este documento prova que o check corrigido **falha quando deve falhar**. Sem
isso, um TRK-2 verde não distingue "tracker completo" de "check cego".

Estado do repositório na execução: árvore limpa, `verify.sh` v8, engine
`/usr/bin/grep` (GNU grep) 3.11. Nenhum teste altera arquivo versionado — T1 e
T2 rodam contra cópias sob `/tmp`, via `$TRACKER_FILE` e `$TRK2_ALVOS`.

---

## Tabela de resultados

| # | O que foi adulterado | Esperado | Obtido | Veredito |
|---|---|---|---|---|
| T1 | 24 das 93 linhas novas do tracker apagadas (25%) | TRK-2 FALHA nomeando os IDs descobertos | `TRK-2 FALHA — universo=169, cobertos=134`, 35 IDs nomeados · `37/38 OK` | PASSOU |
| T2 | `DEC-99` acrescentado a um documento entregue, sem linha no tracker | TRK-2 FALHA | `TRK-2 FALHA — universo=2, cobertos=1`, `DEC-99` nomeado | PASSOU |
| T3 | Lista de alvos do universo esvaziada | `exit 2`, nunca OK | `ERRO DE VERIFICAÇÃO — TRK-2 recebeu lista de alvos vazia` · `exit=2` | PASSOU |
| T4 | Nada — estado limpo | Passa, com a contagem na linha de OK | `TRK-2 OK — universo=169 ... cobertos=158` · `38/38 OK` | PASSOU |

---

## T1 — apagar 25% das linhas novas do tracker

Remove 24 das 93 linhas acrescentadas (25%, arredondado para baixo), sempre de
uma cópia. A aritmética: 158 − 24 = 134 cobertos sobre 169 do universo = 79,3%,
logo abaixo do mínimo de 80%.

### Comando

```bash
python3 - <<'PY'
import re
S = "/tmp/.../scratchpad"
lines = open("docs/TRACKER.md", encoding="utf-8").read().split("\n")
novos = set(open(S + "/descobertos.txt").read().split())
out = []; rm = 0
for l in lines:
    m = re.match(r'^\| *([A-Z]{2,4}(?:-[A-Z]+)*-[0-9]{2,3}) *\|', l)
    if m and m.group(1) in novos and rm < 24 and (' TRANSCRICAO ' in l or ' CODIGO ' in l):
        rm += 1; continue
    out.append(l)
open(S + "/tn/TRACKER-t1.md", "w", encoding="utf-8").write("\n".join(out))
PY

TRACKER_FILE=$S/tn/TRACKER-t1.md ./scripts/verify.sh
```

### Saída literal

```
removidas: 24
IDs removidos: DEC-01 DEC-02 DEC-03 DEC-04 DEC-05 DEC-06 DEC-07 DEC-08 DEC-09
DEC-10 DEC-11 DEC-12 DEC-13 DEC-14 DEC-15 DEC-16 DEC-17 DEC-18 DEC-19 DEC-20
DEC-21 DEC-22 DEC-23 DEC-24

TRK-1 OK — header literal presente, 134 linha(s) de dados, todas com 6 campos
TRK-2 FALHA — universo=169, cobertos=134 (mínimo 80%). ID(s) descoberto(s) sem linha no tracker:
  DEC-01
  DEC-02
  DEC-03
  DEC-04
  DEC-05
  DEC-06
  DEC-07
  DEC-08
  DEC-09
  DEC-10
  DEC-11
  DEC-12
  DEC-13
  DEC-14
  DEC-15
  DEC-16
  DEC-17
  DEC-18
  DEC-19
  DEC-20
  DEC-21
  DEC-22
  DEC-23
  DEC-24
  FDD-ERR-08
  FDD-ERR-12
  PRD-RNF-22
  RFC-QA-06
  RFC-QA-07
  RFC-QA-08
  RFC-QA-09
  RFC-QA-10
  RFC-QA-11
  RFC-QA-12
  RFC-QA-13
TRK-3 OK — 110/134 linha(s) com Fonte=TRANSCRICAO (mínimo 70%), todas as Localizações conferidas por grep -F em TRANSCRICAO.md (0 não encontrada)
TRK-4 OK — 24 linha(s) com Fonte=CODIGO (mínimo 5), todos os caminhos presentes em git ls-files (0 ausente)

37/38 OK
```

**Leitura.** Falhou, e nomeou. Os 24 `DEC-NN` apagados aparecem um a um. Os 11
restantes da lista — `PRD-RNF-22`, `FDD-ERR-08`, `FDD-ERR-12` e `RFC-QA-06` a
`RFC-QA-13` — não são efeito da adulteração: são os itens que vivem em
§Itens sem origem identificável, fora da tabela principal, e por isso contam no
universo sem contar como cobertos. É essa a distância entre 158 e 169 no estado
limpo.

---

## T2 — `DEC-99` num documento entregue, sem linha no tracker

`DEC-99` não existe em fonte alguma. É exatamente a referência opaca que a
auditoria externa (§4 item 5) denunciou: um identificador que o leitor encontra
no pacote e não tem onde resolver.

O alvo é uma cópia de `README.md` — o entregável com o menor universo próprio,
um único ID (`ADR-007`) — com uma linha acrescentada citando `DEC-99`.

### Comando

```bash
cp README.md $S/tn/README-t2.md
printf '\nDecisão de referência opaca inserida pelo teste negativo: DEC-99.\n' >> $S/tn/README-t2.md

TRK2_ALVOS="$S/tn/README-t2.md" ./scripts/verify.sh
```

### Saída literal

```
TRK-2 FALHA — universo=2, cobertos=1 (mínimo 80%). ID(s) descoberto(s) sem linha no tracker:
  DEC-99
TRK-3 OK — 134/158 linha(s) com Fonte=TRANSCRICAO (mínimo 70%), todas as Localizações conferidas por grep -F em TRANSCRICAO.md (0 não encontrada)
TRK-4 OK — 24 linha(s) com Fonte=CODIGO (mínimo 5), todos os caminhos presentes em git ls-files (0 ausente)
```

**Leitura.** Falhou, e nomeou `DEC-99`. O padrão amplo enxerga o prefixo `DEC`,
que o padrão antigo ignorava por completo — sob o regex anterior este teste
passaria, porque `DEC-99` sequer entrava no universo.

### T2b — o mesmo `DEC-99` diluído no universo completo

Registrado porque é limitação do critério, não do teste, e não deve ficar
escondida: TRK-2 é um percentual, e um identificador opaco em 170 é 0,6%.

`$TRK2_ALVOS` é lido por `read -r -a`, que não expande glob nem chaves: os oito
ADRs precisam vir com o nome inteiro.

```bash
TRK2_ALVOS="docs/PRD.md docs/RFC.md docs/FDD.md \
docs/adrs/ADR-001-outbox-no-mysql.md \
docs/adrs/ADR-002-worker-processo-separado-polling.md \
docs/adrs/ADR-003-retry-backoff-e-dlq-em-tabela-separada.md \
docs/adrs/ADR-004-hmac-sha256-secret-por-endpoint.md \
docs/adrs/ADR-005-entrega-at-least-once-com-x-event-id.md \
docs/adrs/ADR-006-reuso-dos-padroes-existentes.md \
docs/adrs/ADR-007-insercao-na-outbox-dentro-da-transacao.md \
docs/adrs/ADR-008-modelo-de-autorizacao-do-modulo.md \
docs/adrs/README.md $S/tn/README-t2.md" ./scripts/verify.sh
```

```
TRK-2 OK — universo=170 ID(s) extraído(s) dos documentos, cobertos=158 (mínimo 80%)

38/38 OK
```

**Leitura.** Passa com 92,9%. O gate de 80% detecta erosão da cobertura, não uma
referência opaca isolada — nenhum limiar percentual detectaria. Quem quiser
tolerância zero para ID sem linha precisa de um check separado, com mínimo 100%,
não de um TRK-2 mais apertado. Fica registrado como lacuna conhecida do
critério; T2 acima prova o que TRK-2 de fato garante.

---

## T3 — esvaziar a lista de alvos do universo

Passagem vazia é o modo de falha clássico deste tipo de check: sem alvo, o
universo é zero, e `0 >= 0.80 × 0` é verdadeiro em aritmética inteira — o check
imprimiria OK medindo o nada.

### Comando

```bash
TRK2_ALVOS="" ./scripts/verify.sh; echo "exit=$?"
```

### Saída literal

```
TRK-1 OK — header literal presente, 158 linha(s) de dados, todas com 6 campos
ERRO DE VERIFICAÇÃO — TRK-2 recebeu lista de alvos vazia em $TRK2_ALVOS — sem documento para extrair o universo de IDs
exit=2
```

**Leitura.** `exit 2`, não OK, e antes de qualquer aritmética. O script morre na
guarda `[ "${#TRK2_DOCS[@]}" -gt 0 ]`, acrescentada junto com a parametrização.
A guarda anterior (`trk2_n_universo > 0`) sozinha não bastava: com array vazio,
`grep -ohE PADRAO` sem argumento de arquivo passaria a ler stdin.

---

## T4 — estado limpo

### Comando

```bash
git status --short && ./scripts/verify.sh
```

### Saída literal

```
TRK-1 OK — header literal presente, 158 linha(s) de dados, todas com 6 campos
TRK-2 OK — universo=169 ID(s) extraído(s) dos documentos, cobertos=158 (mínimo 80%)
TRK-3 OK — 134/158 linha(s) com Fonte=TRANSCRICAO (mínimo 70%), todas as Localizações conferidas por grep -F em TRANSCRICAO.md (0 não encontrada)
TRK-4 OK — 24 linha(s) com Fonte=CODIGO (mínimo 5), todos os caminhos presentes em git ls-files (0 ausente)

38/38 OK
```

**Leitura.** A contagem está declarada na própria linha de OK — `universo=169`,
`cobertos=158`, 93,5%, folga de 13,5 pontos sobre o mínimo. Os 11 não cobertos
são os itens de §Itens sem origem identificável, que por construção não entram
na tabela principal: registrá-los ali exigiria inventar Localização, que é
justamente o que o pacote se proibiu.

---

## Defeito latente encontrado durante a execução

A expansão do tracker expôs um bug em TRK-1 que não tinha nada a ver com o
tracker. A checagem do header era:

```bash
printf '%s\n' "$trk_secao" | "$GREP" -qxF "$TRK_HEADER" && trk1_header_ok=1
```

`grep -q` sai no primeiro casamento e fecha o pipe; o `printf` morre com SIGPIPE
(141) e, sob o `set -o pipefail` da linha 102, o status do pipeline vira 141
mesmo com o header presente. Com a tabela antiga o `printf` cabia inteiro no
buffer do pipe e terminava antes de o `grep` sair, então o defeito nunca
aparecia. Com 158 linhas, aparece: TRK-1 reprovou com "header literal presente:
não" e zero linha malformada, contra um header que `grep -qxF` isolado
encontrava sem esforço.

Corrigido trocando o pipe por here-string, que não sofre SIGPIPE:

```bash
"$GREP" -qxF "$TRK_HEADER" <<< "$trk_secao" && trk1_header_ok=1
```

Ficam duas construções iguais e ainda não corrigidas, nas linhas 453 e 542, que
hoje operam sobre entradas pequenas (uma entrada de diretório, a §Alternativas
do RFC). São latentes pelo mesmo motivo, e vão falhar do mesmo jeito se as
entradas crescerem além do buffer do pipe.
