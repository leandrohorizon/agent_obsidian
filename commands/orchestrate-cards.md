Você é um orquestrador que coordena subagentes para trabalhar em **todos** os cards em `1.not_started/` de uma vez, cada um em seu próprio contexto isolado.

## Tarefa
Para cada card em `1.not_started/`, executar a sequência completa de trabalho — `/start-card` → `/work-on-card` → `/review-card` — usando um subagente dedicado por card, e abrir o PR **em draft**.

## Argumentos
- `[filtro]`: (Opcional) Nome parcial ou lista de cards para processar. Se omitido, processa **todos** os cards em `1.not_started/`.

## Instruções

1. **Verificar configuração:**
   - Verificar se `$OBSIDIAN_VAULT_PATH` está definida
   - Verificar se estamos em um repositório git
   - Ler `.agent_obsidian` (criar/validar via `validate_agent_state()` se necessário)
   - Se `current_card` não for null, **avisar** que já existe um card ativo neste
     projeto e perguntar se o usuário quer continuar mesmo assim (o orquestrador
     trabalha em vários cards; um card ativo pode indicar trabalho em andamento)

2. **Listar os cards alvo:**
   - Listar todos os arquivos `.md` em `$OBSIDIAN_VAULT_PATH/board/1.not_started/`
   - Se `[filtro]` foi fornecido, restringir a lista aos cards que casam com o filtro
   - Se a lista estiver vazia, informar e encerrar
   - **Apresentar a lista ao usuário e pedir confirmação** antes de prosseguir:
     ```
     Vou trabalhar nos seguintes cards (em paralelo, um subagente por card):
     - card-a
     - card-b
     - card-c

     Cada card seguirá: /start-card → /work-on-card → /review-card (PR em draft).
     Confirma? (1. Sim  2. Não)
     ```
   - **Aguardar a resposta.** Não iniciar sem confirmação

3. **Verificar dependências entre cards:**
   - Ler a seção "## Dependências" de cada card alvo
   - Se um card depende de outro que também está na lista, **avisar** o usuário:
     trabalhar em paralelo pode causar conflitos de branch/arquivos
   - Sugerir processar dependências em ordem (sequencial) ou remover o card
     dependente da lista

4. **Executar um subagente por card (em paralelo):**
   - Para cada card, disparar um subagente com contexto isolado
   - O prompt do subagente deve instruir a sequência completa:

     ```
     Você está trabalhando no card "{nome-do-card}" do board Obsidian.

     Execute a sequência completa, na ordem:

     1. /start-card "{nome-do-card}"
        - Move o card de 1.not_started → 2.in_progress
        - Cria a branch feature/{nome-do-card}
        - Atualiza o .agent_obsidian

     2. /work-on-card "{nome-do-card}"
        - Carrega guidelines (conduct.md tem precedência), condensed memory
          (projeto + feature) e cards dependentes
        - Executa TODAS as tarefas pendentes do card
        - Marca tarefas como concluídas, documenta decisões em "Discussões",
          preenche "Descrição Técnica" e "Conhecimento Adquirido"
        - Faz commits incrementais seguindo conventional commits

     3. /review-card "{nome-do-card}"
        - Valida que todas as tarefas estão concluídas
        - Cria o commit final, faz push da branch
        - Cria o Pull Request **EM DRAFT** (ver regra abaixo)
        - Move o card de 2.in_progress → 3.in_review
        - Atualiza o frontmatter com pr_url e reviewed

     REGRA CRÍTICA — PR em draft:
     - O PR DEVE ser criado como draft. Use `gh pr create --draft ...`
     - Nunca abrir PR pronto para review neste fluxo

     Ao final, retorne um resumo com:
     - Status do card (concluído / bloqueado / falhou)
     - Branch criada
     - URL do PR (draft)
     - Tarefas concluídas vs pendentes
     - Bloqueios ou dúvidas encontradas
     ```

   - Disparar os subagentes **em paralelo** (um por card) para maximizar throughput
   - Cada subagente tem contexto isolado — não compartilham memória entre si

5. **Consolidar resultados:**
   - Aguardar todos os subagentes terminarem
   - Montar um relatório consolidado:
     ```
     🎯 Orquestração concluída

     ## Cards processados ({n})

     ### ✅ Concluídos ({n})
     - {card-a} → PR draft: {url}
     - {card-b} → PR draft: {url}

     ### ⚠️ Bloqueados ({n})
     - {card-c} → motivo: {bloqueio}

     ### ❌ Falharam ({n})
     - {card-d} → erro: {erro}

     ## Próximos passos
     - Revise os PRs em draft e marque como "ready for review" quando apropriado
     - Use /complete-card após o merge de cada PR
     ```

6. **Não consolidar conhecimento automaticamente:**
   - O `/condense-memory` só roda após o merge (via `/complete-card`)
   - O orquestrador **não** deve chamar `/condense-memory`

## Casos de Uso

### Trabalhar em todos os cards prontos
```
/orchestrate-cards
```
Processa todos os cards em `1.not_started/` em paralelo, cada um com PR em draft.

### Trabalhar em um subconjunto
```
/orchestrate-cards "autenticação"
```
Processa apenas os cards que casam com o filtro.

## Notas Importantes

- **Um subagente por card**, com contexto isolado — evita poluição de contexto
  entre cards e permite paralelismo
- **PR sempre em draft** — o humano decide quando promover para review
- **Confirmação obrigatória** antes de iniciar (lista de cards + aviso de card ativo)
- **Dependências entre cards** são detectadas e avisadas — paralelismo pode
  causar conflitos
- O orquestrador **não** faz merge nem consolida memória — isso é papel do
  `/complete-card` após revisão humana
- Se um subagente falhar, os outros continuam — o relatório final mostra o que
  deu certo e o que não deu
- Respeita `guidelines/conduct.md` (precedência sobre qualquer outra instrução)
