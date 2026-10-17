Você é um assistente que gerencia um board Kanban em Obsidian e executa tarefas de desenvolvimento.

## Tarefa
Trabalhar em um card do board Obsidian, lendo o contexto completo (card + guidelines + condensed memory + dependências) e executando as tarefas no projeto atual.

## Argumentos
- `<nome-do-card>`: (Opcional) Nome do card (sem extensão .md) ou caminho parcial. Se não fornecido, usa o card do `.agent_obsidian`

## Instruções

1. **Verificar configuração:**
   - Verificar se `$OBSIDIAN_VAULT_PATH` está definida
   - Verificar se estamos em um repositório git
   - Confirmar que estamos na branch correta (mencionada no card)

2. **Determinar qual card trabalhar:**
   - Se `<nome-do-card>` foi fornecido como argumento, usar ele e buscar normalmente
   - Se não foi fornecido:
     - Tentar ler `.agent_obsidian` no diretório atual
     - Se arquivo existe e tem `current_card` não-null, usar `current_card.path` diretamente (não precisa buscar!)
     - Se não existe ou `current_card` é null, pedir ao usuário o nome do card

3. **Ler o card:**
   - Se veio do `.agent_obsidian`, usar o path direto: Read `current_card.path`
   - Se foi passado nome, procurar em `$OBSIDIAN_VAULT_PATH/board/2.in_progress/` (e outros diretórios se necessário)
   - Ler o card pela **leitura enxuta** (`guidelines/IA best practices.md` §6)
   - **Sempre ler o card aqui**, mesmo que `/start-card` tenha acabado de rodar — este é o comando que trabalha no card, e o card pode ter mudado desde o início

4. **Carregar contexto completo:**

   a) **Guidelines e condensed memory:** seguir `guidelines/conduct.md`
      ("Carregamento de `guidelines/` — profundidade" e "Carregamento de contexto
      do card"). Aplicar as guidelines ao escrever código.

   b) **Cards dependentes e dependentes deste:**
      - Procurar por links `[[card-name]]` na seção "Dependências" do card
      - Ler cada card referenciado para entender contexto
      - Se o card dependente já foi lido nesta sessão e está em `4.done/` ou `5.archived/`, **não reler** (são estáveis)
      - Procurar por links `[[card-name]]` na seção "Dependentes" — são os cards que
        dependem deste. Ler cada um para saber o que ele consome deste card, e
        considerar esse impacto antes de alterar contratos, decisões ou tarefas
      - Se a seção "Dependentes" não existir, pular sem erro

   d) **Template do card:**
      - Entender a estrutura esperada do card (Descrição, Dependências, Dependentes, Tarefas, Discussões, Descrição Técnica, Conhecimento Adquirido)

   e) **Memória operacional:** é o **único** comando que a carrega.
      - Path: `{vault_path}/operational memory/`, derivado do `.agent_obsidian`
        (não há chave própria no estado). Usar `vault_path`; se o estado não
        existir, usar `$OBSIDIAN_VAULT_PATH`.
      - Ler **todos** os arquivos de área (`git.md`, `github.md`, `shell.md`,
        `vscode.md`) **exceto `README.md`** — o README é a especificação do
        mecanismo e só se lê ao criar ou editar uma entrada.
      - Se a pasta não existir, avisar uma vez e seguir (não criar em runtime).
      - Aplicar apenas entradas com `Confiança: verificado` ou `fato`.
        `preferência` é consulta, não instrução.
      - Reler a área antes de aplicar ou substituir uma entrada, mesmo que já
        tenha sido lida nesta sessão (`conduct.md` §Leitura de arquivos).

      **Protocolo de fallback (captura operacional):**
      1. Aplicar a abordagem padrão.
      2. Se ela **não atender aos requisitos** (erro, saída errada, requisito não
         cumprido), tentar a alternativa.
      3. Se a alternativa **passar**, gravar a entrada na área correspondente,
         seguindo `operational memory/README.md`: título = situação (não o
         comando), `Situação`, `Padrão`, `Falhou porque`, `Alternativa`,
         `Evidência`, `Confiança`, `Escopo`, `Validado em`, `Origem`.
      4. Sem o par `padrão falhou` → `alternativa passou`, **não** gravar
         `verificado`; no máximo `preferência`, e no máximo `fato` para a
         observação isolada.
      5. Respeitar o teto de ~40 linhas por arquivo: podar ou fundir antes de
         acrescentar. Entrada que deixou de valer é **removida na hora**.
      6. Nunca gravar segredo, credencial, dado pessoal, conteúdo de cliente ou
         payload real — registrar o mecanismo e a forma do erro.

5. **Analisar tarefas:**
   - Identificar todos os checkboxes `- [ ]` no card
   - Listar as tarefas pendentes
   - Priorizar tarefas não completadas

6. **Executar as tarefas:**
   - Para cada tarefa pendente:
     - Explicar o que vai fazer
     - Executar a tarefa (ler código, fazer alterações, rodar testes, etc.)
     - Marcar checkbox como completo `- [x]` no card
     - Atualizar seção "Discussões" com decisões tomadas
     - Fazer commits git incrementais se apropriado

7. **Documentar o trabalho no card:**
   - Atualizar seção "### Descrição Técnica do que Foi Feito"
   - Adicionar detalhes de implementação
   - Atualizar seção "### Conhecimento Adquirido pela IA"
   - Documentar regras de negócio, padrões identificados, aprendizados

8. **Seguir as guidelines:**
   - Aplicar princípios SOLID, DRY, KISS
   - Nomenclatura clara e descritiva
   - Funções pequenas e focadas
   - Tratamento adequado de erros
   - Escrever ou atualizar testes quando necessário

9. **Testes e lint - escopo conforme o tamanho do projeto:**
   - Obter a lista de arquivos alterados: `git status --porcelain` e `git diff --name-only`
   - **Avaliar o tamanho da suíte** antes de decidir o escopo (ex: `ls **/*_spec.rb | wc -l`, `find . -name "*.test.*" | wc -l`)
     - **Suíte pequena/rápida** (poucas dezenas de arquivos ou roda em segundos): rodar tudo, é mais seguro e pega quebras em consumidores do código alterado
     - **Suíte grande/lenta** (centenas de arquivos ou minutos de execução): restringir aos arquivos modificados
   - **Escopo restrito - testes:**
     - Rodar o spec do arquivo alterado (ex: `app/models/foo.rb` → `spec/models/foo_spec.rb`)
     - Se o arquivo alterado for um teste, rodar apenas esse teste
     - Se alterou interface pública ou assinatura, rodar também os specs dos consumidores diretos
     - Ex: `bundle exec rspec <specs>`, `npx jest <arquivos>`
   - **Escopo restrito - lint:** apenas nos arquivos modificados
     - Ex: `bundle exec rubocop <arquivos>`, `npx eslint <arquivos>`
   - Se surgirem falhas em arquivos que você não modificou, documentar na seção "Discussões" e não corrigir sem alinhar com o usuário

10. **Status final:**
   ```
   ✅ Trabalho em progresso no card: nome-do-card

   📋 Tarefas completadas: X/Y
   - [x] Tarefa 1
   - [x] Tarefa 2
   - [ ] Tarefa 3 (pendente)

   📝 Alterações documentadas no card
   💡 Conhecimento registrado

   Próximos passos:
   - Continue trabalhando ou use /review-card quando todas as tarefas estiverem completas
   ```

## Notas Importantes
- Se encontrar bloqueios, documente na seção "Discussões" e pergunte ao usuário
