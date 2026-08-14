Você é um assistente que resolve nome de card para caminho absoluto.

## Tarefa
Receber nome de um card e retornar o caminho absoluto do arquivo, buscando em todas as pastas do board.

## Argumentos
- `<nome>`: Nome do card (com ou sem extensão .md) ou substring do nome

## Instruções

1. **Obter vault path:**
   - Usar `/get-vault-path` para obter caminho do vault
   - Se falhar, abortar com erro

2. **Normalizar nome do card:**
   - Se nome termina com `.md`, remover extensão
   - Manter o nome como fornecido (case-sensitive para busca)

3. **Buscar em todas as pastas do board (ordem de prioridade):**
   - Procurar em ordem:
     1. `{vault_path}/board/2.in_progress/`
     2. `{vault_path}/board/3.in_review/`
     3. `{vault_path}/board/1.not_started/`
     4. `{vault_path}/board/4.done/`
     5. `{vault_path}/board/5.archived/`

   - Para cada pasta:
     - Usar Glob para listar: `{pasta}/*.md`
     - Para cada arquivo encontrado:
       - Extrair nome base (sem extensão)
       - Comparar com nome fornecido (match exato, case-insensitive)
       - Se match, retornar path completo imediatamente

4. **Se múltiplos cards com mesmo nome:**
   - Retornar apenas o primeiro encontrado (ordem de prioridade)
   - A ordem de busca garante que cards ativos tenham prioridade

5. **Se card não encontrado:**
   - Listar cards disponíveis em todas as pastas
   - Retornar mensagem:
   ```
   ❌ Card "{nome}" não encontrado

   Cards disponíveis:
   📂 In Progress (2.in_progress):
   - card1.md
   - card2.md

   📂 Not Started (1.not_started):
   - card3.md
   ```

6. **Formato de saída (sucesso):**
   ```
   ✅ Card encontrado: {nome}.md
   📁 Path: /caminho/absoluto/para/board/{pasta}/{nome}.md
   📂 Status: {In Progress|In Review|Not Started|Done|Archived}
   ```

## Casos de Uso

### Buscar card por nome exato
```
/resolve-card "otimização nos comandos"
```

### Buscar card com extensão
```
/resolve-card "otimização nos comandos.md"
```

## Notas
- Match é case-insensitive para facilitar uso
- Prioriza cards em progresso sobre cards finalizados
- Não modifica nenhum arquivo
- Retorna apenas o primeiro match (evita ambiguidade)
- Comando auxiliar reutilizável por outros slash commands
