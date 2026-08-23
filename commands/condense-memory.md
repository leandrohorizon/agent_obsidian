Você é um assistente que consolida conhecimento de tarefas completadas em um arquivo de memória compartilhada.

## Tarefa
Processar cards em "4.done" (todos ou um específico), extrair conhecimento relevante e atualizar o arquivo "condensed memory.md" com aprendizados consolidados.

## Argumentos
- `<nome-do-card>`: (Opcional) Nome do card específico para processar. Se não fornecido, processa todos os cards em 4.done.

## Instruções

1. **Verificar configuração e obter vault path:**
   - Tentar ler `.agent_obsidian` no diretório atual
   - Se arquivo existe e é válido, usar `vault_path` dele
   - Se não existe ou inválido, usar variável `$OBSIDIAN_VAULT_PATH`
   - Se nenhum dos dois está disponível, instruir: `export OBSIDIAN_VAULT_PATH="/caminho/para/vault"`

2. **Detectar projeto atual:**
   - Obter nome do diretório atual: `basename $(pwd) | tr '[:upper:]' '[:lower:]' | tr '-' '_'`
   - Normalizar nome: lowercase, substituir espaços e hífens por underscore
   - Este será o nome do arquivo de projeto em `condensed memory/projects/`

3. **Ler arquivos de memória (dois eixos):**
   - **Memória de projeto:** se `.agent_obsidian` existe e tem `condensed_memory_path`, usar ele diretamente; senão, construir `$OBSIDIAN_VAULT_PATH/condensed memory/projects/{nome-do-projeto}.md`
   - **Memória de feature:** derivar do campo `feature:` do card via `get_feature_memory_path()` → `$OBSIDIAN_VAULT_PATH/condensed memory/features/{feature}.md`
   - Se não existirem, criar a estrutura de pastas (`projects/` e `features/`)
   - Entender estrutura e conteúdo existente de cada eixo

4. **Determinar cards a processar:**
   - Se `<nome-do-card>` foi fornecido:
     - Procurar card específico em `$OBSIDIAN_VAULT_PATH/board/4.done/`
     - Se não encontrado, avisar usuário e listar cards disponíveis
     - Processar apenas este card
   - Se não foi fornecido argumento:
     - Listar todos os .md em `$OBSIDIAN_VAULT_PATH/board/4.done/`
     - Filtrar apenas cards que NÃO foram processados ainda (sem marcação de consolidação)
     - Processar todos os cards não processados

5. **Processar cards selecionados:**
   - Para cada card, ler:
     - Seção "## Descrição"
     - Seção "## Conhecimento Adquirido pela IA"
     - Seção "## Discussões"
     - Seção "## Descrição Técnica do que Foi Feito"

5. **Extrair e processar conhecimento:**

   **IMPORTANTE: Aplicar deduplicação e condensação**
   - Identificar informações repetidas entre cards
   - Consolidar conceitos relacionados em uma única entrada
   - Priorizar decisões arquiteturais e "por quês" sobre detalhes de implementação
   - Gerar resumos compactos e menos verbosos

   **Classificar cada item em um eixo (projeto OU feature) antes de escrever:**

   **Critério de classificação (com desempate explícito):**
   - **Projeto** — o que é estável e transversal ao repositório: arquitetura,
     convenções de código, ferramentas, setup, gotchas do stack. Responde a
     "como se escreve código neste repo?".
   - **Feature** — regra de negócio, fluxo ponta a ponta, contratos entre
     serviços, decisões e edge cases daquela feature. Responde a "como funciona
     X ponta a ponta?".
   - **Desempate:** se o item descreve um fluxo, contrato ou regra de negócio
     que atravessa serviços/repositórios → **feature**. Se descreve como o
     código do repo é estruturado, configurado ou convencionado → **projeto**.
     Em caso de dúvida, perguntar: "este conhecimento é útil para quem trabalha
     em outro repositório desta mesma feature?" Se sim → feature; se não → projeto.

   **Categorias de projeto (5):**

   a) **🏗️ Arquitetura**
      - Decisões estruturais e seus motivos (sempre destacar com **Decisão:** ou **Rationale:**)
      - Padrões arquiteturais
      - Estrutura de sistemas e subsistemas
      - Integrações e como se conectam

   b) **📋 Padrões e Convenções**
      - Regras estabelecidas
      - Convenções de código
      - Templates e estruturas padronizadas
      - Nomenclatura

   c) **🛠️ Ferramentas e Comandos**
      - Comandos slash disponíveis
      - Scripts e utilitários
      - Gems/packages/bibliotecas
      - Como usar cada ferramenta

   d) **⚙️ Configuração**
      - Variáveis de ambiente
      - Setup necessário
      - Dependências
      - Configurações importantes

   e) **💡 Aprendizados Chave**
      - Problemas encontrados e soluções
      - Trade-offs identificados
      - Edge cases importantes
      - Insights e "gotchas"

   **Categorias de feature (próprias, não reaproveitam as de projeto):**

   a) **🔀 Fluxo Ponta a Ponta**
      - Sequência completa da feature atravessando serviços/repositórios
      - Ordem das chamadas, quem chama quem, onde cada etapa vive

   b) **🤝 Contratos entre Serviços**
      - Payloads, schemas, campos trocados entre serviços
      - Formato esperado/produzido por cada lado do contrato
      - Exemplo: `campo_status` — o que o `service-a` envia e o que o `service-c` consome

   c) **📐 Regras de Negócio**
      - Regras e validações específicas da feature
      - Comportamento esperado em cada cenário

   d) **⚠️ Edge Cases**
      - Casos limite, intermitências, comportamentos inesperados
      - Problemas conhecidos e como foram resolvidos

6. **Atualizar os arquivos de memória (roteamento por eixo):**

   **Roteamento:**
   - Itens classificados como **projeto** → escrever em `condensed memory/projects/{projeto}.md`
   - Itens classificados como **feature** → escrever em `condensed memory/features/{feature}.md`
   - Se o card tem `feature:` no frontmatter → escrever nos dois arquivos (projeto + feature)
   - Se o card NÃO tem `feature:` → escrever só no de projeto e avisar no output:
     `⚠️ Card sem feature: — conhecimento de feature não roteado. Preencha feature: no frontmatter.`
   - Se `feature:` é uma lista YAML (`feature: [a, b]`) → escrever o recorte pertinente de cada item em cada arquivo de feature correspondente

   **FORMATO DO ARQUIVO DE PROJETO - Estrutura obrigatória:**

   ```markdown
   # Condensed Memory - {nome_projeto}

   > Última atualização: YYYY-MM-DD
   > Cards processados: N
   > Origem: [card1, card2, ...]

   ---

   ## 🏗️ Arquitetura

   ### Nome do Subsistema
   Descrição concisa do subsistema (1-2 linhas)
   - Detalhe técnico 1
   - Detalhe técnico 2
   - Exemplo inline quando relevante: `código ou comando`

   **Decisão:** Explique por quê essa arquitetura foi escolhida e qual problema resolve.

   ### Outro Subsistema
   ...

   ---

   ## 📋 Padrões e Convenções

   ### Nome do Padrão
   Como fazer as coisas consistentemente
   - Regra 1
   - Regra 2

   **Rationale:** Por que seguimos este padrão.

   ---

   ## 🛠️ Ferramentas e Comandos

   ### /nome-do-comando
   O que o comando faz (1 linha)
   - Parâmetro 1: descrição
   - Parâmetro 2: descrição
   - Comportamento importante

   ### Biblioteca ou Script
   Para que serve
   - Como usar
   - Configuração necessária

   ---

   ## ⚙️ Configuração

   ### Variáveis de Ambiente
   - `VAR_NAME`: descrição e exemplo de valor

   ### Setup
   Passos necessários para configurar o ambiente

   ---

   ## 💡 Aprendizados Chave

   - Insight importante sobre trade-off ou decisão
   - Problema comum e como evitar
   - Edge case valioso de se conhecer
   ```

   **REGRAS DE FORMATAÇÃO:**

   1. **Origem no topo:** Liste todos os cards processados uma vez no header, não repita em cada item
      ```markdown
      > Origem: [card1, card2, card3]
      ```

   2. **Destacar decisões:** Use sempre `**Decisão:**` ou `**Rationale:**` para explicar "por quê"
      ```markdown
      **Decisão:** Usar sistema de arquivos em vez de DB para evitar dependências externas.
      ```

   3. **Hierarquia clara:** Categoria → Subsistema → Detalhes → Decisão
      ```markdown
      ## 🏗️ Arquitetura
        ### Board Kanban em Obsidian
          - Pastas como estados
          - Cards como arquivos
          **Decisão:** Simplicidade e portabilidade
      ```

   4. **Compactar informação:** Agrupar items relacionados, evitar repetição
      ❌ Evitar:
      ```markdown
      - Sistema usa git
      - Git permite rastreamento
      - Branch criada no git
      ```
      ✅ Fazer:
      ```markdown
      Sistema integrado com Git para rastreamento:
      - Branch automática por card
      - Metadados referenciam commit/branch
      ```

   5. **Emojis para navegação:** Use os emojis definidos para cada categoria (🏗️📋🛠️⚙️💡)

   **FORMATO DO ARQUIVO DE FEATURE - Estrutura obrigatória:**

   ```markdown
   # Feature - {slug-da-feature}

   > Última atualização: YYYY-MM-DD
   > Repositórios envolvidos: [repo1, repo2, ...]
   > Cards de origem: [card1, card2, ...]

   ---

   ## 🔀 Fluxo Ponta a Ponta

   ### Nome do Fluxo
   Sequência completa atravessando serviços/repositórios
   - Etapa 1 (em {repo}): o que acontece
   - Etapa 2 (em {repo}): o que acontece
   - Exemplo inline quando relevante: `código ou comando`

   **Decisão:** Por que o fluxo é assim e qual problema resolve.

   ---

   ## 🤝 Contratos entre Serviços

   ### Nome do Contrato
   O que cada lado envia/consome
   - {serviço A} envia: campos, formato
   - {serviço B} consome: campos, formato
   - Exemplo de payload quando relevante

   ---

   ## 📐 Regras de Negócio

   ### Nome da Regra
   Regra ou validação específica da feature
   - Comportamento esperado em cada cenário

   **Rationale:** Por que a regra existe.

   ---

   ## ⚠️ Edge Cases

   - Caso limite, intermitência ou comportamento inesperado
   - Problema conhecido e como foi resolvido
   ```

   **REGRAS DE FORMATAÇÃO DO ARQUIVO DE FEATURE:**
   1. **Cabeçalho com repositórios e cards de origem:** liste os repositórios
      envolvidos e os cards de origem uma vez no topo, não repita em cada item
   2. **Categorias próprias de feature:** use 🔀🤝📐⚠️ (fluxo, contratos, regras,
      edge cases) — NÃO reaproveite as 5 categorias de projeto
   3. **Destaque decisões:** use `**Decisão:**` ou `**Rationale:**` para o "por quê"
   4. **Compactar:** agrupe itens relacionados, evite verbosidade
   5. **Deduplicação por eixo:** ao consolidar múltiplos cards da mesma feature,
      deduplique dentro do arquivo de feature (mesma regra do eixo de projeto)

7. **Evitar duplicação:**
   - Antes de adicionar conhecimento, verificar se já existe em cada eixo
   - Consolidar informações similares dentro do mesmo arquivo (projeto OU feature)
   - Manter apenas o mais relevante e atual

8. **Marcar cards processados:**
   - Adicionar comentário no final de cada card processado, registrando os dois destinos:
     ```markdown
     ---
     > ✅ Conhecimento consolidado em condensed memory/projects/{projeto}.md e condensed memory/features/{feature}.md em YYYY-MM-DD
     ```
   - Se o card não tem `feature:`, registrar apenas o destino de projeto:
     ```markdown
     ---
     > ✅ Conhecimento consolidado em condensed memory/projects/{projeto}.md em YYYY-MM-DD (sem feature:)
     ```

9. **Confirmar:**

   **Se processou card específico:**
   ```
   ✅ Card consolidado!

   📝 Card processado: {nome-do-card}
   💡 Insights extraídos e consolidados
   📄 Memória de projeto atualizada: condensed memory/projects/{projeto}.md
   📄 Memória de feature atualizada: condensed memory/features/{feature}.md

   Categorias de projeto atualizadas:
   - 🏗️ Arquitetura: +N itens
   - 📋 Padrões e Convenções: +N itens
   - 🛠️ Ferramentas e Comandos: +N itens
   - ⚙️ Configuração: +N itens
   - 💡 Aprendizados Chave: +N itens

   Categorias de feature atualizadas:
   - 🔀 Fluxo Ponta a Ponta: +N itens
   - 🤝 Contratos entre Serviços: +N itens
   - 📐 Regras de Negócio: +N itens
   - ⚠️ Edge Cases: +N itens

   {Se o card não tem feature:}
   ⚠️ Card sem feature: — conhecimento de feature não roteado. Preencha feature: no frontmatter.

   O conhecimento deste card estará disponível automaticamente
   em todos os comandos /work-on-card futuros.
   ```

   **Se processou todos os cards:**
   ```
   ✅ Memória consolidada!

   📚 Cards processados: X
   💡 Insights consolidados: Y
   📄 Memória de projeto atualizada (condensed memory/projects/)
   📄 Memórias de feature atualizadas (condensed memory/features/)

   Categorias de projeto atualizadas:
   - 🏗️ Arquitetura: N subsistemas
   - 📋 Padrões e Convenções: N padrões
   - 🛠️ Ferramentas e Comandos: N ferramentas
   - ⚙️ Configuração: N configurações
   - 💡 Aprendizados Chave: N insights

   Categorias de feature atualizadas:
   - 🔀 Fluxo Ponta a Ponta: N fluxos
   - 🤝 Contratos entre Serviços: N contratos
   - 📐 Regras de Negócio: N regras
   - ⚠️ Edge Cases: N edge cases

   ✨ Melhorias aplicadas:
   - Roteamento do conhecimento em dois eixos (projeto + feature)
   - Deduplicação de informações repetidas dentro de cada eixo
   - Decisões arquiteturais destacadas
   - Formato mais compacto e estruturado
   - Origem consolidada no header

   O conhecimento consolidado estará disponível automaticamente
   em todos os comandos /work-on-card futuros.
   ```

## Casos de Uso

### Processar card específico (recomendado)
```
/condense-memory "melhorias agent obsidian"
```
Use este modo quando um card específico for movido para 4.done. É mais eficiente e evita reprocessamento desnecessário.

### Processar todos os cards pendentes
```
/condense-memory
```
Use este modo para fazer uma consolidação geral de todos os cards que ainda não foram processados.

## Notas Importantes
- **SEMPRE use o novo formato** com emojis de categoria e decisões destacadas
- **Classifique cada item em um eixo** (projeto OU feature) antes de escrever, usando o critério de desempate
- **Roteie para o arquivo correto** - projeto em `projects/{projeto}.md`, feature em `features/{feature}.md`
- **Card sem `feature:`** - escreva só no de projeto e avise no output
- **NÃO repita** a origem em cada item - liste uma vez no header
- **Deduplique** informações dentro de cada eixo - se 3 cards falam de git, consolide em uma seção só
- **Priorize decisões** arquiteturais e "por quês" sobre detalhes de implementação
- **Seja compacto** - agrupe informações relacionadas, evite verbosidade
- **Destaque decisões** - sempre use `**Decisão:**` ou `**Rationale:**` quando explicar escolhas
- **Processe cards individualmente** - use /condense-memory "nome-do-card" logo após mover para done
- Este arquivo serve como contexto otimizado para futuras tarefas da IA
