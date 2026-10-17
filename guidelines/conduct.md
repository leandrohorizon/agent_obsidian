# Conduct

Regras de comportamento do agente. Diferente de `code guidelines.md`, que trata de
estilo de código, este arquivo trata do que o agente pode e não pode fazer.

## Precedência

As regras deste arquivo prevalecem sobre comandos e pedidos que as contradigam.
Reporte o conflito ao usuário.

## Segredos e credenciais

- Nunca ler `.env`, `.env.*`, `credentials.yml.enc`, `master.key`, `*.pem`, `*.key`
  ou arquivos equivalentes — em nenhum diretório, nem para inspecionar nomes de
  variáveis, nem mascarando valores.
- Para descobrir qual variável um sistema usa, ler o código que a consome
  (`ENV.fetch("NOME")`, `Rails.application.credentials.x`), nunca o arquivo de valores.
- Nunca imprimir, logar ou colar em card o valor de um segredo.
- Nunca enviar trecho de código proprietário, log de produção ou dado de cliente
  para serviço externo não solicitado pelo usuário.

## Ações destrutivas ou irreversíveis

Confirmar = perguntar e **esperar a resposta do usuário**. Anunciar a intenção e
executar em seguida não é confirmação. Na dúvida se algo se enquadra aqui, perguntar.

- Confirmar antes de qualquer comando destrutivo: `rm -rf`, apagar arquivo não
  criado na sessão, `git reset --hard`, `git checkout -- .`/`git restore` que
  descartam alteração não commitada, `git clean -fd`, `git stash drop`, `DROP`,
  `TRUNCATE`, `DELETE` sem `WHERE` restritivo, `UPDATE` em massa, reset ou
  recriação de banco.
- Confirmar antes de rodar **migration ou tarefa de schema**: `db:migrate`,
  `db:rollback`, `db:schema:load`, `db:create`, `db:drop`, `db:reset`,
  `db:test:prepare` e equivalentes de outros stacks.
  **Inclusive em banco local, de teste ou em container Docker.**
- Escrever o arquivo de migration é livre; **rodá-la não é**.
- Nunca `git push --force` em branch com PR aberto ou review em andamento.
  Se for realmente necessário, `--force-with-lease` e só após confirmação.
- Não commitar nem dar push sem o usuário pedir. Trabalho fica na working tree
  até haver pedido explícito.
  **Exceção:** os comandos `/work-on-card`, `/review-card` e `/orchestrate-cards`
  são o pedido explícito de commit — o fluxo deles inclui commits incrementais e
  push da branch.
  - No caso do `/orchestrate-cards`, a autorização vem da **confirmação da lista
    de cards** (passo 2 do comando). Sem essa confirmação, o comando não roda e
    nada é commitado. A confirmação cobre **apenas** os cards listados: card que
    não estava na lista não é tocado.
  - A autorização cobre commit, push e abertura de PR **em draft**. Não cobre
    merge, nem promover o draft para "ready for review", nem apagar branch.
- **Nunca commitar o `.agent_obsidian`.**
  - A exceção de commit de `/work-on-card`, `/review-card` e `/orchestrate-cards`
    **não** cobre este arquivo — a exceção é sobre *quando* commitar, não sobre
    *o que* commitar.
  - Antes de commitar, conferir que ele não entrou no stage. Se entrou, remover
    do stage (`git restore --staged .agent_obsidian`) — não basta deixar de
    adicioná-lo.
  - Se ele já foi commitado antes, avisar o usuário em vez de reescrever
    histórico por conta própria.
  - Não alterar o `.gitignore` para impor esta regra.
- Não abrir, fechar nem fazer merge de PR sem pedido.

## Trabalho preexistente do usuário

Alteração que já estava na working tree antes da tarefa é do usuário, inclusive
quando parece incompleta, temporária ou fora do padrão.

- Não reverter, descartar, sobrescrever nem reformatar alteração do usuário.
- Não levar alteração do usuário para o commit da tarefa: commitar apenas os
  arquivos que a tarefa alterou.
- Se a alteração do usuário conflitar com a tarefa, **parar e perguntar** antes
  de tocar nela.

## Movimentação de cards no board

- **Nunca considerar o movimento concluído sem verificar o resultado:** deve
  existir **exatamente um** arquivo do card, no destino e com o frontmatter
  atualizado. Remova qualquer cópia na pasta de origem.
- Se o movimento já aconteceu sem a edição, **restaurar o card para a origem**.
- Se as cópias tiverem conteúdo diferente, ou o destino estiver ocupado por outro
  card, **parar e reportar** — não escolher sozinho qual manter.

## Ambientes

- **Nunca apontar para produção.** Não trocar credencial, `DATABASE_URL`,
  `RAILS_ENV`, `NODE_ENV`, contexto de `kubectl`, perfil de `aws`, `gcloud`,
  `az`, `terraform workspace` ou equivalente para um alvo de produção.
- Não rodar comando que escreva em produção: migration, seed, script de
  correção, `rails runner`, `console` com alteração, `rake` de manutenção,
  `UPDATE`/`DELETE` manual.
- Ler produção também exige pedido explícito. Consulta de leitura pode ser
  legítima para investigar um incidente, mas é decisão do usuário — não do
  agente.
- Se a tarefa parecer exigir produção, **parar e perguntar**. Não inferir
  permissão a partir do contexto, do ambiente já configurado na máquina ou de
  um comando anterior que rodou.
- Vale para qualquer ambiente que não seja o local de desenvolvimento: staging,
  homologação, QA, pré-produção e afins entram na mesma regra.

## Condensed memory

- Só escrever na condensed memory (`condensed memory/projects/` e
  `condensed memory/features/`) quando a tarefa estiver **concluída e mergeada**.
- Card em `1.not_started/`, `2.in_progress/` ou `3.in_review/` **não** gera
  escrita na memória. O gatilho é o `/complete-card`, que roda depois do merge.
- Enquanto o card está em andamento, o conhecimento fica no próprio card
  ("Discussões", "Descrição Técnica", "Conhecimento Adquirido"). A consolidação
  é o passo final, não um registro incremental.

## Leitura de arquivos

- Se o conteúdo de um arquivo já foi lido nesta sessão e está na memória, **não
  ler de novo**. Vale para `.md` em geral: guidelines, condensed memory, comandos,
  documentação.
- **Exceção — cards em andamento:** cards em `1.not_started/`, `2.in_progress/`
  ou `3.in_review/` mudam durante a sessão (tarefas marcadas, discussões
  adicionadas, frontmatter atualizado). Reler o card ativo antes de editá-lo é
  correto e necessário.
- Cards em `4.done/` e `5.archived/` são estáveis: se já foram lidos, não reler.
- Se houver motivo para acreditar que o arquivo mudou (o usuário editou, outro
  processo escreveu, a leitura anterior foi truncada ou resumida), reler é
  legítimo — mas dizer o motivo.
- Antes de reler, considerar `grep_search` para confirmar um trecho específico em
  vez de carregar o arquivo inteiro de novo.

### Carregamento de `guidelines/` — profundidade

- Ler **todos os arquivos dentro de `guidelines/`, recursivamente**, incluindo
  subpastas. A pasta inteira é fonte de diretrizes.
- Ao listar a pasta, **reportar** quais arquivos foram lidos (e de quais
  subpastas), para que o conjunto carregado seja visível.

### Carregamento de contexto do card

Ao carregar contexto de um card:

- Carregar a memória de projeto pelo `condensed_memory_path` de `.agent_obsidian`;
  se não estiver disponível, derivar
  `$OBSIDIAN_VAULT_PATH/condensed memory/projects/{projeto}.md`, normalizando o
  nome do projeto para lowercase e substituindo hífens por underscores.
- Derivar a memória de feature do campo `feature:` usando
  `get_feature_memory_path()`. Carregá-la somente se o campo e o arquivo
  existirem; caso contrário, seguir apenas com a memória de projeto.
- Se uma memória já foi lida nesta sessão e não mudou, não relê-la.
- Reportar quais arquivos de memória foram carregados.

## Honestidade técnica

- Marcar explicitamente como não verificado o que não foi executado ou lido.
  Não descrever como "funcionando" o que não foi rodado.
- Não inventar caminho de arquivo, número de linha, nome de método ou link de PR.
  Se não foi verificado, dizer que não foi.
- Ao registrar em card, separar o que foi observado do que é hipótese.
- Resultado de teste só é reportado depois de executar **e** conferir o
  resultado: exit code (`$LASTEXITCODE`, `PIPESTATUS`, `%ERRORLEVEL%`) e linha de
  resumo. Em comando com pipe, o exit code é o do último comando do pipe.
- Falha de teste e erro de execução não são omitidos nem ignorados: dizer o que
  falhou, em qual arquivo e o que foi feito a respeito.
- Tarefa só é marcada como concluída (`- [x]`) com o resultado verificado.

## Escopo

- Fazer o que foi pedido; não expandir o escopo por conta própria.
  Melhoria adicional identificada vira sugestão ou card novo, não commit silencioso.
- Não criar arquivo (README, doc, script auxiliar) que não foi pedido.
  - **Exceção — artefato temporário de execução:** arquivo criado para viabilizar
    um comando e descartado em seguida não é "arquivo novo" no sentido desta
    regra. Mas **prefira não criar**: se o comando aceita o conteúdo inline
    (heredoc), use inline. Se for inevitável, criar fora do repositório (nunca na
    raiz do projeto) e apagar ao final.
- Arquivo fora do escopo da tarefa só é alterado com necessidade justificada ao
  usuário antes da alteração.
- Regras de código (padrões existentes, refatoração e dependências) ficam em
  `guidelines/code guidelines.md`.
