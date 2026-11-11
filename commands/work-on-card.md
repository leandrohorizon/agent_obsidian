Você é um assistente que gerencia um board Kanban em Obsidian e executa tarefas de desenvolvimento.

## Tarefa
Trabalhar em um card do board Obsidian, lendo o contexto completo (card + guidelines + condensed memory + dependências) e executando as tarefas conforme o `work_type`.

## Argumentos
- `<nome-do-card>`: (Opcional) Nome do card (sem extensão .md) ou caminho parcial. Se não fornecido, usa o card do `.agent_obsidian`

## Instruções

1. **Verificar configuração:**
   - Verificar se `$OBSIDIAN_VAULT_PATH` está definida
   - Ler `guidelines/card work types.md`

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
   - Card sem `work_type` é `implementation`; valor desconhecido interrompe o trabalho explicitamente
   - Para `implementation`, verificar que está em repositório Git e confirmar a branch do card
   - Para `report` e `investigation`, não exigir Git, trocar branch ou fazer pull
   - Para `experiment`, não executar nenhum comando Git; a pasta atual é o espaço de trabalho do experimento

4. **Carregar contexto completo:**

   a) **Guidelines e condensed memory:** seguir `guidelines/conduct.md`
      ("Carregamento de `guidelines/` — profundidade" e "Carregamento de contexto
      do card"). Aplicar as guidelines ao escrever código.

   b) **Cards dependentes e dependentes deste:**
     - Onde ler e como tratar cada forma: `guidelines/IA best practices.md` §8
     - Ler cada card referenciado; se já foi lido nesta sessão e está em
       `4.done/` ou `5.archived/`, **não reler** (são estáveis)
     - Considerar o impacto nos dependentes antes de alterar contratos, decisões
       ou tarefas

   d) **Template do card:**
     - Entender a estrutura esperada do card conforme o `work_type`: seções comuns (Descrição, Tarefas, Discussões) e as seções de entregável do tipo (templates em `templates/card/`)

   e) **Memória operacional:** é o **único** comando que a carrega.
      - Para `experiment`, não registrar entradas de memória operacional; resultados e aprendizados ficam somente no card.
      - Path: `{vault_path}/condensed memory/operational/`, derivado do
        `.agent_obsidian` (não há chave própria no estado). Usar `vault_path`; se
        o estado não existir, usar `$OBSIDIAN_VAULT_PATH`.
      - Ler **todos** os `.md` dessa pasta (`git.md`, `github.md`, `shell.md`,
        `vscode.md`, ...). Não confundir com o `README.md` de
        `condensed memory/`, que é a especificação e só se lê ao criar ou editar
        uma entrada.
      - Se a pasta não existir, seguir sem aviso: ela não é versionada e nasce na
        primeira entrada gravada. Criar o arquivo de área com o cabeçalho
        `# Operacional — {area}` quando houver entrada para gravar.
      - Aplicar apenas entradas com `Confiança: verificado` ou `fato`.
        `preferência` é consulta, não instrução.
      - Reler a área antes de aplicar ou substituir uma entrada, mesmo que já
        tenha sido lida nesta sessão (`conduct.md` §Leitura de arquivos).

      **Protocolo de fallback (captura operacional):**
      - Este protocolo de captura não se aplica a `experiment`; não registrar fallback na memória operacional.
      1. Aplicar a abordagem padrão.
      2. Se ela **não atender aos requisitos** (erro, saída errada, requisito não
         cumprido), tentar a alternativa.
      3. Se a alternativa **passar**, gravar a entrada na área correspondente,
         seguindo `condensed memory/README.md` §Memória operacional: título =
         situação (não o comando), `Situação`, `Padrão`, `Falhou porque`,
         `Alternativa`, `Evidência`, `Confiança`, `Escopo`, `Validado em`,
         `Origem`.
      4. Sem o par `padrão falhou` → `alternativa passou`, **não** gravar
         `verificado`; no máximo `preferência`, e no máximo `fato` para a
         observação isolada.
      5. Respeitar o teto de ~40 linhas por arquivo: podar ou fundir antes de
         acrescentar. Entrada que deixou de valer é **removida na hora**.
      6. Nunca gravar segredo, credencial, dado pessoal, conteúdo de cliente ou
         payload real — registrar o mecanismo e a forma do erro.

   e) **Memória operacional:** é o **único** comando que a carrega.
      - Para `experiment`, não registrar entradas de memória operacional; resultados e aprendizados ficam somente no card.
      - Path: `{vault_path}/condensed memory/operational/`, derivado do
        `.agent_obsidian` (não há chave própria no estado). Usar `vault_path`; se
        o estado não existir, usar `$OBSIDIAN_VAULT_PATH`.
      - Ler **todos** os `.md` dessa pasta (`git.md`, `github.md`, `shell.md`,
        `vscode.md`, ...). Não confundir com o `README.md` de
        `condensed memory/`, que é a especificação e só se lê ao criar ou editar
        uma entrada.
      - Se a pasta não existir, seguir sem aviso: ela não é versionada e nasce na
        primeira entrada gravada. Criar o arquivo de área com o cabeçalho
        `# Operacional — {area}` quando houver entrada para gravar.
      - Aplicar apenas entradas com `Confiança: verificado` ou `fato`.
        `preferência` é consulta, não instrução.
      - Reler a área antes de aplicar ou substituir uma entrada, mesmo que já
        tenha sido lida nesta sessão (`conduct.md` §Leitura de arquivos).

      **Protocolo de fallback (captura operacional):**
      - Este protocolo de captura não se aplica a `experiment`; não registrar fallback na memória operacional.
      1. Aplicar a abordagem padrão.
      2. Se ela **não atender aos requisitos** (erro, saída errada, requisito não
         cumprido), tentar a alternativa.
      3. Se a alternativa **passar**, gravar a entrada na área correspondente,
         seguindo `condensed memory/README.md` §Memória operacional: título =
         situação (não o comando), `Situação`, `Padrão`, `Falhou porque`,
         `Alternativa`, `Evidência`, `Confiança`, `Escopo`, `Validado em`,
         `Origem`.
      4. Sem o par `padrão falhou` → `alternativa passou`, **não** gravar
         `verificado`; no máximo `preferência`, e no máximo `fato` para a
         observação isolada.
      5. Respeitar o teto de ~40 linhas por arquivo: podar ou fundir antes de
         acrescentar. Entrada que deixou de valer é **removida na hora**.
      6. Nunca gravar segredo, credencial, dado pessoal, conteúdo de cliente ou
         payload real — registrar o mecanismo e a forma do erro.

5. **Analisar tarefas:**
   - Identificar todos os checkboxes `- [ ]` na seção `### Tarefas` do card
     (a seção `### Verificação Pós-Deploy` é executada pelo `/complete-card`,
     depois do deploy — não é tarefa deste comando)
   - Listar as tarefas pendentes
   - Priorizar tarefas não completadas

6. **Executar as tarefas:**
   - Para cada tarefa pendente:
     - Explicar o que vai fazer
     - Executar a tarefa (ler código, fazer alterações, rodar testes, etc.)
     - `report`: não alterar código do projeto; produzir o documento solicitado em `docs/{projeto}/reports/` dentro do vault e registrar o caminho no card
     - `investigation`: tratar o código do projeto como somente leitura; registrar evidências, conclusões, incertezas e referências no card; documento opcional em `docs/{projeto}/investigations/` dentro do vault
     - `experiment`: criar ferramentas pequenas somente na pasta de trabalho atual; não executar Git, alterar outro projeto ou escrever na condensed memory; testes são opcionais e, quando úteis, devem ser locais e seguros; registrar caminho relativo, instruções de uso e resultado observado no card
     - Se uma investigação identificar trabalho de implementação, criar um card relacionado com `work_type: implementation`; não converter este card nem alterar código
     - Marcar checkbox como completo `- [x]` no card
     - Atualizar seção "Discussões" com decisões tomadas
     - Somente para `implementation`, commitar cada unidade lógica conforme `guidelines/commit guidelines.md`

7. **Documentar o trabalho no card:**
   - `implementation`: preencher "### Descrição Técnica do que Foi Feito" e "### Conhecimento Adquirido pela IA"
   - `report`: preencher "### Documento Produzido" (caminho) e "### Fontes e Referências"
   - `investigation`: preencher "### Descobertas e Conclusões", "### Referências" e "### Conhecimento Adquirido pela IA"
   - `experiment`: preencher "### Ferramenta e Resultado" (como usar, caminhos relativos e resultado observado)
   - Registrar decisões em "### Discussões"

8. **Seguir as guidelines:**
   - Aplicar princípios SOLID, DRY, KISS
   - Nomenclatura clara e descritiva
   - Funções pequenas e focadas
   - Tratamento adequado de erros
   - Escrever ou atualizar testes quando necessário
   - Para `experiment`, manter o escopo na ferramenta isolada da pasta atual; nenhuma alteração deve ser promovida para outro projeto

9. **Validar o resultado:**
   - Para `report` e `investigation`, não executar testes/lint nem modificar código do projeto
   - Para `experiment`, testes automatizados são opcionais; quando forem úteis, validar apenas a ferramenta criada com execução local segura. Não executar comandos Git, testes do projeto hospedeiro ou lint fora da pasta do experimento
   - Para `implementation`, obter a lista de arquivos alterados: `git status --porcelain` e `git diff --name-only`
   - As regras de escopo de suíte e lint abaixo aplicam-se somente a `implementation`:
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
   - Continue trabalhando; quando todas as tarefas estiverem completas, use /review-card para implementation ou /complete-card para report, investigation e experiment
   ```

## Notas Importantes
- Se encontrar bloqueios, documente na seção "Discussões" e pergunte ao usuário
