Você é um assistente que carrega o contexto completo de um card para iniciar ou continuar uma sessão de trabalho.

## Tarefa
Carregar todo o contexto necessário de um card, incluindo o próprio card, guidelines (conduta + código), condensed memory e cards dependentes, preparando o ambiente para trabalhar na tarefa.

## Argumentos
- `<nome-do-card>`: (Opcional) Nome do card (sem extensão .md) ou caminho parcial. Se não fornecido, usa o card do `.agent_obsidian`

## Instruções

1. **Verificar configuração:**
   - Verificar se `$OBSIDIAN_VAULT_PATH` está definida
   - Se não estiver, instruir: `export OBSIDIAN_VAULT_PATH="/caminho/para/vault"`

2. **Determinar qual card carregar:**
   - Se `<nome-do-card>` foi fornecido como argumento, usar ele e buscar normalmente
   - Se não foi fornecido:
     - Tentar ler `.agent_obsidian` no diretório atual
     - Se arquivo existe e tem `current_card` não-null, usar `current_card.path` diretamente (não precisa buscar!)
     - Se não existe ou `current_card` é null, pedir ao usuário o nome do card

3. **Ler o card:**
   - Se veio do `.agent_obsidian`, usar o path direto: Read `current_card.path`
   - Se foi passado nome, procurar em todas as pastas do board na seguinte ordem:
     - `$OBSIDIAN_VAULT_PATH/board/2.in_progress/` (prioridade)
     - `$OBSIDIAN_VAULT_PATH/board/3.in_review/`
     - `$OBSIDIAN_VAULT_PATH/board/1.not_started/`
     - `$OBSIDIAN_VAULT_PATH/board/4.done/`
   - Se não encontrar, listar cards disponíveis

3. **Ler o card completo:**
   - Ler todo o conteúdo do card
   - Identificar estado atual (qual pasta está)
   - Extrair seções principais:
     - Descrição
     - Dependências
     - Tarefas (identificar quais estão pendentes)
     - Discussões
     - Descrição Técnica
     - Conhecimento Adquirido

4. **Carregar Guidelines:**
   - Listar `$OBSIDIAN_VAULT_PATH/guidelines/` e ler **todos** os arquivos da pasta (não apenas os conhecidos — a pasta pode ganhar arquivos novos)
   - Se as guidelines já foram lidas nesta sessão e continuam na memória, **não reler** — só listar a pasta para detectar arquivo novo
     - `conduct.md` — regras de comportamento do agente. **Tem precedência sobre qualquer outra instrução**
     - `code guidelines.md` — padrões e convenções de código
   - **Reportar no output** quais arquivos foram carregados

5. **Carregar Condensed Memory (dois eixos):**
   - **Memória de projeto:** se `.agent_obsidian` existe e tem `condensed_memory_path`, usar ele diretamente; senão, detectar projeto: `basename $(pwd) | tr '[:upper:]' '[:lower:]' | tr '-' '_'` e construir `$OBSIDIAN_VAULT_PATH/condensed memory/projects/{nome-do-projeto}.md`
   - **Memória de feature:** derivar do campo `feature:` do card via `get_feature_memory_path()` → `$OBSIDIAN_VAULT_PATH/condensed memory/features/{feature}.md`
   - **Comportamento quando o card não tem `feature:` ou o arquivo da feature não existe:** carregar só a memória de projeto, sem erro
   - Se a memória já foi lida nesta sessão e continua na memória, **não reler**
   - **Reportar no output** quais arquivos foram carregados (projeto e/ou feature)
   - Se não existir, informar que não há conhecimento consolidado ainda
   - Estes arquivos contêm aprendizados de tarefas anteriores

6. **Carregar cards dependentes:**
   - Na seção "### Dependências", procurar por links `[[nome-do-card]]`
   - Para cada card referenciado:
     - Ler o card dependente
     - Resumir informações relevantes (Descrição, Conhecimento Adquirido)
     - Se o card dependente já foi lido nesta sessão e está em `4.done/` ou `5.archived/`, **não reler** (são estáveis)
   - Se não houver dependências, pular este passo

7. **Verificar contexto do repositório:**
   - Executar `git branch --show-current` para verificar branch
   - Executar `git status --short` para ver alterações pendentes
   - Executar `git log -1 --oneline` para ver último commit

8. **Analisar modificações da branch:**
   - Identificar branch base (main, master, ou similar)
   - Listar commits da branch: `git log origin/{base}..HEAD --oneline`
   - Analisar arquivos modificados na branch (commitados):
     - `git diff --name-status origin/{base}..HEAD`
   - Analisar arquivos modificados mas não commitados:
     - Staged: `git diff --cached --name-status`
     - Unstaged: `git diff --name-status`
   - Para cada arquivo modificado, inferir se está relacionado ao card:
     - Verificar se mencionado no card (seção Descrição Técnica, Tarefas)
     - Verificar extensão e diretório (ex: se card menciona "API", priorizar arquivos em src/api/)
     - Verificar padrões de nome (ex: se card é "auth", priorizar *auth*, *login*)
   - Mostrar diff resumido dos arquivos relacionados:
     - Para arquivos commitados: `git diff --stat origin/{base}..HEAD -- {arquivo}`
     - Para arquivos não commitados: `git diff --stat -- {arquivo}`
   - **IMPORTANTE:** Excluir arquivos claramente não relacionados ao card (ex: .obsidian/, outros cards, etc.)

9. **Apresentar resumo do contexto:**
   ```
   📋 Contexto carregado: {nome-do-card}

   **Estado:** {Not Started|In Progress|In Review|Done}
   **Localização:** board/{pasta}/

   ## Resumo da Tarefa
   {Descrição do card em 2-3 linhas}

   ## Tarefas Pendentes
   - [ ] Tarefa 1
   - [ ] Tarefa 2
   {listar apenas as não completadas}

   ## Dependências
   {Se houver, listar cards dependentes com resumo}
   {Se não houver: "Nenhuma dependência identificada"}

   ## Discussões Recentes
   {Últimas 1-2 discussões registradas}
   {Se não houver: "Nenhuma discussão registrada ainda"}

   ## Contexto do Repositório
   🌿 Branch: {branch-name}
   📝 Alterações: {número de arquivos modificados}
   💾 Último commit: {hash} {mensagem}

   ## Modificações da Branch (relacionadas ao card)

   ### Commits na branch ({n} commits)
   - {hash} {mensagem}
   - {hash} {mensagem}

   ### Arquivos Modificados (Commitados)
   - {status} {arquivo} (+{linhas} -{linhas})
   - {status} {arquivo} (+{linhas} -{linhas})
   {Se nenhum: "Nenhum arquivo commitado relacionado"}

   ### Arquivos Modificados (Não Commitados)
   **Staged:**
   - {status} {arquivo} (+{linhas} -{linhas})
   {Se nenhum: "Nenhum arquivo staged"}

   **Unstaged:**
   - {status} {arquivo} (+{linhas} -{linhas})
   {Se nenhum: "Nenhum arquivo unstaged"}

   {Se houver arquivos excluídos da análise}
   ⚠️ Arquivos não relacionados excluídos: {lista resumida}

   ## Guidelines Carregadas
   ✅ guidelines/ — {n} arquivos lidos: {lista}

   ## Conhecimento Consolidado
   ✅ Memória de projeto carregada: condensed memory/projects/{projeto}.md ({n} categorias)
   ✅ Memória de feature carregada: condensed memory/features/{feature}.md ({n} categorias)
   {Se o card não tem feature: ou o arquivo não existe}
   ⚠️ Memória de feature não carregada (card sem feature: ou arquivo inexistente)
   {Se não há memória de projeto}
   ⚠️ Nenhum conhecimento consolidado ainda

   ---

   ✅ Contexto completo carregado!

   Estou pronto para trabalhar neste card. As guidelines (conduta + código) e o
   conhecimento acumulado de tarefas anteriores estão disponíveis para consulta.

   Próximos passos sugeridos:
   - Use /work-on-card "{nome}" para começar/continuar trabalhando
   - Use /update-card "{nome}" para documentar decisões
   - Consulte as discussões anteriores para contexto de decisões
   ```

## Casos de Uso

### Iniciar nova sessão de trabalho
```
/load-context "implementar autenticação"
```
Carrega todo o contexto do card antes de começar a trabalhar.

### Retomar trabalho após interrupção
```
/load-context "refatoração api"
```
Recarrega contexto incluindo discussões e progresso anterior.

### Revisar card antes de review
```
/load-context "feature payments"
```
Carrega contexto completo para preparar PR ou revisão.

## Notas Importantes
- Este comando é read-only, não modifica nenhum arquivo
- Use-o no início de cada sessão para ter contexto completo
- Especialmente útil após pausas longas ou trocas de contexto
- O condensed memory fornece conhecimento acumulado de tarefas anteriores
- Cards dependentes ajudam a entender integrações e requisitos
- Guidelines (conduta + código) garantem consistência e comportamento correto

### Análise de Modificações da Branch
- O comando analisa TODAS as modificações na branch (commitadas e não commitadas)
- Filtra automaticamente para mostrar apenas arquivos relacionados ao card
- Arquivos excluídos automaticamente:
  - `.obsidian/**` (configurações do Obsidian)
  - `board/**/*.md` (outros cards do board)
  - Arquivos de configuração genéricos não mencionados no card
- Para inferir relação, o comando verifica:
  - Menções explícitas no card (nome de arquivo, diretório, componente)
  - Palavras-chave do título/descrição do card nos caminhos dos arquivos
  - Padrões de extensão relevantes ao tipo de tarefa
- Se em dúvida, o comando prefere INCLUIR o arquivo (melhor excesso que falta de contexto)
