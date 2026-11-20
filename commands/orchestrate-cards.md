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

3. **Modo épico — montar as ondas:**
   - Ler **só** a seção de ondas do épico (`guidelines/IA best practices.md` §6):
     da linha `## Ondas` até o próximo heading `## `. Formato em
     `templates/card/epic.md`. Dentro da região:
     - cada `### Onda {N}` abre uma onda
     - só `- [[card]]` conta como card; prosa, linha de blockquote (`>`) e bloco
       cercado por ``` são ignorados
     - a **ordem é a ordem de aparição**; número fora de sequência é divergência
   - **Fallback:** seção ausente, ou sem nenhum `- [[card]]` em nenhuma onda →
     derivar dos filhos:
     - conjunto = `parse_frontmatter_list "$épico" "dependents"`
     - onda(card) = 1 + maior onda entre as dependências **dentro do conjunto**,
       ignorando o link para o épico — parentesco não é dependência de execução
       (`guidelines/IA best practices.md` §8)
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
     - nenhum card em duas ondas
     - nenhuma dependência interna na **mesma** onda (rodaria em paralelo) nem em
       onda **posterior** (inverteria a ordem)
   - **Divergência aborta:** imprimir card, onda e regra violada, e encerrar sem
     pedir confirmação, sem criar worktree e sem commitar. Não corrigir o épico
     por conta própria e não seguir com a ordem parcial

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
   - Nunca usar o diretório atual para um card de outro repositório: commitar no
     repositório errado é pior do que bloquear

6. **Escolher a onda:**
   - Modo épico: a **primeira** onda que não tem todos os cards em `4.done`
   - Modo lote: a lista do passo 4
   - Classificar cada card da onda pela pasta em que está no board:
     - `4.done` → já concluído, sai da onda
     - `1.not_started` → pronto para executar
     - `3.in_review` → **parar**: há PR em draft esperando merge, e a onda
       seguinte depende desse código na base. Pedir merge e `/complete-card` do
       card antes de continuar
     - `2.in_progress` → **parar**: card já iniciado fora do lote. Pedir
       `/review-card` (ou `/complete-card`) dele antes de continuar
   - Todos os cards da onda em `4.done` → avançar para a próxima; todas as ondas
     concluídas → informar que o épico está pronto para `/complete-card`
   - Qualquer card bloqueado (passo 5) → a onda **não roda**: informar o motivo e
     encerrar. Resolver o bloqueio é decisão do usuário

7. **Apresentar o plano e pedir confirmação:**
   ```
   🎯 Plano por ondas — épico "{nome}"

   Onda {N} (executar agora)
   - {card-a} → {path-do-clone}
   - {card-b}

   Ondas seguintes
   - Onda {N+1}: {card-c}, {card-d}

   Ignorados em 1.not_started (fora do épico) ({n})
   - {card-e}

   Bloqueios e divergências
   - {nenhum | card: motivo}

   Cada card seguirá: /start-card → /work-on-card → /review-card (PR em draft).
   Confirma? (1. Sim  2. Não)
   ```
   - Em modo lote, listar os cards da lista e os ignorados por tipo, como antes
   - **Aguardar a resposta.** Não iniciar sem confirmação
   - **Esta confirmação é a autorização de commit/push/PR** exigida por
     `guidelines/conduct.md`: incluir essa autorização no prompt do subagente
   - A autorização vale **só para os cards desta onda** e só para commit, push e
     PR **em draft**. Não cobre merge, promoção do draft para "ready for review",
     apagar branch, nem os cards das ondas seguintes — cada onda é confirmada de
     novo

8. **Preparar worktree e branch por card:**
   - Só quando há cards prontos para executar. O diretório atual **não** precisa
     ser o repositório do card: o mapa do passo 5 diz onde cada um roda. Sem
     nenhum repositório resolvido, todos os cards estão bloqueados e a onda não
     roda
   - Para cada card pronto:
     - `slug` = nome do card em minúsculas, sem acento, com cada sequência de
       caracteres não alfanuméricos virando `-`
     - `branch` = `feature/{slug}`. Se a branch já existir, **bloquear o card** e
       reportar: ela pode conter trabalho anterior
     - `git -C {repo} fetch origin --prune`
     - `git -C {repo} worktree add -b feature/{slug} {pai-do-repo}/{nome-do-repo}-wt-{slug} origin/{base}`,
       com `{base}` na branch default do repositório (`main`, preferindo-a a
       `master`). A worktree nasce da base atualizada sem mexer no working tree
       principal
     - Sem remote configurado: avisar e criar a worktree a partir de `{base}`
       local, reportando que a base pode estar desatualizada
   - Falha ao criar a worktree → o card fica bloqueado e a onda não roda
   - Uma worktree por card: dois cards do mesmo repositório não compartilham
     working tree nem branch

9. **Disparar os subagentes da onda (em paralelo):**
   - Um subagente por card, com contexto isolado, rodando **dentro da worktree do
     card**. O prompt deve instruir a sequência completa:

     ```
     Você está trabalhando no card "{nome-do-card}" do board Obsidian.

     Diretório de trabalho: {path-da-worktree}   ← já é a worktree do card
     Repositório principal: {path-do-repo}
     Branch: feature/{slug} — já criada a partir de origin/{base}. NÃO crie outra.

     Execute a sequência completa, na ordem:

     1. /start-card "{nome-do-card}"
        - A branch atual já é feature/{slug}: o comando pula checkout, pull e
          criação de branch
        - Move o card para 2.in_progress e atualiza o .agent_obsidian da worktree
        - Não há usuário para responder perguntas neste fluxo. Se algum passo
          exigir confirmação, PARE e retorne o bloqueio em vez de decidir sozinho

     2. /work-on-card "{nome-do-card}"
        - Carrega guidelines e contexto do card conforme `guidelines/conduct.md`,
          além dos cards dependentes
        - Executa TODAS as tarefas pendentes do card
        - Marca tarefas como concluídas, documenta decisões em "Discussões",
          preenche "Descrição Técnica" e "Conhecimento Adquirido"
        - Commita conforme `guidelines/commit guidelines.md`

     3. /review-card "{nome-do-card}"
        - Valida que todas as tarefas estão concluídas
        - Lê o histórico da branch e **não** reorganiza: reescrever histórico
          está fora da autorização do lote (`guidelines/commit guidelines.md`)
        - Cria o commit final, faz push da branch
        - Cria o Pull Request **EM DRAFT** (ver regra abaixo)
        - Move o card para 3.in_review e grava pr_url e reviewed
        - Ao final, remove `{path-da-worktree}/.agent_obsidian` e a própria
          worktree, rodando do repositório principal:
          `git -C {path-do-repo} worktree remove {path-da-worktree}`
        - A branch feature/{slug} **permanece**: o /complete-card roda depois, no
          repositório principal, e é ele quem apaga depois do merge

     REGRA CRÍTICA — PR em draft:
     - O PR DEVE ser criado como draft. Use `gh pr create --draft ...`
     - Nunca abrir PR pronto para review neste fluxo
     - Merge, promoção do draft para "ready for review" e remoção de branch não
       fazem parte deste fluxo, mesmo que o trabalho pareça pronto

     Ao final, retorne um resumo com:
     - Status do card (concluído / bloqueado / falhou)
     - Branch criada
     - URL do PR (draft)
     - Tarefas concluídas vs pendentes
     - Bloqueios ou dúvidas encontradas
     - Se a worktree foi removida
     ```

   - Disparar os subagentes **em paralelo** (um por card da onda)
   - Cada subagente tem contexto isolado — não compartilham memória entre si

10. **Falha e bloqueio na onda:**
   - O **primeiro** bloqueio ou falha interrompe o despacho dos cards restantes
     da onda: não dispare o próximo subagente
   - Deixar terminar o que já está rodando e consolidar o resultado deles
   - **Nenhuma onda seguinte é considerada** nesta execução
   - O relatório aponta o card, o motivo e o que fazer: resolver o bloqueio; para
     PR em draft, merge seguido de `/complete-card` manual. Só então rodar o
     comando de novo

11. **Consolidar resultados:**
   - Aguardar os subagentes despachados terminarem
   - Montar um relatório consolidado:
     ```
     🎯 Orquestração concluída — onda {N} de {total}

     ## Cards processados ({n})

     ### ✅ Concluídos ({n})
     - {card-a} → PR draft: {url}

     ### ⚠️ Bloqueados ({n})
     - {card-c} → motivo: {bloqueio}

     ### ❌ Falharam ({n})
     - {card-d} → erro: {erro}

     ## Não executados nesta chamada
     - Onda {N+1}: {cards} (aguardando a onda atual)
     - Bloqueados por falha: {cards}

     ## Próximos passos
     - Revise os PRs em draft e marque como "ready for review" quando apropriado
     - Após o merge de cada PR, use /complete-card no repositório principal
     - Rode /orchestrate-cards "{épico}" de novo para a próxima onda
     ```

12. **Verificar a limpeza:**
   - `git -C {repo} worktree list` não deve mostrar nenhuma worktree `-wt-` sobrando
   - Worktree que sobrou → informar o caminho e o comando de remoção; **não**
     executar `git worktree remove --force`
   - A branch de cada card concluído continua existindo, à espera do merge

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

## Casos de Uso

### Executar um épico, uma onda por vez
```
/orchestrate-cards "{nome-do-épico}"
```
Monta as ondas do épico, mostra o plano, confirma e executa **só a onda atual**,
cada card numa worktree própria. Depois do merge dos PRs, `/complete-card` em
cada card e rodar de novo para a próxima onda.

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