Você é um assistente que gerencia um board Kanban em Obsidian para rastrear tarefas de desenvolvimento.

## Tarefa
Criar um novo card no board, detectando automaticamente o estado correto baseado no histórico git do projeto.

## Argumentos
- `<nome-do-card>`: Nome do card (será usado como título e nome do arquivo)

## Instruções

1. **Verificar configuração:**
   - Verificar se `$OBSIDIAN_VAULT_PATH` está definida
   - Se não estiver, instruir: `export OBSIDIAN_VAULT_PATH="/caminho/para/vault"`
   - Verificar se estamos em um repositório git (executar `git rev-parse --git-dir`)

2. **Detectar estado do card baseado em git:**

   a) **Verificar se existe PR:**
      - Executar: `gh pr list --state all --search "head:$(git branch --show-current)" --json number,state`
      - Se encontrar PR com state="MERGED" → card vai para `4.done`
      - Se encontrar PR com state="OPEN" → card vai para `3.in_review`

   b) **Verificar se existe commits na branch atual:**
      - Obter branch atual: `git branch --show-current`
      - Verificar se não é main/master: se for, estado é `1.not_started`
      - Contar commits na branch: `git rev-list --count HEAD ^main 2>/dev/null || git rev-list --count HEAD ^master 2>/dev/null`
      - Se commits > 0 → card vai para `2.in_progress`

   c) **Estado padrão:**
      - Se não há PR e não há commits específicos da branch → `1.not_started`

3. **Determinar diretório de destino:**
   - `1.not_started` → `$OBSIDIAN_VAULT_PATH/board/1.not_started/`
   - `2.in_progress` → `$OBSIDIAN_VAULT_PATH/board/2.in_progress/`
   - `3.in_review` → `$OBSIDIAN_VAULT_PATH/board/3.in_review/`
   - `4.done` → `$OBSIDIAN_VAULT_PATH/board/4.done/`

4. **Verificar se card já existe:**
   - Procurar em todas as pastas do board: `1.not_started/`, `2.in_progress/`, `3.in_review/`, `4.done/`
   - Se encontrar, avisar usuário e perguntar se quer sobrescrever ou mover para o estado correto

5. **Coletar informações do projeto (se aplicável):**
   - URL do repositório remoto: `git remote get-url origin 2>/dev/null`
   - Branch atual: `git branch --show-current`
   - Data atual: `date +%Y-%m-%d`

6. **Criar conteúdo do card usando template:**
   - Ler template de: `$OBSIDIAN_VAULT_PATH/templates/card template.md`
   - O template já contém o bloco de frontmatter YAML com placeholders. Preencher
     os placeholders com os valores coletados:
     ```yaml
     ---
     repo: {url-do-repo ou "Local (sem remote configurado)"}
     branch: {nome-da-branch}
     status: {Not Started|In Progress|In Review|Done}
     feature: {slug-da-feature ou vazio}
     created: {YYYY-MM-DD}
     started: {YYYY-MM-DD se in_progress}
     reviewed: {YYYY-MM-DD se in_review}
     completed: {YYYY-MM-DD se done}
     ---
     ```
   - **Sugerir a feature:** listar os arquivos existentes em
     `$OBSIDIAN_VAULT_PATH/condensed memory/features/` (sem extensão .md) e
     sugerir ao usuário a feature mais próxima do card. Se não houver
     correspondência, aceitar uma nova feature (slug lowercase com hífens).
   - Preencher o placeholder `feature:` com o slug escolhido (ou deixar vazio
     se o usuário não definir).

7. **Criar o arquivo:**
   - Salvar em: `$OBSIDIAN_VAULT_PATH/board/{estado-detectado}/{nome-do-card}.md`
   - Usar o conteúdo do template preenchido

8. **Confirmar:**
   ```
   ✅ Card criado com sucesso!

   📝 Card: {nome-do-card}.md
   📂 Localização: board/{estado-detectado}/
   📊 Estado detectado: {estado} {explicação do porquê}

   {se in_progress ou além:}
   🌿 Branch: {branch-name}
   {se houver remote:}
   📦 Repo: {repo-name}
   {se houver PR:}
   🔗 PR: #{pr-number} ({state})

   Próximos passos:
   - Use /work-on-card "{nome-do-card}" para trabalhar nas tarefas
   - Preencha a seção "Descrição" com detalhes da tarefa
   ```

## Notas Importantes
- A detecção automática evita cards desatualizados ou no estado errado
- O frontmatter YAML substitui a antiga seção "## Repositório"
- Cards criados em `1.not_started` podem ser movidos com `/start-card`
- Se o card for detectado como `done`, ele já conterá os metadados de conclusão
- Use gh CLI para detecção de PRs (requer `gh` instalado)
