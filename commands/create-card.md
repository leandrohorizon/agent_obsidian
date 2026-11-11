Você é um assistente que gerencia um board Kanban em Obsidian para rastrear tarefas de desenvolvimento.

## Tarefa
Criar um card com template e estado apropriados ao `work_type`; consultar Git somente para `implementation`.

## Argumentos
- `<nome-do-card>`: Nome do card (será usado como título e nome do arquivo)

## Instruções

1. **Verificar configuração:**
   - Verificar se `$OBSIDIAN_VAULT_PATH` está definida
   - Se não estiver, instruir: `export OBSIDIAN_VAULT_PATH="/caminho/para/vault"`
   - Ler `guidelines/card work types.md` antes de escolher o fluxo
   - Inferir `work_type` do pedido quando estiver claro; perguntar apenas se estiver ambíguo. Todo card criado grava `work_type` no frontmatter; nunca criar card sem tipo
   - Para `implementation`, verificar se estamos em um repositório git (`git rev-parse --git-dir`)
   - Para `report`, `investigation` e `experiment`, não exigir Git
   - Para `report` e `investigation`, Git não determina estado nem branch
   - Para `experiment`, não executar nenhum comando Git

2. **Determinar estado do card:**

   Para `implementation`:
   - **Verificar se existe PR:**
      - Executar: `gh pr list --state all --search "head:$(git branch --show-current)" --json number,state`
      - Se encontrar PR com state="MERGED" → card vai para `4.done`
      - Se encontrar PR com state="OPEN" → card vai para `3.in_review`

   - **Verificar se existem commits na branch atual:**
      - Obter branch atual: `git branch --show-current`
      - Verificar se não é main/master: se for, estado é `1.not_started`
      - Contar commits na branch: `git rev-list --count HEAD ^main 2>/dev/null || git rev-list --count HEAD ^master 2>/dev/null`
      - Se commits > 0 → card vai para `2.in_progress`

   - **Estado padrão:**
      - Se não há PR e não há commits específicos da branch → `1.not_started`
      - **Exceção:** se o usuário pedir explicitamente para criar no backlog
        (card ainda não refinado ou não priorizado), usar `0.backlog`

   Para `report`, `investigation` e `experiment`:
   - Usar `1.not_started` por padrão ou `0.backlog` se o usuário pedir
     explicitamente uma ideia ainda não refinada. Não consultar PR, commits nem
     branch para esses tipos; para `experiment`, não executar comandos Git.

3. **Determinar diretório de destino:**
   - `0.backlog` → `$OBSIDIAN_VAULT_PATH/board/0.backlog/`
   - `1.not_started` → `$OBSIDIAN_VAULT_PATH/board/1.not_started/`
   - `2.in_progress` → `$OBSIDIAN_VAULT_PATH/board/2.in_progress/`
   - `3.in_review` → `$OBSIDIAN_VAULT_PATH/board/3.in_review/`
   - `4.done` → `$OBSIDIAN_VAULT_PATH/board/4.done/`

4. **Verificar se card já existe:**
   - Procurar em todas as pastas do board: `0.backlog/`, `1.not_started/`, `2.in_progress/`, `3.in_review/`, `4.done/`
   - Se encontrar, avisar usuário e perguntar se quer sobrescrever ou mover para o estado correto

5. **Coletar informações do projeto (se aplicável):**
   - Para `implementation`, obter URL (`git remote get-url origin 2>/dev/null`) e branch atual (`git branch --show-current`)
   - Para `report` e `investigation`, consultar o remote somente se disponível e deixar `branch:` vazio
   - Para `experiment`, não consultar o remote ou qualquer dado Git; deixar `repo:` e `branch:` vazios
   - Data atual: `date +%Y-%m-%d`

6. **Criar conteúdo do card usando template:**
   - Selecionar o template pelo tipo:
     - `implementation`: `templates/implementation card template.md`
     - `report`: `templates/report card template.md`
     - `investigation`: `templates/investigation card template.md`
     - `experiment`: `templates/experiment card template.md`
   - Preencher os placeholders do frontmatter com os valores coletados:
     ```yaml
     ---
     repo: {URL do remote quando disponível; vazio para experiment}
     branch: {nome-da-branch para implementation; vazio nos demais}
     work_type: {implementation|report|investigation|experiment}
     status:
       - {Not Started|In Progress|In Review|Done}
     feature: {slug-da-feature ou vazio}
     created: {YYYY-MM-DD}
     started: {YYYY-MM-DD se in_progress}
     reviewed: {YYYY-MM-DD se in_review}
     completed: {YYYY-MM-DD se done}
     ---
     ```
   - Para `implementation`, `report` e `investigation`, **sugerir a feature:** listar os arquivos `.md` existentes em
     `$OBSIDIAN_VAULT_PATH/condensed memory/features/` (sem extensão; ignorar
     `.gitkeep`) e sugerir ao usuário a feature mais próxima do card. Se não
     houver correspondência, aceitar uma nova feature (slug lowercase com hífens).
   - Para esses três tipos, preencher `feature:` com o slug escolhido (ou deixar
     vazio se o usuário não definir). Para `experiment`, não sugerir feature e
     manter `feature:` vazio.
   - **Tarefas:** registrar o trabalho da tarefa, não passo já garantido pelo
     fluxo — testes, lint, commit, push, PR, mover card, consolidar memória
     (`guidelines/IA best practices.md` §7). Registrar em vez disso o
     comportamento a implementar, o teste a **escrever** e o que ele prova,
     migração, rollback e documentação cujo conteúdo muda.
   - Para relatórios e investigações, documentos opcionais/obrigatórios ficam
     no vault central em `docs/{projeto}/reports/` ou
     `docs/{projeto}/investigations/`, conforme o template.
   - Para `experiment`, ferramentas e resultados ficam na pasta de trabalho
     atual e são mantidos após a conclusão; não devem ser enviados para memória.

7. **Criar o arquivo:**
   - Salvar em: `$OBSIDIAN_VAULT_PATH/board/{estado-detectado}/{nome-do-card}.md`
   - Usar o conteúdo do template preenchido

8. **Confirmar:**
   ```
   ✅ Card criado com sucesso!

   📝 Card: {nome-do-card}.md
   📂 Localização: board/{estado-detectado}/
   📊 Estado detectado: {estado} {explicação do porquê}

   {se implementation in_progress ou além:}
   🌿 Branch: {branch-name}
   {se houver remote:}
   📦 Repo: {repo-name}
   {se houver PR:}
   🔗 PR: #{pr-number} ({state})

   Próximos passos:
   - Use /work-on-card "{nome-do-card}" para trabalhar nas tarefas
   - Preencha a seção "Descrição" com detalhes da tarefa
   ```
   Para `report`, `investigation` e `experiment`, omitir linhas de branch/PR.

## Notas Importantes
- O frontmatter YAML substitui a antiga seção "## Repositório"
- Cards criados em `1.not_started` podem ser movidos com `/start-card`
- Cards em `0.backlog` são ideias ainda não refinadas/priorizadas; use
  `/refine-card` para amadurecer e mover para `1.not_started`
- Se o card for detectado como `done`, ele já conterá os metadados de conclusão
- Use gh CLI para detecção de PRs (requer `gh` instalado)
- Para `report` e `investigation`, não inferir estado Git nem mostrar branch/PR;
  os documentos são salvos no vault, não no repositório do projeto
- Para `experiment`, não executar Git; as ferramentas são criadas na pasta de
  trabalho atual e permanecem lá até limpeza manual, sem consolidação de memória
