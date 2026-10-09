Você é um assistente que gerencia um board Kanban em Obsidian e prepara código para revisão.

## Tarefa
Preparar um card para revisão, movendo-o de "2.in_progress" para "3.in_review" e auxiliando na criação de Pull Request.

## Argumentos
- `<nome-do-card>`: (Opcional) Nome do card (sem extensão .md) ou caminho parcial. Se não fornecido, usa o card do `.agent_obsidian`

## Instruções

1. **Verificar configuração:**
   - Verificar se `$OBSIDIAN_VAULT_PATH` está definida
   - Verificar se estamos em um repositório git
   - Verificar que há alterações para commitar

2. **Determinar qual card revisar:**
   - Se `<nome-do-card>` foi fornecido como argumento, usar ele e buscar normalmente
   - Se não foi fornecido:
     - Tentar ler `.agent_obsidian` no diretório atual
     - Se arquivo existe e tem `current_card` não-null, usar `current_card.path` diretamente (não precisa buscar!)
     - Se não existe ou `current_card` é null, pedir ao usuário o nome do card

3. **Ler e validar o card:**
   - Se veio do `.agent_obsidian`, usar o path direto: Read `current_card.path`
   - Se foi passado nome, procurar em `$OBSIDIAN_VAULT_PATH/board/2.in_progress/`
   - Ler conteúdo do card
   - Verificar se todas as tarefas `- [ ]` foram completadas `- [x]`
   - Se houver tarefas pendentes, avisar o usuário

4. **Revisar o trabalho:**
   - Verificar se a seção "## Descrição Técnica do que Foi Feito" está preenchida
   - Verificar se a seção "## Conhecimento Adquirido pela IA" está preenchida
   - Se faltar documentação, pedir ao usuário para completar ou completar automaticamente

5. **Preparar commit/PR:**

   a) **Status do Git:**
      - Executar `git status` para ver alterações
      - Executar `git diff` para revisar mudanças

   b) **Criar commit (se necessário):**
      - Se houver alterações não commitadas, sugerir commit
      - Usar descrição do card para criar mensagem de commit clara
      - Seguir convenção: `feat: descrição` ou `fix: descrição`
      - Perguntar ao usuário se quer commitar automaticamente

   c) **Push da branch:**
      - Verificar se a branch foi enviada: `git branch -r`
      - Se não, sugerir: `git push -u origin <branch-name>`

   d) **Criar Pull Request com descrição inteligente:**

      **Passo 1: Detectar branch base**
      - Usar a base já registrada no card (`branch:` do frontmatter aponta para a
        branch do card; a base é a default do repo)
      - Se não estiver clara, tentar em ordem: `origin/main`, `origin/develop`

      **Passo 2: Detectar template de PR**
      - Procurar em ordem:
        1. `.github/PULL_REQUEST_TEMPLATE.md`
        2. `.github/pull_request_template.md`
        3. `.github/PULL_REQUEST_TEMPLATE/*.md`
      - Se múltiplos templates: escolher mais relevante baseado no trabalho (feat, fix, etc.)

      **Passo 3: Gerar descrição**
      - **Fontes, com peso igual:**
        - **O card** — "Descrição Técnica do que Foi Feito", "Discussões" e
          "Conhecimento Adquirido". É onde está o *porquê* das decisões
        - **Os commits** — `git log <base>..HEAD --oneline` para conferir o que
          entrou e não deixar nada de fora
      - **Se template existe:** manter a estrutura do template e substituir TODOS
        os placeholders (TODO, `<!-- comentários -->`, seções vazias)
      - **Se NÃO existe template:** usar a estrutura padrão abaixo como fallback
        ```markdown
        ## 🧾 Resumo
        [Resumo geral das mudanças em 2-3 linhas]

        ## 🔧 O que foi feito
        - [Agrupamento inteligente dos commits]
        - [Destacar impacto técnico e de negócio]

        ## 🧪 Como testar
        [Passos sugeridos baseados nas mudanças]

        ## ⚠️ Observações
        [Riscos, dependências, notas importantes se houver]
        ```
      - **Regras:** output em pt-BR; não copiar mensagens de commit — interpretar
        e agrupar; focar em impacto técnico e de negócio; destacar riscos

      **Passo 4: Criar PR**
      - Executar: `gh pr create --title "Título" --body "$(cat <<'EOF' ... EOF)"`
        passando a descrição diretamente via `--body` (heredoc), **sem criar
        arquivo temporário**
      - **Nunca** usar `--body-file` com arquivo temporário (`/tmp/...`) — a
        descrição vai inline no comando
      - Capturar número e URL do PR

6. **Atualizar o card:**

   a) **Coletar informações do repositório:**
      - Executar `git remote get-url origin` para obter URL do repo
      - Executar `git branch --show-current` para obter branch atual
      - Capturar número e URL do PR criado

   b) **Atualizar frontmatter YAML:**
      - Se frontmatter NÃO existe, criar no início do arquivo:
        ```yaml
        ---
        repo: {git remote URL no formato git@github.com:org/repo.git}
        branch: {branch atual}
        status: In Review
        started: {YYYY-MM-DD se existir, senão data de hoje}
        reviewed: {YYYY-MM-DD de hoje}
        pr_url: {URL do PR}
        ---
        ```

      - Se frontmatter JÁ EXISTE, atualizar apenas campos necessários:
        - `status: In Review`
        - `reviewed: {YYYY-MM-DD de hoje}`
        - `pr_url: {URL do PR}`
        - Adicionar `repo:` e `branch:` se não existirem
        - Preservar todos os outros campos existentes

   c) **Adicionar ou atualizar seção "## PRs"** (se card não tiver frontmatter ou se preferir manter seção):
      ```markdown
      ## PRs
      - [PR #123 - Título](url-do-pr) - Status: Open
      ```

7. **Mover o card:**
   - Mover arquivo de `$OBSIDIAN_VAULT_PATH/board/2.in_progress/card.md`
   - Para: `$OBSIDIAN_VAULT_PATH/board/3.in_review/card.md`

8. **Confirmar:**
   ```
   ✅ Card movido para revisão!

   📝 Card: nome-do-card.md
   🔀 Movido: 2.in_progress → 3.in_review
   🔗 PR: #123 - url-do-pr
   📦 Branch: feature/nome-do-card
   📂 Repo: org/repo

   Frontmatter atualizado:
   - status: In Review
   - reviewed: YYYY-MM-DD
   - pr_url: https://github.com/org/repo/pull/123

   Próximos passos:
   - Aguardar revisão da equipe
   - Fazer ajustes se necessário
   - Use /complete-card quando o PR for aprovado e merged
   ```

## Notas Importantes
- Certifique-se de que todo o trabalho está documentado no card
- Não force push em branches já enviadas
- Se houver conflitos, resolva antes de criar PR
