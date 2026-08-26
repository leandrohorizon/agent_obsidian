Você é um assistente que inicializa o arquivo de estado .agent_obsidian para um projeto.

## Tarefa
Criar o arquivo `.agent_obsidian` no diretório atual com estrutura completa, incluindo todos os paths necessários.

## Argumentos
Nenhum.

## Instruções

1. **Verificar se já existe:**
   - Tentar ler `.agent_obsidian` no diretório atual
   - Se já existe e é JSON válido, informar ao usuário e não fazer nada
   - Se existe mas JSON inválido, avisar que será recriado

2. **Verificar $OBSIDIAN_VAULT_PATH:**
   - Executar: `echo $OBSIDIAN_VAULT_PATH`
   - Se não estiver definida, retornar erro:
     ```
     ❌ OBSIDIAN_VAULT_PATH não está definido

     Configure usando:
     export OBSIDIAN_VAULT_PATH="/caminho/para/vault"
     ```

3. **Detectar nome do projeto:**
   - Executar: `basename $(pwd) | tr '[:upper:]' '[:lower:]' | tr '-' '_' | tr ' ' '_'`
   - Este será usado para o path do condensed memory de projeto

4. **Criar .agent_obsidian:**
   - Criar estrutura completa com Write tool (modelo de dois eixos, version 2.0):
     ```json
     {
       "version": "2.0",
       "vault_path": "{valor de $OBSIDIAN_VAULT_PATH}",
       "code_guidelines_path": "{$OBSIDIAN_VAULT_PATH}/code guidelines.md",
       "condensed_memory_path": "{$OBSIDIAN_VAULT_PATH}/condensed memory/projects/{project_name}.md",
       "current_card": null
     }
     ```
   - O path da memória de feature NÃO fica no estado: ele é derivado do campo
     `feature:` do card atual em tempo de carga (ver `get_feature_memory_path()`)

5. **Adicionar ao .gitignore:**
   - Verificar se `.gitignore` existe no diretório atual
   - Se existe, verificar se já contém `.agent_obsidian`
   - Se não contém, adicionar linha:
     ```

     # Agent state file (local to each project)
     .agent_obsidian
     ```

6. **Confirmar:**
   ```
   ✅ Agent state inicializado!

   📁 Vault: {vault_path}
   📦 Projeto: {project_name}
   📝 Code guidelines: {code_guidelines_path}
   💾 Condensed memory (projeto): {condensed_memory_path}

   O arquivo .agent_obsidian foi criado e adicionado ao .gitignore.
   Você pode agora usar os outros comandos do Agent Obsidian.
   ```

## Uso

```bash
/init-agent-state
```

Inicializa o projeto atual para uso com Agent Obsidian.

## Notas
- Este comando deve ser executado uma vez por projeto
- Cria a estrutura base, outros comandos irão atualizar o `current_card`
- É chamado automaticamente por comandos como `/start-card` se necessário
- Comando auxiliar reutilizável e testável isoladamente
- Não requer argumentos (detecta tudo automaticamente)
