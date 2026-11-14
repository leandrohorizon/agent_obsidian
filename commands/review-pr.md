Você é um assistente que revisa Pull Requests usando as guidelines do vault e as memórias do projeto.

## Tarefa
Revisar um PR recebido — de trabalho próprio ou de terceiro — devolver achados com arquivo, linha, severidade e a **regra citada** que sustenta cada um e manter o card do PR sincronizado com o ciclo de vida dele: todo PR tem um card no board, atualizado automaticamente e roteado para a memória quando mergeado.

## Argumentos
- `<pr>`: (Obrigatório) Número ou URL do PR a revisar
- `[caminho-do-clone]`: (Opcional) Diretório local do repositório do PR, quando o clone não está em `~/workspace/{repo}`

## Fontes, em ordem de peso

1. `guidelines/` — vale para qualquer repositório
2. `condensed memory/projects/{projeto}.md` — decisões e convenções **daquele** repositório
3. o card do PR e a memória de feature do `feature:` dele
4. o diff

## Instruções

1. **Verificar configuração e ler o PR:**
   - Obter o vault: ler `.agent_obsidian` do diretório atual, se existir e for válido; senão usar `$OBSIDIAN_VAULT_PATH`; senão instruir `export OBSIDIAN_VAULT_PATH="/caminho/para/vault"`
   - Verificar `gh auth status`
   - Resolver `<pr>`: se for URL, extrair `{owner}/{repo}` e o número; se for número, usar o repositório do diretório atual (`git remote get-url origin`)
   - Executar: `gh pr view <n> --json number,title,url,state,isDraft,author,headRefName,headRefOid,baseRefName,mergedAt,files,body`
   - Classificar o estado do PR: `OPEN` (aberto), `DRAFT` (`state: OPEN` com `isDraft: true`), `CLOSED` sem `mergedAt` (fechado sem merge) e `MERGED` (`state: MERGED` ou `mergedAt` presente). Revisar o diff em qualquer estado e registrar o estado no resultado

2. **Carregar as guidelines do vault:**
   - Seguir `guidelines/conduct.md` §"Carregamento de `guidelines/` — profundidade"
   - Reportar no resultado quais arquivos foram lidos
   - Aplicar essas guidelines a qualquer PR, inclusive de repositório desconhecido

3. **Localizar ou criar o card do PR (todo PR tem um card):**
   - Procurar no board o card cujo frontmatter `pr_url` aponta para este PR: `grep -rl "pull/<n>" "{vault}/board"` e confirmar o campo `pr_url` completo — `pull/<n>` pode casar PR de outro repositório, então validar a URL inteira. Procurar também na seção legada de PRs do corpo quando o frontmatter não tiver `pr_url`
   - Se mais de um card apontar para o mesmo PR, **parar e perguntar** qual vale
   - Se houver card: ler pela leitura enxuta (`guidelines/IA best practices.md` §6) e usar `repo:`, `feature:`, `pr_author` e `### Descrição` como fonte de intenção do autor; derivar a memória de feature do `feature:` com `get_feature_memory_path()` (`commands/lib/common.sh`), carregando-a só se o campo e o arquivo existirem
   - Se não houver card, **criar um card** `work_type: implementation` a partir de `templates/card/implementation.md`, mesmo que a revisão não encontre problema:
     - preencher `repo:` com a URL do repositório do PR e `work_type: implementation`
     - preencher `pr_url:` com a URL do PR e `pr_author:` com `author.login` do `gh pr view`
     - preencher `feature:` — listar os `.md` existentes em `condensed memory/features/` (ignorar `.gitkeep`) e sugerir a feature mais próxima, aceitando feature nova quando não houver correspondência
     - montar `### Tarefas` conforme `guidelines/IA best practices.md` §7: registrar comportamento e teste a **escrever**, não passo já garantido pelo fluxo
     - destino: `0.backlog/` quando não houver clone em `~/workspace/{repo}`; `1.not_started/` quando houver clone (o estado é sincronizado no passo 8)
   - Se o card existir, atualizá-lo em vez de criar outro: registrar/atualizar `pr_author` (fonte: `author.login`) e preservar os demais campos e o estado atual

4. **Classificar o caso do repositório:**

   Ordem de procura do clone:
   1. `[caminho-do-clone]`, se informado
   2. o diretório atual, se `git remote get-url origin` aponta para `{owner}/{repo}`
   3. `~/workspace/{repo}`, se existir e o `origin` apontar para `{owner}/{repo}`

   Memória de projeto (dois eixos, um arquivo por repositório): normalizar o nome a partir do basename do clone — lowercase, hífens e espaços por underscore, como em `commands/detect-project.md` — e montar `{vault}/condensed memory/projects/{nome}.md`. Sem clone, usar `{repo}` normalizado.

   | Caso | Como reconhecer | O que a revisão usa | Efeito no achado |
   |---|---|---|---|
   | Repo clonado, com memória | clone encontrado **e** arquivo de memória existe | guidelines + memória de projeto + memória de feature + card + diff | achado com regra citada; classe "padrão do repositório" ou "decisão anterior" |
   | Repo clonado, sem memória | clone encontrado **e** arquivo de memória não existe | guidelines + o próprio código do clone | convenção do repositório é **desconhecida**: declarar no achado, não supor padrão |
   | Repo não clonado | nenhum clone encontrado | `gh pr view`, `gh pr diff`, `gh api` — só o que a API oferece | achado restrito ao diff e às guidelines do vault; convenção **desconhecida** |

   - Declarar o caso escolhido no resultado, nomeando os arquivos de memória carregados (ou a ausência deles)
   - **Nunca clonar neste passo.** O clone só é criado quando o usuário confirmar trabalho de código, em `~/workspace/{repo}`, para que `/start-card` e a memória de projeto funcionem

5. **Recortar o contexto do diff:**
   - Executar: `gh pr diff <n> --name-only`
   - Ordenar os arquivos por risco: primeiro os que tocam segredos, migrations, produção e configuração de ambiente; depois os que tocam áreas das guidelines (comentários, testes, nomenclatura, dependências); por último o restante
   - Ignorar por padrão, mencionando no resultado que foram ignorados: lockfiles (`Gemfile.lock`, `package-lock.json`, `yarn.lock`, `poetry.lock`, `go.sum`), código gerado e minificado (`dist/`, `build/`, `vendor/`, `*.min.js`, `*.pb.go`), binários e imagens, `.obsidian/` e fixtures de snapshot
   - Ler **por arquivo**, não o diff inteiro: `gh api "repos/{owner}/{repo}/pulls/<n>/files" --paginate` devolve cada arquivo com o campo `patch`; alternativa é `gh pr diff <n> --patch` recortado pelos cabeçalhos `diff --git a/<caminho>`
   - Quando o hunk não bastar para julgar, ler o arquivo inteiro no head do PR: `gh api "repos/{owner}/{repo}/contents/<caminho>?ref=<headRefOid>" -H "Accept: application/vnd.github.raw"`
   - `patch` ausente no retorno da API significa arquivo binário ou diff grande demais; nesse caso declarar no resultado em vez de supor o conteúdo
   - Arquivo com diff muito extenso: ler apenas os hunks que tocam a área da guideline aplicável
   - Aplicar a cada trecho **somente** a guideline pertinente; não reler arquivo já lido (`guidelines/conduct.md` §Leitura de arquivos)
   - Registrar no resultado os arquivos lidos e os ignorados com o motivo

6. **Levantar achados com regra citada:**

   Cada achado usa este formato:
   ```markdown
   #### {n}. {título curto}
   - **Arquivo:** `{caminho}:{linha}` (linha do arquivo no head do PR)
   - **Severidade:** Bloqueio | Alta | Média | Baixa
   - **Regra violada:** `{arquivo da guideline} §{seção}` ou `condensed memory/projects/{projeto}.md › {categoria} › {item}`
   - **Classe:** guideline do vault | padrão do repositório | decisão anterior
   - **Evidência:** {trecho do diff que viola a regra}
   - **Por que procede:** {o que a regra exige e como o trecho diverge}
   - **Como verificar:** {comando ou leitura objetiva que confirma ou derruba o achado}
   - **Convenção do repositório:** conhecida | desconhecida
   ```

   Severidade:
   - **Bloqueio** — viola `guidelines/conduct.md` ou regra de `guidelines/` de forma direta; o PR não deve ser mergeado assim
   - **Alta** — viola padrão ou decisão registrada na memória do repositório, ou cria risco concreto (bug, regressão, perda de dado)
   - **Média** — viola convenção citável sem risco imediato
   - **Baixa** — desvio menor de estilo citável

   Regras de montagem:
   - Achado sem regra citável **não é achado** — vai para o passo 7, como sugestão
   - Achado sem `Como verificar` também não entra: sem forma de derrubar a afirmação, é opinião
   - Nos casos "repo clonado, sem memória" e "repo não clonado", marcar `Convenção do repositório: desconhecida` e escrever essa limitação no achado. Não inventar padrão do repositório: `guidelines/conduct.md` §Honestidade técnica proíbe apresentar como verificado o que não foi lido
   - Não repetir o mesmo achado por ocorrência: agrupar as linhas afetadas no mesmo item
   - Não citar caminho, linha ou número de PR que não foi lido de fato

7. **Separar sugestões sem regra:**

   O maior risco do comando é virar gerador de opinião com aparência de norma. Sugestão fica em seção própria, nunca se mistura com achado e nunca recebe severidade.

   Critério de inclusão (todos obrigatórios):
   - não existe regra em `guidelines/` nem na memória que sustente o item
   - a alternativa é concreta — arquivo, trecho e mudança descritos, não "melhorar X"
   - a alternativa é testável: dá para dizer o que provaria que ela vale

   ```markdown
   #### {n}. {título curto}
   - **Arquivo:** `{caminho}:{linha}`
   - **Alternativa:** {mudança concreta}
   - **Como testar:** {verificação objetiva}
   ```

   - Máximo de 5 sugestões, ordenadas por impacto; o que não couber é descartado, não resumido
   - Item sem alternativa concreta ou sem teste possível é descartado em silêncio

8. **Sincronizar o card com o estado do PR:**
   - `OPEN` (sem `isDraft`): mover o card para `3.in_review/` e registrar `status: In Review` — vale para PRs próprios e recebidos. Seguir `guidelines/conduct.md` §Movimentação de cards: exatamente um arquivo no destino, nenhuma cópia na origem, frontmatter atualizado
   - `DRAFT` (`isDraft: true`): não mover para `3.in_review/`; registrar no card que o PR está em draft e aguardar
   - `CLOSED` sem `mergedAt` (fechado sem merge): mover o card para `5.archived/` e registrar `pr_status: Closed`
   - `MERGED` (`state: MERGED` ou `mergedAt` presente): registrar `pr_status: Merged` e encaminhar para o fluxo de conclusão (passo 9)
   - PR reaberto após fechado: reavaliar pelo estado atual; se o card estava em `5.archived/`, devolvê-lo à pasta correspondente ao novo `state`
   - Card em `0.backlog/` sem clone: atualizar `pr_url`, `pr_author`, `pr_status` e o registro da revisão, mas **não** mover para `3.in_review/` nem `5.archived/` — pastas de andamento exigem repositório Git local; registrar a limitação no resultado
   - Se o card movido for o `current_card` ativo de outro projeto, corrigir o `current_card.path` do `.agent_obsidian` do projeto dono após mover

9. **PR mergeado — alimentar a memória:**
   - Após confirmar o merge (`mergedAt` presente), seguir o fluxo de `/complete-card` para o card do PR: ele valida, move para `4.done/`, limpa `current_card` (só se apontar para este card), volta à branch default, apaga a branch do card e chama `/condense-memory`
   - A consolidação roteia para a memória de projeto (`condensed memory/projects/{repo}.md`) e, quando o card declarar `feature:`, para a memória de feature; card sem `feature:` consolida só no eixo de projeto — pular o eixo de feature quando vazio
   - Consolidar apenas conhecimento duradouro e reutilizável, sem duplicações; nunca registrar conclusão ou aprendizado como definitivo antes do merge
   - `/complete-card` roda no diretório do clone; sem clone, registrar o resultado no card e informar que a conclusão aguarda o clone

10. **Documentar a revisão no card do PR:**
   - Acrescentar entrada em `### Discussões` com data, o caso do repositório, `pr_author`, o estado do PR e a contagem de achados por severidade, com o resumo de cada achado e a regra citada
   - O card sempre existe (passo 3); não há mais o caso "sem card"
   - Se o card estiver em `4.done/` ou `5.archived/` e o PR for reaberto, não editá-lo: registrar os achados só no resultado e avisar o usuário

11. **Entregar o resultado, sem publicar nada:**

    **Proibido publicar no GitHub:** nada de `gh pr review`, `gh pr comment`, `gh pr edit`, nem `gh api` em `.../reviews` ou `.../comments`. Consultar o PR é leitura; os achados vão para o usuário e para o card.

    ```markdown
    ## Revisão do PR #{n} — {título}

    **Repositório:** {owner}/{repo}
    **Caso:** repo clonado com memória | repo clonado sem memória | repo não clonado
    **Card do PR:** {nome do card} — criado | atualizado
    **Dono do PR (pr_author):** {author.login}
    **Estado do PR:** OPEN | DRAFT | CLOSED sem merge | MERGED
    **Memórias carregadas:** {projeto}, {feature} | nenhuma
    **Guidelines carregadas:** {lista}
    **Arquivos revisados:** {n} de {total} | ignorados: {lista com motivo}

    ### Achados ({quantidade})
    {achados no formato do passo 6, ordenados por severidade}

    ### Sugestões sem regra ({quantidade})
    {sugestões no formato do passo 7, ou "nenhuma"}

    ### Limitações desta revisão
    - {convenção do repositório desconhecida, arquivo ignorado, hunk não lido, card sem clone não movido, ...}

    ### Próximos passos
    - {card criado/atualizado, sincronização de estado aplicada, correções esperadas do autor, /complete-card pendente após merge}
    ```

12. **Confirmar o que não foi feito:**
    - Nada foi publicado no PR — a leitura do estado (`gh pr view`/`gh pr diff`/`gh api`) não emite review, comentário nem mudança
    - Nenhuma condensed memory foi escrita antes do merge — a consolidação é do `/complete-card`, depois do merge (`guidelines/conduct.md` §Condensed memory)
    - O card foi movido/arquivado apenas conforme o estado do PR (passo 8); nenhum outro card foi tocado

## Casos de verificação

Casos que o comando precisa acertar. Servem como roteiro de conferência após editar o comando.

### Caso 1 — achado cita a guideline violada

Entrada: PR com card no board, repositório clonado com memória, diff que adiciona `# valida o input` em um método novo.

Saída esperada:
```markdown
#### 1. Comentário narrativo em método novo
- **Arquivo:** `app/services/parser.rb:42`
- **Severidade:** Média
- **Regra violada:** `guidelines/code guidelines.md` §Comentários
- **Classe:** guideline do vault
- **Evidência:** `# valida o input`
- **Por que procede:** a regra proíbe comentário que repete o código e manda refatorar para nome descritivo
- **Como verificar:** ler o método; se o nome já expressa a validação, o comentário é redundante
- **Convenção do repositório:** conhecida
```

O achado só é válido com a citação da seção — "comentário desnecessário" sem `§Comentários` seria sugestão, não achado.

### Caso 2 — PR sem card e sem clone cria card no backlog

Entrada: URL de PR de repositório que não está clonado e não tem card no board.

Saída esperada:
- card criado em `0.backlog/` com `repo:`, `pr_url:` e `pr_author:` preenchidos, `work_type: implementation`
- caso `repo não clonado`, com achados restritos ao diff e às guidelines do vault; todo achado com `Convenção do repositório: desconhecida`
- nenhum clone executado; card não movido para `3.in_review/` nem `5.archived/` (sem repositório Git local)
- resultado entregue com a limitação declarada

### Caso 3 — PR aberto move o card para `3.in_review`

Entrada: PR `OPEN` (sem `isDraft`) com card no board em `1.not_started/`.

Saída esperada:
- card movido para `3.in_review/` com `status: In Review` (exatamente um arquivo, sem cópia na origem)
- `pr_author` e `pr_url` registrados no frontmatter

### Caso 4 — PR fechado sem merge arquiva o card

Entrada: PR `CLOSED` sem `mergedAt`.

Saída esperada:
- card movido para `5.archived/` com `pr_status: Closed`
- nenhuma consolidação de memória

### Caso 5 — PR mergeado encaminha para conclusão

Entrada: PR `MERGED` (ou `CLOSED` com `mergedAt` presente).

Saída esperada:
- `pr_status: Merged` no card
- card encaminhado para o fluxo de `/complete-card` (que chama `/condense-memory`)
- memória consolidada só depois do merge; card sem `feature:` consolida apenas no eixo de projeto

### Caso 6 — card sem `feature:` não quebra o roteamento

Entrada: PR mergeado cujo card não declara `feature:`.

Saída esperada:
- consolidação roteada apenas para `condensed memory/projects/{repo}.md`
- nenhuma tentativa de escrever `condensed memory/features/` sem campo

## Notas Importantes
- Revisar não é aprovar: o comando não emite `approve` nem `request changes` em lugar nenhum
- `gh` só é usado para leitura (`pr view`, `pr diff`, `api` em conteúdo de arquivo); nunca para abrir, fechar, mergear, comentar ou revisar
- Sem memória, o que falta não é regra, é a decisão daquele repositório — declarar a lacuna em vez de preenchê-la por suposição
- A invocação de `/review-pr` é o pedido explícito dos seus efeitos no board (criar/atualizar/mover o card do PR), como o `/review-card` é o pedido de commit/push — o GitHub permanece somente leitura
- O primeiro card concluído em um repositório cria a memória dele via `/condense-memory`; a revisão abre o caminho, a consolidação só acontece depois do merge
- Card sem clone não é movido para pastas de andamento; a conclusão pós-merge aguarda o clone
