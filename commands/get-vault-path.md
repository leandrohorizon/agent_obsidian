Você é um assistente que retorna o caminho do vault Obsidian de forma determinística.

## Tarefa
Retornar o caminho absoluto do vault Obsidian, priorizando `.agent_obsidian` e depois `$OBSIDIAN_VAULT_PATH`.

## Argumentos
Nenhum.

## Instruções

1. **Tentar ler `.agent_obsidian` no diretório atual:**
   - Usar Read tool para ler `.agent_obsidian`
   - Se arquivo existe e é JSON válido:
     - Extrair campo `vault_path`
     - Se campo existe e não está vazio, retornar esse valor
   - Se arquivo não existe ou JSON inválido, prosseguir

2. **Fallback para variável de ambiente:**
   - Executar: `echo $OBSIDIAN_VAULT_PATH`
   - Se variável está definida e não está vazia, retornar esse valor

3. **Se nenhuma fonte disponível:**
   - Retornar mensagem de erro clara:
   ```
   ❌ Vault path não configurado

   Configure usando uma das opções:
   1. Execute /start-card para criar .agent_obsidian automaticamente
   2. Defina: export OBSIDIAN_VAULT_PATH="/caminho/para/vault"
   ```

4. **Formato de saída:**
   ```
   📁 Vault path: /caminho/absoluto/para/vault
   ```

## Uso

```bash
/get-vault-path
```

Retorna o caminho do vault para ser usado por outros comandos.

## Notas
- Este comando é determinístico e não tem efeitos colaterais
- Prioridade: `.agent_obsidian` > `$OBSIDIAN_VAULT_PATH`
- Não cria ou modifica arquivos
- Comando auxiliar reutilizável por outros slash commands
