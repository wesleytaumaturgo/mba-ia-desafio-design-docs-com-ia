# 14 — Correções apuradas na auditoria externa

Insumo: `.planning/13-auditoria-externa.md`. Fecha **Geral-1** e as observações
corrigíveis de §4. **Tracker-2 NÃO é tocado aqui** — `docs/TRACKER.md` é o
próximo bloco e depende deste texto já corrigido.

Princípio aplicado: contradição → corrige · ausência → já declarada · invenção →
sai. Nenhum requisito, número, política ou contrato novo foi criado.

---

## Tabela de correções

| ID | O que mudou | arquivo:linha | Busca que fundamentou |
|---|---|---|---|
| **C1** | Frases órfãs de "retentada/retentar 5 vezes" (= 6 chamadas) uniformizadas para **"até 5 tentativas de entrega no total (1 inicial + 4 retentativas)"** | `docs/FDD.md`:46, :230–232, :694 (tabela de resiliência), :707 · `docs/PRD.md`:150 · `docs/adrs/ADR-003-...`:30–32 | `grep -rniE '5 (vezes\|tentativas\|retries)\|cinco (vezes\|tentativas)' docs/` |
| **C2** | `eventId` acrescentado à lista de colunas de `webhook_outbox`, com tipo do padrão do projeto (`String @db.Char(36)`), e regra declarada: `eventId` identifica o **evento** e é copiado no replay, `id` identifica a **linha** | `docs/FDD.md`:962 (lista de campos), :971–978 (regra) · :640 (§Mapeamento) · :283–292 (§DLQ e replay) | `sed -n '70,85p' prisma/schema.prisma` → `id String @id @default(uuid()) @db.Char(36)` (linha 75) |
| **C3a** | Classificação de falha: **lacuna sobrevive**; a decisão foi reduzida ao que a ata sustenta (só o timeout) e o resto ficou marcado `(decisão de desenho deste FDD, sem origem na reunião)` + `RFC-QA-12` | `docs/FDD.md`:130–134 (lacuna) · :230–237 (§Retry) · :681 (FDD-ERR-12) | `grep -niE '2xx\|4xx\|5xx\|erro de rede\|timeout\|falha (permanente\|definitiva\|transit)\|retent\|retry' .planning/02-transcricao.md` + `grep -niE '2xx\|...' TRANSCRICAO.md` → só `[09:15] Diego` (esgotamento) e `[09:42] Diego` (timeout); zero fala sobre 4xx × 5xx |
| **C3b** | Concorrência de replay: **lacuna sobrevive**; removidas as duas frases afirmativas ("item marcado como já reprocessado", "segunda tentativa recusada"), o 409 do contrato de replay, `FDD-ERR-09` e o critério de aceite correspondente | `docs/FDD.md`:294–298 (nota de lacuna) · :574–578 (contrato) · :681 (matriz, linha removida) · §Critérios de aceite técnicos | `grep -niE 'replay\|reprocess\|duas vezes\|concorr\|simultan' .planning/02-transcricao.md TRANSCRICAO.md` → `[09:18] Diego`, `[09:35/09:36]` só fecham "recoloca na outbox como pendente" + role ADMIN + auditoria |
| **C3c** | Lifecycle do `DELETE`: **lacuna sobrevive**; o contrato passou a afirmar só o que `[09:33] Bruno` sustenta (remove o endpoint, 204/404) e a preservação do histórico foi devolvida à lista de não decididos | `docs/FDD.md`:439–446 (contrato) · :116–120 (lacuna) | `grep -niE 'delete\|remov\|deleta\|excluir\|soft ?delete\|desativ' .planning/02-transcricao.md TRANSCRICAO.md` → única ocorrência: RF-03, `[09:33] Bruno` |
| **C4** | "Latência mínima de 2s" → **"o intervalo de polling acrescenta até 2s de espera de agendamento antes da primeira tentativa"**, com a fala literal citada e uma frase registrando que a ata é ambígua ("mínima" e "pior caso" não descrevem o mesmo número) | `docs/PRD.md`:147 · `docs/FDD.md`:215–222, :700 · `docs/adrs/ADR-001-...`:118–124 · `docs/adrs/ADR-002-...`:141–142 | `grep -n -B2 -A2 '09:10' TRANSCRICAO.md` → `[09:10] Larissa`: "A latência mínima vai ser 2 segundos no pior caso. Aceitamos." + `grep -rniE 'lat[êe]ncia m[íi]nima' docs/` |
| **C5** | 4 regras sem origem **removidas** do FDD, 2 **sobrevivem marcadas** com ratificação pedida no RFC (`RFC-QA-12`, `RFC-QA-13`) | `docs/FDD.md` §Contratos públicos e §Matriz de erros (13 → 9 códigos) · `docs/RFC.md`:177–178 · `docs/PRD.md`:166 | ver §C5 abaixo, uma busca por regra |
| **C6** | `DEC-24` mantida (payload sem `items`); **a justificativa** foi corrigida: a rota `GET /orders/:id` citada como alternativa não é alcançável pelo cliente externo hoje, o que torna a omissão **lacuna funcional declarada** | `docs/FDD.md`:580–594 | `grep -n -A2 '09:43' TRANSCRICAO.md` → `[09:43] Diego` · `sed -n '10,20p' src/modules/orders/order.routes.ts` → `router.use(authenticate)` na linha 12 |
| **C7** | "na maioria dos casos observados" (expressão ausente da ata) removida; o critério de aceite passa a ser a meta que `[09:02] Marcos` deu, sem condição atenuante | `docs/PRD.md`:213–216 | `grep -rn 'maioria' docs/` · `[09:02] Marcos`: "qualquer coisa abaixo de 10 segundos" — nenhuma fala condiciona a meta |
| **C8** | Altura do PRD subida nos quatro trechos: middleware/token, JWT/modelo de dados, transação/redação de log e arquivo de teste saíram do PRD e viraram referência ao documento técnico. **Nenhuma seção foi apagada** — os 6 riscos completos (PRD-6) e a §Estratégia de testes seguem inteiros | `docs/PRD.md`:31–43, :57–66, :194–199, :232–241 | `grep -nE 'redactPaths\|middleware\|JWT\|jwt\|transação\|tests/\|\.ts\|token' docs/PRD.md` |

---

## C3 — qual lado sobreviveu, e por quê

Regra aplicada: decisão **com** origem em fala → a lacuna sai e a decisão fica
citando `[hh:mm] Nome`; decisão **sem** origem → a lacuna sobrevive e a decisão
é reduzida ao que a ata sustenta.

**a) Classificação de falha — sobreviveu a LACUNA.** A ata fecha o timeout
(`[09:42] Diego`, DEC-23/RNF-22) e o esgotamento de tentativas
(`[09:15] Diego`). Nenhuma fala separa 4xx definitiva de 5xx transitória. Logo
"todo não-2xx é retentável" é escolha do desenho: ficou marcada, com
`RFC-QA-12` aberta para ratificação.

**b) Concorrência de replay — sobreviveu a LACUNA.** `[09:18] Diego` fecha só
"Recoloca na outbox como pendente"; `[09:36]` fecha role ADMIN e auditoria.
Nada sobre idempotência do replay nem sobre dois replays simultâneos. As duas
frases afirmativas do FDD saíram junto com `FDD-ERR-09`, o 409 do contrato e o
critério de aceite que dependia dele.

**c) Lifecycle do DELETE — sobreviveram os DOIS LADOS, separados.** A remoção do
endpoint **tem** origem (`[09:33] Bruno`, RF-03) e ficou no contrato, citada. A
preservação do histórico de entregas **não tem** origem e voltou para a lista de
não decididos, ao lado de soft delete, pendências e `onDelete`. Não é meia
decisão: é a fala inteira de um lado e o silêncio inteiro do outro.

---

## C5 — o que saiu e o que sobreviveu marcado

| Regra | Busca | Veredito |
|---|---|---|
| `WEBHOOK_DUPLICATE_URL` | `grep -rniE 'duplicad\|duplicat\|url j[áa] cadastrad\|mesma url\|url repetid' .planning/02-transcricao.md TRANSCRICAO.md` → **vazio** | **REMOVIDO** — sem origem e não essencial: o contrato de criação fica de pé com 201/400/404/422 |
| Bloqueio de nova rotação dentro do grace (`WEBHOOK_ROTATION_IN_GRACE_PERIOD`) | `grep -rniE 'rota[çc]\|rotate\|grace\|24 ?h\|24 horas' ...` → `[09:21] Sofia` e `[09:22] Sofia` instituem o grace period e **não** recusam re-rotação | **REMOVIDO** — sem origem, não essencial e de efeito adverso (impediria revogar secret comprometida por 24h). O FDD agora afirma explicitamente que a re-rotação não é recusada |
| Replay único (`WEBHOOK_DEAD_LETTER_ALREADY_REPLAYED`) | `grep -niE 'replay' TRANSCRICAO.md` → `[09:18]`, `[09:35]`, `[09:36]`: só "recoloca como pendente", role ADMIN e auditoria | **REMOVIDO** — sem origem; e mantê-lo contradiria a lacuna de C3b |
| Retry de todo não-2xx (`WEBHOOK_DELIVERY_FAILED`) | `grep -niE '2xx\|falha\|falhou' TRANSCRICAO.md` → `[09:15] Diego` (esgotamento), `[09:42] Diego` (timeout); nada sobre faixa de status | **SOBREVIVE MARCADO** — essencial: é o gatilho de toda a política de retry. Ratificação em `RFC-QA-12` |
| `WEBHOOK_SIGNATURE_UNAVAILABLE` | `grep -niE 'secret' TRANSCRICAO.md` → `[09:20]`–`[09:22]`, `[09:31]`, `[09:46]`; nenhuma fala prevê envio sem secret utilizável | **REMOVIDO** — sem origem e não essencial: todo endpoint nasce com secret na criação |
| Sigilo da secret (`PRD-RNF-22`) | mesma busca → `[09:31] Marcos` (devolvida na criação) e `[09:21] Sofia` (devolvida na rotação); nenhuma fala proíbe as demais leituras | **SOBREVIVE MARCADO** — essencial: secret legível em consulta anula a secret por endpoint de `[09:21] Sofia`. Ratificação em `RFC-QA-13` |

Resultado: 4 removidas, **2 sobrevivem marcadas** — dentro da meta.

---

## Efeitos colaterais declarados

1. **Numeração de `FDD-ERR` ficou com buracos** (01, 02, 04, 05, 07, 08, 10, 11,
   12). Renumerar arrastaria referências no tracker e no README; a escolha foi
   diff mínimo. `FDD-4` continua passando: 9 códigos, mínimo 8.
2. **Contagem de classes novas em §Integração** caiu de 13 para 9 (e de "oito
   delas" para "quatro delas" nas bases que aceitam código por parâmetro),
   porque a matriz encolheu. Sem esse ajuste a correção deixaria exatamente o
   tipo de frase órfã que este bloco fecha.
3. **`docs/RFC.md` foi comprimido em ~90 palavras** para caber as duas linhas de
   `RFC-QA-12`/`RFC-QA-13` sob o teto normativo de 2200 de `.planning/03-design.md`
   §5 (INV-8) — hoje 2199. A compressão não removeu fato nenhum: reduziu a
   terceira e a segunda repetição de DIV-07/DIV-08 dentro do próprio RFC a
   referência cruzada, mantendo o enunciado completo em §Contexto e problema.
4. **Pendências que este bloco NÃO fecha, por serem do bloco do tracker:**
   - `docs/TRACKER.md`:35 ainda diz "Retentativa até 5 vezes antes da DLQ" — a
     mesma formulação ambígua que C1 corrigiu nos documentos;
   - `docs/TRACKER.md`:97, :99, :101, :103 ainda listam `FDD-ERR-03`, `-06`,
     `-09` e `-13` como itens sem origem em `docs/FDD.md`; os quatro deixaram de
     existir lá;
   - `RFC-QA-12` e `RFC-QA-13` são IDs novos e ainda não têm linha no tracker.
   `TRK-2` segue passando pelo critério estreito do script (universo 76,
   cobertos 65 = 85,5%).

---

## Gate

```
./scripts/verify.sh                     → 38/38 OK
wc -w docs/PRD.md docs/RFC.md docs/FDD.md
grep -rniE '5 (vezes|tentativas|retries)|cinco (vezes|tentativas)' docs/
```

Nenhuma ocorrência restante de `retentada/retentar N vezes` fora de
`docs/TRACKER.md`. As ocorrências de "5 tentativas" que permanecem significam
5 tentativas **no total** ou são cópia literal da ata (`C-3`).
