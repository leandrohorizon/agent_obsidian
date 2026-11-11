Você é um assistente que gerencia um board Kanban em Obsidian e finaliza tarefas.

## Tarefa
Finalizar um card, movendo-o para "4.done" e garantindo que os entregáveis correspondam ao tipo de trabalho.

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
   - Se foi passado nome, procurar em `$OBSIDIAN_VAULT_PATH/board/3.in_review/` e `2.in_progress/`
   - Ler o card pela **leitura enxuta** (`guidelines/IA best practices.md` §6)
   - Ler `guidelines/card work types.md`
   - Card sem `work_type` é `implementation`; valor desconhecido interrompe sem mover o card ou alterar estado
   - Verificar se o PR foi merged somente para `implementation`, se houver PR
   - `report`, `investigation` e `experiment` podem ser concluídos diretamente de `2.in_progress`, sem PR
   - Para `experiment`, não executar nenhum comando Git

4. **Validar completude:**
   - Para `implementation`: todas as tarefas, descrição técnica, conhecimento adquirido e PR (`pr_url`) conforme o fluxo existente
   - Para `report`: todas as tarefas concluídas, documento presente em `docs/{projeto}/reports/` no vault e caminho registrado na descrição técnica
   - Para `investigation`: todas as tarefas concluídas; descobertas, conclusões e referências registradas no card; documento em `docs/{projeto}/investigations/` é opcional
   - Para `experiment`: todas as tarefas concluídas; ferramenta e resultado presentes na pasta atual; caminho relativo e instruções de uso registrados na descrição técnica
   - ✅ Seção "Discussões" documentada? (leitura sob demanda)

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
   - `implementation`: mover de `3.in_review/` para `4.done/`
   - `report`, `investigation` e `experiment`: mover de `2.in_progress/` para `4.done/`

8. **Limpar .agent_obsidian:**
   - Ler `.agent_obsidian` do diretório atual (se existir)
   - Manter todos os campos existentes (version, vault_path, guidelines_path, condensed_memory_path)
   - Atualizar `current_card` para `null` somente se ele apontar para o card que está sendo concluído
   - Escrever de volta usando Write tool preservando estrutura completa

9. **Voltar para a branch default e apagar a branch do card:**
   - Aplicável somente a `implementation`. Para `report`, `investigation` e `experiment`, não executar nenhum comando Git.
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
   - `implementation`: manter o fluxo atual e executar `/condense-memory "{nome-do-card}"` automaticamente
   - `report`: não chamar `/condense-memory`
   - `investigation`: se houver conhecimento potencialmente reutilizável, perguntar se o usuário confirma a consolidação. Só após resposta afirmativa executar `/condense-memory "{nome-do-card}"`; resposta negativa conclui o card sem memória
   - `experiment`: nunca chamar `/condense-memory`, mesmo após pedido explícito; conhecimento, resultados e referências permanecem somente no card

11. **Confirmar:**
   ```
   ✅ Card concluído!

   📝 Card: nome-do-card.md
   🔀 Movido: 3.in_review → 4.done
   🌿 Branch: {branch-do-card} → {branch-default} (branch do card apagada)
   🎉 Tarefa finalizada com sucesso!

   📊 Resumo:
   - Tarefas completadas: X
   - PRs merged: Y
   - Conhecimento documentado: ✅

   💡 Conhecimento consolidado:
   - Card processado e adicionado à condensed memory
   - Aprendizados disponíveis para futuras tarefas
   ```
   - Usar o resumo de branch e memória acima somente para `implementation`
   - Para `report` e `investigation`, informar o caminho dos documentos no vault e que nenhum Git foi executado; memória de relatório: não aplicável; investigação: indicar se o usuário confirmou ou recusou a consolidação
   - Para `experiment`, informar que o card foi concluído sem Git ou consolidação de memória e que os artefatos continuam na pasta atual até limpeza manual

## Notas Importantes
- Não delete informações ao mover o card, preserve todo o histórico
- Para relatórios e investigações, informar que os documentos no vault são alterações locais e não foram commitados
- Para experimentos, não apagar os artefatos ao concluir; a limpeza é manual
