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

4. **Validar completude:**
   - ✅ Todas as tarefas `- [x]` completadas?
   - ✅ Seção "Descrição Técnica do que Foi Feito" preenchida?
   - ✅ Seção "Conhecimento Adquirido pela IA" preenchida?
   - ✅ Seção "PRs" com status atualizado?
   - ✅ Seção "Discussões" documentada?

5. **Completar documentação:**
   - Se algo estiver faltando, perguntar ao usuário ou completar automaticamente

6. **Atualizar frontmatter do card:**
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

7. **Mover o card:**
   - Mover arquivo de `$OBSIDIAN_VAULT_PATH/board/3.in_review/card.md`
   - Para: `$OBSIDIAN_VAULT_PATH/board/4.done/card.md`

8. **Limpar .agent_obsidian:**
   - Ler `.agent_obsidian` do diretório atual (se existir)
   - Manter todos os campos existentes (version, vault_path, guidelines_path, condensed_memory_path)
   - Atualizar campo `current_card` para `null`
   - Escrever de volta usando Write tool preservando estrutura completa

9. **Voltar para a branch default e apagar a branch do card:**
   - Detectar a branch default do repositório (`main`/`master`), preferindo `main` quando ambas existirem
   - Ler a branch do card no frontmatter (`branch:`)
   - Verificar alterações não commitadas: `git status --short`
     - Se houver, **parar e avisar** — trocar de branch pode perder trabalho ou arrastar alterações para a branch errada. Perguntar o que fazer (commit, stash ou cancelar)
   - Executar: `git checkout {branch-default}`
   - Executar: `git pull` na branch default
     - Se o pull falhar (conflito, sem upstream, sem remote), **parar e reportar**. Não apagar a branch sobre estado desatualizado
     - Se não houver remote configurado, avisar e seguir
   - Apagar a branch do card: `git branch -d {branch-do-card}`
     - Usar `-d` (não `-D`): se o git recusar por commits não mergeados, **parar e reportar** em vez de forçar. Branch não mergeada apagada com `-D` perde trabalho
     - **Squash merge faz o `-d` recusar mesmo com o PR merged.** O squash cria um commit novo na base, então os commits da branch não são ancestrais dela e o git não os reconhece como mergeados. Antes de reportar como problema, confirmar que o conteúdo está na base: `git diff --stat {branch} {default}` deve vir vazio. Se vier vazio, o merge está completo e a recusa é esperada — informar o usuário e deixar a decisão de apagar com `-D` para ele, já que `-D` é destrutivo
     - Se a branch do card for a própria branch default, não apagar nada
   - Se o remoto ainda tiver a branch, informar o comando de limpeza (`git push origin --delete {branch-do-card}`) sem executá-lo — apagar branch remota é ação destrutiva que exige pedido explícito

10. **Consolidar conhecimento automaticamente:**
   - Executar `/condense-memory "{nome-do-card}"` automaticamente
   - Isso irá extrair e consolidar o conhecimento do card recém-finalizado
   - O conhecimento será imediatamente disponível para futuras tarefas

11. **Confirmar:**
   ```
   ✅ Card concluído!

   📝 Card: nome-do-card.md
   🔀 Movido: 3.in_review → 4.done
   � Branch: {branch-do-card} → {branch-default} (branch do card apagada)
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
- **O comando volta para a branch default e apaga a branch do card** (passo 9). Usa `git branch -d` e para se o git recusar por commits não mergeados — nunca força com `-D`. Em squash merge a recusa é esperada: confirmar com `git diff --stat {branch} {default}` que o conteúdo está na base antes de reportar
- A branch remota **não** é apagada automaticamente: o comando apenas informa o comando de limpeza, porque apagar branch remota é ação destrutiva que exige pedido explícito
