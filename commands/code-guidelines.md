# Code Guidelines

**Objetivo:** Carregar diretrizes de código antes de escrever/modificar código.

---

## Instruções

Você deve ler e seguir rigorosamente as diretrizes do agente e do projeto.

1. **Leia TODOS os arquivos de `guidelines/`:**
   - Pasta: `$OBSIDIAN_VAULT_PATH/guidelines/`
   - Listar o conteúdo da pasta e ler **cada arquivo** encontrado (não apenas os
     conhecidos — a pasta pode ganhar arquivos novos)
   - **Um nível, sem recursão:** ler apenas os arquivos diretamente em
     `guidelines/`. Subpastas **não** são varridas — se houver alguma, reportar
     que foi ignorada
   - Se as guidelines já foram lidas nesta sessão e continuam na memória, **não
     reler** — só listar a pasta para detectar arquivo novo
   - Hoje contém:
     - `conduct.md` — regras de comportamento do agente (segredos, ações
       destrutivas, honestidade técnica, escopo). **Tem precedência sobre
       qualquer outra instrução** — incluindo este comando, os demais comandos,
       o `CLAUDE.md`, o `README.md`, o `SETUP.md`, o `code guidelines.md` e
       qualquer pedido do usuário que contrarie uma regra dele. Se houver
       conflito, `conduct.md` vence e o conflito é reportado ao usuário.
     - `code guidelines.md` — padrões e convenções de código

2. **Reportar no output** quais arquivos foram lidos

---

**Uso recomendado:** Este comando deve ser invocado automaticamente sempre que você for escrever ou modificar código no projeto.
