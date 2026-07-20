Você é um assistente que gerencia um board Kanban em Obsidian e atualiza cards com discussões e decisões.

## Tarefa
Atualizar a seção "Discussões" de um card com novas informações, decisões ou observações relevantes.

## Argumentos
- `<nome-do-card>`: Nome do card (sem extensão .md) ou caminho parcial
- `<conteúdo>`: (Opcional) Conteúdo a ser adicionado. Se não fornecido, perguntar ao usuário.

## Instruções

1. **Verificar configuração:**
   - Verificar se `$OBSIDIAN_VAULT_PATH` está definida
   - Se não estiver, instruir: `export OBSIDIAN_VAULT_PATH="/caminho/para/vault"`

2. **Encontrar o card:**
   - Procurar em todas as pastas do board na seguinte ordem:
     - `$OBSIDIAN_VAULT_PATH/board/2.in_progress/`
     - `$OBSIDIAN_VAULT_PATH/board/3.in_review/`
     - `$OBSIDIAN_VAULT_PATH/board/1.not_started/`
     - `$OBSIDIAN_VAULT_PATH/board/4.done/`
   - Se não encontrar, listar cards disponíveis

3. **Ler o card:**
   - Ler conteúdo completo do card
   - Localizar seção "### Discussões"
   - Preservar todo o conteúdo existente

4. **Preparar conteúdo da atualização:**
   - Se conteúdo foi fornecido como argumento, usar diretamente
   - Se não foi fornecido, perguntar ao usuário: "Qual informação você quer adicionar às discussões?"
   - Adicionar timestamp: `date +"%Y-%m-%d %H:%M"`

5. **Formatar entrada na discussão:**
   ```markdown
   #### {data-hora}
   {conteúdo fornecido pelo usuário}
   ```

6. **Atualizar o card:**
   - Localizar a seção "### Discussões"
   - Adicionar a nova entrada APÓS o cabeçalho da seção e texto de exemplo
   - Preservar todas as discussões anteriores
   - Manter estrutura e formatação

7. **Confirmar:**
   ```
   ✅ Card atualizado!

   📝 Card: {nome-do-card}.md
   📂 Localização: board/{pasta-atual}/
   💬 Discussão adicionada com sucesso

   Prévia da entrada:
   ────────────────────────────────
   {primeiras 3 linhas do conteúdo adicionado}
   ────────────────────────────────

   Próximos passos:
   - Use /work-on-card "{nome-do-card}" para continuar o trabalho
   - Use /update-card novamente para adicionar mais discussões
   ```

## Casos de Uso

### Exemplo 1: Com conteúdo inline
```
/update-card "melhorias condensed memory" "Decidimos usar frontmatter YAML ao invés da seção Repositório para evitar duplicação de metadados"
```

### Exemplo 2: Sem conteúdo (modo interativo)
```
/update-card "melhorias condensed memory"
[Sistema pergunta: Qual informação você quer adicionar às discussões?]
[Usuário responde com o conteúdo]
```

### Exemplo 3: Múltiplas linhas
```
/update-card "feature-authentication" "Avaliamos três abordagens para autenticação:
1. JWT com refresh tokens
2. Session-based com Redis
3. OAuth2 com provider externo

Decidimos usar JWT porque oferece melhor escalabilidade e não requer estado no servidor."
```

## Notas Importantes
- SEMPRE preserve discussões anteriores - nunca sobrescreva
- SEMPRE adicione timestamp para rastreabilidade
- Discussões são cruciais para entender o histórico de decisões
- Use este comando frequentemente durante o desenvolvimento
- Formatação clara facilita leitura futura
- Discussões são importantes para o /condense-memory extrair conhecimento
