Você é um assistente que revisa Pull Requests usando as guidelines do vault e as memórias do projeto.

## Tarefa
Revisar um PR recebido — de trabalho próprio ou de terceiro — e devolver achados com arquivo, linha, severidade e a **regra citada** que sustenta cada um. O comando é análise sem efeito de estado: não publica nada no GitHub, não move card e não escreve em condensed memory.

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
   - Executar: `gh pr view <n> --json number,title,url,state,isDraft,author,headRefName,headRefOid,baseRefName,files,body`
   - Se `state` não for `OPEN`, revisar o diff normalmente e avisar no resultado que o PR está fechado ou mergeado

2. **Carregar as guidelines do vault:**
   - Seguir `guidelines/conduct.md` §"Carregamento de `guidelines/` — profundidade"
   - Reportar no resultado quais arquivos foram lidos
   - Aplicar essas guidelines a qualquer PR, inclusive de repositório desconhecido

3. **Identificar o card do PR e a memória de feature:**
   - Procurar no board o card cujo frontmatter `pr_url` aponta para este PR: `grep -rl "pull/<n>" "{vault}/board"` e confirmar o campo `pr_url`
   - Se mais de um card apontar para o mesmo PR, **parar e perguntar** qual vale
   - Se houver card:
     - ler pela leitura enxuta (`guidelines/IA best practices.md` §6) e usar `repo:`, `feature:` e `### Descrição` como fonte de intenção do autor
     - derivar a memória de feature do `feature:` com `get_feature_memory_path()` (`commands/lib/common.sh`), carregando-a só se o campo e o arquivo existirem
   - Se não houver card: seguir sem ele, declarar no resultado "card do PR: não identificado" e não tentar adivinhar feature nem intenção

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
   - **Nunca clonar neste passo.** O clone só acontece no passo 8, quando a revisão originar trabalho de código

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

8. **Gerar card novo, sempre com confirmação:**

   Condições para propor card: a revisão encontrou trabalho de código — correção pedida e aceita, melhoria aceita, ou problema real sem dono.

   - Apresentar a proposta ao usuário e **esperar a resposta**. Sem confirmação, nada é gravado no vault (`guidelines/conduct.md` §Ações destrutivas ou irreversíveis)
   - Aprovada a criação:
     - usar `{vault}/templates/card template.md` como base, como o `/create-card` faz
     - preencher `repo:` com a URL do repositório do PR, `work_type: implementation` (contrato em `guidelines/card work types.md`; se o arquivo não existir no vault, manter `implementation` e registrar a ausência no resultado) e `feature:` com o slug sugerido — listando os arquivos existentes em `condensed memory/features/` e aceitando feature nova quando não houver correspondência
     - declarar `depends_on` com o card do PR revisado, quando ele existir
     - montar `### Tarefas` conforme `guidelines/IA best practices.md` §7: registrar comportamento a implementar e teste a **escrever**, não passo já garantido pelo fluxo
   - Destino:
     - clone existente em `~/workspace/{repo}` → `board/1.not_started/`
     - sem clone → `board/0.backlog/` como proposta; `/start-card` exige repositório Git local, então o card só avança depois do clone
   - **Não converter o card revisado nem movê-lo de pasta.** Card que descobre trabalho de código gera card novo, como no precedente de `investigation`
   - Um card por problema agrupável; não abrir um card por achado
   - O clone só é criado quando o usuário confirmar o trabalho de código: `git clone <url> ~/workspace/{repo}`, para que o nome da memória de projeto (`basename` do diretório) saia igual ao nome do repositório

9. **Documentar no card do PR:**
   - Se houver card identificado no passo 3, acrescentar entrada em `### Discussões` com data, o caso do repositório, a contagem de achados por severidade e o resumo de cada achado com a regra citada
   - Não alterar `status`, `reviewed`, `pr_url` nem mover o card: revisar não é etapa do ciclo do card
   - Se o card estiver em `4.done/` ou `5.archived/`, não editá-lo: registrar os achados só no resultado e avisar o usuário
   - Se não houver card, registrar apenas no resultado apresentado ao usuário e dizer que não havia card para documentar

10. **Entregar o resultado, sem publicar nada:**

    **Proibido publicar no GitHub:** nada de `gh pr review`, `gh pr comment`, `gh pr edit`, nem `gh api` em `.../reviews` ou `.../comments`. Consultar o PR é leitura; os achados vão para o usuário e para o card.

    ```markdown
    ## Revisão do PR #{n} — {título}

    **Repositório:** {owner}/{repo}
    **Caso:** repo clonado com memória | repo clonado sem memória | repo não clonado
    **Card do PR:** {nome do card} | não identificado
    **Memórias carregadas:** {projeto}, {feature} | nenhuma
    **Guidelines carregadas:** {lista}
    **Arquivos revisados:** {n} de {total} | ignorados: {lista com motivo}

    ### Achados ({quantidade})
    {achados no formato do passo 6, ordenados por severidade}

    ### Sugestões sem regra ({quantidade})
    {sugestões no formato do passo 7, ou "nenhuma"}

    ### Limitações desta revisão
    - {convenção do repositório desconhecida, arquivo ignorado, hunk não lido, PR fechado, ...}

    ### Próximos passos
    - {card criado, card proposto aguardando clone, correções esperadas do autor, nada a fazer}
    ```

11. **Confirmar o que não foi feito:**
    - Nada foi publicado no PR
    - Nenhum card foi movido
    - Nenhuma condensed memory foi escrita — consolidação é do `/complete-card`, depois do merge (`guidelines/conduct.md` §Condensed memory)

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

### Caso 2 — PR sem card não quebra o comando

Entrada: URL de PR de repositório que não está clonado e não tem card no board.

Saída esperada:
- `Card do PR: não identificado` e `Memórias carregadas: nenhuma`
- caso `repo não clonado`, com achados restritos ao diff e às guidelines do vault
- todo achado com `Convenção do repositório: desconhecida`
- nenhuma tentativa de leitura de memória de feature, nenhum clone, nenhuma escrita em card
- resultado entregue ao usuário com a limitação declarada

## Notas Importantes
- Revisar não é aprovar: o comando não emite `approve` nem `request changes` em lugar nenhum
- `gh` só é usado para leitura (`pr view`, `pr diff`, `api` em conteúdo de arquivo)
- Sem memória, o que falta não é regra, é a decisão daquele repositório — declarar a lacuna em vez de preenchê-la por suposição
- O primeiro card concluído em um repositório cria a memória dele via `/condense-memory`; a revisão só abre o caminho, não consolida
