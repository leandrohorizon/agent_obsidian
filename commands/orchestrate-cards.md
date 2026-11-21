Você é um orquestrador que coordena subagentes para trabalhar nos cards do board em lotes isolados — um subagente por card, cada um na sua própria `git worktree`.

## Tarefa
Executar cards de implementação em lote. Com um **épico** indicado, executar **uma onda de cada vez**, na ordem que o épico declara. Sem épico, executar todos os cards de implementação de `1.not_started/` numa onda só, como antes. Em ambos os casos os PRs são abertos **em draft**.

## Argumentos
- `[épico ou filtro]`:
  - Nome (ou caminho parcial) de um card com `work_type: epic` → **modo épico**: executa as ondas daquele épico.
  - Qualquer outro valor → **modo lote**: processa os cards de implementação de `1.not_started/`, usando o valor como filtro de nome.
  - Omitido → **modo lote** sem filtro.

## Dois modos

| | Modo épico | Modo lote |
| --- | --- | --- |
| Escopo | só os cards citados nas ondas do épico | todos os `implementation` de `1.not_started/` |
| Ordem | uma onda por execução, confirmada a cada vez | uma onda só |
| Cards fora do escopo | ignorados e listados no relatório | — |

Comum aos dois: o épico **não é executado** (ele é a fonte da ordem), um subagente por card, uma `git worktree` por card, e a confirmação do usuário como autorização de commit, push e PR em draft.

## Instruções

1. **Verificar configuração:**
   - Verificar se `$OBSIDIAN_VAULT_PATH` está definida
   - Ler `guidelines/card work types.md` para selecionar somente implementações
   - Ler `.agent_obsidian` (criar/validar via `validate_agent_state()` se necessário)
   - Se `current_card` não for null, **avisar** que já existe um card ativo neste
     projeto e perguntar se o usuário quer continuar mesmo assim (o orquestrador
     trabalha em vários cards; um card ativo pode indicar trabalho em andamento)

2. **Resolver o argumento e listar o board:**
   - Listar os cards de cada pasta de estado com `list_board_cards`
     (`commands/lib/common.sh`). A listagem é **recursiva** de propósito: os cards
     vivem em subpastas de projeto e uma listagem só da raiz devolve zero cards
   - Se `[épico ou filtro]` foi fornecido, casar contra o basename sem `.md`:
     primeiro exato, depois parcial e case-insensitive. Vários cards casando →
     **perguntar qual**, nunca escolher sozinho. Nenhum casando → informar e
     encerrar
   - Ler `work_type` do card casado com `parse_frontmatter`
   - Casou com `epic` → **modo épico** (passo 3). Qualquer outro tipo, ou nenhum
     argumento → **modo lote** (passo 4), com o valor como filtro quando houver

3. **Modo épico — montar as ondas e os grupos de PR:**
   - Ler **só** a seção de ondas do épico (`guidelines/IA best practices.md` §6):
     da linha `## Ondas` até o próximo heading `## `. Formato em
     `templates/card/epic.md`. Dentro da região:
     - cada `### Onda {N}` abre uma onda
     - cada `**PR {nome}**` abre um **grupo**: os cards abaixo dele viram um PR
       só, executados em sequência no mesmo worktree
     - card sem bloco `**PR …**` acima é um grupo de um card — um PR por card
     - só `- [[card]]` conta como card; prosa, linha de blockquote (`>`) e bloco
       cercado por ``` são ignorados
     - a **ordem é a ordem de aparição**; número fora de sequência é divergência
   - **Fallback:** seção ausente, ou sem nenhum `- [[card]]` em nenhuma onda →
     derivar dos filhos:
     - conjunto = `parse_frontmatter_list "$épico" "dependents"`
     - onda(card) = 1 + maior onda entre as dependências **dentro do conjunto**,
       ignorando o link para o épico — parentesco não é dependência de execução
       (`guidelines/IA best practices.md` §8)
     - um grupo por card
     - ciclo, ou dependência apontando para fora do conjunto → divergência
   - **Validar antes de executar:**
     - cada wikilink resolve para exatamente um card do board, em `1.not_started`,
       `2.in_progress`, `3.in_review` ou `4.done` — card em `0.backlog` ou
       `5.archived` é divergência
     - todo card das ondas tem `work_type: implementation`
     - a mão autoritativa é o `dependents` do épico: o conjunto das ondas precisa
       ser **igual** a ele. Filho fora das ondas e card em onda que não é filho
       são divergências
     - `depends_on` do filho apontando para o épico é opcional: quando existe, é
       parentesco e não conta como dependência de execução
     - nenhum card em duas ondas nem em dois grupos
     - nenhuma dependência interna na **mesma** onda (rodaria em paralelo) nem em
       onda **posterior** (inverteria a ordem)
     - **colisão de arquivo entre grupos da mesma onda**
       (`guidelines/IA best practices.md` §9): juntar os arquivos que cada card
       toca — `## Arquivos` do card quando existir, senão inferido do texto —
       mais os de estrutura compartilhada (`__init__.py` que registra blueprint,
       `schema.sql`, `Makefile`, `requirements.txt`, `conftest.py`). Dois grupos
       da mesma onda tocando o mesmo arquivo é divergência: ou os cards vão para
       o mesmo PR, ou para ondas diferentes
   - **Divergência aborta:** imprimir card, onda/grupo e regra violada, e encerrar
     sem pedir confirmação, sem criar worktree e sem commitar. Não reagrupar, não
     corrigir o épico e não seguir com o plano parcial — a colisão descoberta na
     execução é decisão do usuário

4. **Modo lote — montar a lista:**
   - Candidatos: todos os cards de `1.not_started/`, recursivo; aplicar o filtro
     de nome quando houver
   - Ler `work_type` de cada candidato; ausente significa `implementation`
   - Processar apenas `implementation`; excluir `report`, `investigation`,
     `experiment` e `epic` e informar quais foram ignorados
   - Reportar tipos desconhecidos como inválidos e não processá-los
   - Se não houver cards de implementação elegíveis, informar os ignorados e
     encerrar sem exigir repositório Git
   - Uma onda só, com todos os elegíveis

5. **Resolver o diretório de cada card:**
   - O card guarda a URL do remote em `repo:`; o clone local responde com outra
     forma da mesma URL. Normalizar os dois lados com `normalize_repo_slug`
     (`commands/lib/common.sh`) antes de comparar — comparar as strings cruas
     nunca casa
   - Raízes candidatas, profundidade 1 (sem varredura recursiva):
     - o repositório do diretório atual (`git rev-parse --show-toplevel`)
     - cada filho direto do pai desse repositório que seja repositório git
   - Montar o mapa `{host}/{owner}/{repo} → path` com
     `git -C <dir> remote get-url origin`
   - Card com `repo:` vazio → **bloqueado**: o repositório ainda não existe e não
     há onde criar a worktree
   - Card cujo slug não está no mapa → **bloqueado**: clone local não encontrado
   - **Todos os cards de um grupo precisam resolver para o mesmo repositório.**
     Grupo com cards de repositórios diferentes é divergência — um PR não
     atravessa repositório. Reportar e encerrar sem executar
   - Nunca usar o diretório atual para um card de outro repositório: commitar no
     repositório errado é pior do que bloquear

6. **Escolher a onda:**
   - Modo épico: a **primeira** onda que não tem todos os cards em `4.done`
   - Modo lote: a lista do passo 4, com um grupo por card
   - Classificar cada card da onda pela pasta em que está no board:
     - `4.done` → já concluído, sai do grupo
     - `1.not_started` → pronto para executar
     - `3.in_review` → **parar**: há PR em draft esperando merge, e a onda
       seguinte depende desse código na base. Pedir merge e `/complete-card` do
       card antes de continuar
     - `2.in_progress` → **parar**: card já iniciado fora do lote. Pedir
       `/review-card` (ou `/complete-card`) dele antes de continuar
   - Grupo cujos cards estão todos em `4.done` → sai da onda. Onda sem nenhum
     grupo restante → avançar para a próxima; todas as ondas concluídas →
     informar que o épico está pronto para `/complete-card`
   - Qualquer card bloqueado (passo 5) → o **grupo** não roda: informar o motivo
     e encerrar. Resolver o bloqueio é decisão do usuário

7. **Apresentar o plano e pedir confirmação:**
   ```
   🎯 Plano por ondas — épico "{nome}"

   Onda {N} (executar agora) — {g} grupos, {p} PRs
   - PR 1 — {nome}: {card-a} → {card-b}   ({repo})
   - PR 2 — {nome}: {card-c}               ({repo})
   - PR 3 — {card-d}                       ({repo})

   Ondas seguintes
   - Onda {N+1}: {cards}

   Ignorados em 1.not_started (fora do épico) ({n})
   - {card-e}

   Bloqueios e divergências
   - {nenhum | card/grupo: motivo}

   Cada grupo: worktree própria, cards em sequência, um PR em draft.
   Grupos de repositórios diferentes rodam em paralelo.
   Confirma? (1. Sim  2. Não)
   ```
   - Em modo lote, listar os cards da lista e os ignorados por tipo, como antes
   - **Aguardar a resposta.** Não iniciar sem confirmação
   - **Esta confirmação é a autorização de commit/push/PR** exigida por
     `guidelines/conduct.md`: incluir essa autorização no prompt do subagente
   - A autorização vale **só para os grupos desta onda** e só para commit, push e
     PR **em draft**. Não cobre merge, promoção do draft para "ready for review",
     apagar branch, nem os cards das ondas seguintes — cada onda é confirmada de
     novo

8. **Preparar uma worktree e uma branch por grupo:**
   - Só quando há grupos prontos para executar. O diretório atual **não** precisa
     ser o repositório do card: o mapa do passo 5 diz onde cada um roda. Sem
     nenhum repositório resolvido, todos os grupos estão bloqueados e a onda não
     roda
   - `slug-do-grupo`:
     - grupo declarado como `**PR {nome}**` → `{onda}-{nome}` normalizado
     - grupo de um card → o `slug` do card, preservando a convenção
       `feature/{slug-do-card}`
   - `branch` = `feature/{slug-do-grupo}`. Se a branch já existir, **bloquear o
     grupo** e reportar: ela pode conter trabalho anterior
   - `git -C {repo} fetch origin --prune`
   - `git -C {repo} worktree add -b feature/{slug-do-grupo} {pai-do-repo}/{nome-do-repo}-wt-{slug-do-grupo} origin/{base}`,
     com `{base}` na branch default do repositório (`main`, preferindo-a a
     `master`). A worktree nasce da base atualizada sem mexer no working tree
     principal
   - Sem remote configurado: avisar e criar a worktree a partir de `{base}`
       local, reportando que a base pode estar desatualizada
   - Falha ao criar a worktree → o grupo fica bloqueado e a onda não roda
   - **Uma worktree por grupo**: os cards do grupo rodam em sequência nela; grupos
     diferentes nunca compartilham working tree nem branch

9. **Disparar um subagente por grupo (grupos em paralelo):**
   - Um subagente por grupo, com contexto isolado, rodando **dentro da worktree do
     grupo** e executando os cards do grupo **em sequência**. O prompt:

     ```
     Você está trabalhando no grupo "{nome-do-grupo}" do épico "{épico}".

     Diretório de trabalho: {path-da-worktree}   ← worktree do grupo
     Repositório principal: {path-do-repo}
     Branch: feature/{slug-do-grupo} — já criada a partir de origin/{base}. NÃO crie outra.

     Cards deste grupo, NESTA ORDEM (um commit set por card, na mesma branch):
       1. {card-a}
       2. {card-b}

     Para cada card, na ordem:

     a) /start-card "{card}"
        - A branch atual já é a do grupo: o comando pula checkout, pull e
          criação de branch
        - Move o card para 2.in_progress e atualiza o .agent_obsidian da worktree
        - Se o comando perguntar qualquer coisa, PARE e retorne o bloqueio: não
          há usuário neste fluxo

     b) /work-on-card "{card}"
        - Executa TODAS as tarefas pendentes do card
        - Marca tarefas, documenta "Discussões", preenche "Descrição Técnica" e
          "Conhecimento Adquirido"
        - Commita conforme `guidelines/commit guidelines.md`, deixando a história
          legível: o review vai ler os dois cards juntos
        - NÃO chame /review-card por card — o grupo inteiro tem um PR só

     Depois do ÚLTIMO card do grupo:

     c) /review-card "{último-card}"
        - Valida o grupo todo, faz push da branch e cria **UM** Pull Request
        - O título e o corpo do PR cobrem todos os cards do grupo, agrupados por
          assunto; citar cada card pelo nome
        - O PR DEVE ser draft: `gh pr create --draft ...`
        - Move o último card para 3.in_review e grava pr_url e reviewed

     d) Para os DEMAIS cards do grupo (os que não foram o último):
        - Atualizar o frontmatter: `status: In Review`, `reviewed: {hoje}` e o
          mesmo `pr_url` do grupo
        - Mover cada um para 3.in_review preservando a subpasta de projeto
          (`guidelines/conduct.md` §Movimentação de cards no board)

     e) Ao final, remover `{path-da-worktree}/.agent_obsidian` e a própria
        worktree, do repositório principal:
        `git -C {path-do-repo} worktree remove {path-da-worktree}`
        - A branch feature/{slug-do-grupo} **permanece**: o /complete-card roda
          depois, no repositório principal, e é ele quem apaga após o merge

     REGRA CRÍTICA — PR em draft:
     - Um único PR por grupo, sempre draft
     - Merge, promoção para "ready for review" e remoção de branch não fazem
       parte deste fluxo

     Ao final, retorne: status do grupo, branch, URL do PR, cards concluídos vs
     pendentes, bloqueios encontrados e se a worktree foi removida.
     ```

   - Disparar os subagentes **em paralelo** — um por grupo. Grupos de
     repositórios diferentes não se cruzam; é isso que torna o paralelismo
     seguro, já que cards que disputam arquivo estão no mesmo grupo
   - Cada subagente tem contexto isolado — não compartilham memória entre si

10. **Falha e bloqueio na onda:**
   - O **primeiro** bloqueio ou falha interrompe o despacho dos grupos restantes
     da onda: não dispare o próximo subagente
   - Deixar terminar o que já está rodando e consolidar o resultado deles
   - Grupo que falha no meio não abre PR: os cards já commitados ficam na branch
     do grupo, e o relatório diz em qual card parou
   - **Nenhuma onda seguinte é considerada** nesta execução
   - O relatório aponta o card/grupo, o motivo e o que fazer: resolver o
     bloqueio; para PR em draft, merge seguido de `/complete-card` manual. Só
     então rodar o comando de novo

11. **Consolidar resultados:**
   - Aguardar os subagentes despachados terminarem
   - Montar um relatório consolidado:
     ```
     🎯 Orquestração concluída — onda {N} de {total}

     ## Grupos processados ({g}) — {p} PRs

     ### ✅ Concluídos ({g})
     - PR 1 — {nome}: {card-a}, {card-b} → {url}
     - PR 2 — {nome}: {card-c}             → {url}

     ### ⚠️ Bloqueados ({g})
     - {grupo} → motivo: {bloqueio}

     ### ❌ Falharam ({g})
     - {grupo} → parou em {card}: {erro}

     ## Cards por estado
     - Em 3.in_review: {n}
     - Não executados nesta chamada: Onda {N+1}: {cards}

     ## Próximos passos
     - Revise os PRs em draft e marque como "ready for review" quando apropriado
     - Após o merge de CADA PR, use /complete-card nos cards daquele grupo — o
       mesmo PR cobre mais de um card
     - Rode /orchestrate-cards "{épico}" de novo para a próxima onda
     ```

12. **Verificar a limpeza:**
   - `git -C {repo} worktree list` não deve mostrar nenhuma worktree `-wt-` sobrando
   - Worktree que sobrou → informar o caminho e o comando de remoção; **não**
     executar `git worktree remove --force`
   - A branch de cada grupo concluído continua existindo, à espera do merge

13. **Não consolidar conhecimento automaticamente:**
   - O `/condense-memory` só roda após o merge (via `/complete-card`)
   - O orquestrador **não** deve chamar `/condense-memory`

## Notas Importantes

- O épico não é executado: ele fornece a ordem e é concluído por último, com
  `/complete-card`, quando todos os cards das ondas estiverem em `4.done`
- Card com `repo:` vazio é bloqueante de propósito. É o caso do card que **cria**
  o repositório: rode esse card fora do lote (`/start-card` + `/work-on-card` +
  `/review-card`), preencha `repo:` ao concluir e volte a orquestrar
- Duas fontes de ordem convivem: `## Ondas` no épico manda quando existe; os
  `depends_on` dos filhos são o fallback e o contrapeso da validação
- O link do filho para o épico é parentesco, não dependência: contá-lo como
  dependência criaria ciclo e nada rodaria (`guidelines/IA best practices.md` §8)
- **Um PR por grupo, não por card.** Review é o passo caro: cards que tocam os
  mesmos arquivos rodam em sequência na mesma branch e viram um PR só. Quem
  decide o agrupamento é o usuário, no refinamento do épico — o orquestrador só
  obedece ao plano e valida colisões (`guidelines/IA best practices.md` §9)
- **Colisão entre grupos aborta.** Nunca reagrupar por conta própria: o
  agrupamento confirmado é o que foi revisado com o usuário

## Casos de Uso

### Executar um épico, uma onda por vez
```
/orchestrate-cards "{nome-do-épico}"
```
Monta as ondas e os grupos de PR do épico, mostra o plano, confirma e executa
**só a onda atual**. Cada grupo roda numa worktree própria e gera um PR em draft;
grupos de repositórios diferentes rodam em paralelo. Depois do merge de cada PR,
`/complete-card` em todos os cards daquele grupo e rodar de novo para a próxima
onda.

### Trabalhar em todos os cards prontos (comportamento anterior)
```
/orchestrate-cards
```
Processa todos os cards de implementação em `1.not_started/` numa onda só, cada
um com PR em draft. Cards `report`, `investigation`, `experiment` e `epic` são
ignorados e informados no resultado; use `/work-on-card` e `/complete-card`
individualmente para esses tipos.

### Trabalhar em um subconjunto
```
/orchestrate-cards "autenticação"
```
Processa apenas os cards que casam com o filtro.