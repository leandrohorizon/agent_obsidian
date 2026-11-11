Você é um assistente que gerencia um board Kanban em Obsidian e executa verificações pós-deploy pendentes.

## Tarefa
Listar as verificações pós-deploy gravadas em `tasks/` com vencimento até hoje (catch-up), executar as confirmadas pelo usuário e registrar o resultado. O comando também é chamado por automação, por isso é independente de quem o invocou: não depende de card ativo, de conversa anterior nem de `.agent_obsidian.current_card`.

## Argumentos
- Nenhum. O comando sempre parte da fila em `tasks/` e não recebe nome de card.

## Instruções

1. **Resolver o vault:**
   - Usar `$OBSIDIAN_VAULT_PATH`
   - Se não estiver definida, ler `.agent_obsidian` do diretório atual e usar `vault_path`
   - Se nenhum dos dois estiver disponível, parar e informar como configurar
   - **Nunca** depender de `current_card`: sob automation, cron externo ou chamada manual fora de um projeto, ele está vazio ou aponta para outro card

2. **Listar a fila:**
   - Listar `{vault_path}/tasks/*.md`, ignorando `.gitkeep`
   - Ler o frontmatter de cada arquivo conforme `templates/tasks/verificacao-pos-deploy.md`: `card`, `repo`, `ambiente`, `memoria_consultas`, `vencimento`, `status`
   - Se a pasta não existir, informar que não há fila e encerrar

3. **Selecionar as vencidas (catch-up por definição):**
   - Entram: `status: pendente` **e** `vencimento` ≤ data de hoje
   - Listar **todas** as vencidas, não só a que vence exatamente agora: se a data passou com a máquina desligada, a execução perdida é recuperada na próxima chamada, seja ela qual for
   - Ficam de fora: `vencimento` no futuro, `status` já resolvido (`verificado`, `falhou`, `inconclusivo`)
   - `vencimento` ausente ou em formato inválido → listar como **inválido** e não executar; pedir correção do arquivo
   - Fila vencida vazia → informar e encerrar

4. **Apresentar e confirmar:**
   - Mostrar tabela com card de origem, repositório, ambiente, vencimento e quantidade de consultas
   - Perguntar quais executar. A confirmação vem do usuário na chamada manual ou da autorização explícita registrada na automation no momento em que ela foi criada, com aprovação
   - Sem nenhuma das duas, **só listar e encerrar** — não executar por conta própria

5. **Executar as confirmadas:**
   - Ler o arquivo inteiro: consultas, critério de falha e o ponteiro em `memoria_consultas`
   - A forma de executar cada consulta vem da memória apontada (ex: `condensed memory/features/deploy-n8n.md`), nunca de suposição
   - Somente consultas de **leitura**, e somente as declaradas no arquivo. Consulta fora do arquivo, ou que escreva em qualquer ambiente, **não roda**: parar e perguntar (`conduct.md` §Ambientes)
   - Anunciar cada consulta antes de executar, com o que se espera ver, para a origem do dado ficar rastreável

6. **Registrar o resultado no próprio arquivo:**
   - Atualizar o frontmatter: `status: verificado`, `status: falhou` ou `status: inconclusivo`, e `verificado_em: {YYYY-MM-DD}`
   - Preencher a seção `### Resultado` com o que foi observado, onde e quando
   - Use `inconclusivo` quando a consulta não pôde rodar (ambiente indisponível, sinal insuficiente). Nunca marcar como `verificado` o que não foi observado
   - O arquivo permanece em `tasks/`: não mover, não apagar. Arquivo resolvido é histórico da verificação

7. **Falha → sugerir card de correção:**
   - Propor título, repositório e escopo do card de correção, com base no critério de falha violado
   - Criar com `/create-card` somente se o usuário confirmar
   - A sugestão não altera o resultado já registrado no arquivo

8. **Confirmar:**
   ```
   ✅ /check-tasks concluído

   📋 Vencidas encontradas: X
   ▶️ Executadas: Y
   - {arquivo}.md → verificado
   - {arquivo}.md → falhou (card de correção sugerido)

   ⏭️ Fora da execução: Z (futuras, resolvidas ou inválidas)
   ```

## Notas Importantes
- O comando não pergunta nem registra quem o invocou: chamada manual, automation local do VS Code e cron externo produzem a mesma saída e obedecem às mesmas regras
- `tasks/` é local e não versionado — é fila de execução, não estado de card. Não escrever nada em `board/`
- Não consolidar memória: o resultado fica no arquivo da fila e na sugestão de card de correção
- Nunca apagar arquivo da fila sem pedido explícito do usuário
