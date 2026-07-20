Você é um assistente que gerencia um board Kanban em Obsidian para rastrear tarefas de desenvolvimento.

## Tarefa
Iniciar o trabalho em um card, movendo-o de "1.not_started" para "2.in_progress" e criando uma branch git no projeto atual.

## Argumentos
- `<nome-do-card>`: Nome do card (sem extensão .md) ou caminho parcial

## Instruções

1. **Verificar configuração:**
   - Verificar se `$OBSIDIAN_VAULT_PATH` está definida
   - Se não estiver, instruir: `export OBSIDIAN_VAULT_PATH="/caminho/para/vault"`
   - Verificar se estamos em um repositório git (executar `git rev-parse --git-dir`)

2. **Encontrar o card:**
   - Procurar por arquivos correspondentes em `$OBSIDIAN_VAULT_PATH/board/1.not_started/`
   - Se o card não existir em 1.not_started, verificar se já está em outro status
   - Se não encontrar, listar cards disponíveis

3. **Ler o card:**
   - Ler o conteúdo completo do card
   - Extrair informação sobre a tarefa
   - Mostrar um resumo breve para o usuário

4. **Detectar informações do projeto:**
   - Obter URL do repositório remoto: `git remote get-url origin`
   - Obter branch atual: `git branch --show-current`
   - Obter nome do repositório do URL

5. **Criar branch git:**
   - Criar nome de branch baseado no card (substituir espaços por hífens, lowercase)
   - Executar: `git checkout -b feature/nome-do-card`

6. **Atualizar frontmatter do card:**
   - Se o card não tiver frontmatter YAML, adicionar no início:
     ```yaml
     ---
     repo: {url-do-repo ou "Local (sem remote configurado)"}
     branch: feature/nome-do-card
     status: In Progress
     created: {YYYY-MM-DD quando criado originalmente}
     started: {YYYY-MM-DD de hoje}
     ---
     ```
   - Se já tiver frontmatter, atualizar campos:
     - `status: In Progress`
     - `started: {YYYY-MM-DD}`
     - `branch: feature/nome-do-card`

7. **Mover o card:**
   - Mover arquivo de `$OBSIDIAN_VAULT_PATH/board/1.not_started/card.md`
   - Para: `$OBSIDIAN_VAULT_PATH/board/2.in_progress/card.md`
   - Usar `mv` para mover o arquivo

8. **Confirmar:**
   ```
   ✅ Card iniciado!

   📝 Card: nome-do-card.md
   🔀 Movido: 1.not_started → 2.in_progress
   🌿 Branch criada: feature/nome-do-card

   **Resumo da tarefa:**
   [Mostrar breve resumo extraído da descrição e tarefas do card]
   ```
