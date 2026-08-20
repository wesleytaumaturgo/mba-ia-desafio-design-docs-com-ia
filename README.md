# Sistema de Webhooks de Notificação de Pedidos — Design Docs

## Sobre o desafio

A tarefa era transformar a gravação de uma reunião técnica de 53 minutos —
cinco participantes, decisões fechadas em falas curtas, algumas ideias
descartadas no meio do caminho — em um pacote de documentação de design
completo e acionável para uma feature nova: um sistema de webhooks que notifica
clientes B2B quando o status de um pedido muda, num Order Management System
que hoje não tem nenhum mecanismo de notificação externa. Nada da decisão
técnica estava escrito em lugar nenhum além da transcrição.

O critério que governou cada linha escrita foi um só: toda afirmação nos
documentos — todo número, requisito, contrato ou restrição — precisa ter
origem identificável, na fala de alguém na reunião ou em código que já existe
no repositório. Onde essa origem não existisse, a lacuna tinha que ficar
declarada, não preenchida por inferência da IA.

## Ferramentas de IA utilizadas

- **Claude Opus 5, via Claude Code** — a ferramenta principal de produção. Leu
  a transcrição na íntegra e o código-fonte relevante, gerou os 8 ADRs, o RFC,
  o FDD, conduziu o review adversarial do pacote pronto e aplicou as correções
  apuradas por esse review e pela verificação externa. Também escreveu e
  manteve o script de verificação executável usado a cada bloco.
- **Claude Sonnet 5, via Claude Code** — usado nos blocos de consolidação e
  redação que vêm depois que as decisões já estão fechadas em outros
  documentos: a produção do `docs/PRD.md` e do `docs/TRACKER.md` (que
  consolida, não decide) e a redação deste README.
- **Claude Opus 5, via interface web** — usado na fase de planejamento anterior
  à geração de documentos: a leitura preliminar do enunciado e da transcrição,
  a montagem do contrato de aceite (que critério cada seção precisa satisfazer,
  antes de qualquer documento existir) e o desenho normativo do pacote — quais
  seções cada documento tem, em que ordem, com que convenções de marcação.
  Também usado para revisar prompts entre blocos, fora do terminal.
- **Cursor, com modelo de outro fornecedor** — usado como segunda opinião
  independente depois que o pacote já batia 34/34 no verificador e tinha
  passado pelo review adversarial da própria Claude. A tarefa dada a essa
  ferramenta foi simular um engenheiro que começaria a implementação sem ter
  participado da reunião, e listar onde ele travaria. Ela achou defeitos que as
  duas rodadas anteriores, feitas pela mesma família de modelo, não pegaram —
  a razão de ter sido incluída deliberadamente, e não por acaso.

## Workflow adotado

A ordem real de produção foi: contrato de aceite → leitura forense da
transcrição → leitura forense do código → design normativo do pacote → ADRs →
RFC → FDD → PRD → tracker → review adversarial interno → verificação externa
independente → bloco de correções → bloco de lacunas → este README.

**A transcrição foi lida antes do código, deliberadamente.** A ordem inversa
tem um viés difícil de perceber depois: ler o código primeiro faz o modelo
reconhecer símbolos, nomes de classe, nomes de método — e a tentação seguinte é
inferir que a reunião os mencionou, porque "faz sentido que sim". A extração
forense da transcrição foi feita como bloco isolado, sem nenhum arquivo de
`src/`, `prisma/` ou `tests/` aberto na mesma sessão, exatamente para que a
tabela de decisões e requisitos fechados refletisse só o que foi dito, não o
que o código tornaria plausível. O código só entrou depois, num bloco à parte,
para mapear os pontos de acoplamento — e aí sim, cruzar os dois lados
propositalmente revelou 14 divergências entre o que a reunião presumiu sobre o
repositório e o que o repositório de fato tem.

**O papel do verificador executável.** Cada critério do enunciado que dá para
checar mecanicamente — seção obrigatória presente, contagem mínima de
requisitos, timestamp que existe de verdade na transcrição, caminho de arquivo
que existe de verdade no repositório — virou um check num script único,
chamado a cada bloco de produção. O script cresceu de um punhado de checks de
invariante básica para 38 checks ao final da entrega. Cada check, ao ser
escrito, ganhou também um teste negativo: uma versão sabotada do documento que
prova que o check *falha* quando o critério falha, não só que ele passa quando
está tudo certo. Um verificador que nunca foi visto reprovar nada não prova
nada — só prova que ninguém tentou quebrá-lo. Esse verificador não olha
significado: ele prova forma (a seção existe, o número bate um mínimo, o
timestamp é real). Foi por isso que dois blocos de revisão de conteúdo — um
adversarial, um externo — continuaram necessários mesmo com o script todo
verde.

**A convenção `(novo)`.** Todo caminho de arquivo citado nos documentos que
ainda não existe no repositório — os arquivos do módulo de webhooks que a
implementação vai criar — leva o marcador literal `(novo)` logo depois do
caminho entre crases. Sem esse marcador, um caminho citado é lido como
afirmação sobre o código *que já existe*, e é conferido contra o índice real do
git. O verificador anti-alucinação depende dessa distinção: sem ela, ele não
teria como diferenciar "o FDD projeta um arquivo novo" de "o FDD inventou que
um arquivo já existe".

## Prompts customizados

O prompt abaixo abriu o bloco de leitura forense da transcrição. A restrição de
não ler código nesta etapa está no próprio prompt, não como lembrete separado —
é o que impediu o viés descrito acima.

```
Leia TRANSCRICAO.md por inteiro, do início ao fim, sem offset/limit. Não abra
nenhum arquivo de src/, prisma/ ou tests/ nesta sessão — essa restrição é
deliberada, existe para que a extração reflita só o que foi dito, sem
contaminação do que o código tornaria plausível.

Produza tabelas separadas para: decisões fechadas (com a fala literal que
fechou cada uma, marcada por [hh:mm] Nome), requisitos funcionais, requisitos
não funcionais com todo número dito em voz alta, itens descartados
explicitamente, itens adiados para fase futura, e pontos ambíguos onde a
mesma coisa foi tratada de duas formas diferentes na mesma reunião.

Regra de fechamento: quando uma decisão é fechada por um aceno curto ("Faz.",
"Beleza.", "Concordo."), a Localização é a fala que FECHA, não a fala que
propôs. Onde a fala original passar de 20 palavras, corte em duas linhas com
IDs distintos — nunca parafraseie o conteúdo da fala para encurtar.

Não infira requisito que não foi dito. Se uma validação foi rebaixada pela
própria reunião a "não é decisão arquitetural, é só requisito não funcional",
respeite essa classificação.
```

O prompt abaixo abriu o bloco de review adversarial, depois que o pacote já
batia 34/34 no verificador. A instrução de tratar o verde do script como ponto
de partida da desconfiança, não como credencial, é o que forçou o modelo a não
aceitar o próprio trabalho anterior.

```
Você é revisor externo deste pacote de documentos. Sua saída padrão é
REPROVADO; só chega a APROVADO se a tentativa de derrubar o pacote falhar de
verdade. O script de verificação já passa 34/34 — isso é o ponto de partida da
sua desconfiança, não uma credencial que o pacote já tem.

Para cada número que aparece em qualquer documento, confira contra a fala
original na transcrição ou contra o código em disco, e cole o comando que
confere. Sorteie uma amostra de linhas do tracker com um método determinístico
e reproduzível, abra a transcrição no timestamp declarado, e classifique cada
uma: CONFERE, RESUMO DISTORCE ou LOCALIZAÇÃO ERRADA. Para cada um dos checks do
verificador, escreva a entrada errada mais plausível que passaria por ele
mesmo assim, e diga se esse defeito ocorre nesta entrega.

Termine com veredito binário — APROVADO ou REPROVADO — e, se REPROVADO, uma
lista ordenada por gravidade do que precisa mudar, cada item com o arquivo, a
linha e o que dispara de re-verificação.
```

## Iterações e ajustes

Seis blocos de correção concreta, cada um sobre um defeito real encontrado
durante a produção — não ajuste de estilo. São os seis commits com prefixo
`fix` do histórico do projeto.

1. **O check de `.gitignore` passava em cima da própria sabotagem.**
   `git check-ignore` no modo padrão nunca reporta como ignorado um caminho já
   rastreado pelo git — então uma regra sabotando `docs/adrs/` era invisível
   para o check enquanto os arquivos já existissem no índice. Corrigido
   sondando um caminho de arquivo *futuro*, que ainda não existe no índice, em
   vez de um caminho já rastreado.
2. **A lista de proteção do invariante de "só documentação muda" era lista de
   bloqueio, não de permissão.** Ela deixava passar um `.gitignore` alterado,
   um `vitest.config.ts` alterado e um arquivo novo criado dentro de `src/`,
   porque nenhum desses três estava na lista de nomes bloqueados. Invertida
   para lista de permissão: só `README.md`, `docs/**`, `.planning/**` e
   `scripts/**` podem divergir da revisão-base: qualquer outra coisa reprova.
3. **O check de cobertura das 6 decisões principais dos ADRs era
   tautológico.** Ele extraía os identificadores das próprias decisões dentro
   dos ADRs e conferia se os ADRs continham esses mesmos identificadores — não
   podia falhar nunca, porque o numerador e o denominador vinham do mesmo
   lugar. Refeito com denominador externo: as 6 decisões são digitadas à mão a
   partir do enunciado do desafio, num arquivo à parte, e o check confere os
   ADRs contra esse denominador independente.
4. **A leitura forense do código achou 14 divergências entre o que a reunião
   presumiu e o que o repositório tem.** Uma delas: a reunião tratou
   `OrderService.changeStatus` como o único ponto que grava linha de histórico
   de status (`src/modules/orders/order.service.ts:126`), mas
   `OrderService.create` grava a primeira linha de `order_status_history` por
   um caminho separado (`src/modules/orders/order.service.ts:50`). Isso virou
   limitação declarada em ADR-007, não um requisito silenciosamente ignorado.
5. **O review adversarial reprovou a primeira versão fechada do pacote.**
   Dois problemas de conteúdo que 34/34 no verificador não detectava: o número
   de transições de status foi descrito como 8 em dois documentos quando
   `src/modules/orders/order.status.ts:3-10` declara 7; e a política de retry
   tinha três leituras aritmeticamente incompatíveis dentro do mesmo FDD (5
   tentativas, 5 intervalos, "quase 15 horas" — 5 chamadas só têm 4
   intervalos). Corrigido para 7 transições e para 5 chamadas com 4 intervalos,
   com a ambiguidade da ata registrada como questão em aberto em vez de
   escondida atrás de um número que não fechava.
6. **A verificação externa achou o que as duas rodadas anteriores não
   pegaram.** As classes de erro do projeto fixam o próprio código no
   construtor — `ValidationError`, `ForbiddenError` e `NotFoundError`
   (`src/shared/errors/http-errors.ts:9-31`) não recebem código por parâmetro,
   e `AppError.errorCode` é `readonly`
   (`src/shared/errors/app-error.ts:5`) — então o prefixo `WEBHOOK_` decidido
   na reunião não é alcançável só por herança para cinco das nove classes de
   erro do módulo, como o FDD original afirmava. Documentado como delta
   declarado sobre código existente, sem alterar nenhum arquivo de código.

## Como navegar a entrega

Ordem sugerida de leitura, do mais alto nível ao mais detalhado:

1. `docs/RFC.md` — a proposta técnica: o que foi decidido, as alternativas
   descartadas, o que ainda está em aberto. Ponto de entrada mais curto para
   entender a arquitetura inteira antes de descer ao detalhe.
2. `docs/adrs/` — as 8 decisões isoladas que o RFC referencia, cada uma com
   contexto, alternativas e consequências próprias.
3. `docs/FDD.md` — o desenho de implementação: fluxos, contratos HTTP, matriz
   de erros, integração com o código existente, e a seção que declara
   explicitamente o que a reunião não decidiu.
4. `docs/PRD.md` — a consolidação em nível de produto: problema, público,
   escopo, métricas de sucesso.
5. `docs/TRACKER.md` — a referência cruzada: de onde veio cada item dos quatro
   documentos acima, fala ou código, com a prova de conferência.

**Reproduzindo a verificação.** O verificador executável dos critérios de aceite
não faz parte da árvore entregue — é ferramenta de processo, não documento —,
mas está preservado no histórico. Para rodar os 38 checks sobre o pacote final:

```
git worktree add /tmp/repro 07f8496
cd /tmp/repro && ./scripts/verify.sh
```

`07f8496` é o único commit que reúne as duas coisas: o pacote já corrigido e o
verificador ainda versionado.
