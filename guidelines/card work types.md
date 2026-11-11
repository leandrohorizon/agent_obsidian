# Card Work Types

`work_type` define o contrato de execução do card. O campo fica no frontmatter e
aceita somente `implementation`, `report`, `investigation` ou `experiment`.

## Compatibilidade e validação

- Card sem `work_type` é `implementation`, preservando o fluxo existente.
- Valor presente fora dos tipos listados é inválido. Informar o valor e interromper
  antes de trocar branch, mover o card, alterar o estado ou executar outra ação.
- `/create-card` infere o tipo do pedido quando estiver claro; pergunta somente
  quando o tipo estiver ambíguo. Não deve adicionar uma pergunta fixa a todo uso.
- `/orchestrate-cards` processa apenas `implementation` e cards legados sem o
  campo. Relatórios, investigações e experimentos são informados como ignorados;
  tipos inválidos são reportados como erro, nunca tratados como implementação.

## Contrato por tipo

| Comportamento | `implementation` | `report` | `investigation` | `experiment` |
|---|---|---|---|---|
| Branch, commit, push e PR | Fluxo existente, quando aplicável | Não | Não | Nunca executar comandos Git |
| Alterar código do projeto | Sim | Não | Não | Não; criar ferramentas pequenas na pasta de trabalho atual |
| Entregável | Alterações, testes e informações de Git | Documento em `docs/{projeto}/reports/` | Descobertas, conclusões e referências; documento opcional em `docs/{projeto}/investigations/` | Ferramenta e resultado preservados na pasta atual; registrar uso e resultado no card |
| Revisão em `3.in_review` | Sim, via PR | Não; concluir diretamente | Não; concluir diretamente | Não; concluir diretamente |
| Consolidar memória | Automática ao concluir, conforme fluxo existente | Nunca | Perguntar ao concluir; consolidar só após confirmação | Nunca, nem sob solicitação explícita do comando |

`{projeto}` é o nome do diretório raiz do projeto normalizado para lowercase,
com espaços e hífens substituídos por underscore, igual ao nome da memória de
projeto. Os documentos ficam no vault central, não no repositório do projeto.
Não criar branch, commit ou PR para persistir esses documentos; informar o
caminho completo ao usuário.

## Ciclo branchless de relatórios e investigações

- `/start-card` move relatório e investigação para `2.in_progress`, atualiza
  `status` e `started`, mantém `branch:` vazio e não troca branch, faz pull ou
  cria branch.
- `/work-on-card` pode criar o entregável somente nas pastas `docs/` do vault.
  Relatório e investigação não alteram código do projeto e não fazem commits.
- `/load-context` carrega o contexto normalmente, mas não sincroniza branch,
  executa pull ou analisa diff como trabalho deste card.
- `/review-card` não se aplica a esses tipos; orienta a concluir diretamente.
- `/complete-card` aceita relatório e investigação em `2.in_progress`, move
  diretamente para `4.done`, não exige PR e não executa checkout, pull ou
  exclusão de branch. Só limpa `.agent_obsidian.current_card` quando ele aponta
  para o card concluído.
- Na conclusão, relatório não chama `/condense-memory`. Para investigação,
  perguntar se há conhecimento reutilizável e se o usuário confirma a
  consolidação; executar `/condense-memory "{card}"` somente após confirmação.
- `/condense-memory` nunca processa relatório. A execução sem nome processa
  implementações pendentes, mas não investigações. Nomear explicitamente uma
  investigação no comando é confirmação para processá-la.

Manter `3.in_review` exclusivo de implementação. Uma investigação que descobrir
trabalho de código pode criar um novo card relacionado com
`work_type: implementation`; não transformar silenciosamente o card de
investigação em implementação.

As regras acima também dispensam Git em `experiment`; para esse tipo, a
proibição inclui até comandos de consulta. O ciclo específico é:

- `/create-card` identifica `experiment` quando o pedido for criar e validar
  uma ferramenta pequena para um problema isolado. Não consulta Git nem sugere
  `feature:`; mantenha o campo vazio.
- O usuário entra na pasta do experimento e chama `/start-card` ali. Esse tipo
  não executa nenhum comando Git — nem para consultar repositório, branch ou
  remote — e mantém `repo:` e `branch:` vazios.
- `/work-on-card` pode criar e executar a ferramenta na pasta atual. Não alterar
  outros projetos, executar comandos Git, criar commits ou enviar os artefatos
  para versionamento. Testes automatizados são opcionais; quando forem úteis,
  executar validações locais seguras e registrar no card o caminho relativo,
  como usar e o resultado observado.
- `/load-context` atualiza `.agent_obsidian` e carrega contexto normalmente, mas
  não executa comandos Git nem apresenta estado de branch ou diff.
- `/review-card` não se aplica; concluir diretamente com `/complete-card`.
- `/complete-card` move o card de `2.in_progress` para `4.done`, sem Git e sem
  consolidação de memória. Os arquivos do experimento permanecem na pasta até
  que o usuário os remova manualmente.
- `/condense-memory` nunca processa experimentos, nem quando são nomeados
  explicitamente. O conhecimento e as referências permanecem apenas no card.
