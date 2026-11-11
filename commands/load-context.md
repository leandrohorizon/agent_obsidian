Você é um assistente que carrega o contexto completo de um card — ou do projeto, quando ainda não há card — para iniciar ou continuar uma sessão de trabalho.

## Tarefa
Carregar todo o contexto necessário. **Com card:** o próprio card, guidelines (conduta + código), condensed memory e cards dependentes, preparando o ambiente para trabalhar na tarefa. **Sem card:** guidelines, memória do projeto, estado do Git e os cards deste repositório, sem pedir nome de card e sem tocar no `.agent_obsidian`.

## Argumentos
- `<nome-do-card>`: (Opcional) Nome do card (sem extensão .md) ou caminho parcial. Se não fornecido, usa o card do `.agent_obsidian`; se o estado não tiver card, o comando roda no **modo sem card**

## Modos
- **Com card:** há `<nome-do-card>` ou `.agent_obsidian` com `current_card` preenchido. Segue os passos 1 a 9.
- **Sem card:** nenhum argumento e `current_card` ausente, `null` ou estado ilegível. Segue a seção "Modo sem card" e **não** pede nome de card.

## Instruções

1. **Verificar configuração:**
   - Verificar se `$OBSIDIAN_VAULT_PATH` está definida
   - Se não estiver, instruir: `export OBSIDIAN_VAULT_PATH="/caminho/para/vault"`

2. **Determinar o modo e qual card carregar:**
   - Se `<nome-do-card>` foi fornecido como argumento, usar ele e buscar normalmente
   - Se não foi fornecido:
     - Tentar ler `.agent_obsidian` no diretório atual
     - Se arquivo existe e tem `current_card` não-null, usar `current_card.path` diretamente (não precisa buscar!)
     - Se não existe, o JSON é inválido ou `current_card` é null, **seguir para "Modo sem card"** — não pedir nome de card

3. **Ler o card pela leitura enxuta** (`guidelines/IA best practices.md` §6):
   - Se veio do `.agent_obsidian`, usar o path direto: Read `current_card.path`
   - Se foi passado nome, procurar em todas as pastas do board na seguinte ordem:
     - `$OBSIDIAN_VAULT_PATH/board/2.in_progress/` (prioridade)
     - `$OBSIDIAN_VAULT_PATH/board/3.in_review/`
     - `$OBSIDIAN_VAULT_PATH/board/1.not_started/`
     - `$OBSIDIAN_VAULT_PATH/board/0.backlog/`
     - `$OBSIDIAN_VAULT_PATH/board/4.done/`
   - Se não encontrar, listar cards disponíveis
   - Identificar estado atual (qual pasta está)
   - Ler `guidelines/card work types.md`
   - Card sem `work_type` é `implementation`; valor desconhecido interrompe o carregamento com erro explícito

4. **Carregar guidelines e condensed memory:**
   - Seguir `guidelines/conduct.md` ("Carregamento de `guidelines/` —
     profundidade" e "Carregamento de contexto do card")
   - Se não houver memória de projeto, informar que ainda não há conhecimento
     consolidado

5. **Carregar cards dependentes e dependentes deste:**
   - Onde ler e como tratar cada forma: `guidelines/IA best practices.md` §8
   - Para cada card dependência: ler o card e resumir
   - Para cada card dependente: ler e resumir o que ele consome deste card
   - Se o card já foi lido nesta sessão e está em `4.done/` ou `5.archived/`, **não reler** (são estáveis)
   - Se não houver nenhuma das duas formas, pular este passo

6. **Verificar contexto do repositório:**
   - Para `implementation`, executar `git branch --show-current`, `git status --short` e `git log -1 --oneline`
   - Para `report` e `investigation`, não exigir Git nem usar branch/commits como contexto do card
   - Para `experiment`, não executar nenhum comando Git nem apresentar dados de Git

7. **Sincronizar branch e estado (`.agent_obsidian`):**
   - Valor desconhecido de `work_type` interrompe o fluxo com erro explícito,
     conforme o passo 3.
   - Para `implementation` ou quando `work_type` estiver ausente:
     - Comparar a branch atual (`git branch --show-current`) com a branch do
       card (campo `branch:` do frontmatter).
     - **Se divergirem**, perguntar antes de trocar:
       ```
       O card está na branch `{branch-do-card}`, mas o repositório está em `{branch-atual}`.
       Deseja mudar para `{branch-do-card}`?

       1. Sim — trocar de branch (recomendado)
       2. Não — continuar em `{branch-atual}`
       ```
     - **Aguardar a resposta.** Não trocar de branch sem confirmação.
     - Se o usuário escolher trocar, verificar alterações não commitadas com
       `git status --short`. Se houver, parar e perguntar o que fazer (commit,
       stash ou cancelar); caso contrário, executar
       `git checkout {branch-do-card}`.
     - Atualizar a branch com o remoto: executar `git pull` na branch do card.
       Se falhar (conflito, sem upstream ou sem remote), parar e reportar; não
       seguir com contexto de uma branch desatualizada ou em conflito. Se não
       houver remote configurado, avisar e seguir (não há o que puxar).
     - Atualizar `.agent_obsidian.current_card` para o card carregado. Se veio
       por argumento, gravar `name` e `path`; se o path aponta para uma pasta
       diferente da atual (por exemplo, o card foi movido de `2.in_progress/`
       para `3.in_review/`), corrigir para a localização real. Preservar os
       outros campos (`version`, `vault_path`, `guidelines_path`,
       `condensed_memory_path`).
     - Se a branch já é a do card e `current_card` já está correto, não alterar
       nada — apenas reportar que está sincronizado.
   - Para `report`, `investigation` e `experiment`, não comparar branch,
     perguntar sobre checkout, executar comandos Git nem afirmar que a branch
     está sincronizada. Atualizar somente `.agent_obsidian.current_card` para o
     card carregado (nome e path, corrigindo path de card movido) e preservar
     todos os outros campos. O passo 6 continua valendo, conforme os limites de
     cada tipo.

8. **Analisar modificações da branch** — somente para `implementation` (ou
   quando `work_type` estiver ausente). Para `report`, `investigation` e
   `experiment`, pular este passo; valor desconhecido já foi interrompido no
   passo 3.
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
   - Para `report` e `investigation`, substituir os campos Branch/Pull por `Git: não aplicável a este tipo` e omitir as seções de contexto/modificações da branch.
   - Para `experiment`, informar `Git: não utilizado conforme o tipo do card` e omitir qualquer seção de branch, pull ou diff.
   ```
   📋 Contexto carregado: {nome-do-card}

   **Estado:** {Not Started|In Progress|In Review|Done}
   **Localização:** board/{pasta}/
   **Branch:** {branch-atual} {✅ sincronizada com o card | ⚠️ divergente (card: {branch-do-card})}
   **Pull:** {✅ atualizada com o remoto | ⚠️ falhou: {motivo} | — sem remote}
   **Estado (.agent_obsidian):** {✅ atualizado | ✅ já estava correto}

   ## Resumo da Tarefa
   {Descrição do card em 2-3 linhas}

   ## Tarefas Pendentes
   - [ ] Tarefa 1
   - [ ] Tarefa 2
   {listar apenas as não completadas}

   ## Dependências
   {Se houver, listar cards dos quais este depende, com resumo}
   {Se não houver: "Nenhuma dependência identificada"}

   ## Dependentes
   {Se houver, listar cards que dependem deste, com o que consomem}
   {Se não houver: "Nenhum card depende deste"}

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
   - Consulte as discussões anteriores para contexto de decisões
   ```

## Modo sem card

Vale quando não há argumento e o `.agent_obsidian` não tem `current_card` (ou não
existe, ou é ilegível). Responde "onde este repositório está" sem exigir um card —
o caso mais comum de início de sessão.

**Este modo é somente leitura.** Não pede nome de card, não cria nem regrava o
`.agent_obsidian` e não escreve no repositório: nada de `git checkout`,
`git pull` ou `git fetch`.

### O que é o contexto de projeto

| Item | Como carregar |
|---|---|
| `guidelines/` inteiro, recursivo | passo 4, mesma profundidade do `guidelines/conduct.md` |
| `condensed memory/projects/{projeto}.md` | passo 4; ausente → informar que ainda não há conhecimento consolidado |
| Estado do Git | passo 6, mais `git status -sb` para mostrar upstream e à frente/atrás |
| Cards deste repositório em `2.in_progress/` e `3.in_review/` | passo S3 |

**Fora do contexto de projeto, com motivo:**

- `condensed memory/features/{feature}.md` — o path depende do `feature:` do card;
  sem card não há feature, e carregar todas as features seria ruído.
- `condensed memory/operational/*.md` — `guidelines/conduct.md` reserva a memória
  operacional ao `/work-on-card`, o único comando que a carrega.
- Cards em `0.backlog/`, `1.not_started/` e `4.done/` — são fila e histórico, não
  o estado ativo do repositório; a visão completa é do `/board-status`.
- Cards dependentes e dependentes deste — a relação parte de um card.
- Diff da branch atual contra a base — sem card o diff não é atribuível a nenhum
  trabalho e não muda a próxima ação.

### S1. Identificar o projeto

1. `$OBSIDIAN_VAULT_PATH` (passo 1); se o `.agent_obsidian` existir e tiver
   `vault_path`, ele prevalece — apenas leitura.
2. Memória de projeto: usar `condensed_memory_path` do `.agent_obsidian` quando
   existir. Sem estado, derivar de `/detect-project` (nome do diretório em
   lowercase, hífen e espaço → underscore):
   `{vault_path}/condensed memory/projects/{projeto}.md`.
3. Não executar `/init-agent-state` nem o auto-reparo de
   `validate_agent_state()`: os dois escrevem no `.agent_obsidian`.

### S2. Carregar guidelines e memória de projeto

Seguir o passo 4 igual ao modo com card. Reportar quais arquivos de `guidelines/`
foram lidos e se a memória de projeto existe.

### S3. Listar os cards deste repositório

1. Obter o remote: `git remote get-url origin`.
2. Normalizar para `owner/repo`, dos dois lados da comparação: lowercase; remover
   `git@`, `https://`, `ssh://` e o host; trocar o `:` do formato SCP por `/`;
   remover o sufixo `.git`; manter os dois últimos segmentos.
   - `https://github.com/leandrohorizon/agent_obsidian.git` → `leandrohorizon/agent_obsidian`
   - `git@github.com:leandrohorizon/third-hand.git` → `leandrohorizon/third-hand`
3. Listar os `.md` de `board/2.in_progress/` e `board/3.in_review/`, recursivo, e
   ler **apenas o frontmatter** de cada um — não o corpo
   (`guidelines/IA best practices.md` §6).
4. Comparar o `repo:` de cada card com o remote normalizado. Campo ausente ou
   valor que não é URL de repositório (ex: `Local (sem Git)`) não casa. A
   comparação é por repositório, **não** pelo nome do diretório: o diretório
   local pode ter nome diferente do repositório, e o `repo:` aparece nas duas
   formas (`https` e `git@`).
5. Sem remote (repositório local), não é possível atribuir cards ao diretório:
   informar e apresentar a lista vazia. **Não** cair para "todos os cards do
   board" — card de outro repositório na lista deste é pior que lista vazia.
6. Agrupar em dois blocos, um por pasta, para a saída distinguir o estado. Cards
   de qualquer `work_type` entram na lista; o comando não executa nada por tipo,
   apenas lê.

### S4. Não alterar o estado

O `.agent_obsidian` sai **intocado** neste modo: não criar, não gravar
`current_card`, não corrigir `path` de card movido e não reescrever `version`,
`guidelines_path` ou `condensed_memory_path`. Se o arquivo existir, só leitura.

### S5. Sincronizar branch e `git pull`: não

- Sem card o comando **não troca de branch e não faz `git pull`**. Não existe
  branch de card para sincronizar; puxar a branch atual altera a working tree sem
  que o usuário tenha escolhido o alvo e pode arrastar trabalho de outro card.
- O comando só **reporta**: branch atual, upstream e se está à frente/atrás
  (`git status -sb`). Quem decide atualizar é o usuário — sugerir `git pull` ou
  `git switch` no resumo, sem executar.
- A branch atual pode ser a default, uma branch de card já mergeado ou qualquer
  outra; o comando não julga nem corrige.

### S6. Apresentar o resumo do projeto

```
📦 Contexto do projeto: {projeto}
ℹ️ Modo sem card — `.agent_obsidian` não foi alterado.

## Guidelines Carregadas
✅ guidelines/ — {n} arquivos lidos: {lista}

## Conhecimento Consolidado
✅ Memória de projeto carregada: condensed memory/projects/{projeto}.md ({n} categorias)
⚠️ Nenhum conhecimento consolidado ainda

## Contexto do Repositório
🌿 Branch: {branch} — {↑{n} ↓{n} vs {upstream} | sem upstream}
📝 Alterações: {n} arquivos modificados
💾 Último commit: {hash} {mensagem}

## Cards deste Repositório
### 🚧 In Progress ({n})
- {nome} — branch: {branch} | work_type: {work_type}
### 👀 In Review ({n})
- {nome} — PR: {pr_url}
{Se nenhum: "Nenhum card deste repositório em 2.in_progress ou 3.in_review"}

ℹ️ Memória de feature e memória operacional ficam fora do contexto de projeto
   (dependem do card). O uso do Git foi apenas leitura.

Próximos passos sugeridos:
- Use /load-context "{nome}" para carregar um card inteiro
- Use /board-status para o board completo
- Use /start-card "{nome}" para iniciar um card
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

### Retomar card em outra branch
```
/load-context
```
Se o repositório estiver em uma branch diferente da do card, o comando pergunta se
deve trocar para a branch correta e atualiza o `.agent_obsidian`.

### Sessão nova, sem card ativo
```
/load-context
```
Sem argumento e com `current_card: null` no `.agent_obsidian`, o comando **não pede
nome de card**: carrega o `guidelines/` inteiro e a memória do projeto, mostra o
estado do Git e lista os cards deste repositório em `2.in_progress` e
`3.in_review`. Não troca de branch, não faz `git pull` e deixa o `.agent_obsidian`
intocado. Este caso só vale para a ausência de card — com argumento, ou com card
ativo no estado, o comportamento é o dos passos 1 a 9.

## Notas Importantes
- Este comando **não altera o conteúdo do card** — é de leitura para contexto
- No modo sem card o comando também **não escreve no repositório**: nenhum
  `git checkout`, `git pull` ou `git fetch`, e o `.agent_obsidian` sai intocado
- Os passos 7 e 8 (sincronizar branch, analisar modificações) rodam só para
  `implementation`; `report`, `investigation`, `experiment` e `work_type`
  desconhecido pulam os dois

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
