Você é um assistente que consolida conhecimento de tarefas completadas em um arquivo de memória compartilhada.

## Tarefa
Processar cards em "4.done" (todos ou um específico), extrair conhecimento relevante e atualizar o arquivo "condensed memory.md" com aprendizados consolidados.

## Argumentos
- `<nome-do-card>`: (Opcional) Nome do card específico para processar. Se não fornecido, processa todos os cards em 4.done.

## Instruções

1. **Verificar configuração:**
   - Verificar se `$OBSIDIAN_VAULT_PATH` está definida

2. **Detectar projeto atual:**
   - Obter nome do diretório atual: `basename $(pwd)`
   - Normalizar nome: lowercase, substituir espaços por underscore
   - Este será o nome da pasta do projeto em `condensed memory/`

3. **Ler arquivo de memória atual:**
   - Ler `$OBSIDIAN_VAULT_PATH/condensed memory/{nome-do-projeto}/condensed memory.md`
   - Se não existir, criar a estrutura de pastas
   - Entender estrutura e conteúdo existente

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

   **Categorizar por tipo:**

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

6. **Atualizar condensed memory.md:**

   **NOVO FORMATO - Estrutura obrigatória:**

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

7. **Evitar duplicação:**
   - Antes de adicionar conhecimento, verificar se já existe
   - Consolidar informações similares
   - Manter apenas o mais relevante e atual

8. **Marcar cards processados:**
   - Adicionar comentário no final de cada card processado:
     ```markdown
     ---
     > ✅ Conhecimento consolidado em condensed memory/{nome-do-projeto}/condensed memory.md em YYYY-MM-DD
     ```

9. **Confirmar:**

   **Se processou card específico:**
   ```
   ✅ Card consolidado!

   📝 Card processado: {nome-do-card}
   💡 Insights extraídos e consolidados
   📄 Condensed memory atualizado

   Categorias atualizadas:
   - 🏗️ Arquitetura: +N itens
   - 📋 Padrões e Convenções: +N itens
   - 🛠️ Ferramentas e Comandos: +N itens
   - ⚙️ Configuração: +N itens
   - 💡 Aprendizados Chave: +N itens

   O conhecimento deste card estará disponível automaticamente
   em todos os comandos /work-on-card futuros.
   ```

   **Se processou todos os cards:**
   ```
   ✅ Memória consolidada!

   📚 Cards processados: X
   💡 Insights consolidados: Y
   📄 Condensed memory atualizado em novo formato

   Categorias atualizadas:
   - 🏗️ Arquitetura: N subsistemas
   - 📋 Padrões e Convenções: N padrões
   - 🛠️ Ferramentas e Comandos: N ferramentas
   - ⚙️ Configuração: N configurações
   - 💡 Aprendizados Chave: N insights

   ✨ Melhorias aplicadas:
   - Deduplicação de informações repetidas
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
- **NÃO repita** a origem em cada item - liste uma vez no header
- **Deduplique** informações - se 3 cards falam de git, consolide em uma seção só
- **Priorize decisões** arquiteturais e "por quês" sobre detalhes de implementação
- **Seja compacto** - agrupe informações relacionadas, evite verbosidade
- **Destaque decisões** - sempre use `**Decisão:**` ou `**Rationale:**` quando explicar escolhas
- **Processe cards individualmente** - use /condense-memory "nome-do-card" logo após mover para done
- Este arquivo serve como contexto otimizado para futuras tarefas da IA
