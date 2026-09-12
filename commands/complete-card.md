Você é um assistente que gerencia um board Kanban em Obsidian e finaliza tarefas.

## Tarefa
Finalizar um card, movendo-o de "3.in_review" para "4.done" e garantindo que toda documentação está completa.

## Argumentos
- `<nome-do-card>`: (Opcional) Nome do card (sem extensão .md) ou caminho parcial. Se não fornecido, usa o card do `.agent_obsidian`

## Instruções

1. **Verificar configuração:**
   - Verificar se `$OBSIDIAN_VAULT_PATH` está definida

2. **Determinar qual card completar:**
   - Se `<nome-do-card>` foi fornecido como argumento, usar ele e buscar normalmente
   - Se não foi fornecido:
     - Tentar ler `.agent_obsidian` no diretório atual
     - Se arquivo existe e tem `current_card` não-null, usar `current_card.path` diretamente (não precisa buscar!)
     - Se não existe ou `current_card` é null, pedir ao usuário o nome do card

3. **Ler e validar o card:**
   - Se veio do `.agent_obsidian`, usar o path direto: Read `current_card.path`
   - Se foi passado nome, procurar em `$OBSIDIAN_VAULT_PATH/board/3.in_review/`
   - Ler conteúdo completo do card
   - Verificar se o PR foi merged (se houver PR mencionado)

3. **Validar completude:**
   - ✅ Todas as tarefas `- [x]` completadas?
   - ✅ Seção "Descrição Técnica do que Foi Feito" preenchida?
   - ✅ Seção "Conhecimento Adquirido pela IA" preenchida?
   - ✅ Seção "PRs" com status atualizado?
   - ✅ Seção "Discussões" documentada?

4. **Completar documentação:**
   - Se algo estiver faltando, perguntar ao usuário ou completar automaticamente

5. **Atualizar frontmatter do card:**
   - Atualizar campos no frontmatter YAML:
     ```yaml
     status: Done
     completed: {YYYY-MM-DD}
     ```
   - Se PR existir, atualizar:
     ```yaml
     pr_status: Merged
     ```
   - Calcular tempo total baseado nas datas de `started` e `completed`

6. **Mover o card:**
   - Mover arquivo de `$OBSIDIAN_VAULT_PATH/board/3.in_review/card.md`
   - Para: `$OBSIDIAN_VAULT_PATH/board/4.done/card.md`

7. **Limpar .agent_obsidian:**
   - Ler `.agent_obsidian` do diretório atual (se existir)
   - Manter todos os campos existentes (version, vault_path, code_guidelines_path, conduct_path, condensed_memory_path)
   - Atualizar campo `current_card` para `null`
   - Escrever de volta usando Write tool preservando estrutura completa

8. **Consolidar conhecimento automaticamente:**
   - Executar `/condense-memory "{nome-do-card}"` automaticamente
   - Isso irá extrair e consolidar o conhecimento do card recém-finalizado
   - O conhecimento será imediatamente disponível para futuras tarefas

8. **Confirmar:**
   ```
   ✅ Card concluído!

   📝 Card: nome-do-card.md
   🔀 Movido: 3.in_review → 4.done
   🎉 Tarefa finalizada com sucesso!

   📊 Resumo:
   - Tarefas completadas: X
   - PRs merged: Y
   - Conhecimento documentado: ✅

   💡 Conhecimento consolidado:
   - Card processado e adicionado à condensed memory
   - Aprendizados disponíveis para futuras tarefas
   ```

## Notas Importantes
- Certifique-se de que TODO o trabalho está documentado antes de mover para done
- Cards em 4.done servem como histórico e base de conhecimento
- A seção "Conhecimento Adquirido pela IA" é crucial para /condense-memory
- Não delete informações ao mover o card, preserve todo o histórico
- **O comando automaticamente chama `/condense-memory` após finalizar** para consolidar o conhecimento imediatamente
