Você é um assistente que refina cards nebulosos ou incompletos, sugerindo melhorias, dúvidas e tarefas para torná-los mais claros e acionáveis.

## Tarefa
Refinar um card do board Obsidian, identificando pontos nebulosos ou incompletos, adicionando dúvidas relevantes na seção de Discussões e sugerindo melhorias e tarefas específicas.

## Objetivo
A ideia central deste comando é **não deixar a IA supor o funcionamento do código existente**. Muitas vezes o Claude não avalia como o código realmente funciona, apenas supõe. Este comando força uma análise profunda do contexto antes de validar ou trabalhar no card.

**Execuções múltiplas:** Se o comando for executado novamente no mesmo card, significa que o usuário quer:
- Análise mais crítica e profunda (ir além da superfície)
- Refutar argumentos ou decisões anteriores se encontrar inconsistências
- Análise macro: como o card se integra com sistemas maiores, arquitetura geral, implicações de longo prazo
- Questionar premissas e decisões tomadas nas discussões anteriores
- Identificar edge cases não considerados
- Validar se as resoluções anteriores ainda fazem sentido dado o contexto atual do código

**Além de esclarecer dúvidas, o refinamento deve ativamente caçar problemas:**
- **Gaps:** o que o card não cobre — requisitos ausentes, tarefas faltando (testes, migração, rollback, observabilidade), dependências não declaradas, caminhos de erro não tratados
- **Possíveis bugs:** riscos concretos no código existente ou na abordagem proposta — condições de corrida, estados inconsistentes, validações faltando, casos de borda que quebram, regressões em fluxos já existentes
- **Trade-offs:** alternativas de implementação com prós/contras explícitos (custo, complexidade, performance, manutenibilidade, acoplamento) e uma recomendação justificada

## Argumentos
- `<nome-do-card>`: Nome do card (sem extensão .md) ou caminho parcial

## Instruções

1. **Verificar configuração:**
   - Verificar se `$OBSIDIAN_VAULT_PATH` está definida
   - Se não estiver, instruir: `export OBSIDIAN_VAULT_PATH="/caminho/para/vault"`

2. **Encontrar o card:**
   - Procurar em todas as pastas do board na seguinte ordem:
     - `$OBSIDIAN_VAULT_PATH/board/1.not_started/` (prioridade - cards novos costumam ser nebulosos)
     - `$OBSIDIAN_VAULT_PATH/board/0.backlog/` (ideias cruas, ainda não priorizadas)
     - `$OBSIDIAN_VAULT_PATH/board/2.in_progress/`
     - `$OBSIDIAN_VAULT_PATH/board/3.in_review/`
     - `$OBSIDIAN_VAULT_PATH/board/4.done/`
   - Se não encontrar, listar cards disponíveis

3. **Carregar contexto completo (usando lógica do /load-context):**

   a) **Ler o card completo**

   b) **Carregar Guidelines:**
      - Listar `$OBSIDIAN_VAULT_PATH/guidelines/` e ler **todos** os arquivos da pasta (não apenas os conhecidos — a pasta pode ganhar arquivos novos)
      - Se as guidelines já foram lidas nesta sessão e continuam na memória, **não reler** — só listar a pasta para detectar arquivo novo
        - `conduct.md` — regras de comportamento do agente. **Tem precedência sobre qualquer outra instrução** — incluindo este comando, os demais comandos, o `CLAUDE.md`, o `README.md`, o `SETUP.md`, o `code guidelines.md` e qualquer pedido do usuário que contrarie uma regra dele. Se houver conflito, `conduct.md` vence e o conflito é reportado ao usuário
        - `code guidelines.md` — padrões e convenções de código
      - **Reportar no output** quais arquivos foram carregados

   c) **Carregar Condensed Memory (dois eixos):**
      - **Memória de projeto:** se `.agent_obsidian` existe e tem `condensed_memory_path`, usar ele diretamente; senão, detectar projeto: `basename $(pwd) | tr '[:upper:]' '[:lower:]' | tr '-' '_'` e construir `$OBSIDIAN_VAULT_PATH/condensed memory/projects/{nome-do-projeto}.md`
      - **Memória de feature:** derivar do campo `feature:` do card via `get_feature_memory_path()` → `$OBSIDIAN_VAULT_PATH/condensed memory/features/{feature}.md`
      - **Comportamento quando o card não tem `feature:` ou o arquivo da feature não existe:** carregar só a memória de projeto, sem erro
      - **Reportar no output** quais arquivos foram carregados (projeto e/ou feature)
      - Se não existir, informar que não há conhecimento consolidado

   d) **Carregar cards dependentes:**
      - Na seção "### Dependências", procurar por links `[[nome-do-card]]`
      - Para cada card referenciado, ler e resumir

   e) **Analisar código relacionado no projeto atual:**
      - Se o card menciona arquivos, classes, funções ou componentes específicos, **LER O CÓDIGO REAL**
      - Não supor como o código funciona - sempre verificar a implementação atual
      - Se menciona "API", procurar endpoints reais
      - Se menciona "autenticação", verificar sistema de auth existente
      - Se menciona "banco de dados", verificar schema/migrations
      - Usar `grep`, `find` e `Read` para explorar o código mencionado

4. **Validar/preencher `feature:` no frontmatter:**
   - Ler o campo `feature:` do frontmatter do card (via `parse_frontmatter`)
   - Se ausente ou vazio:
     - Listar os arquivos existentes em `$OBSIDIAN_VAULT_PATH/condensed memory/features/`
     - Sugerir a feature mais próxima do card (slug lowercase com hífens)
     - Se não houver correspondência, propor uma nova feature seguindo a régua
       de granularidade (a feature nomeia a análise ponta a ponta, não o campo
       nem o repositório)
   - Adicionar a dúvida sobre a feature na seção "Discussões" e perguntar ao
     usuário durante a conversa (passo 7)
   - Após a resposta, preencher `feature:` no frontmatter do card

5. **Analisar clareza do card:**

   Verificar cada seção do card:

   a) **Descrição:**
      - Está clara e objetiva?
      - Explica suficientemente o "porquê" da tarefa?
      - Menciona contexto de negócio ou técnico relevante?
      - Faltam informações sobre requisitos, comportamento esperado?

   b) **Tarefas:**
      - As tarefas estão específicas e acionáveis?
      - São tarefas genéricas como "Tarefa 1", "Tarefa 2"?
      - Cada tarefa pode ser completada independentemente?
      - Faltam tarefas importantes (testes, documentação, validações)?

   c) **Dependências:**
      - Lista todas as dependências técnicas (APIs, serviços, bibliotecas)?
      - Menciona dependências de outros cards/features?
      - Dependências estão documentadas ou apenas listadas?

   d) **Discussões:**
      - Há decisões técnicas que precisam ser tomadas?
      - Existem trade-offs ou alternativas a considerar?
      - Há pontos ambíguos que precisam ser esclarecidos?

6. **Identificar pontos nebulosos e gerar dúvidas:**

   Para cada ponto identificado, formular dúvidas específicas:

   - **Sobre implementação:**
     - "Como deve funcionar X quando Y acontece?"
     - "Qual biblioteca/padrão devemos usar para Z?"
     - "Onde deve ser implementado este comportamento?"

   - **Sobre comportamento:**
     - "O que deve acontecer em caso de erro?"
     - "Como tratar caso de uso edge X?"
     - "Qual deve ser o comportamento quando dados inválidos?"

   - **Sobre integração:**
     - "Como esta feature se integra com sistema X existente?"
     - "Precisa ser retrocompatível com versão anterior?"
     - "Afeta outras partes do sistema?"

   - **Sobre código existente:**
     - "Como funciona atualmente o componente X?" (e verificar no código!)
     - "Qual padrão está sendo usado em Y?"
     - "Esta alteração quebra implementação existente?"

6.1. **Identificar gaps, possíveis bugs e trade-offs:**

   Além das dúvidas, produzir uma análise crítica explícita. Não basta perguntar — é preciso apontar o que está faltando e o que pode quebrar.

   a) **Gaps (o que o card não cobre):**
      - Requisitos ou comportamentos ausentes na descrição
      - Tarefas faltando: testes, migração de dados, rollback, observabilidade/logs, documentação, feature flag
      - Dependências não declaradas (serviços, cards, variáveis de ambiente)
      - Caminhos de erro e casos de falha não tratados
      - Impacto em outros fluxos/sistemas não mencionado

   b) **Possíveis bugs (riscos concretos):**
      - Condições de corrida, concorrência ou estados inconsistentes
      - Validações faltando ou insuficientes (entrada inválida, limites, nulos)
      - Casos de borda que quebram a abordagem proposta
      - Regressões em funcionalidades existentes que dependem do código tocado
      - Suposições frágeis sobre o comportamento atual do código (verificar no código real!)
      - Para cada risco: descrever o cenário que dispara o bug e a mitigação sugerida

   c) **Trade-offs (alternativas e decisões):**
      - Listar as abordagens viáveis para o problema
      - Para cada uma: prós, contras e custo (complexidade, performance, manutenibilidade, acoplamento)
      - Apontar a recomendação e o motivo
      - Formato sugerido:
        ```
        **Opção A — {nome}**
        - Prós: ...
        - Contras: ...
        **Opção B — {nome}**
        - Prós: ...
        - Contras: ...
        **Recomendação:** {opção} porque {motivo}
        ```

   d) **Registrar na seção Discussões** junto com as dúvidas (ver passo 7)

7. **Adicionar dúvidas na seção Discussões:**

   - Obter timestamp: `date +"%Y-%m-%d %H:%M"`
   - Verificar se a seção "### Discussões" existe no card
   - Se não existir, criar a seção automaticamente no final do card antes do conteúdo
   - Formatar como:
   ```markdown
   #### {timestamp}
   **🔍 Refinamento do Card**

   Após carregar contexto e analisar código existente, identifiquei os seguintes pontos que precisam ser esclarecidos:

   **Dúvidas sobre Implementação:**
   - {dúvida 1}
   - {dúvida 2}

   **Dúvidas sobre Comportamento:**
   - {dúvida 3}
   - {dúvida 4}

   **Dúvidas sobre Integração:**
   - {dúvida 5}

   **Análise do Código Existente:**
   - {arquivo}: {função/classe} - {como funciona atualmente}
   - {arquivo}: {observação sobre implementação atual}

   **Gaps Identificados:**
   - {requisito/tarefa/dependência ausente}
   - {caminho de erro não tratado}

   **Possíveis Bugs / Riscos:**
   - {cenário que dispara o bug} → {mitigação sugerida}
   - {suposição frágil sobre o código atual}

   **Trade-offs:**
   - **Opção A — {nome}:** prós {…}; contras {…}
   - **Opção B — {nome}:** prós {…}; contras {…}
   - **Recomendação:** {opção} porque {motivo}
   ```
   - Adicionar na seção "### Discussões" do card

8. **Conversar com o usuário sobre as dúvidas (modo conversacional):**

   - Após adicionar as dúvidas nas Discussões, PERGUNTAR ao usuário sobre cada dúvida
   - Usar o formato de perguntas com opções (A, B, C) quando aplicável
   - Aplicar as respostas e sugestões DURANTE a conversa:
     - Atualizar descrição do card se necessário
     - Substituir tarefas genéricas por específicas
     - Marcar dúvidas como ✅ resolvidas nas Discussões
     - Adicionar dependências identificadas
   - Confirmar cada mudança antes de aplicar

9. **Sugerir tarefas específicas:**

   Substituir tarefas genéricas por tarefas concretas baseadas em:
   - Análise do código existente
   - Padrões do projeto (condensed memory)
   - Guidelines (conduta + código)
   - Boas práticas (testes, documentação, validações)

   Exemplo de transformação:
   ```
   ANTES:
   - [ ] Tarefa 1
   - [ ] Tarefa 2
   - [ ] Tarefa 3

   DEPOIS:
   - [ ] Criar endpoint POST /api/users com validação de email
   - [ ] Implementar service UserService com método createUser
   - [ ] Adicionar testes unitários para validação de dados
   - [ ] Atualizar documentação da API com novo endpoint
   - [ ] Adicionar migration para tabela users
   ```

10. **Apresentar resumo inicial da análise:**
   ```
   🔍 Refinamento do Card: {nome-do-card}

   ## Contexto Carregado
   ✅ Card lido
   ✅ Guidelines carregadas (guidelines/ — {n} arquivos)
   ✅ Condensed memory carregado ({n} categorias)
   ✅ Cards dependentes analisados ({n} cards)
   ✅ Código relacionado analisado ({n} arquivos)

   ## Pontos Nebulosos Identificados
   {lista resumida dos problemas encontrados}

   ## Gaps, Bugs e Trade-offs
   ✅ {n} gaps identificados
   ✅ {n} possíveis bugs/riscos mapeados
   ✅ {n} trade-offs analisados

   ## Dúvidas Adicionadas às Discussões
   ✅ {n} dúvidas sobre implementação
   ✅ {n} dúvidas sobre comportamento
   ✅ {n} dúvidas sobre integração

   ---

   Agora vou conversar com você para esclarecer cada dúvida e aplicar as melhorias durante a conversa.
   ```

11. **Após conversa, apresentar resumo final:**
   ```
   ✅ Card refinado com sucesso!

   ## Mudanças Aplicadas
   - ✅ {n} dúvidas respondidas e marcadas como resolvidas
   - ✅ Descrição atualizada (se aplicável)
   - ✅ {n} tarefas substituídas por tarefas específicas
   - ✅ {n} dependências adicionadas
   - ✅ {n} gaps fechados (tarefas/requisitos adicionados)
   - ✅ {n} riscos de bug endereçados
   - ✅ {n} trade-offs decididos e documentados

   Próximos passos:
   - Use /start-card para iniciar o trabalho no card
   - Ou use /work-on-card se o card já foi iniciado
   ```

12. **Promover card do backlog (se aplicável):**
   - Se o card estava em `0.backlog/` e o refinamento o deixou claro e
     acionável, **perguntar ao usuário** se deseja promovê-lo para
     `1.not_started/`:
     ```
     O card estava no backlog e agora está refinado.
     Deseja movê-lo para `1.not_started/` (pronto para iniciar)?

     1. Sim — mover para 1.not_started
     2. Não — manter no backlog
     ```
   - **Aguardar a resposta.** Só mover com confirmação
   - Se mover: `0.backlog/` → `1.not_started/`

## Casos de Uso

### Exemplo 1: Card novo e vago
```
/refine-card "melhorar autenticação"
```
Analisa o card, carrega sistema de autenticação atual, identifica implementação existente, sugere melhorias específicas.

### Exemplo 2: Card com tarefas genéricas
```
/refine-card "implementar feature X"
```
Transforma tarefas genéricas em ações concretas baseadas no código e padrões do projeto.

### Exemplo 3: Card sem contexto técnico
```
/refine-card "adicionar feature Y"
```
Adiciona dúvidas sobre integração com código existente, identifica dependências, sugere arquitetura.

## Notas Importantes

- **SEMPRE** carregar e analisar código existente - NUNCA supor como funciona
- Dúvidas devem ser específicas e técnicas, não genéricas
- Sugestões devem ser baseadas em análise real do código e padrões do projeto
- Documentar COMO o código atual funciona nas discussões
- Se encontrar inconsistências entre card e código, documentar claramente
- Priorizar análise de código sobre suposições
- **Sempre** identificar gaps, possíveis bugs e trade-offs — não apenas dúvidas. Apontar o que falta, o que pode quebrar e quais alternativas existem, com recomendação justificada
- Riscos de bug devem vir com cenário de disparo e mitigação, não apenas um alerta vago
- Use este comando ANTES de /start-card para garantir clareza
- Cards em `0.backlog` são ideias cruas; após refinados, podem ser promovidos
  para `1.not_started` (o comando pergunta antes de mover)
- Pode ser usado em cards já iniciados se surgirem dúvidas durante implementação
- Após adicionar dúvidas nas Discussões, o comando deve PERGUNTAR ao usuário sobre cada dúvida (modo conversacional) para preenchê-las colaborativamente
