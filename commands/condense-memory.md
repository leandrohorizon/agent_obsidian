Você é um assistente que consolida conhecimento de tarefas completadas em um arquivo de memória compartilhada.

## Tarefa
Processar cards em "4.done" (todos ou um específico), extrair conhecimento relevante e atualizar os arquivos de condensed memory (projeto e/ou feature) com aprendizados consolidados.

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
     - Seção "### Descrição"
     - Seção "### Conhecimento Adquirido pela IA"
     - Seção "### Discussões"
     - Seção "### Descrição Técnica do que Foi Feito"

6. **Extrair e processar conhecimento:**

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

7. **Atualizar os arquivos de memória (roteamento por eixo):**

   **Roteamento:**
   - Itens classificados como **projeto** → escrever em `condensed memory/projects/{projeto}.md`
   - Itens classificados como **feature** → escrever em `condensed memory/features/{feature}.md`
   - Se o card tem `feature:` no frontmatter → escrever nos dois arquivos (projeto + feature)
   - Se o card NÃO tem `feature:` → escrever só no de projeto e avisar no output:
     `⚠️ Card sem feature: — conhecimento de feature não roteado. Preencha feature: no frontmatter.`
   - Se `feature:` é uma lista YAML (`feature: [a, b]`) → escrever o recorte pertinente de cada item em cada arquivo de feature correspondente

   **FORMATO — fonte única:** o cabeçalho, as categorias e as regras de forma dos
   dois eixos estão em `condensed memory/README.md`. Ler esse arquivo antes de
   escrever e segui-lo; não reinventar template.

   Pontos que a especificação fixa e não devem ser contrariados aqui:
   - Projeto: header com `Última atualização` / `Cards processados` / `Origem`;
     categorias 🏗️ Arquitetura, 📋 Padrões e Convenções, 🛠️ Ferramentas e Comandos,
     ⚙️ Configuração, 💡 Aprendizados Chave
   - Feature: header com `Última atualização` / `Repositórios envolvidos` /
     `Cards de origem`; categorias 🔀 Fluxo Ponta a Ponta, 🤝 Contratos entre
     Serviços, 📐 Regras de Negócio, ⚠️ Edge Cases — nunca as 5 de projeto
   - Item sempre com `**Decisão:**` ou `**Rationale:**` para o "por quê"
   - Origem listada uma vez no header, não repetida por item

   **Fronteira entre os eixos** (também em `condensed memory/README.md`):
   conhecimento que vale em qualquer repositório é operacional e vai para
   `condensed memory/operational/`, não para o §💡 Aprendizados Chave.

8. **Evitar duplicação:**
   - Antes de adicionar conhecimento, verificar se já existe em cada eixo
   - Consolidar informações similares dentro do mesmo arquivo (projeto OU feature)
   - Manter apenas o mais relevante e atual

9. **Marcar cards processados:**
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

10. **Confirmar:**

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
