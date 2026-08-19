# ADR-004 — Assinatura HMAC-SHA256 com secret por endpoint

## Status
Aceito — 2026-08-19 · decidido em reunião técnica de [09:00]–[09:53]

## Contexto

A partir do momento em que a plataforma passa a chamar uma URL fornecida pelo
cliente (ADR-002), o cliente precisa de alguma forma de saber que a requisição
que chegou nele foi mesmo emitida por nós, e não por um terceiro que descobriu a
URL. Sofia conduziu esse bloco da reunião e trouxe os três pontos juntos:
transporte, prova de origem e ciclo de vida da chave.

Do transporte, a exigência foi dita sem meio-termo: `[09:23] Sofia` — "TLS
obrigatório. URL do webhook tem que ser https." O ponto de aplicação disso já
existe no projeto e foi reconhecido pela própria reunião: `[09:23] Sofia` — "é só
uma validação no schema Zod". O disco confirma (GAN-22): a validação de entrada
do projeto é o middleware `validate`
(`src/middlewares/validate.middleware.ts`:11), aplicado rota a rota — o
precedente literal está em `src/modules/orders/order.routes.ts`:16–24, com os
schemas declarados num arquivo `*.schemas.ts` por módulo
(`src/modules/orders/order.schemas.ts`:18 e :33).

Do ciclo de vida da chave, a exigência veio de um problema de operação: trocar a
secret não pode derrubar a integração do cliente. `[09:21] Sofia` — "Endpoint pro
cliente conseguir pedir nova secret pela API." e "a antiga fica válida por 24
horas em paralelo".

O que não existe no projeto é a primitiva criptográfica. A busca por
`hmac|crypto|createHmac|signature` em `src/`, `prisma/`, `tests/` e
`package.json` retorna vazia; a única dependência de criptografia é o `bcrypt`
(`package.json`:27), usado exclusivamente para hash de senha em
`src/modules/auth/auth.service.ts`:36 — que não serve para assinar payload.

## Decisão

Toda entrega leva assinatura HMAC-SHA256 calculada sobre o corpo do request, com uma secret única por endpoint de webhook cadastrado — não uma secret global da
plataforma. A secret é rotacionável pelo cliente via API, e a secret anterior
continua válida em paralelo por 24 horas (grace period), de modo que a rotação
não exige troca simultânea dos dois lados. A obrigatoriedade de `https` na URL
cadastrada é validada no schema Zod do módulo, pelo mesmo `validate` de
`src/middlewares/validate.middleware.ts`:11 já usado em
`src/modules/orders/order.routes.ts`:16–24.

Falas que fecham, todas em `[09:22] Sofia`:

- "Decidido: HMAC-SHA256 sobre o corpo do request" — **DEC-07**.
- "secret por endpoint" — **DEC-08**.
- "suporte a rotação com grace period de 24h" — **DEC-09**.

## Alternativas Consideradas

### Secret global da plataforma

Uma única chave de assinatura para todos os clientes e todos os endpoints, com o
cliente verificando contra um segredo publicado uma vez.

- Quem levantou e quando: a transcrição não registra defesa dessa opção; ela é
  nomeada apenas na forma negativa da própria decisão.
- **Motivo do descarte:** `[09:22] Sofia` — "secret por endpoint" (DEC-08). A
  reunião registrou a escolha, não o debate: não há razão adicional dita em ata,
  e nenhuma foi inventada aqui.

### Entrega sem assinatura, confiando só no TLS

Depender apenas do `https` obrigatório: o canal é cifrado, o corpo vai limpo e o
cliente aceita o que chegar na URL dele.

- `(alternativa plausível, não discutida na reunião)`
- **Motivo do descarte:** o TLS protege o canal, mas quem conhece a URL pode
  chamá-la; a decisão da reunião foi por prova de origem sobre o corpo —
  `[09:22] Sofia`: "Decidido: HMAC-SHA256 sobre o corpo do request".

### Rotação sem grace period (corte seco da secret antiga)

Gerar a nova secret e invalidar a anterior no mesmo instante.

- Quem levantou e quando: `[09:21] Sofia`, ao definir o comportamento da rotação.
- **Motivo do descarte:** `[09:21] Sofia` — "a antiga fica válida por 24 horas em
  paralelo". O trade-off registrado é a janela que o cliente tem para adotar a
  chave nova sem perder entrega.

## Consequências

### Positivas

- O cliente ganha prova de origem e de integridade do corpo, verificável do lado
  dele com uma primitiva padrão, sem handshake adicional com a plataforma.
- A rotação não tem janela de indisponibilidade para o cliente: por 24 horas as
  duas secrets validam (`[09:21] Sofia`), e a troca é iniciada pelo próprio
  cliente via API.
- Uma secret por endpoint permite rotacionar ou revogar um cliente sem tocar em
  nenhum outro — cada endpoint cadastrado é uma unidade independente de
  confiança.
- A exigência de `https` não custa código novo de infraestrutura: entra como
  regra no schema Zod do módulo e é aplicada pelo `validate` existente
  (`src/middlewares/validate.middleware.ts`:11), com erro de validação já
  formatado pelo middleware de erro (`src/middlewares/error.middleware.ts`:26).

### Negativas

- A plataforma passa a guardar material sensível por endpoint cadastrado: N
  secrets vivas no banco, mais as antigas ainda dentro do grace period. O projeto
  não tem hoje nenhuma primitiva de criptografia aplicável — a busca por
  `hmac|crypto|createHmac|signature` em `src/`, `prisma/`, `tests/` e
  `package.json` é vazia, e o `bcrypt` de `package.json`:27 serve a hash de senha
  em `src/modules/auth/auth.service.ts`:36, não a assinatura. Tanto o cálculo do
  HMAC quanto a forma de guardar a secret são decisões novas, sem precedente
  interno para copiar.
- O grace period de 24 horas é, por definição, uma janela em que duas chaves
  valem: uma secret vazada continua aceita por um dia inteiro depois de o cliente
  ter rotacionado (`[09:21] Sofia`).
- A lista de `redactPaths` do logger (`src/shared/logger/index.ts`:4–11) cobre
  hoje `authorization`, `cookie`, `*.password`, `*.passwordHash`, `*.token` e
  `*.accessToken` —
  nenhum campo de secret de webhook. Sem entrada nova nessa lista, qualquer log
  que carregue o objeto de configuração do endpoint imprime a secret em claro.
- A verificação da assinatura é trabalho do lado do cliente: a plataforma assume
  o custo de suporte de uma integração que só funciona se o cliente implementar o
  HMAC corretamente — e a reunião reservou revisão de segurança dedicada por
  causa disso, `[09:46] Sofia`: "Reservem pelo menos dois dias úteis pra eu
  revisar o código de segurança antes do deploy."
