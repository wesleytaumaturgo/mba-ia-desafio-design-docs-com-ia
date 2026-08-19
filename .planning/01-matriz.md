# 01 — Matriz de aceite

Todo texto de critério abaixo é citação literal de `README.md` (o enunciado),
lido nesta sessão. Nenhum critério "arquivo existe" é tratado como suficiente
sozinho — ver "Decisões normativas" e a nota de cada ID marcado com ⚠.

| ID | Critério (texto do enunciado) | Comando que prova | Evidência em | Bloco |
| --- | --- | --- | --- | --- |
| RA-1 | "A restrição de não alterar o código da aplicação é absoluta: o código serve de contexto e referência" — implementado por **lista de PERMISSÃO**: só `README.md`, `docs/**`, `.planning/**` e `scripts/**` podem divergir de `$BASE`; qualquer outro caminho modificado (M), criado (A), removido (D) ou untracked é violação | `git diff --name-status $BASE -- .` **e** `git ls-files --others --exclude-standard`: nenhum caminho fora do conjunto permitido + `sha256sum TRANSCRICAO.md` == hash em `$BASE` | `scripts/verify.sh` INV-1 + INV-2 | **2 (hoje)** |
| RA-2 | "Toda informação registrada nos documentos deve ser rastreável à transcrição ou ao código fonte da aplicação. Não é permitido inventar requisitos, decisões ou restrições sem origem identificável." | cruzamento: todo ID citado em PRD/RFC/FDD/ADR aparece como linha em TRACKER.md com Fonte + Localização válida | `scripts/verify.sh` (checagem cruzada Tracker × demais docs, a implementar) | 10 (reforçado continuamente pelo Bloco 8) |
| PRD-1 ⚠ | "Arquivo existe e está em Markdown" | `test -f docs/PRD.md` **e** `wc -w docs/PRD.md` ≥ 120 **e** zero ocorrências de `<!--.*(a ser elaborado\|será preenchido).*-->` | `scripts/verify.sh` (a estender) | 7 |
| PRD-2 | "Contém todas as seções obrigatórias listadas no requisito 1" (12 seções: Resumo e contexto · Problema e motivação · Público-alvo e cenários de uso · Objetivos e métricas de sucesso · Escopo · Requisitos funcionais · Requisitos não funcionais · Decisões e trade-offs principais · Dependências · Riscos e mitigação · Critérios de aceitação · Estratégia de testes e validação) | `grep -qi '^## '"<título>"'' docs/PRD.md` para cada uma das 12 | `scripts/verify.sh` (a estender) | 7 |
| PRD-3 | "Identifica no mínimo 8 requisitos funcionais discutidos na reunião" | `grep -coE 'PRD-FR-[0-9]+' docs/PRD.md` ≥ 8 | `scripts/verify.sh` (a estender) | 7 |
| PRD-4 | "Inclui pelo menos 1 objetivo com métrica e meta quantitativa" | seção "Objetivos e métricas de sucesso" contém ao menos 1 padrão numérico com unidade (`%`, `ms`, `s`, `min`, `dias`) | `scripts/verify.sh` (a estender) | 7 |
| PRD-5 | Seção "Fora de escopo" lista pelo menos 2 itens explicitamente descartados ou adiados na reunião | contagem de itens de lista (`^- `) sob o heading "Fora de escopo" ≥ 2 | `scripts/verify.sh` (a estender) | 7 |
| PRD-6 | Seção "Riscos" inclui pelo menos 2 riscos com probabilidade, impacto e mitigação | contagem de blocos/linhas de risco com os 3 campos preenchidos ≥ 2 | `scripts/verify.sh` (a estender) | 7 |
| RFC-1 ⚠ | "Arquivo existe e está em Markdown" | `test -f docs/RFC.md` **e** `wc -w docs/RFC.md` ≥ 120 **e** zero placeholders | `scripts/verify.sh` (a estender) | 5 |
| RFC-2 | "Contém todas as seções obrigatórias listadas no requisito 2" (8 seções: Metadados · Resumo executivo · Contexto e problema · Proposta técnica · Alternativas consideradas · Questões em aberto · Impacto e riscos · Decisões relacionadas) | `grep -qi` para cada uma das 8 | `scripts/verify.sh` (a estender) | 5 |
| RFC-3 | Seção "Alternativas consideradas" lista pelo menos 2 alternativas descartadas na reunião, cada uma com o trade-off que motivou o descarte | `grep -coE 'RFC-ALT-[0-9]+' docs/RFC.md` ≥ 2, cada bloco contém a palavra "trade-off" | `scripts/verify.sh` (a estender) | 5 |
| RFC-4 | Seção "Questões em aberto" lista pelo menos 2 pontos adiados ou não decididos na reunião | `grep -coE 'RFC-QA-[0-9]+' docs/RFC.md` ≥ 2 | `scripts/verify.sh` (a estender) | 5 |
| RFC-5 | Referencia, com link, pelo menos 2 ADRs do pacote | `grep -coE '\[[^]]*\]\([^)]*ADR-[0-9]{3}[^)]*\.md\)' docs/RFC.md` ≥ 2 | `scripts/verify.sh` (a estender) | 5 |
| RFC-6 (novo) | "É um documento conciso (2 a 4 páginas); o detalhamento de implementação fica no FDD" / "O RFC não deve duplicar o detalhamento do FDD" | `wc -w docs/RFC.md` ≤ 2400 (teto de concisão, ver justificativa abaixo) | `scripts/verify.sh` (a estender) | 5 |
| FDD-1 ⚠ | "Arquivo existe e está em Markdown" | `test -f docs/FDD.md` **e** `wc -w docs/FDD.md` ≥ 120 **e** zero placeholders | `scripts/verify.sh` (a estender) | 6 |
| FDD-2 | "Contém todas as seções obrigatórias listadas no requisito 3" (11 seções + a seção obrigatória adicional "Integração com o sistema existente" = 12) | `grep -qi` para cada uma das 12 | `scripts/verify.sh` (a estender) | 6 |
| FDD-3 | Seção "Contratos públicos" inclui pelo menos 4 endpoints HTTP com payload de exemplo (request e response) e status codes | `grep -coE 'FDD-CONTRATO-[0-9]+' docs/FDD.md` ≥ 4, cada bloco contém "request", "response" e um código HTTP de 3 dígitos | `scripts/verify.sh` (a estender) | 6 |
| FDD-4 | "Matriz de erros usa códigos com prefixo `WEBHOOK_`" | `grep -coE 'WEBHOOK_[A-Z_]+' docs/FDD.md` ≥ 1 na seção de matriz de erros | `scripts/verify.sh` (a estender) | 6 |
| FDD-5 | Seção "Integração com o sistema existente" referencia pelo menos 4 caminhos de arquivo reais do código base | extrair caminhos citados na seção e cruzar contra `.planning/00-inventario-paths.txt`; interseção ≥ 4 | `scripts/verify.sh` (a estender) | 6 |
| FDD-6 | Seção "Observabilidade" cita métricas, logs e tracing | `grep -qi 'métric'` **e** `grep -qi 'log'` **e** `grep -qi 'trac'` dentro da seção | `scripts/verify.sh` (a estender) | 6 |
| ADR-1 | Pasta `docs/adrs/` contém entre 5 e 8 arquivos no formato `ADR-NNN-titulo-em-kebab-case.md` | `ls docs/adrs/ADR-[0-9][0-9][0-9]-*.md \| wc -l` entre 5 e 8 **e** essa contagem == `ls docs/adrs/*.md \| wc -l` − 1 (menos README.md) | `scripts/verify.sh` (a estender) | 4 |
| ADR-2 | Cada ADR contém as seções Status, Contexto, Decisão, Alternativas Consideradas, Consequências | para cada `ADR-*.md`: `grep -qi` das 5 seções | `scripts/verify.sh` (a estender) | 4 |
| ADR-3 | O conjunto cobre pelo menos 5 das 6 decisões principais do requisito 4 (Outbox no MySQL · retry+backoff+DLQ · HMAC-SHA256 por endpoint · at-least-once com `X-Event-Id` · worker em processo separado em polling · reuso de padrões existentes) | checklist de palavras-chave por decisão, mapeado a qual ADR cobre cada uma; ≥ 5 de 6 cobertas | `scripts/verify.sh` (a estender, semi-automatizado) | 4 |
| ADR-4 | Pelo menos 1 ADR referencia explicitamente arquivos, módulos ou classes do código base | extrair caminhos citados nos `ADR-*.md` e cruzar contra `.planning/00-inventario-paths.txt`; interseção ≥ 1 | `scripts/verify.sh` (a estender) | 4 |
| TRK-1 ⚠ | "Arquivo existe e segue o formato de tabela definido no requisito 5" | `test -f docs/TRACKER.md` **e** `wc -w docs/TRACKER.md` ≥ 100 **e** zero placeholders **e** header da tabela == `\| ID \| Documento \| Tipo \| Conteúdo (resumo) \| Fonte \| Localização \|` | `scripts/verify.sh` (a estender) | 8 |
| TRK-2 | Pelo menos 80% dos itens identificáveis dos documentos têm linha correspondente | contagem de IDs (`PRD-FR-*`, `RFC-ALT-*`, `FDD-CONTRATO-*`, `ADR-*` etc.) citados nos docs vs. presentes como linha no tracker; razão ≥ 0.80 | `scripts/verify.sh` (a estender) | 8 |
| TRK-3 | Pelo menos 70% das linhas têm Fonte = `TRANSCRICAO` com timestamp válido no formato `[hh:mm] Nome` | `awk`/regex sobre as linhas da tabela, valida coluna Localização contra `^\[[0-9]{2}:[0-9]{2}\] \S+$`; razão ≥ 0.70 | `scripts/verify.sh` (a estender) | 8 |
| TRK-4 | Pelo menos 5 linhas têm Fonte = `CODIGO` com caminho de arquivo real | contagem de linhas com Fonte=CODIGO cujo caminho existe em `.planning/00-inventario-paths.txt` ≥ 5 | `scripts/verify.sh` (a estender) | 8 |
| RME-1 | "Contém todas as seções obrigatórias listadas no requisito 6" (Sobre o desafio · Ferramentas de IA utilizadas · Workflow adotado · Prompts customizados · Iterações e ajustes · Como navegar a entrega) | `grep -qi` para cada uma das 6 em `README.md` | `scripts/verify.sh` (a estender) | 9 |
| RME-2 | "Lista pelo menos 1 ferramenta de IA utilizada" | seção "Ferramentas de IA utilizadas" tem ≥ 1 item de lista | `scripts/verify.sh` (a estender) | 9 |
| RME-3 | "Mostra pelo menos 2 prompts customizados em blocos de código" | contagem de blocos ` ``` ` dentro da seção "Prompts customizados" ≥ 2 | `scripts/verify.sh` (a estender) | 9 |
| RME-4 | "Descreve pelo menos 2 iterações ou ajustes concretos feitos durante a produção" | contagem de itens/blocos na seção "Iterações e ajustes" ≥ 2 | `scripts/verify.sh` (a estender) | 9 |
| GER-1 | "Nenhum requisito, decisão ou restrição registrada nos documentos contradiz a transcrição ou o código" | revisão qualitativa assistida (não 100% mecanizável); checagem de fatos-chave cruzados contra `TRANSCRICAO.md` e código | revisão manual + `scripts/verify.sh` (parcial) | 10 |
| GER-2 | "Nenhum arquivo de código mencionado nos documentos é inexistente no repositório" | extrair todo caminho tipo `src/...`, `prisma/...`, `tests/...` citado em `docs/*.md` e `docs/adrs/*.md`; cada um deve estar em `.planning/00-inventario-paths.txt` | `scripts/verify.sh` (a estender) | 10 |
| EST-1 | Árvore obrigatória do entregável (seção "Estrutura obrigatória do entregável") presente e rastreável | hoje (parcial): `git check-ignore -v` com sondas em cada diretório protegido vazio (INV-3). Completo: todos os caminhos da árvore do enunciado existem com conteúdo real | `scripts/verify.sh` INV-3 (parcial) / a estender (completo) | **2 (parcial, hoje)** / 10 (completo) |
| EST-2 (novo) | `docs/adrs/` não deve conter nada além de `ADR-NNN-*.md` e `README.md` (implícito na estrutura obrigatória + no formato de nome do requisito 4) | `git ls-files docs/adrs \| grep -vE '^docs/adrs/(README\.md\|ADR-[0-9]{3}-[a-z0-9-]+\.md)$'` vazio | `scripts/verify.sh` (a estender) | 4 |
| MAN-01 | REC-09 `customer_id` derivado do JWT não pode aparecer como decisão vigente | verificação MANUAL — ERE sem lookaround não distingue a adoção da negativa (DEC-17) | `.planning/09-review.md` | 9 |

⚠ = critério que o enunciado descreve como "arquivo existe", mas que **não** é
implementado como `test -f` sozinho — ver "Decisões normativas".

MAN-NN = verificação que **não** tem comando que prove — ver "Verificações
manuais". Um MAN-NN nunca conta como coberto por `scripts/verify.sh`.

## Decisões normativas

**D-01 — Convenção de nome dos ADRs.**
A convenção usada será a do enunciado: `ADR-NNN-titulo-em-kebab-case.md` (3
dígitos, prefixo `ADR-`, ex.: `ADR-001-outbox-no-mysql.md`), conforme
requisito 4 e a seção "Estrutura obrigatória do entregável" do README.

*Justificativa:* o enunciado (o documento que efetivamente será usado para
avaliação) especifica essa convenção duas vezes — no requisito 4 e na árvore
de estrutura obrigatória (linhas 126 e 251-256 do README lido nesta sessão).
`docs/adrs/README.md`, que hoje prescreve `NNNN-titulo-da-decisao.md` (4
dígitos, sem prefixo), é scaffolding do repositório base, não o enunciado da
avaliação — tem menos peso normativo. Ele será reescrito como índice, já na
convenção `ADR-NNN-*`, no **Bloco 4**. Não tocado neste bloco.

*Risco residual:* um avaliador automatizado ou humano que conte
"arquivos .md em `docs/adrs/`" sem excluir `README.md` vai contar 1 arquivo a
mais que o número real de ADRs — por isso ADR-1 exige explicitamente a
igualdade `contagem(ADR-NNN-*.md) == contagem(*.md) − 1`, não apenas "entre 5
e 8", como forma de autodetectar essa divergência antes da entrega.

## Verificações manuais

Verificações que nenhum comando prova, e que por isso precisam de um revisor
humano com um alvo escrito. Se novos MAN-NN surgirem nos próximos blocos, é
aqui que moram. A regra é a mesma de sempre: um item que não tem comando não
pode ser contado como verde por `scripts/verify.sh` — ele fica visível como
pendência até alguém registrar o resultado da revisão no documento indicado.

### MAN-01 — `customer_id` derivado do JWT (REC-09)

**O que foi recusado.** Marcos propôs em `[09:31] Marcos` que o `customer_id`
viesse implícito do JWT. Bruno apontou em `[09:32] Bruno` que o JWT atual é do
usuário operador, não do cliente, e Larissa fechou em `[09:32] Larissa` que o
`customer_id` **não** vem do JWT. O item está em `.planning/02-recusa.md` como
REC-09, DESCARTADO.

**Por que não é automatizável.** A âncora precisaria casar a adoção ("o
`customer_id` é derivado do JWT") e **não** casar a decisão correta, que é a
mesma frase na negativa ("o `customer_id` **não** vem do JWT", DEC-17). ERE não
tem lookaround, então nenhum padrão separa as duas. Duas tentativas foram
gastas e ambas casaram os dois casos — o registro completo, com a saída dos
testes, está em `.planning/02-recusa.md`, seção "Itens sem âncora viável".
Trocar para PCRE (`grep -P`) resolveria a negação, mas mudaria o contrato de
todas as outras 14 âncoras, que são ERE e estão provadas em ERE; o custo não se
justifica por um item.

**O que o revisor precisa procurar.** Em `docs/PRD.md`, `docs/RFC.md`,
`docs/FDD.md` e `docs/adrs/ADR-*.md`, localizar toda menção a `customer_id`
junto de JWT/token e classificar cada ocorrência em uma de três:

1. **Correta** — afirma que o `customer_id` vem do body ou do path, e/ou nega
   explicitamente a origem no JWT. Nada a fazer.
2. **Vazamento** — afirma, exige ou implica que o `customer_id` é extraído,
   derivado, inferido ou lido do JWT/token. Reprova; o documento tem que ser
   corrigido.
3. **Ambígua** — cita os dois sem dizer qual vale. Tratar como vazamento até
   ser reescrita, porque um leitor implementaria o caminho errado.

Ponto de partida sugerido para a varredura (é um filtro amplo de propósito, para
não perder ocorrência; a classificação é humana):

```
grep -rniE 'customer_?id' docs/ | grep -iE 'jwt|token|claim'
```

**Onde registrar o resultado.** `.planning/09-review.md`, no bloco 9, com a
lista de ocorrências encontradas e a classificação de cada uma. Sem esse
registro, MAN-01 permanece pendente.

## Convenções

- `(novo)`: identifica critério/caminho de arquivo que ainda não existe e será
  criado em bloco futuro — não confundir com scaffolding já presente hoje.
- IDs inline usados dentro dos documentos, conforme o enunciado e a matriz:
  `PRD-FR-NN` (requisito funcional), `PRD-RNF-NN` (requisito não funcional),
  `RFC-ALT-NN` (alternativa considerada), `RFC-QA-NN` (questão em aberto),
  `FDD-CONTRATO-NN` (contrato público/endpoint), `FDD-ERR-NN` (erro na matriz
  `WEBHOOK_*`), `ADR-NNN` (decisão arquitetural, 3 dígitos).
- Títulos de seção `##` nos documentos devem ser **idênticos** aos nomes de
  seção citados no enunciado (ex.: `## Fora de escopo`, `## Alternativas
  consideradas`, `## Integração com o sistema existente`) — os comandos de
  prova acima dependem de `grep` textual contra esses títulos exatos.

## Duas linhas de reprova

- **RA-1 (código intocado):** se qualquer caminho **fora** do conjunto
  `{ README.md, docs/**, .planning/**, scripts/** }` divergir de `$BASE` — seja
  por modificação, criação, remoção ou por estar untracked —, a entrega reprova
  independentemente do conteúdo dos documentos. É a restrição absoluta do
  enunciado. A regra é uma lista de permissão de propósito: enumerar o que é
  proibido deixa passar tudo que a enumeração esquecer.
- **RA-2 (nada registrado sem origem rastreável):** se um requisito, decisão
  ou restrição aparecer em PRD/RFC/FDD/ADR sem linha correspondente e
  verificável em `TRACKER.md`, a entrega reprova mesmo que os documentos
  estejam formalmente completos. É a exigência específica deste desafio contra
  alucinação (README, linha 30 e seção "Dicas Finais").

## Estado

**Verificável HOJE (`scripts/verify.sh` v2):** apenas os 4
invariantes de baixo nível — INV-1, INV-2, INV-3, INV-4. Nenhum ID de critério
de aceite (PRD-\*, RFC-\*, FDD-\*, ADR-\*, TRK-\*, RME-\*, GER-\*) é
mecanicamente verificável ainda, porque todos dependem de conteúdo que ainda
não existe (ver `.planning/01-scaffolding.md`).

- **RA-1** já está coberto por INV-1 + INV-2 hoje.
- **EST-1** está parcialmente coberto por INV-3 hoje (garante que a árvore
  *pode* ser versionada); a checagem completa (árvore inteira com conteúdo
  real) só fecha no Bloco 10.
- **MAN-01** não é verificável por comando em bloco nenhum, por construção —
  fecha por revisão humana registrada em `.planning/09-review.md` no Bloco 9.
- Todos os demais IDs entram no bloco indicado na coluna "Bloco" da tabela
  acima.

**Plano de blocos proposto** (âncora fixa: D-01 define Bloco 4 = ADRs; os
demais números são um plano, não uma decisão travada):

| Bloco | Conteúdo |
| --- | --- |
| 1 | Preflight (concluído) |
| 2 | Scaffolding + matriz de aceite + verify v0 (**este bloco**) |
| 3 | Extração forense da transcrição + mapeamento de código (insumo para os docs) |
| 4 | ADRs (5–8 arquivos) + reescrita de `docs/adrs/README.md` como índice (D-01) |
| 5 | RFC |
| 6 | FDD |
| 7 | PRD |
| 8 | Tracker |
| 9 | README do processo |
| 10 | `verify.sh` vFinal (todos os INV + todos os critérios de aceite) + revisão final |

## Piso de `wc -w` proposto — justificativa

Piso = 10× o tamanho do esqueleto atual (`.planning/01-scaffolding.md`),
arredondado, e sempre abaixo do mínimo realista somando o número de seções
obrigatórias × ~15 palavras mínimas por seção — para não virar barra de
qualidade, só filtro anti-esqueleto:

| Documento | Esqueleto hoje | Piso proposto | Mínimo realista (nº seções × ~15 palavras) |
| --- | --- | --- | --- |
| PRD | 12 palavras | **120** | 12 seções × 15 ≈ 180 |
| RFC | 12 palavras | **120** | 8 seções × 15 ≈ 120 |
| FDD | 12 palavras | **120** | 12 seções × 15 ≈ 180 (subestimado — FDD inclui payloads JSON, tende a ser bem maior) |
| TRACKER | 10 palavras | **100** | tabela, não prosa — piso mais baixo é adequado ao formato |

RFC recebe adicionalmente um **teto** (RFC-6, 2400 palavras ≈ 4 páginas de
~600 palavras) porque o enunciado pede concisão explícita ("documento conciso,
2 a 4 páginas... não deve duplicar o detalhamento do FDD") — nesse caso, texto
demais é o defeito, não texto de menos.

## Revisões

| Data | O que mudou | Motivo |
| --- | --- | --- |
| 2026-08-19 | **ADR-3 reescrito** em `scripts/verify.sh` v3.1, com o denominador movido para `.planning/04-cobertura.md` | A v3 media duas coisas que não são o critério: a cobertura das DEC do mapa de `.planning/03-design.md` §4 — mapa escrito no mesmo movimento que planejou os ADRs, portanto consistência interna do pacote e não cobertura da reunião — e seis regex digitadas dentro do próprio script, sem T1/T2. O critério do enunciado é 5 das 6 decisões principais, e o denominador tem que ser externo ao que está sendo medido. As seis decisões agora são digitadas à mão a partir do enunciado, cada uma com âncora ERE provada discriminante (T1 contra os 8 ADRs, T2 contra arquivo de controle), e o check exige exatamente 6 âncoras carregadas sob pena de `exit 2`. Provado por S1..S3 em `.planning/04-teste-negativo.md`. Nenhum ADR foi alterado. **Não houve MAN-02**: as seis têm âncora viável. |
| 2026-08-18 | **RA-1 reescrito de lista de BLOQUEIO para lista de PERMISSÃO** em `scripts/verify.sh` v2, com as duas linhas de reprova atualizadas | O patch P1.1 já tinha pedido esta inversão e **ela não foi aplicada** — auditoria de disco encontrou o array `PROTEGIDOS` ainda no código, com os 7 caminhos originais. O buraco era medido, não teórico: `.gitignore`, `vitest.config.ts`, `docker-compose.yml`, `tsconfig.build.json`, `.eslintrc.json`, `.prettierrc`, `.prettierignore` e `.env.example` podiam ser alterados sem INV-1 falhar, e um arquivo NOVO criado dentro de `src/` também passava, porque a lista só conferia o que já existia em `$BASE`. Agora o conjunto permitido é `{ README.md, docs/**, .planning/**, scripts/** }` e as fontes são `git diff --name-status` mais `git ls-files --others --exclude-standard`. Provado por N1..N4 em `.planning/01-teste-negativo.md`. |
| 2026-08-18 | Fonte de verdade de **GER-2** passa a ser `git ls-files` no momento da verificação | `.planning/00-inventario-paths.txt` é um snapshot do Bloco 0, com 67 caminhos contra 76 no índice de hoje — já defasado. Onde os comandos de prova de FDD-5, ADR-4 e GER-2 citam esse arquivo, leia-se `git ls-files` executado na hora. Retificação registrada em `.planning/00-preflight.md` §0.6. |
| 2026-08-18 | `.planning/paths-reais.txt` apagado | Identificado por comando como byte-a-byte igual a `git ls-files -- src prisma tests` (diff vazio, exit 0): era o insumo da lista de bloqueio do INV-1, que deixou de existir. Sem consumidor, seria só uma segunda fonte de verdade defasável. |
| 2026-08-18 | Acrescentado **MAN-01** à tabela de critérios e criada a seção "Verificações manuais" | REC-09 (`customer_id` derivado do JWT) ficou marcado `[sem âncora viável]` em `.planning/02-recusa.md` e existia só como nota solta num documento. Sem linha de matriz, uma verificação que ninguém consegue automatizar também é uma verificação que ninguém lembra de fazer. Agora tem ID, alvo escrito e documento onde o resultado é registrado. |
| 2026-08-18 | Referência de `scripts/verify.sh` atualizada de v0 para v1 na seção "Estado" | O verificador ganhou guardas contra passagem vazia (exit 2 / `ERRO DE VERIFICAÇÃO`), contagem de entradas em toda linha OK e resolução determinística do binário de grep. Os quatro invariantes cobertos continuam os mesmos — INV-1..INV-4 —, e nenhuma lógica de FALHA foi alterada. Motivador: o patch das âncoras encontrou, dentro do próprio INV-7, um check que imprimia OK com zero entradas carregadas; a auditoria subsequente achou a mesma classe de defeito em INV-1, INV-2 e INV-4. |
