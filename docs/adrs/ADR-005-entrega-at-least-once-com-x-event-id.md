# ADR-005 — Entrega at-least-once com X-Event-Id para dedup no cliente

## Status
Aceito — 2026-08-19 · decidido em reunião técnica de [09:00]–[09:53]

## Contexto

A política de retentativa de ADR-003 cria um caso inevitável: o cliente pode ter
processado a requisição e falhado ao responder — timeout, conexão cortada, 500
depois do commit dele. Do lado da plataforma isso é indistinguível de uma entrega
que não chegou, e a resposta do worker é retentar. A reunião reconheceu o efeito
antes de decidir a garantia: `[09:24] Diego` — "Pode acontecer de o cliente
receber o mesmo evento duas vezes."

O gatilho concreto dessa duplicidade também foi fechado na reunião: o worker
trata como falha qualquer chamada que não responda em 10 segundos —
`[09:42] Diego`: "10 segundos. Cliente lento que não responde em 10s a gente
trata como falha". Um cliente lento que processou o evento e demorou a responder
recebe o mesmo evento de novo.

A alternativa forte — garantir que o evento chegue exatamente uma vez — foi
avaliada e o custo foi dito em voz alta na mesma janela (`[09:25] Diego`).

No repositório não há nenhuma chave de idempotência para reaproveitar: a busca
por `idempot` em `src/`, `prisma/`, `tests/` e `package.json` retorna vazia. O
identificador do evento nasce com a feature, seguindo o padrão de id do projeto,
`String @id @default(uuid()) @db.Char(36)` (`prisma/schema.prisma`:75).

## Decisão

A garantia de entrega é at-least-once, e a deduplicação é responsabilidade do cliente, feita pelo header `X-Event-Id`, que carrega o UUID do evento e é estável
entre todas as tentativas do mesmo evento. O header vai junto com os demais
definidos para a entrega — `[09:44] Diego`: "X-Event-Id com o UUID, X-Signature
com o HMAC, X-Timestamp com o timestamp do envio".

Fecha a decisão `[09:26] Larissa`: "At-least-once com X-Event-Id pra dedup do
lado do cliente. Decisão." — **DEC-10**.

## Alternativas Consideradas

### Garantia de entrega exactly-once

Assegurar que cada evento chegue uma única vez ao cliente, sem exigir dedup do
outro lado.

- Quem levantou e quando: `[09:25] Diego`, imediatamente depois de reconhecer a
  duplicidade em `[09:24] Diego`.
- **Motivo do descarte:** `[09:25] Diego` — "Garantir exactly-once exigiria
  coordenação dos dois lados e fica muito mais complexo." O trade-off dito é
  custo de complexidade e coordenação com o cliente (REC-08).

### Deduplicação do lado da plataforma, antes do envio

Guardar quais eventos já receberam resposta de sucesso e suprimir reenvio, em vez
de repassar a responsabilidade ao cliente.

- `(alternativa plausível, não discutida na reunião)`
- **Motivo do descarte:** não resolve o caso que motivou a decisão — a
  ambiguidade está justamente em não saber se o cliente processou quando ele não
  responde (`[09:24] Diego`), e suprimir o reenvio nesse estado transformaria
  duplicidade em perda de evento.

## Consequências

### Positivas

- A política de retry de ADR-003 fica segura de aplicar: retentar é sempre a
  ação correta, porque o contrato admite duplicidade.
- Nenhuma coordenação com o cliente na hora da entrega — sem confirmação em duas
  fases, sem estado compartilhado (`[09:25] Diego`).
- A chave de dedup viaja no próprio request (`X-Event-Id`), então o cliente não
  precisa de chamada extra à plataforma para deduplicar (`[09:44] Diego`).

### Negativas

- O custo é transferido para o cliente, e isso é contratual: ele precisa
  persistir os `event_id` já processados para não processar duas vezes. A reunião
  registrou o ônus explicitamente — `[09:24] Diego`: "Pode acontecer de o cliente
  receber o mesmo evento duas vezes." Cliente que não implementar dedup vai
  processar o mesmo evento mais de uma vez, e o efeito disso acontece do lado
  dele, fora do alcance da plataforma.
- Do lado da plataforma não existe rede de proteção: a busca por `idempot` em
  `src/`, `prisma/`, `tests/` e `package.json` é vazia — não há chave de
  idempotência a reaproveitar, e o `X-Event-Id` é apenas informado, nunca
  verificado por nós.
- A duplicidade escala com a política de retentativa: até 5 entregas do mesmo
  evento (ADR-003), e o timeout de 10 segundos (`[09:42] Diego`) é o gatilho mais
  provável para gerar cópia de um evento que já foi processado.
- **O "at least" de DEC-10 depende de um mecanismo de recuperação que a reunião
  não decidiu.** At-least-once só vale se toda linha aceita for entregue pelo
  menos uma vez, e o desenho do worker marca a linha como em processamento antes
  de tentar o envio. Uma queda entre as duas coisas deixa a linha fora do
  conjunto que o worker lê — zero entrega, não uma. A reunião não tratou de
  lease, timeout de processamento nem reset no startup; nenhuma fala de
  `[09:00]`–`[09:53]` toca no assunto. A garantia decidida em `[09:26] Larissa`
  fica, portanto, **condicionada a uma decisão que ainda não existe**, registrada
  em `RFC-QA-06` e em `docs/FDD.md` §Não decidido na reunião. Este ADR não a
  toma: escolher o mecanismo aqui seria inventar decisão de reunião.
- **A estabilidade do `event_id` vira restrição de implementação do replay.** Só
  há dedup se o identificador for do *evento*, não da linha que o transporta:
  como o replay da DLQ (ADR-003) cria uma linha nova de outbox, essa linha tem de
  **copiar** o `event_id` do evento original em vez de gerar um novo. Se gerar um
  novo, o cliente que deduplica corretamente processa o replay como evento
  inédito e DEC-10 deixa de valer justamente no caminho em que mais importa. A
  consequência está registrada no FDD, §DLQ e replay e §Mapeamento payload ↔
  schema.
- O replay manual da DLQ (ADR-003) é uma sexta chance de duplicata, disparada por
  operador — e reentrega fora da ordem original, somando-se ao limite de ordering
  já registrado em DEC-04 (ADR-002).
