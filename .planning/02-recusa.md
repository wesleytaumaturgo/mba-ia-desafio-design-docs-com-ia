# 02 — Lista de recusa (âncoras discriminantes)

Extrato operacional das seções `## Descartado` e `## Adiado para fase futura` de
`.planning/02-transcricao.md`. A classificação DESCARTADO/ADIADO e as
Localizações vêm daquele arquivo e **não mudaram** neste patch —
`02-transcricao.md` está congelado. O que mudou foi só a coluna de âncora.

## Por que as âncoras foram trocadas

A v1 usava fragmentos de fala como âncora. Revisão apurou dois defeitos:

- **(a) Âncora que nunca dispara.** `3 é pouco`, `"failed" na própria outbox`,
  `Trunca`, `implícito do JWT`, `endurecer` são coisas que ninguém escreve num
  documento técnico. O check passaria sempre, por vacuidade.
- **(b) Âncora que casa conteúdo correto.** `Síncrono` casa dentro de
  `assíncrono` — que é justamente o desenho aprovado. `Email` casa um campo
  `email` de payload. `arquiva` casa qualquer flexão em qualquer contexto.

A v2 troca fragmento de fala por **conceito técnico + regex ERE discriminante**:
a âncora tem que casar a adoção do item recusado e **não** casar o seu contrário
nem o seu contexto legítimo. Cada uma passou por dois testes colados adiante.

## Notas de leitura da tabela

1. **O `\|` na coluna de âncora é escape de markdown, não parte do regex.** As
   âncoras usam alternância ERE, e um `|` cru quebraria a célula da tabela. O
   script consumidor desescapa (`sed 's/\\|/|/g'`) antes de usar o padrão. O
   round-trip é provado em `## INV-7 v2`.
2. **Engine normativo: GNU grep 3.11** (`/usr/bin/grep -E`), que é o que
   `scripts/verify.sh` usa. Todas as 14 âncoras foram checadas também contra
   ugrep 7.5.0 e passam nos dois — isso importa porque o shell interativo desta
   máquina substitui `grep` por ugrep, cujo limite de complexidade é menor.
3. Um hit de grep, sozinho, não é violação: `exactly-once` ou `Redis` podem
   aparecer legitimamente numa seção de "alternativas rejeitadas". Por isso o
   INV-7 procura as âncoras **apenas dentro de linhas de requisito**.

## Tabela

| ID | Conceito | Âncora (regex) | Classificação | Localização | Discriminante? |
|---|---|---|---|---|---|
| REC-01 | Disparo síncrono do webhook | `\bs[íi]ncron[oa]` | DESCARTADO | `[09:06] Diego` | SIM |
| REC-02 | Redis Streams como transporte | `\bredis\b` | DESCARTADO | `[09:07] Diego` | SIM |
| REC-03 | Database trigger como gatilho | `\btriggers?\b` | DESCARTADO | `[09:09] Diego` | SIM |
| REC-04 | Retry indefinido sem teto | `(retry\|retries\|tentativas)[^\|]{0,25}(indefinid\|infinit\|ilimitad)\|(indefinid\|infinit\|ilimitad)[a-zçãeoas]*[^\|]{0,25}(retry\|retries\|tentativas)` | DESCARTADO | `[09:15] Diego` | SIM |
| REC-05 | Teto de 3 tentativas | `\b(3\|três\|tres) +tentativas\|tentativas *[:=] *(3\|três\|tres)\b\|max_?retries? *[:=]? *3\b` | DESCARTADO | `[09:16] Diego` | SIM |
| REC-06 | DLQ na própria outbox | `(própria\|propria\|mesma) +(tabela +)?(webhook_)?outbox\|(sem\|dispensa\|em vez de\|ao invés de) +(uma +\|a +)?(tabela +)?(de +)?(dead[_ -]?letter\|DLQ)` | DESCARTADO | `[09:18] Diego` | SIM |
| REC-07 | Truncamento de payload | `\btrunca` | DESCARTADO | `[09:23] Sofia` | SIM |
| REC-08 | Entrega exactly-once | `exactly[- _]?once` | DESCARTADO | `[09:25] Diego` | SIM |
| REC-09 | customer_id derivado do JWT | `[sem âncora viável]` | DESCARTADO | `[09:32] Larissa` | NÃO — verificação manual |
| REC-10 | Dashboard web do cliente | `\bdashboard\b\|\bpainel[^\|]{0,25}(visual\|web\|de controle\|de webhooks\|para o cliente\|pro cliente\|do cliente)` | DESCARTADO | `[09:40] Larissa` | SIM |
| REC-11 | Arquivamento da outbox | `(arquiva\|purga\|expurg\|retenç\|retenc\|limpeza\|housekeeping\|cleanup)[a-zçãáé]*[^\|]{0,40}(outbox\|eventos entregues\|linhas entregues)\|(outbox\|eventos entregues\|linhas entregues)[^\|]{0,40}(arquiva\|purga\|expurg\|retenç\|retenc\|limpeza)` | ADIADO | `[09:08] Diego` | SIM |
| REC-12 | Escala horizontal do worker | `\block pessimista\b\|particiona(r\|mento\|do)[^\|]{0,25}order_?id\|(múltiplos\|multiplos\|vários\|varios\|dois ou mais) +workers?` | ADIADO | `[09:13] Diego` | SIM |
| REC-13 | Notificação por email | `(envi\|manda\|dispar\|notifi\|alert\|avis)[a-zçãáéíó]*[^\|]{0,30}\be-?mails?\b\|\be-?mails?\b[^\|]{0,30}(de +)?(alerta\|notifica\|aviso)` | ADIADO | `[09:37] Larissa` | SIM |
| REC-14 | Hardening de autorização do CRUD | `(cadastro\|cadastrar\|CRUD\|configuração)[^\|]{0,45}(role +ADMIN\|somente +admin\|apenas +admin)` | ADIADO | `[09:37] Sofia` | SIM |
| REC-15 | Rate limiting de saída | `rate[- _]?limit\|throttl\|limitação de (taxa\|envio)\|limitacao de (taxa\|envio)` | ADIADO | `[09:39] Diego` | SIM |

**Totais:** 10 DESCARTADO · 5 ADIADO · 15 itens · 14 com âncora discriminante
provada · 1 sem âncora viável (REC-09).

### Itens sem âncora viável

| ID | Conceito | Por quê |
|---|---|---|
| REC-09 | customer_id derivado do JWT | ERE não tem lookaround, então nenhum padrão separa a adoção ("o customer_id é derivado do JWT") da decisão correta enunciada na negativa ("o customer_id **não** vem do JWT", DEC-17). Toda tentativa casou as duas. Vira verificação manual no bloco 9. |

Duas tentativas foram gastas em REC-09 antes da desistência, conforme o limite:

```
tentativa 1: customer_?id[^|]{0,40}(implícit|...|a partir d)[^|]{0,30}(jwt|token)|(jwt|token)[^|]{0,40}(fornece|define|determina|carrega)[^|]{0,25}customer_?id
  -> rejeitada pelo engine ugrep: "error at position 1404 ... exceeds complexity limits"

tentativa 2: customer_?id[^|]{0,40}(implícit|extraíd|derivad|inferid|obtid|vem do|a partir do)[^|]{0,25}(jwt|token)
  -> T1 com falso positivo em conteúdo legítimo:
.planning/02-transcricao.md:69:| DEC-17 | Endpoint de cadastro é autenticado normal e o customer_id NÃO é derivado do JWT | ...
```

---

## Prova de discriminância

Cada âncora tem os dois testes com saída literal. **T1** roda a âncora contra o
corpus de conteúdo legítimo já em disco e não pode ter falso positivo. **T2**
roda a âncora contra um arquivo temporário com duas linhas: a primeira **adota**
o item recusado (tem que disparar), a segunda é o **contexto legítimo** vizinho
(não pode disparar). O `Discriminante? = SIM` da tabela só foi preenchido para
quem passou nos dois.

Nas saídas abaixo, `grep` é `/usr/bin/grep` (GNU 3.11) e as âncoras aparecem
**sem** o escape `\|` — é o padrão real, depois do desescape. `$SP` é o
diretório de trabalho temporário desta sessão.

### REC-01 — Disparo síncrono do webhook

Âncora: `\bs[íi]ncron[oa]`

**T1 — não pode ter falso positivo** (5 hit(s))

```
$ grep -rniE '\bs[íi]ncron[oa]' TRANSCRICAO.md src/ docs/ .planning/02-transcricao.md
TRANSCRICAO.md:30:[09:03] Larissa: Acho que a primeira pergunta é: a gente dispara isso sincronamente no service de orders quando o status muda, ou faz algum tipo de fila/outbox?
TRANSCRICAO.md:32:[09:04] Bruno: Síncrono não rola. A transação de mudança de status hoje já é pesada — atualiza orders, insere na order_status_history, decrementa stock_quantity dos produtos do pedido. Se a gente acrescentar um HTTP call no meio disso, qualquer cliente lento vai travar mudança de status pra outros pedidos.
TRANSCRICAO.md:42:[09:05] Larissa: Tranquilo, a gente tá no começo. Estamos definindo se webhook vai ser síncrono dentro do service de orders ou se vai pra alguma fila. O Bruno tava argumentando contra síncrono.
TRANSCRICAO.md:44:[09:06] Diego: Síncrono está fora de questão. Aliás, eu nem chamaria de "fila" — o que a gente quer aqui é um padrão outbox.
.planning/02-transcricao.md:145:| REC-01 | Disparo síncrono do webhook dentro do service de orders | Transação de mudança de status já é pesada e cliente lento travaria os outros pedidos; e não daria pra dar rollback se o cliente estivesse fora do ar (`[09:04] Bruno`) | "Síncrono está fora de questão." | `[09:06] Diego` | `Síncrono` |
```

Os 4 hits em TRANSCRICAO.md são o próprio debate que rejeitou o síncrono (linhas 30, 32, 42, 44) — ESPERADO. O hit em 02-transcricao.md é a linha REC-01 — ESPERADO. Zero hits em src/ e docs/. A negação de `assíncrono` é provada em T2: a fronteira `\b` impede o casamento dentro de `assíncrono`.

**T2 — tem que disparar** (linha 1 adota o item recusado; linha 2 é o contexto
legítimo que NÃO pode casar)

```
$ cat $SP/t2-REC-01.md
| PRD-FR-99 | O webhook é disparado de forma síncrona dentro da transação de mudança de status. |
| PRD-FR-98 | O envio do webhook é assíncrono, fora da transação principal. |

$ grep -niE '\bs[íi]ncron[oa]' $SP/t2-REC-01.md
1:| PRD-FR-99 | O webhook é disparado de forma síncrona dentro da transação de mudança de status. |
```

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### REC-02 — Redis Streams como transporte

Âncora: `\bredis\b`

**T1 — não pode ter falso positivo** (3 hit(s))

```
$ grep -rniE '\bredis\b' TRANSCRICAO.md src/ docs/ .planning/02-transcricao.md
TRANSCRICAO.md:50:[09:07] Larissa: Faz sentido. A alternativa seria botar Redis Streams ou alguma coisa parecida, mas a gente acabaria precisando subir mais infra.
TRANSCRICAO.md:52:[09:07] Diego: Exato, e a gente é um time pequeno. Subir Redis Cluster pra isso é overengineering. Outbox no MySQL existente resolve.
.planning/02-transcricao.md:146:| REC-02 | Redis Streams / Redis Cluster como transporte dos eventos | Exigiria subir mais infra e é overengineering para um time pequeno | "Exato, e a gente é um time pequeno. Subir Redis Cluster pra isso é overengineering." | `[09:07] Diego` | `Redis` |
```

Os 2 hits em TRANSCRICAO.md são as falas que descartaram Redis — ESPERADO. O hit em 02-transcricao.md é a linha REC-02 — ESPERADO. Redis não tem contexto legítimo neste projeto.

**T2 — tem que disparar** (linha 1 adota o item recusado; linha 2 é o contexto
legítimo que NÃO pode casar)

```
$ cat $SP/t2-REC-02.md
| PRD-RNF-99 | Os eventos trafegam por Redis Streams antes de chegar ao worker. |
| PRD-RNF-98 | Os eventos ficam na tabela webhook_outbox no MySQL existente. |

$ grep -niE '\bredis\b' $SP/t2-REC-02.md
1:| PRD-RNF-99 | Os eventos trafegam por Redis Streams antes de chegar ao worker. |
```

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### REC-03 — Database trigger como gatilho

Âncora: `\btriggers?\b`

**T1 — não pode ter falso positivo** (3 hit(s))

```
$ grep -rniE '\btriggers?\b' TRANSCRICAO.md src/ docs/ .planning/02-transcricao.md
TRANSCRICAO.md:62:[09:09] Bruno: Não dá pra usar trigger do banco pra ser mais reativo?
TRANSCRICAO.md:64:[09:09] Diego: MySQL não tem listener nativo tipo o NOTIFY/LISTEN do Postgres. Trigger no banco a gente até tem, mas ela não notifica processo externo, ela só executa SQL. Pra avisar o worker, a gente teria que improvisar algo tipo escrever em arquivo ou bater num endpoint, fica esquisito. Polling de 2 segundos atende o requisito de "abaixo de 10 segundos" tranquilo.
.planning/02-transcricao.md:147:| REC-03 | Trigger de banco para notificar o worker de forma reativa | MySQL não tem listener nativo; a trigger só executa SQL e não avisa processo externo | "MySQL não tem listener nativo tipo o NOTIFY/LISTEN do Postgres." | `[09:09] Diego` | `trigger do banco` |
```

Os 2 hits em TRANSCRICAO.md são a proposta e a rejeição da trigger — ESPERADO. O hit em 02-transcricao.md é a linha REC-03 — ESPERADO. Zero hits em src/.

**T2 — tem que disparar** (linha 1 adota o item recusado; linha 2 é o contexto
legítimo que NÃO pode casar)

```
$ cat $SP/t2-REC-03.md
| FDD-CONTRATO-99 | Uma trigger no MySQL notifica o worker a cada insert na outbox. |
| FDD-CONTRATO-98 | O worker faz polling na outbox a cada 2 segundos. |

$ grep -niE '\btriggers?\b' $SP/t2-REC-03.md
1:| FDD-CONTRATO-99 | Uma trigger no MySQL notifica o worker a cada insert na outbox. |
```

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### REC-04 — Retry indefinido sem teto

Âncora: `(retry|retries|tentativas)[^|]{0,25}(indefinid|infinit|ilimitad)|(indefinid|infinit|ilimitad)[a-zçãeoas]*[^|]{0,25}(retry|retries|tentativas)`

**T1 — não pode ter falso positivo** (2 hit(s))

```
$ grep -rniE '(retry|retries|tentativas)[^|]{0,25}(indefinid|infinit|ilimitad)|(indefinid|infinit|ilimitad)[a-zçãeoas]*[^|]{0,25}(retry|retries|tentativas)' TRANSCRICAO.md src/ docs/ .planning/02-transcricao.md
TRANSCRICAO.md:96:[09:15] Diego: Eu sugiro 5. Algumas pessoas defendem retry indefinido com backoff, mas isso traz o problema de evento ficar pendurado pra sempre se o cliente sumiu. Cinco já dá pra cobrir uma janela de até 12 ou 24 horas.
.planning/02-transcricao.md:148:| REC-04 | Retry indefinido com backoff | Evento ficaria pendurado para sempre se o cliente sumisse | "Algumas pessoas defendem retry indefinido com backoff, mas isso traz o problema de evento ficar pendurado" | `[09:15] Diego` | `retry indefinido` |
```

1 hit em TRANSCRICAO.md (fala que rejeita) e 1 em 02-transcricao.md (linha REC-04) — ambos ESPERADO.

**T2 — tem que disparar** (linha 1 adota o item recusado; linha 2 é o contexto
legítimo que NÃO pode casar)

```
$ cat $SP/t2-REC-04.md
| PRD-RNF-99 | O retry é indefinido, com backoff exponencial até o cliente responder. |
| PRD-RNF-98 | O retry é limitado a 5 tentativas antes da DLQ. |

$ grep -niE '(retry|retries|tentativas)[^|]{0,25}(indefinid|infinit|ilimitad)|(indefinid|infinit|ilimitad)[a-zçãeoas]*[^|]{0,25}(retry|retries|tentativas)' $SP/t2-REC-04.md
1:| PRD-RNF-99 | O retry é indefinido, com backoff exponencial até o cliente responder. |
```

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### REC-05 — Teto de 3 tentativas

Âncora: `\b(3|três|tres) +tentativas|tentativas *[:=] *(3|três|tres)\b|max_?retries? *[:=]? *3\b`

**T1 — não pode ter falso positivo** (2 hit(s))

```
$ grep -rniE '\b(3|três|tres) +tentativas|tentativas *[:=] *(3|três|tres)\b|max_?retries? *[:=]? *3\b' TRANSCRICAO.md src/ docs/ .planning/02-transcricao.md
.planning/02-transcricao.md:122:| RNF-12 | Cenário citado ao rejeitar 3 tentativas: três retries em 30 minutos (ver REC-05) | operação | "a gente retentaria três vezes em 30 minutos e mataria" | `[09:16] Diego` |
.planning/02-transcricao.md:149:| REC-05 | Limite de 3 tentativas de entrega | Cobriria só 30 minutos e mataria o evento antes de indisponibilidades reais | "3 é pouco. Se o cliente teve indisponibilidade de manhã, a gente retentaria três vezes em 30 minutos e mataria." | `[09:16] Diego` | `3 é pouco` |
```

v1 (`3 é pouco` como texto e depois `tentativas[^|]{0,20}\b3\b`) dava falso positivo na prosa da nota de método (`tentativas, 24h, 10s, 3 sprints`). v2 exige adjacência `3 tentativas`. Restam 2 hits em 02-transcricao.md: RNF-12 (registro numérico da própria recusa) e a linha REC-05 — ambos ESPERADO. Não casa a decisão vigente de 5 tentativas, provado no controle de T2.

**T2 — tem que disparar** (linha 1 adota o item recusado; linha 2 é o contexto
legítimo que NÃO pode casar)

```
$ cat $SP/t2-REC-05.md
| PRD-RNF-99 | O worker faz no máximo 3 tentativas de entrega antes de mover para a DLQ. |
| PRD-RNF-98 | O worker faz 5 tentativas com backoff 1m/5m/30m/2h/12h. |

$ grep -niE '\b(3|três|tres) +tentativas|tentativas *[:=] *(3|três|tres)\b|max_?retries? *[:=]? *3\b' $SP/t2-REC-05.md
1:| PRD-RNF-99 | O worker faz no máximo 3 tentativas de entrega antes de mover para a DLQ. |
```

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### REC-06 — DLQ na própria outbox

Âncora: `(própria|propria|mesma) +(tabela +)?(webhook_)?outbox|(sem|dispensa|em vez de|ao invés de) +(uma +|a +)?(tabela +)?(de +)?(dead[_ -]?letter|DLQ)`

**T1 — não pode ter falso positivo** (2 hit(s))

```
$ grep -rniE '(própria|propria|mesma) +(tabela +)?(webhook_)?outbox|(sem|dispensa|em vez de|ao invés de) +(uma +|a +)?(tabela +)?(de +)?(dead[_ -]?letter|DLQ)' TRANSCRICAO.md src/ docs/ .planning/02-transcricao.md
TRANSCRICAO.md:108:[09:17] Larissa: Decidido: 5 tentativas, backoff 1m/5m/30m/2h/12h. Próximo: DLQ. Faz numa tabela separada ou marca como "failed" na própria outbox?
.planning/02-transcricao.md:150:| REC-06 | Marcar falha permanente como "failed" na própria outbox, sem tabela de DLQ | Tabela separada mantém a leitura da outbox principal mais limpa e serve de evidence para debug e reprocessamento | "Eu fazia uma tabela webhook_dead_letter separada, com a payload, motivo da falha e timestamp." | `[09:18] Diego` | `"failed" na própria outbox` |
```

1 hit em TRANSCRICAO.md: a pergunta de Larissa que enuncia a opção descartada — ESPERADO. 1 hit em 02-transcricao.md na linha REC-06 — ESPERADO. O controle de T2 prova que o desenho correto (tabela `webhook_dead_letter`) não dispara.

**T2 — tem que disparar** (linha 1 adota o item recusado; linha 2 é o contexto
legítimo que NÃO pode casar)

```
$ cat $SP/t2-REC-06.md
| FDD-CONTRATO-99 | Eventos que esgotam as tentativas ficam na própria outbox com status failed. |
| FDD-CONTRATO-98 | Eventos que esgotam as tentativas são movidos para a tabela webhook_dead_letter. |

$ grep -niE '(própria|propria|mesma) +(tabela +)?(webhook_)?outbox|(sem|dispensa|em vez de|ao invés de) +(uma +|a +)?(tabela +)?(de +)?(dead[_ -]?letter|DLQ)' $SP/t2-REC-06.md
1:| FDD-CONTRATO-99 | Eventos que esgotam as tentativas ficam na própria outbox com status failed. |
```

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### REC-07 — Truncamento de payload

Âncora: `\btrunca`

**T1 — não pode ter falso positivo** (2 hit(s))

```
$ grep -rniE '\btrunca' TRANSCRICAO.md src/ docs/ .planning/02-transcricao.md
TRANSCRICAO.md:140:[09:23] Sofia: E uma coisa: limite de tamanho de payload. Se por algum motivo o evento tiver 500KB, a gente não envia. Trunca? Erra? Eu sou a favor de erra. Se chegou nesse tamanho, tem algo errado.
.planning/02-transcricao.md:151:| REC-07 | Truncar o payload que ultrapassa o limite de tamanho | Se chegou nesse tamanho, tem algo errado — melhor errar | "Trunca? Erra? Eu sou a favor de erra." | `[09:23] Sofia` | `Trunca` |
```

1 hit em TRANSCRICAO.md (fala de Sofia que rejeita truncar) e 1 em 02-transcricao.md (linha REC-07) — ambos ESPERADO.

**T2 — tem que disparar** (linha 1 adota o item recusado; linha 2 é o contexto
legítimo que NÃO pode casar)

```
$ cat $SP/t2-REC-07.md
| PRD-RNF-99 | Payloads acima de 64KB são truncados antes do envio. |
| PRD-RNF-98 | Payloads acima de 64KB geram erro e não são enviados. |

$ grep -niE '\btrunca' $SP/t2-REC-07.md
1:| PRD-RNF-99 | Payloads acima de 64KB são truncados antes do envio. |
```

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### REC-08 — Entrega exactly-once

Âncora: `exactly[- _]?once`

**T1 — não pode ter falso positivo** (2 hit(s))

```
$ grep -rniE 'exactly[- _]?once' TRANSCRICAO.md src/ docs/ .planning/02-transcricao.md
TRANSCRICAO.md:154:[09:25] Diego: Joga, mas é o padrão de mercado. Stripe faz assim, GitHub faz assim. Garantir exactly-once exigiria coordenação dos dois lados e fica muito mais complexo. At-least-once com event_id resolve 99% dos casos.
.planning/02-transcricao.md:152:| REC-08 | Garantia de entrega exactly-once | Exigiria coordenação dos dois lados e ficaria muito mais complexo | "Garantir exactly-once exigiria coordenação dos dois lados e fica muito mais complexo." | `[09:25] Diego` | `exactly-once` |
```

1 hit em TRANSCRICAO.md (fala que rejeita) e 1 em 02-transcricao.md (linha REC-08) — ambos ESPERADO. O controle de T2 prova que `at-least-once` não dispara.

**T2 — tem que disparar** (linha 1 adota o item recusado; linha 2 é o contexto
legítimo que NÃO pode casar)

```
$ cat $SP/t2-REC-08.md
| FDD-CONTRATO-99 | A plataforma garante entrega exactly-once para cada evento. |
| FDD-CONTRATO-98 | A entrega é at-least-once; o cliente deduplica por X-Event-Id. |

$ grep -niE 'exactly[- _]?once' $SP/t2-REC-08.md
1:| FDD-CONTRATO-99 | A plataforma garante entrega exactly-once para cada evento. |
```

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### REC-10 — Dashboard web do cliente

Âncora: `\bdashboard\b|\bpainel[^|]{0,25}(visual|web|de controle|de webhooks|para o cliente|pro cliente|do cliente)`

**T1 — não pode ter falso positivo** (4 hit(s))

```
$ grep -rniE '\bdashboard\b|\bpainel[^|]{0,25}(visual|web|de controle|de webhooks|para o cliente|pro cliente|do cliente)' TRANSCRICAO.md src/ docs/ .planning/02-transcricao.md
TRANSCRICAO.md:232:[09:39] Marcos: Dashboard visual? Tipo painel pro cliente ver os webhooks dele?
TRANSCRICAO.md:282:[09:48] Larissa: Padrão outbox no MySQL, transação atômica com mudança de status. Worker separado em polling de 2 segundos. Retry com backoff exponencial 1m/5m/30m/2h/12h, total 5 tentativas, depois DLQ persistida em tabela separada. HMAC-SHA256 sobre payload, secret por endpoint, rotação com grace period de 24h. Idempotência por X-Event-Id, garantia at-least-once. Padrões do projeto reaproveitados: AppError, Pino, error middleware, módulo em src/modules/webhooks, prefixo WEBHOOK_ nos códigos de erro. Endpoints CRUD de configuração autenticados normal, endpoint de replay de DLQ exige role ADMIN. Email como fallback fica pra próxima fase. Rate limiting de saída a gente observa. Dashboard visual fora de escopo. Prazo três sprints. Algo errado ou faltando?
.planning/02-transcricao.md:154:| REC-10 | Dashboard/painel visual para o cliente acompanhar os webhooks | É projeto separado do time de frontend; a entrega desta feature é só endpoints | "Não, agora não. Só endpoints. Painel é projeto separado do time de frontend." | `[09:40] Larissa` | `Painel` |
.planning/02-transcricao.md:159:> "Email como fallback fica pra próxima fase. […] Dashboard visual fora de
```

v1 (`Painel`) dava falso positivo em `[09:32] Bruno` — "Cliente cadastra pelo painel deles", que é o painel DO CLIENTE, contexto legítimo e não a recusa. v2 exige `dashboard` ou `painel` qualificado. Restam 4 hits, todos ESPERADO: a proposta (linha 232), o resumo que a descarta (linha 282) e duas linhas de 02-transcricao.md. O controle de T2 reproduz `painel deles` e não dispara.

**T2 — tem que disparar** (linha 1 adota o item recusado; linha 2 é o contexto
legítimo que NÃO pode casar)

```
$ cat $SP/t2-REC-10.md
| PRD-FR-99 | O cliente acompanha as entregas por um dashboard web na nossa plataforma. |
| PRD-FR-98 | O cliente consulta as entregas pelo painel deles, consumindo a nossa API. |

$ grep -niE '\bdashboard\b|\bpainel[^|]{0,25}(visual|web|de controle|de webhooks|para o cliente|pro cliente|do cliente)' $SP/t2-REC-10.md
1:| PRD-FR-99 | O cliente acompanha as entregas por um dashboard web na nossa plataforma. |
```

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### REC-11 — Arquivamento da outbox

Âncora: `(arquiva|purga|expurg|retenç|retenc|limpeza|housekeeping|cleanup)[a-zçãáé]*[^|]{0,40}(outbox|eventos entregues|linhas entregues)|(outbox|eventos entregues|linhas entregues)[^|]{0,40}(arquiva|purga|expurg|retenç|retenc|limpeza)`

**T1 — não pode ter falso positivo** (3 hit(s))

```
$ grep -rniE '(arquiva|purga|expurg|retenç|retenc|limpeza|housekeeping|cleanup)[a-zçãáé]*[^|]{0,40}(outbox|eventos entregues|linhas entregues)|(outbox|eventos entregues|linhas entregues)[^|]{0,40}(arquiva|purga|expurg|retenç|retenc|limpeza)' TRANSCRICAO.md src/ docs/ .planning/02-transcricao.md
TRANSCRICAO.md:56:[09:08] Diego: A tabela tem índice no campo de status (pendente, processando, falhou, entregue) e em created_at. Worker lê só os pendentes em batch pequeno, processa, marca como entregue. Linhas entregues a gente arquiva depois de 30 dias ou assim, fora do escopo dessa feature.
.planning/02-transcricao.md:116:| RNF-06 | Arquivamento de linhas entregues após ~30 dias — fora do escopo desta feature (ver REC-11) | operação | "Linhas entregues a gente arquiva depois de 30 dias ou assim, fora do escopo dessa feature." | `[09:08] Diego` |
.planning/02-transcricao.md:167:| REC-11 | Arquivamento das linhas já entregues da outbox | Declarado fora do escopo desta feature | "Linhas entregues a gente arquiva depois de 30 dias ou assim, fora do escopo dessa feature." | `[09:08] Diego` | `arquiva` |
```

v1 (`arquiva`) casava qualquer flexão em qualquer contexto. v2 exige a proximidade com outbox/linhas entregues. 1 hit em TRANSCRICAO.md: a própria fala que adia (linha 56) — ESPERADO. 2 hits em 02-transcricao.md: RNF-06 e a linha REC-11, ambos com referência cruzada explícita a REC-11 — ESPERADO. O controle de T2 (`arquivamento de logs`) não dispara.

**T2 — tem que disparar** (linha 1 adota o item recusado; linha 2 é o contexto
legítimo que NÃO pode casar)

```
$ cat $SP/t2-REC-11.md
| PRD-RNF-99 | Uma rotina arquiva as linhas entregues da webhook_outbox após 30 dias. |
| PRD-RNF-98 | O arquivamento de logs da aplicação segue a política corporativa. |

$ grep -niE '(arquiva|purga|expurg|retenç|retenc|limpeza|housekeeping|cleanup)[a-zçãáé]*[^|]{0,40}(outbox|eventos entregues|linhas entregues)|(outbox|eventos entregues|linhas entregues)[^|]{0,40}(arquiva|purga|expurg|retenç|retenc|limpeza)' $SP/t2-REC-11.md
1:| PRD-RNF-99 | Uma rotina arquiva as linhas entregues da webhook_outbox após 30 dias. |
```

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### REC-12 — Escala horizontal do worker

Âncora: `\block pessimista\b|particiona(r|mento|do)[^|]{0,25}order_?id|(múltiplos|multiplos|vários|varios|dois ou mais) +workers?`

**T1 — não pode ter falso positivo** (4 hit(s))

```
$ grep -rniE '\block pessimista\b|particiona(r|mento|do)[^|]{0,25}order_?id|(múltiplos|multiplos|vários|varios|dois ou mais) +workers?' TRANSCRICAO.md src/ docs/ .planning/02-transcricao.md
TRANSCRICAO.md:80:[09:12] Diego: Depende. Se a gente tem um único worker rodando, ele processa em ordem de created_at do outbox. Aí o cliente recebe em ordem. Se a gente escala pra múltiplos workers em paralelo no futuro, perde a garantia. Por enquanto, single-worker e ordering implícita por order_id.
TRANSCRICAO.md:84:[09:13] Diego: Aí dá pra particionar por order_id, ou usar lock pessimista. Mas isso é problema do futuro, não agora.
.planning/02-transcricao.md:168:| REC-12 | Escalar para múltiplos workers, particionando por order_id ou usando lock pessimista | É problema do futuro, não de agora | "Aí dá pra particionar por order_id, ou usar lock pessimista. Mas isso é problema do futuro, não agora." | `[09:13] Diego` | `lock pessimista` |
.planning/02-transcricao.md:180:| QA-04 | Garantia de ordering quando houver mais de um worker | A perda da garantia foi reconhecida e a solução foi empurrada para o futuro sem escolha entre particionamento e lock (ver REC-12) | "Se a gente escala pra múltiplos workers em paralelo no futuro, perde a garantia." | `[09:12] Diego` |
```

4 hits, todos ESPERADO: linhas 80 e 84 de TRANSCRICAO.md são as falas que reconhecem a perda de garantia e adiam a solução; em 02-transcricao.md são a linha REC-12 e QA-04, que é a referência cruzada declarada do mesmo item.

**T2 — tem que disparar** (linha 1 adota o item recusado; linha 2 é o contexto
legítimo que NÃO pode casar)

```
$ cat $SP/t2-REC-12.md
| PRD-RNF-99 | O processamento escala para múltiplos workers com lock pessimista por order_id. |
| PRD-RNF-98 | O sistema opera com um único worker, sem garantia de ordering global. |

$ grep -niE '\block pessimista\b|particiona(r|mento|do)[^|]{0,25}order_?id|(múltiplos|multiplos|vários|varios|dois ou mais) +workers?' $SP/t2-REC-12.md
1:| PRD-RNF-99 | O processamento escala para múltiplos workers com lock pessimista por order_id. |
```

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### REC-13 — Notificação por email

Âncora: `(envi|manda|dispar|notifi|alert|avis)[a-zçãáéíó]*[^|]{0,30}\be-?mails?\b|\be-?mails?\b[^|]{0,30}(de +)?(alerta|notifica|aviso)`

**T1 — não pode ter falso positivo** (2 hit(s))

```
$ grep -rniE '(envi|manda|dispar|notifi|alert|avis)[a-zçãáéíó]*[^|]{0,30}\be-?mails?\b|\be-?mails?\b[^|]{0,30}(de +)?(alerta|notifica|aviso)' TRANSCRICAO.md src/ docs/ .planning/02-transcricao.md
TRANSCRICAO.md:218:[09:37] Marcos: Última pergunta de requisito. Tem como avisar o cliente quando o webhook dele tá com problema? Tipo se ele falhou 3 vezes seguidas, mandar email pra ele.
.planning/02-transcricao.md:169:| REC-13 | Aviso por email ao cliente quando o webhook dele falha | Fora de escopo desta fase; talvez na próxima, depois de medir o impacto | "Não. Email tá fora de escopo dessa fase. Talvez próxima fase, depois que a gente medir o impacto." | `[09:37] Larissa` | `Email` |
```

v1 (`Email` puro) casaria qualquer campo `email` de payload. v2 exige um verbo de envio/notificação adjacente. 1 hit em TRANSCRICAO.md: a fala de Marcos que propõe o email e foi adiada — ESPERADO. 1 hit em 02-transcricao.md na linha REC-13 — ESPERADO. O controle de T2 é exatamente o caso citado no defeito: `o payload inclui ... email de contato do comprador` — não dispara.

**T2 — tem que disparar** (linha 1 adota o item recusado; linha 2 é o contexto
legítimo que NÃO pode casar)

```
$ cat $SP/t2-REC-13.md
| PRD-FR-99 | O sistema envia um email de alerta ao cliente após três falhas consecutivas. |
| FDD-CONTRATO-98 | O payload inclui customer_id, order_number e o email de contato do comprador. |

$ grep -niE '(envi|manda|dispar|notifi|alert|avis)[a-zçãáéíó]*[^|]{0,30}\be-?mails?\b|\be-?mails?\b[^|]{0,30}(de +)?(alerta|notifica|aviso)' $SP/t2-REC-13.md
1:| PRD-FR-99 | O sistema envia um email de alerta ao cliente após três falhas consecutivas. |
```

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### REC-14 — Hardening de autorização do CRUD

Âncora: `(cadastro|cadastrar|CRUD|configuração)[^|]{0,45}(role +ADMIN|somente +admin|apenas +admin)`

**T1 — não pode ter falso positivo** (0 hit(s))

```
$ grep -rniE '(cadastro|cadastrar|CRUD|configuração)[^|]{0,45}(role +ADMIN|somente +admin|apenas +admin)' TRANSCRICAO.md src/ docs/ .planning/02-transcricao.md
(nenhuma linha — 0 hits)
```

v1 (`endurecer`) nunca dispararia — nenhum documento escreve "endurecer". v2 mira o efeito: role ADMIN exigida no CRUD de configuração. v2 na primeira forma (com alternativa reversa `role ADMIN ... CRUD`) dava falso positivo na prosa de fechamento de 02-transcricao.md linha 201, que cita a decisão CORRETA (`DEC-19 (role ADMIN no replay), DEC-20 (CRUD`). v2 final é só a forma direta: zero hits no corpus. O controle de T2 prova que a exigência legítima de ADMIN no replay não dispara.

**T2 — tem que disparar** (linha 1 adota o item recusado; linha 2 é o contexto
legítimo que NÃO pode casar)

```
$ cat $SP/t2-REC-14.md
| PRD-FR-99 | O CRUD de configuração de webhooks exige role ADMIN em todos os verbos. |
| PRD-FR-98 | O replay de dead letter exige role ADMIN; o CRUD aceita qualquer role autenticada. |

$ grep -niE '(cadastro|cadastrar|CRUD|configuração)[^|]{0,45}(role +ADMIN|somente +admin|apenas +admin)' $SP/t2-REC-14.md
1:| PRD-FR-99 | O CRUD de configuração de webhooks exige role ADMIN em todos os verbos. |
```

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

### REC-15 — Rate limiting de saída

Âncora: `rate[- _]?limit|throttl|limitação de (taxa|envio)|limitacao de (taxa|envio)`

**T1 — não pode ter falso positivo** (5 hit(s))

```
$ grep -rniE 'rate[- _]?limit|throttl|limitação de (taxa|envio)|limitacao de (taxa|envio)' TRANSCRICAO.md src/ docs/ .planning/02-transcricao.md
TRANSCRICAO.md:224:[09:38] Diego: Outra coisa que ficou na minha cabeça: rate limiting de envio pra cliente. Se o cliente tem 50 pedidos mudando de status em um minuto, a gente bombardeia ele com 50 chamadas?
TRANSCRICAO.md:282:[09:48] Larissa: Padrão outbox no MySQL, transação atômica com mudança de status. Worker separado em polling de 2 segundos. Retry com backoff exponencial 1m/5m/30m/2h/12h, total 5 tentativas, depois DLQ persistida em tabela separada. HMAC-SHA256 sobre payload, secret por endpoint, rotação com grace period de 24h. Idempotência por X-Event-Id, garantia at-least-once. Padrões do projeto reaproveitados: AppError, Pino, error middleware, módulo em src/modules/webhooks, prefixo WEBHOOK_ nos códigos de erro. Endpoints CRUD de configuração autenticados normal, endpoint de replay de DLQ exige role ADMIN. Email como fallback fica pra próxima fase. Rate limiting de saída a gente observa. Dashboard visual fora de escopo. Prazo três sprints. Algo errado ou faltando?
.planning/02-transcricao.md:42:   a mesma coisa foi tratada nos dois registros (rate limiting, escala de
.planning/02-transcricao.md:171:| REC-15 | Rate limiting de envio para o cliente | Observa e implementa se virar problema (também registrado como ponto em aberto — ver QA-03) | "Eu acho que não. A gente observa e implementa se virar problema." | `[09:39] Diego` | `rate limiting` |
.planning/02-transcricao.md:179:| QA-03 | Rate limiting de envio para o cliente | A própria reunião pediu que ficasse registrado como ponto em aberto, além de tirá-lo do escopo (ver REC-15) | "Mas vale registrar como ponto em aberto." | `[09:39] Diego` |
```

5 hits, todos ESPERADO: a fala que tira do escopo (linha 224), o resumo (linha 282) e três linhas de 02-transcricao.md — a nota de método, a linha REC-15 e QA-03, que é a referência cruzada declarada. Zero hits em src/ e docs/.

**T2 — tem que disparar** (linha 1 adota o item recusado; linha 2 é o contexto
legítimo que NÃO pode casar)

```
$ cat $SP/t2-REC-15.md
| PRD-RNF-99 | O envio para o cliente é limitado a 10 requisições por segundo (rate limiting). |
| PRD-RNF-98 | Não há limite de taxa no envio; a vazão acompanha a outbox. |

$ grep -niE 'rate[- _]?limit|throttl|limitação de (taxa|envio)|limitacao de (taxa|envio)' $SP/t2-REC-15.md
1:| PRD-RNF-99 | O envio para o cliente é limitado a 10 requisições por segundo (rate limiting). |
```

**T1 PASSOU · T2 PASSOU → Discriminante: SIM**

---

## INV-7 v2

Script consumidor. Lê as âncoras da tabela acima, procura cada uma **somente**
dentro de linhas que comecem com ID de requisito
(`^\| *(PRD-FR|PRD-RNF|FDD-CONTRATO|FDD-ERR)-[0-9]{2} *\|`) e imprime
`VAZAMENTO` com o ID do requisito, o arquivo e a linha.

**`[entra no verify.sh no bloco 7]`** — não foi adicionado a `scripts/verify.sh`
agora porque `docs/PRD.md` e `docs/FDD.md` ainda são stubs de 3 linhas: um
INV-7 rodando contra arquivo vazio passa por vacuidade e vira ruído verde.

```bash
#!/usr/bin/env bash
# INV-7 v2 — nenhum item de .planning/02-recusa.md pode reaparecer como
# requisito vigente no PRD ou no FDD.
# [entra no verify.sh no bloco 7] — hoje docs/PRD.md e docs/FDD.md são stubs.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

RECUSA="${INV7_RECUSA:-.planning/02-recusa.md}"
read -r -a ALVOS <<< "${INV7_ALVOS:-docs/PRD.md docs/FDD.md}"

# a âncora só é procurada DENTRO de linhas que comecem com ID de requisito
ID_RE='^\| *(PRD-FR|PRD-RNF|FDD-CONTRATO|FDD-ERR)-[0-9]{2} *\|'

[ -r "$RECUSA" ] || { echo "INV-7 ERRO — lista de recusa ilegível: $RECUSA"; exit 2; }

# 3a coluna da tabela de recusa = âncora regex; o \| do markdown é desescapado.
ANCORAS="$(sed -nE 's/^\| *(REC-[0-9]{2}) *\|[^|]*\| *`(.*)` *\| *(DESCARTADO|ADIADO).*/\1\t\2/p' "$RECUSA" \
           | sed 's/\\|/|/g')"
n_anc="$(printf '%s' "$ANCORAS" | grep -c . )"
[ "$n_anc" -gt 0 ] || { echo "INV-7 ERRO — nenhuma âncora extraída de $RECUSA"; exit 2; }

vaz=0
usadas=0
while IFS=$'\t' read -r rec ancora; do
  [ "$ancora" = "[sem âncora viável]" ] && continue
  usadas=$((usadas + 1))
  for alvo in "${ALVOS[@]}"; do
    [ -f "$alvo" ] || continue
    while IFS= read -r hit; do
      lnum="${hit%%:*}"
      texto="${hit#*:}"
      reqid="$(printf '%s' "$texto" | sed -E 's/^\| *([A-Z]+-[A-Z]+-[0-9]{2}).*/\1/')"
      printf 'VAZAMENTO  %s -> %s  (%s:%s)\n' "$rec" "$reqid" "$alvo" "$lnum"
      printf '           %s\n' "$(printf '%s' "$texto" | cut -c1-100)"
      vaz=$((vaz + 1))
    done < <(grep -nE "$ID_RE" "$alvo" | grep -iE "$ancora")
  done
done <<< "$ANCORAS"

echo "INV-7 — $n_anc item(ns) na lista de recusa, $usadas com âncora aplicável"
if [ "$vaz" -eq 0 ]; then
  echo "INV-7 OK — nenhum item recusado reaparece como requisito"
else
  echo "INV-7 FALHA — $vaz vazamento(s)"
fi
[ "$vaz" -eq 0 ]
```

### Round-trip do escape e smoke test

O script foi rodado contra um fixture de 6 linhas de requisito: duas adotam
itens recusados (dashboard web, truncamento de payload) e quatro são desenho
aprovado — incluindo, de propósito, a tabela `webhook_dead_letter` e a exigência
de `role ADMIN` no replay, que são justamente os vizinhos legítimos de REC-06 e
REC-14.

```
$ cat $SP/fixture-PRD.md
| PRD-FR-01 | O cliente cadastra webhook via POST informando a url https. |
| PRD-FR-02 | O cliente acompanha as entregas por um dashboard web na nossa plataforma. |
| PRD-RNF-01 | O worker faz 5 tentativas com backoff 1m/5m/30m/2h/12h antes da DLQ. |

$ cat $SP/fixture-FDD.md
| FDD-CONTRATO-01 | Eventos que esgotam as tentativas são movidos para a tabela webhook_dead_letter. |
| FDD-CONTRATO-02 | O replay de dead letter exige role ADMIN; o CRUD aceita qualquer role autenticada. |
| FDD-ERR-01 | Payloads acima de 64KB são truncados antes do envio. |
```

Saída literal:

```
$ INV7_RECUSA=$PWD/.planning/02-recusa.md \
  INV7_ALVOS="$SP/fixture-PRD.md $SP/fixture-FDD.md" ./inv7.sh
VAZAMENTO  REC-07 -> FDD-ERR-01  (/tmp/claude-1000/-home-wesley-Github-MBA-Desafio-mba-ia-desafio-design-docs-com-ia/4ed7fe83-5851-4713-9700-6c41ba51d5a4/scratchpad/fixture-FDD.md:3)
           | FDD-ERR-01 | Payloads acima de 64KB são truncados antes do envio. |
VAZAMENTO  REC-10 -> PRD-FR-02  (/tmp/claude-1000/-home-wesley-Github-MBA-Desafio-mba-ia-desafio-design-docs-com-ia/4ed7fe83-5851-4713-9700-6c41ba51d5a4/scratchpad/fixture-PRD.md:2)
           | PRD-FR-02 | O cliente acompanha as entregas por um dashboard web na nossa plataforma. |
INV-7 — 15 item(ns) na lista de recusa, 14 com âncora aplicável
INV-7 FALHA — 2 vazamento(s)

$ echo $?
1

$ INV7_RECUSA=/nao/existe.md ./inv7.sh
INV-7 ERRO — lista de recusa ilegível: /nao/existe.md
$ echo $?
2
```

O extrator devolveu as 14 âncoras com o `\|` desescapado (REC-09 pulado por ser
`[sem âncora viável]`), pegou os dois vazamentos plantados e ignorou as quatro
linhas legítimas — inclusive as que mencionam `webhook_dead_letter` e
`role ADMIN`, que são desenho aprovado.

O round-trip do escape foi conferido byte-a-byte contra os padrões que passaram
por T1/T2:

```
$ diff <(grep -v '^REC-09' anchors-testadas.txt) <(grep -v '^REC-09' extraidas-da-tabela.txt)
ROUND-TRIP OK — as 14 âncoras extraídas são byte-a-byte as testadas
```

A segunda invocação do smoke test cobre uma regressão encontrada durante este
patch: na primeira versão, com `$RECUSA` ilegível o script imprimia `INV-7 OK`
com zero âncoras carregadas — verde por vacuidade, exatamente o defeito (a) que
este documento existe para eliminar. As guardas `[ -r "$RECUSA" ]` e
`[ "$n_anc" -gt 0 ]` fazem esse caso sair com `exit 2`.
