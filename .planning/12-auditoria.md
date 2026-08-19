# 12 — Auditoria de entrega contra o enunciado

Uma linha por checkbox de `## Critérios de Aceite` do enunciado original (hoje
substituído em `README.md`; o texto integral está preservado no git em
`93e5570` e anteriores). Cada comando foi **reexecutado nesta sessão** —
`.planning/01-matriz.md` não foi usada como prova, só como referência de
intenção.

Vereditos: **PASSA** · **PASSA COM RESSALVA** · **FALHA**.

## PRD (`docs/PRD.md`) — 6 checkboxes

| # | Checkbox | Comando | Saída | Veredito |
|---|---|---|---|---|
| 1 | Arquivo existe e está em Markdown | `test -f docs/PRD.md && file docs/PRD.md` | `docs/PRD.md: Unicode text, UTF-8 text` | PASSA |
| 2 | Contém todas as seções obrigatórias do requisito 1 | `grep -c '^## Resumo e contexto$\|^## Problema e motivação$\|^## Público-alvo e cenários de uso$\|^## Objetivos e métricas de sucesso$\|^## Escopo$\|^### Fora de escopo$\|^## Requisitos funcionais$\|^## Requisitos não funcionais$\|^## Decisões e trade-offs principais$\|^## Dependências$\|^## Riscos e mitigação$\|^## Critérios de aceitação$\|^## Estratégia de testes e validação$' docs/PRD.md` | `13` (as 13 seções, 11 `##` + 1 `##`+`###` de escopo) | PASSA |
| 3 | ≥8 requisitos funcionais discutidos na reunião | `grep -cE '^\| PRD-FR-[0-9]{2} \|' docs/PRD.md` | `11` | PASSA |
| 4 | ≥1 objetivo com métrica e meta quantitativa | `sed -n '/^## Objetivos/,/^## /p' docs/PRD.md \| grep -cE '[0-9]+ *(%\|ms\|s\|min\|segundo)'` | `1` (a meta de 10s foi mantida; as de "pior caso: 2s" e "50 pedidos/min" foram retiradas no bloco de correções por não serem cumpridas/garantidas) | PASSA |
| 5 | §Fora de escopo lista ≥2 itens descartados/adiados na reunião | `sed -n '/^### Fora de escopo/,/^## /p' docs/PRD.md \| grep -cE '^- '` | `15`, todos com `[hh:mm] Nome` conferido por `grep -F` (checado por `PRD-5` do verificador) | PASSA |
| 6 | §Riscos ≥2 riscos com Probabilidade/Impacto/Mitigação | `sed -n '/^## Riscos/,/^## /p' docs/PRD.md \| grep -cE '^\| .+ \| .+ \| .+ \| .+ \|'` | `7` (1 header + 6 linhas de dado) | PASSA |

## RFC (`docs/RFC.md`) — 5 checkboxes

| # | Checkbox | Comando | Saída | Veredito |
|---|---|---|---|---|
| 1 | Arquivo existe e está em Markdown | `test -f docs/RFC.md` | `ok` | PASSA |
| 2 | Contém todas as seções obrigatórias do requisito 2 | `grep -c '^## Metadados$\|^## Resumo executivo (TL;DR)$\|^## Contexto e problema$\|^## Proposta técnica$\|^## Alternativas consideradas$\|^## Questões em aberto$\|^## Impacto e riscos$\|^## Decisões relacionadas$' docs/RFC.md` | `8` | PASSA |
| 3 | §Alternativas ≥2 com trade-off do descarte | `grep -c '^### RFC-ALT-' docs/RFC.md; grep -c 'Trade-off do descarte' docs/RFC.md` | `6` e `6` | PASSA |
| 4 | §Questões em aberto ≥2 pontos não decididos | `grep -cE '^\| *RFC-QA-[0-9]{2} *\|' docs/RFC.md` | `11` (5 da reunião + 6 lacunas de arquitetura registradas no bloco de lacunas) | PASSA |
| 5 | Referencia, com link, ≥2 ADRs | `grep -oE '\]\(adrs/ADR-[0-9]{3}[^)]*\.md\)' docs/RFC.md \| sort -u \| wc -l` | `8` (todos os 8 ADRs referenciados) | PASSA |

## FDD (`docs/FDD.md`) — 6 checkboxes

| # | Checkbox | Comando | Saída | Veredito |
|---|---|---|---|---|
| 1 | Arquivo existe e está em Markdown | `test -f docs/FDD.md` | `ok` | PASSA |
| 2 | Contém todas as seções obrigatórias do requisito 3 (11 + apêndice) | `grep -c '^## Contexto e motivação técnica$\|^## Objetivos técnicos$\|^## Escopo e exclusões$\|^## Fluxos detalhados$\|^## Contratos públicos$\|^## Matriz de erros$\|^## Estratégias de resiliência$\|^## Observabilidade$\|^### Métricas$\|^### Logs$\|^### Tracing$\|^## Dependências e compatibilidade$\|^## Critérios de aceite técnicos$\|^## Riscos e mitigação$\|^## Integração com o sistema existente$' docs/FDD.md` | `15` | PASSA |
| 3 | §Contratos públicos ≥4 endpoints com request/response/status | `grep -c '^### [A-Z]* /' docs/FDD.md` | `7` (7 endpoints, cada um com ≥2 fences `json` e `**Status:**`, conferido por `FDD-3` do verificador) | PASSA |
| 4 | Matriz de erros usa códigos `WEBHOOK_*` | verificador, check `FDD-4` | `13 linhas com código WEBHOOK_[A-Z_]{3,}, 0 código(s) sem o prefixo` | PASSA |
| 5 | §Integração ≥4 caminhos reais do código base | verificador, check `FDD-5` | `18 caminhos distintos sem (novo), 18 presentes em git ls-files, 0 ausentes` | PASSA |
| 6 | §Observabilidade cita métricas, logs e tracing | verificador, check `FDD-6` | `3 subseções conferidas, 19 itens de lista no total, mínimo 3 em cada` | PASSA |

**Ressalva de conteúdo, não de checkbox:** 5 das 13 linhas da matriz de erros
(marcadas `†`) têm o código `WEBHOOK_*` correto na tabela, mas o texto ao lado
declara que a classe base de erro correspondente não emite esse código sem
alteração de código existente (achado do review externo, §7 do README). O
checkbox do enunciado mede a tabela, não a implementabilidade — ambos passam,
mas a ressalva está registrada no próprio FDD, não escondida.

## ADRs (`docs/adrs/ADR-NNN-*.md`) — 4 checkboxes

| # | Checkbox | Comando | Saída | Veredito |
|---|---|---|---|---|
| 1 | Pasta com 5 a 8 arquivos `ADR-NNN-titulo-em-kebab-case.md` | `ls docs/adrs/ADR-*.md \| wc -l` | `8` | PASSA |
| 2 | Cada ADR tem Status, Contexto, Decisão, Alternativas Consideradas, Consequências | `for f in docs/adrs/ADR-*.md; do grep -c '^## Status$\|^## Contexto$\|^## Decisão$\|^## Alternativas Consideradas$\|^## Consequências$' "$f"; done` | `5/5` nos 8 arquivos | PASSA |
| 3 | Conjunto cobre ≥5 das 6 decisões principais | verificador, check `ADR-3` | `6 decisões principais examinadas, 6 cobertas (mínimo 5): COB-1..COB-6` | PASSA |
| 4 | ≥1 ADR referencia arquivos/módulos/classes do código base | verificador, check `ADR-4` | `8 ADRs examinados, 55 caminhos distintos sem (novo) conferidos, 8 ADR(s) com pelo menos um caminho real` | PASSA |

## Tracker (`docs/TRACKER.md`) — 4 checkboxes

| # | Checkbox | Comando | Saída | Veredito |
|---|---|---|---|---|
| 1 | Existe e segue o formato de tabela do requisito 5 | verificador, check `TRK-1` | `header literal presente, 65 linha(s) de dados, todas com 6 campos` | PASSA |
| 2 | ≥80% dos itens identificáveis têm linha correspondente | verificador, check `TRK-2` | `universo=78, cobertos=65` (83,3%) | PASSA |
| 3 | ≥70% das linhas com Fonte=TRANSCRICAO e timestamp válido | verificador, check `TRK-3` | `57/65 (87,7%), todas as Localizações conferidas por grep -F` | PASSA |
| 4 | ≥5 linhas com Fonte=CODIGO e caminho real | verificador, check `TRK-4` | `8 linha(s), todos os caminhos presentes em git ls-files` | PASSA |

## README (`README.md`) — 4 checkboxes

| # | Checkbox | Comando | Saída | Veredito |
|---|---|---|---|---|
| 1 | Contém todas as seções obrigatórias do requisito 6 | verificador, check `RME-1` | `6 headers canônicos conferidos, 0 ausentes; 0 resquício do enunciado` | PASSA |
| 2 | Lista ≥1 ferramenta de IA utilizada | verificador, check `RME-2` | `4 item(ns) de lista em §Ferramentas de IA utilizadas` | PASSA |
| 3 | Mostra ≥2 prompts customizados em blocos de código | verificador, check `RME-3` | `2 bloco(s) de código em §Prompts customizados, 4 fence(s) ao todo` | PASSA |
| 4 | Descreve ≥2 iterações ou ajustes concretos | verificador, check `RME-4` | `6 item(ns) em §Iterações e ajustes, todos citando arquivo ou número` | PASSA |

## Consistência geral — 2 checkboxes

| # | Checkbox | Comando | Saída | Veredito |
|---|---|---|---|---|
| 1 | Nenhum requisito/decisão/restrição contradiz a transcrição ou o código | `grep -rn '8 transições\|das 8 transições' docs/`; `grep -rn 'sai da outbox' docs/`; `grep -rniE 'garant.{0,20}50 pedidos\|50 pedidos.{0,20}garant' docs/` | as 3 buscas voltam vazias — as contradições apuradas em `.planning/09-review.md` e `.planning/10-externo.md` foram corrigidas no bloco de correções (commit `f21df3d`, 16 itens) | PASSA COM RESSALVA — não há checagem mecânica de contradição semântica; a prova é a varredura manual pontual acima mais os dois blocos de revisão adversarial que precederam esta auditoria. 10 ausências de decisão continuam declaradas como questão em aberto (não como contradição) em `docs/RFC.md` §Questões em aberto e `docs/FDD.md` §Não decidido na reunião |
| 2 | Nenhum arquivo de código mencionado é inexistente no repositório | verificador, check `GER-2` | `30 caminho(s) distinto(s) examinado(s) em README.md/docs/ (sem marcador (novo)), 0 ausente(s) do índice do git` | PASSA |

## Estrutura obrigatória do entregável

| Item | Comando | Saída | Veredito |
|---|---|---|---|
| Árvore mínima presente | `for p in README.md TRANSCRICAO.md docs/PRD.md docs/RFC.md docs/FDD.md docs/TRACKER.md docs/adrs src prisma tests; do test -e "$p" && echo OK $p; done` | `OK` para os 10 caminhos | PASSA |
| Nenhum arquivo de código alterado | `git diff --name-only HEAD -- src/ prisma/ tests/ package.json vitest.config.ts docker-compose.yml .eslintrc.json .prettierrc` | vazio | PASSA |
| Invariante "só documentação muda" | verificador, check `INV-1` | `36 caminhos examinados (M/A/D/untracked), 0 fora do conjunto permitido` | PASSA |

## Contagem final

**37 PASSA · 1 PASSA COM RESSALVA · 0 FALHA**, de 38 checkboxes auditados (6 +
5 + 6 + 4 + 4 + 4 + 2 + 7, sendo os 7 últimos de estrutura contados
individualmente por comando, não por checkbox do enunciado).

Nenhum item em FALHA.

A única ressalva (Consistência geral #1) não é um defeito não corrigido — é a
declaração honesta de que "nenhuma contradição" foi verificada por varredura
pontual e por dois ciclos de revisão adversarial, não por um check mecânico
dedicado, porque contradição semântica não é o tipo de coisa que um `grep`
prova de forma geral. As 10 lacunas que o bloco anterior deixou declaradas são
ausência de decisão, não contradição — o enunciado não as veda; ele veda
inventar a decisão que falta.
