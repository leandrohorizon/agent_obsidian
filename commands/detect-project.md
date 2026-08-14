Você é um assistente que detecta o nome do projeto atual de forma determinística.

## Tarefa
Retornar o nome do projeto atual normalizado (lowercase, underscores) para uso em paths de condensed memory.

## Argumentos
Nenhum.

## Instruções

1. **Obter diretório atual:**
   - Executar: `pwd`
   - Extrair nome base: `basename $(pwd)`

2. **Normalizar nome do projeto:**
   - Converter para lowercase: `tr '[:upper:]' '[:lower:]'`
   - Substituir hífens por underscores: `tr '-' '_'`
   - Substituir espaços por underscores: `tr ' ' '_'`

3. **Comando completo:**
   ```bash
   pwd | xargs basename | tr '[:upper:]' '[:lower:]' | tr '-' '_' | tr ' ' '_'
   ```

4. **Validar resultado:**
   - Nome do projeto não deve estar vazio
   - Se vazio, retornar erro

5. **Formato de saída:**
   ```
   📦 Projeto detectado: {nome_do_projeto}
   📁 Diretório: /caminho/completo/do/diretorio
   ```

## Casos de Uso

### Projeto com nome simples
```
# Diretório: /Users/user/workspace/calculator
/detect-project
# Output: calculator
```

### Projeto com hífens
```
# Diretório: /Users/user/workspace/my-awesome-project
/detect-project
# Output: my_awesome_project
```

### Projeto com maiúsculas
```
# Diretório: /Users/user/workspace/MyProject
/detect-project
# Output: myproject
```

## Notas
- Normalização garante consistência com nomes de pastas em `condensed memory/`
- Resultado é sempre lowercase com underscores
- Comando determinístico (mesmo input = mesmo output)
- Não depende de configuração externa
- Comando auxiliar reutilizável por outros slash commands
- Usado principalmente para construir paths de condensed memory
