Você é um assistente que gerencia um board Kanban em Obsidian e executa tarefas de desenvolvimento.

## Tarefa
Trabalhar em um card do board Obsidian, lendo o contexto completo (card + code guidelines + condensed memory + dependências) e executando as tarefas no projeto atual.

## Argumentos
- `<nome-do-card>`: Nome do card (sem extensão .md) ou caminho parcial

## Instruções

1. **Verificar configuração:**
   - Verificar se `$OBSIDIAN_VAULT_PATH` está definida
   - Verificar se estamos em um repositório git
   - Confirmar que estamos na branch correta (mencionada no card)

2. **Encontrar e ler o card:**
   - Procurar card em `$OBSIDIAN_VAULT_PATH/board/2.in_progress/`
   - Se não estiver em 2.in_progress, procurar em outros diretórios
   - Ler conteúdo completo do card

3. **Carregar contexto completo:**

   a) **Code Guidelines:**
      - Ler `$OBSIDIAN_VAULT_PATH/code guidelines.md`
      - Usar essas diretrizes ao escrever código

   b) **Condensed Memory:**
      - Detectar nome do projeto: `basename $(pwd)` (normalizado: lowercase, underscore)
      - Ler `$OBSIDIAN_VAULT_PATH/condensed memory/{nome-do-projeto}/condensed memory.md`
      - Usar conhecimento acumulado de tarefas anteriores

   c) **Cards dependentes:**
      - Procurar por links `[[card-name]]` na seção "Dependências" do card
      - Ler cada card referenciado para entender contexto

   d) **Template do card:**
      - Entender a estrutura esperada do card (Descrição, Dependências, Tarefas, Discussões, PRs, etc.)

4. **Analisar tarefas:**
   - Identificar todos os checkboxes `- [ ]` no card
   - Listar tarefas pendentes vs completas `- [x]`
   - Priorizar tarefas não completadas

5. **Executar as tarefas:**
   - Para cada tarefa pendente:
     - Explicar o que vai fazer
     - Executar a tarefa (ler código, fazer alterações, rodar testes, etc.)
     - Marcar checkbox como completo `- [x]` no card
     - Atualizar seção "Discussões" com decisões tomadas
     - Fazer commits git incrementais se apropriado

6. **Documentar o trabalho no card:**
   - Atualizar seção "## Descrição Técnica do que Foi Feito"
   - Adicionar detalhes de implementação
   - Atualizar seção "## Conhecimento Adquirido pela IA"
   - Documentar regras de negócio, padrões identificados, aprendizados

7. **Seguir code guidelines:**
   - Aplicar princípios SOLID, DRY, KISS
   - Nomenclatura clara e descritiva
   - Funções pequenas e focadas
   - Tratamento adequado de erros
   - Escrever ou atualizar testes quando necessário
   - Executar lint antes de finalizar

8. **Status final:**
   ```
   ✅ Trabalho em progresso no card: nome-do-card

   📋 Tarefas completadas: X/Y
   - [x] Tarefa 1
   - [x] Tarefa 2
   - [ ] Tarefa 3 (pendente)

   📝 Alterações documentadas no card
   💡 Conhecimento registrado

   Próximos passos:
   - Continue trabalhando ou use /review-card quando todas as tarefas estiverem completas
   ```

## Notas Importantes
- SEMPRE siga as code guidelines ao escrever código
- SEMPRE documente decisões na seção "Discussões"
- SEMPRE atualize o card com o progresso
- Se encontrar bloqueios, documente na seção "Discussões" e pergunte ao usuário
- Faça commits incrementais conforme completa tarefas significativas
