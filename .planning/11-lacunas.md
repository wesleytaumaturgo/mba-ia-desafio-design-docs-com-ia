# 11 — Lacunas não decididas na reunião de [09:00]–[09:53]

Dez ausências apuradas pelo review externo (`.planning/10-externo.md`),
registradas como **questão em aberto** e **exclusão de escopo**. Nenhuma foi
preenchida: declarar é dizer que falta, não escolher. Nenhum ID de requisito foi
criado para elas — as seis de peso arquitetural ganharam `RFC-QA-NN`, que é
identificador de questão, não de requisito, e as dez estão em
`docs/FDD.md` §Não decidido na reunião.

Toda lacuna foi precedida de busca em `TRANSCRICAO.md`. Onde a busca ampla
voltou com acerto, o acerto está classificado abaixo e uma busca precisa isolou
a ausência real. **Um caso — L4 — teve o escopo reduzido porque parte dele tinha
origem**; está registrado como desvio em §Desvio de escopo.

| ID | Lacuna | Busca que provou a ausência | Onde foi registrada |
|---|---|---|---|
| L1 | Recuperação de linha em `PROCESSING` após queda do worker | `grep -inE 'lease\|crash\|travad\|preso\|órf\|recuper\|reset\|stuck\|processing'` → 1 acerto, `[09:12] Larissa`, onde `PROCESSING` é valor de `OrderStatus` numa pergunta sobre ordering, não estado de linha de outbox · busca precisa `'worker.{0,30}(cai\|cair\|morre\|reinicia)\|reinici\|retoma\|em processamento\|timeout de processamento'` → 1 acerto, `[09:11] Diego` ("se a API reinicia, perde o worker"), que motiva separar o processo e não trata da linha em voo. **Nenhuma fala decide lease, timeout de processamento ou reset** | `RFC-QA-06` · FDD §Não decidido · FDD §Riscos · ADR-005 §Negativas · TRACKER §Itens sem origem |
| L2 | Ordering por `order_id` quebrado por backoff, com um worker só | `grep -inE 'ultrapass\|fora de ordem\|reordena\|adiantar\|na frente'` → 1 acerto, `[09:24] Larissa`, "64KB de limite, erro caso **ultrapasse**" — tamanho de payload, não ordem · busca precisa `'backoff.{0,40}ordem\|ordem.{0,40}backoff\|ordem.{0,30}retentativa\|retentativa.{0,30}ordem'` → **vazio (rc=1)** | `RFC-QA-07` · FDD §Não decidido · FDD §Riscos · ADR-002 §Negativas · TRACKER §Itens sem origem |
| L3 | Armazenamento da secret em repouso e key management | `grep -inE 'em repouso\|at rest\|criptograf\|cofre\|vault\|kms\|key management\|armazena.{0,20}secret'` → 1 acerto, `[09:21] Bruno`, "a tabela de configuração de webhook armazena url + secret + customer_id" — decide que a coluna existe, não como protegê-la · busca precisa `'secret.{0,30}(cifrad\|criptograf\|hash\|plain\|texto claro\|em claro)\|proteg.{0,20}secret'` → **vazio (rc=1)** | `RFC-QA-08` · FDD §Não decidido · TRACKER §Itens sem origem |
| L4 | Encoding e canonicalização de `X-Signature` — **escopo reduzido, ver §Desvio** | `grep -inE 'hex\|base64\|canonical\|sha256=\|prefixo\|encoding\|codificaç'` → 2 acertos, ambos sobre o prefixo `WEBHOOK_` dos códigos de erro (`[09:29] Larissa`, `[09:48] Larissa`), nada sobre assinatura · busca precisa `'hexadecimal\|base ?64\|serializ\|canonicaliz\|byte a byte\|string exata\|sha256='` → **vazio (rc=1)** | FDD §Não decidido (só encoding e canonicalização; algoritmo e objeto assinado creditados a `[09:22] Sofia`) |
| L5 | Política anti-SSRF para url fornecida pelo cliente | `grep -inE 'ssrf\|rebind\|loopback\|127\.0\|localhost\|ip privado\|rede interna\|redirect\|10\.0\|192\.168'` → **vazio (rc=1)** | `RFC-QA-09` · FDD §Não decidido · TRACKER §Itens sem origem |
| L6 | Ciclo de vida do `DELETE` de endpoint com eventos pendentes | `grep -inE 'soft delete\|hard delete\|exclusão lógica\|cascade\|on delete\|onDelete\|cancelar.{0,20}pendente\|apagar.{0,20}pendente'` → **vazio (rc=1)** | FDD §Não decidido |
| L7 | Schema de `WebhookEndpoint`, `WebhookDelivery` e `WebhookDeadLetter` | `grep -inE 'nullable\|not null\|unique\|índice único\|varchar\|tamanho de campo\|foreign key'` → **vazio (rc=1)** | `RFC-QA-10` · FDD §Não decidido · TRACKER §Itens sem origem |
| L8 | Atomicidade e concorrência de `outbox → DLQ` e `DLQ → nova outbox` | `grep -inE 'lock\|CAS\|concorren\|simultân\|race\|atomic\|transação.{0,20}dlq'` → 9 acertos, nenhum sobre a DLQ: `[09:13] Diego` fala de lock pessimista para **múltiplos workers** e o adia; `[09:40] Bruno` e `[09:48] Larissa` fecham a atomicidade **da inserção na outbox dentro de `changeStatus`**, que é outra escrita · busca precisa `'(dlq\|dead.?letter).{0,40}(transaç\|atomic\|lock)\|replay.{0,40}(simultân\|concorr\|duas vezes\|dois)'` → **vazio (rc=1)** | `RFC-QA-11` · FDD §Não decidido · TRACKER §Itens sem origem |
| L9 | Classificação de falha: 4xx permanente × 5xx transitória | `grep -inE '4xx\|permanente\|não retent\|erro do cliente\|400\|404 '` → 1 acerto, `[09:15] Diego`, "depois de um teto de tentativas considera falha **permanente**" — define permanência por esgotamento de tentativas, não por código de resposta · busca precisa `'(2xx\|4xx\|5xx)\|resposta.{0,20}(inválid\|erro).{0,30}(retent\|desist)'` → **vazio (rc=1)** | FDD §Não decidido |
| L10 | Listagem administrativa da DLQ — como o operador descobre o `:id` | `grep -inE 'listar.{0,20}(dlq\|dead\|fila)\|consulta.{0,20}(dlq\|dead)\|GET .*dead\|descobre.{0,15}id'` → **vazio (rc=1)** | FDD §Não decidido |

## Desvio de escopo — L4

A lacuna, como enunciada, incluía "quais bytes são assinados". Essa parte **tem
origem**: `[09:22] Sofia` — "Decidido: HMAC-SHA256 sobre o corpo do request,
secret por endpoint, suporte a rotação com grace period de 24h" — fecha o
algoritmo e o objeto assinado, e `[09:20] Sofia` já dizia "assina o payload […]
manda a assinatura num header tipo X-Signature".

Registrar isso como não decidido seria o erro simétrico ao de inventar
requisito: apagar uma decisão que existe. L4 entrou, portanto, **apenas com o
que a ata não fecha** — a codificação do digest (hex ou base64), o prefixo do
header e a serialização exata dos bytes assinados —, e a linha do FDD credita
explicitamente `[09:22] Sofia` pelo que foi decidido. Por ser lacuna de segurança
sem peso de arquitetura nova, ficou só no FDD, como as demais de Categoria 2 que
não constam da lista de RFC-QA do enunciado.

## O que NÃO foi feito, deliberadamente

- Nenhuma das dez recebeu valor default, recomendação ou solução técnica. A
  mitigação de L1 e L2 em `docs/FDD.md` §Riscos e mitigação é, literalmente,
  "decidir antes de implementar".
- DEC-04 não foi reescrita. `[09:13] Larissa` é fala literal e permanece citada
  como está em ADR-002; o alcance ampliado entrou como bullet novo, marcado como
  descoberta da análise do algoritmo.
- Nenhum endpoint, coluna, política ou número novo foi criado. L7 e L10, em
  particular, continuam sem schema e sem contrato.
- As seis linhas `RFC-QA-NN` novas **não** entraram na tabela principal do
  tracker. Lacuna não tem origem na transcrição — é a definição dela —, então o
  lugar correto é §Itens sem origem identificável, com a razão declarada.
