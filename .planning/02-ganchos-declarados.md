# 02 — Ganchos declarados na reunião (NÃO VERIFICADOS)

Inventário de toda menção da reunião a artefato do código existente — arquivo,
classe, método, tabela, coluna, módulo, biblioteca, rota, padrão — **como foi
dita**, sem qualquer conferência contra o disco.

Nenhum arquivo de `src/`, `prisma/` ou `tests/` foi aberto nesta sessão. A
coluna `Status` traz `NÃO VERIFICADO` em todas as linhas por construção: o
cruzamento com o repositório é o próximo bloco e antecipá-lo aqui destruiria a
independência entre "o que a reunião afirmou existir" e "o que existe".

Artefatos **novos** propostos na reunião (`webhook_outbox`,
`webhook_dead_letter`, `src/worker.ts`, `src/modules/webhooks`,
`publishWebhookEvent`, headers `X-*`, códigos `WEBHOOK_*`) não entram nesta
tabela — não são ganchos com o código existente. Eles estão registrados como
decisões e requisitos em `02-transcricao.md`.

| ID | O que foi dito | Fala (literal) | Localização | Status |
|---|---|---|---|---|
| GAN-01 | Rota `GET /orders`, hoje usada pelos clientes em polling | "Hoje eles ficam batendo no GET /orders de tempos em tempos" | `[09:00] Marcos` | NÃO VERIFICADO |
| GAN-02 | Tabela/entidade `orders`, atualizada na mudança de status | "atualiza orders" | `[09:04] Bruno` | NÃO VERIFICADO |
| GAN-03 | Tabela `order_status_history`, alimentada na mesma transação | "insere na order_status_history" | `[09:04] Bruno` | NÃO VERIFICADO |
| GAN-04 | Campo `stock_quantity` dos produtos, decrementado na mesma transação | "decrementa stock_quantity dos produtos do pedido" | `[09:04] Bruno` | NÃO VERIFICADO |
| GAN-05 | Existe um "service de orders" onde o disparo entraria | "a gente dispara isso sincronamente no service de orders quando o status muda" | `[09:03] Larissa` | NÃO VERIFICADO |
| GAN-06 | Método `changeStatus` como ponto de integração crítico | "a alteração crítica é dentro do service de orders, no método changeStatus" | `[09:40] Bruno` | NÃO VERIFICADO |
| GAN-07 | Objeto/arquivo `order.service` que chamaria a nova função | "Aí o order.service chama isso." | `[09:41] Bruno` | NÃO VERIFICADO |
| GAN-08 | Transação atual do changeStatus faz update na order, insere no history e atualiza estoque | "Hoje a transação faz update na order, insere no history e atualiza estoque." | `[09:40] Bruno` | NÃO VERIFICADO |
| GAN-09 | Banco MySQL já existente, reaproveitado para a outbox | "Outbox no MySQL existente resolve." | `[09:07] Diego` | NÃO VERIFICADO |
| GAN-10 | MySQL não tem listener nativo tipo NOTIFY/LISTEN do Postgres | "MySQL não tem listener nativo tipo o NOTIFY/LISTEN do Postgres." | `[09:09] Diego` | NÃO VERIFICADO |
| GAN-11 | Suporte a trigger no banco já existe hoje | "Trigger no banco a gente até tem, mas ela não notifica processo externo" | `[09:09] Diego` | NÃO VERIFICADO |
| GAN-12 | Entry-point `src/server.ts` já existente, usada como modelo para a nova entry | "Tipo o que a gente já tem em src/server.ts" | `[09:11] Larissa` | NÃO VERIFICADO |
| GAN-13 | Prisma client já em uso, a ser reaproveitado pelo worker | "vai precisar conectar no mesmo banco e usar o mesmo Prisma client" | `[09:11] Bruno` | NÃO VERIFICADO |
| GAN-14 | Pool de conexão do Prisma já configurado no projeto | "o pool de conexão do Prisma já tá lá" | `[09:29] Diego` | NÃO VERIFICADO |
| GAN-15 | Variável `DATABASE_URL` compartilhada entre API e worker | "Mesmo banco, mesma DATABASE_URL, mas instância nova porque é outro processo Node." | `[09:30] Bruno` | NÃO VERIFICADO |
| GAN-16 | Padrão de módulos em `src/modules`, cada domínio com controller, service, repository, routes e schemas | "Cada domínio é um módulo em src/modules com controller, service, repository, routes e schemas." | `[09:27] Bruno` | NÃO VERIFICADO |
| GAN-17 | Classe `AppError` já existente | "Tem classe AppError" | `[09:28] Bruno` | NÃO VERIFICADO |
| GAN-18 | Classes de erro específicas `InsufficientStockError` e `InvalidStatusTransitionError` | "classes específicas tipo InsufficientStockError, InvalidStatusTransitionError" | `[09:28] Bruno` | NÃO VERIFICADO |
| GAN-19 | Convenção de códigos de erro `INSUFFICIENT_STOCK`, `INVALID_STATUS_TRANSITION` | "Todas usam código tipo INSUFFICIENT_STOCK, INVALID_STATUS_TRANSITION." | `[09:28] Bruno` | NÃO VERIFICADO |
| GAN-20 | Logger Pino já presente no projeto inteiro | "E o logger, que é Pino, já tá no projeto inteiro." | `[09:29] Bruno` | NÃO VERIFICADO |
| GAN-21 | Middleware de erro centralizado que já trata AppError, Zod e Prisma | "O middleware de erro centralizado já trata AppError, Zod e Prisma." | `[09:29] Bruno` | NÃO VERIFICADO |
| GAN-22 | Validação por schema Zod já é o padrão do projeto | "é só uma validação no schema Zod" | `[09:23] Sofia` | NÃO VERIFICADO |
| GAN-23 | Padrão de schemas Zod e de códigos de erro citados como reuso | "padrão de schemas Zod, padrão de códigos de erro." | `[09:30] Larissa` | NÃO VERIFICADO |
| GAN-24 | Autenticação por JWT do sistema, com usuários que representam o cliente | "autenticado com JWT do nosso sistema. A gente tem usuários que representam o cliente" | `[09:32] Marcos` | NÃO VERIFICADO |
| GAN-25 | JWT atual é do usuário operador, não do cliente | "o JWT atual é do usuário operador, não do cliente" | `[09:32] Bruno` | NÃO VERIFICADO |
| GAN-26 | Role `ADMIN` no JWT | "Tem que ser role ADMIN do JWT?" | `[09:35] Larissa` | NÃO VERIFICADO |
| GAN-27 | Helper `requireRole` já existente, a ser reaproveitado | "a gente reaproveita o requireRole que já existe" | `[09:36] Larissa` | NÃO VERIFICADO |
| GAN-28 | Rota `GET /orders/:id` para o cliente buscar detalhes do pedido | "ele bate no GET /orders/:id depois" | `[09:43] Diego` | NÃO VERIFICADO |
| GAN-29 | Campos `order_number` e `total_cents` da order | "order_id, order_number, from_status, to_status, customer_id" | `[09:43] Diego` | NÃO VERIFICADO |
| GAN-30 | Campo `total_cents` citado como campo básico da order | "os campos básicos da order tipo total_cents" | `[09:43] Diego` | NÃO VERIFICADO |
| GAN-31 | Status de pedido PAID, PROCESSING, SHIPPED | "Se o pedido X muda PAID, depois PROCESSING, depois SHIPPED em sequência rápida" | `[09:12] Larissa` | NÃO VERIFICADO |
| GAN-32 | Status de pedido SHIPPED e DELIVERED | "só quero saber quando vira SHIPPED e DELIVERED" | `[09:33] Marcos` | NÃO VERIFICADO |
| GAN-33 | Runtime Node, com processo separado implicando nova instância de client | "porque é outro processo Node" | `[09:30] Bruno` | NÃO VERIFICADO |
| GAN-34 | Padrão de id do projeto: tudo é uuid | "segue o padrão do resto do projeto. Tudo é uuid" | `[09:51] Larissa` | NÃO VERIFICADO |

**Total: 34 ganchos declarados, 34 com Status `NÃO VERIFICADO`.**
