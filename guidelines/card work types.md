# Card Work Types

`work_type` é o contrato de execução do card. O campo fica no frontmatter e aceita
**exatamente** um de quatro valores: `implementation`, `report`, `investigation`
ou `experiment`.

Este arquivo é a **fonte única de verdade** do que cada tipo pode fazer. Os
comandos consumidores (`/create-card`, `/start-card`, `/work-on-card`,
`/load-context`, `/review-card`, `/complete-card`, `/condense-memory` e
`/orchestrate-cards`) leem o tipo **antes** de executar qualquer ação e executam
somente o que está autorizado para ele.

## Regra geral — permissão explícita (allowlist)

- Cada tipo executa **somente** as ações listadas na sua allowlist.
- **Tudo que não estiver listado está proibido**, independentemente do que outro
  tipo faz ou do que o fluxo já fez no passado.
- Não inferir permissão a partir do comportamento padrão de outros tipos, nem
  executar etapa por convenção ou compatibilidade.
- Tipo ausente segue o fallback documentado abaixo (tratado como
  `implementation`). Valor presente e fora da lista é **inválido**: interromper
  a execução, informar explicitamente o problema e **não produzir efeito
  colateral** — não trocar branch, não mover o card, não alterar estado, não
  escrever memória.

## Validação do tipo

- Cards novos são sempre criados com `work_type` no frontmatter.
- Ausente → tratar como `implementation` (fallback de compatibilidade).
- Valor presente e fora da lista → interromper e informar o valor encontrado,
  sem efeito colateral.
- `/create-card` infere o tipo do pedido quando estiver claro e pergunta quando
  estiver ambíguo; o card criado sempre grava `work_type` no frontmatter.
- `/orchestrate-cards` processa `implementation` e cards sem `work_type`; valor
  inválido é reportado como erro, nunca tratado como implementação.

## Allowlist por tipo

### `implementation`
- Executar Git: criar e trocar branch, `git pull`, commit, push, abrir e atualizar PR.
- Alterar código do projeto.
- Escrever e rodar testes, lint e build do projeto.
- Documentação opcional no repositório, quando relevante.
- Passar por `3.in_review` (revisão via PR).
- Consolidar memória automaticamente na conclusão, após o merge.

### `report`
- Ler o projeto e fontes externas, sem alterar código.
- Produzir o documento do relatório em `docs/{projeto}/reports/` no vault central.
- Registrar no card o caminho do documento.
- Atualizar as seções do card (Descrição, Tarefas, Discussões, Documento Produzido, Fontes e Referências).
- Concluir diretamente de `2.in_progress` para `4.done`, sem `3.in_review`.

### `investigation`
- Ler e estudar o projeto ou fluxo, sem alterar código.
- Registrar no card descobertas, conclusões, incertezas e referências.
- Documento opcional em `docs/{projeto}/investigations/` no vault central.
- Criar card relacionado `work_type: implementation` quando a investigação
  revelar trabalho de código.
- Concluir diretamente de `2.in_progress` para `4.done`, sem `3.in_review`.
- Consolidar memória somente após confirmação explícita do usuário na conclusão.

### `experiment`
- Criar e executar ferramentas pequenas na pasta de trabalho atual.
- Rodar validações locais da ferramenta (testes automatizados opcionais).
- Registrar no card o resultado, como usar e os caminhos relativos dos artefatos.
- Concluir diretamente de `2.in_progress` para `4.done`, sem `3.in_review`.
- Manter os artefatos na pasta atual até limpeza manual.

`{projeto}` é o nome do diretório raiz do projeto normalizado para lowercase,
com espaços e hífens substituídos por underscore, igual ao nome da memória de
projeto. Os documentos de relatório e investigação ficam no vault central, não
no repositório do projeto; informar o caminho completo ao usuário.

## Comportamento dos comandos por tipo

Cada comando executa apenas as ações da allowlist do tipo; ação fora da lista
interrompe o comando com erro explícito, sem efeito colateral.

- `/start-card`: `implementation` troca branch, faz pull e cria branch;
  `report`, `investigation` e `experiment` movem para `2.in_progress` e atualizam
  `status`/`started`, mantendo `branch:` vazio.
- `/work-on-card`: `implementation` executa as tarefas e commita
  incrementalmente; `report` produz o documento em `docs/{projeto}/reports/`;
  `investigation` registra descobertas no card; `experiment` cria a ferramenta
  na pasta atual e valida localmente quando útil.
- `/load-context`: carrega contexto em todos os tipos; sincroniza branch e
  apresenta estado Git apenas para `implementation`.
- `/review-card`: aplica-se apenas a `implementation`; os demais tipos concluem
  diretamente com `/complete-card`.
- `/complete-card`: `implementation` exige PR merged, volta para a branch default
  e apaga a branch local; os demais tipos concluem de `2.in_progress` para
  `4.done`. Só limpa `.agent_obsidian.current_card` quando ele aponta para o
  card concluído.
- `/condense-memory`: processa apenas `implementation` (e `investigation`
  nomeada explicitamente, como confirmação). `report` e `experiment` nunca são
  consolidados.

`3.in_review` é exclusivo de `implementation`. Uma investigação que descobrir
trabalho de código cria um novo card relacionado com `work_type: implementation`;
não transforma silenciosamente o card de investigação em implementação.
