# Conduct

Regras de comportamento do agente. Diferente de `code guidelines.md`, que trata de
estilo de código, este arquivo trata do que o agente pode e não pode fazer.

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
  criado na sessão, `git reset --hard`, `git checkout` que descarta alteração não
  commitada, `DROP`, `TRUNCATE`, `DELETE` sem `WHERE` restritivo, `UPDATE` em massa,
  reset ou recriação de banco.
- Confirmar antes de rodar **migration ou tarefa de schema**: `db:migrate`,
  `db:rollback`, `db:schema:load`, `db:create`, `db:drop`, `db:reset`,
  `db:test:prepare` e equivalentes de outros stacks.
  **Inclusive em banco local, de teste ou em container Docker.**
- A regra não depende de o alvo parecer descartável. Julgar se um banco é
  descartável é justamente a avaliação que o agente pode errar — o mesmo comando
  num banco de desenvolvimento com dados reais é destrutivo e irreversível.
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
- **Nunca commitar o `.agent_obsidian`.** É arquivo de estado local da máquina:
  guarda `vault_path` absoluto, `current_card` e paths que só fazem sentido no
  ambiente de quem está trabalhando. Commitá-lo versiona configuração de máquina
  e faz o estado de um projeto vazar para outro clone.
  - A exceção de commit de `/work-on-card`, `/review-card` e `/orchestrate-cards`
    **não** cobre este arquivo — a exceção é sobre *quando* commitar, não sobre
    *o que* commitar.
  - Antes de commitar, conferir que ele não entrou no stage. Se entrou, remover
    do stage (`git restore --staged .agent_obsidian`) — não basta deixar de
    adicioná-lo.
  - Se ele já foi commitado antes, avisar o usuário em vez de reescrever
    histórico por conta própria.
  - Não é preciso mexer no `.gitignore` para isso: a regra é de comportamento do
    agente, não de configuração do repositório. O `.gitignore` de cada projeto
    fica como está.
- Não abrir, fechar nem fazer merge de PR sem pedido.

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
- Motivo: o erro em produção não é reversível como no local. Um `db:migrate`
  apontado para o alvo errado, ou um `console` que altera dado real, não tem
  desfazer — e a diferença entre os ambientes costuma estar só numa variável de
  ambiente que o agente não vê.

## Condensed memory

- Só escrever na condensed memory (`condensed memory/projects/` e
  `condensed memory/features/`) quando a tarefa estiver **concluída e mergeada**.
- Card em `1.not_started/`, `2.in_progress/` ou `3.in_review/` **não** gera
  escrita na memória. O gatilho é o `/complete-card`, que roda depois do merge.
- Enquanto o card está em andamento, o conhecimento fica no próprio card
  ("Discussões", "Descrição Técnica", "Conhecimento Adquirido"). A consolidação
  é o passo final, não um registro incremental.
- Motivo: a memória é lida como verdade estabelecida por todos os projetos. Se
  ela registra trabalho ainda em revisão, um plano que pode mudar passa a ser
  tratado como decisão tomada — e o custo de corrigir depois é maior que o de
  esperar o merge.

## Leitura de arquivos

- Se o conteúdo de um arquivo já foi lido nesta sessão e está na memória, **não
  ler de novo**. Vale para `.md` em geral: guidelines, condensed memory, comandos,
  documentação.
- Muitos comandos pedem a leitura de um arquivo que já foi carregado antes
  (`/work-on-card` depois de `/load-context`, `/refine-card` depois de
  `/work-on-card`, guidelines relidas a cada passo). Repetir a leitura não
  acrescenta informação e queima contexto.
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

- Ler **apenas os arquivos diretamente dentro de `guidelines/`** (um nível, sem
  recursão). Subpastas **não** são varridas automaticamente.
- Motivo: recursão silenciosa transforma a pasta em fonte de contexto de tamanho
  imprevisível. Um `guidelines/archive/` ou `guidelines/wip/` com material antigo
  passaria a ser carregado a cada comando sem ninguém perceber.
- Se uma subpasta precisar ser carregada, ela deve ser **promovida** — os arquivos
  vão para a raiz de `guidelines/`. Se o volume justificar subpasta, a decisão de
  carregá-la é explícita e entra no comando, não é comportamento implícito.
- Ao listar a pasta, se houver subpastas, **reportar** que foram ignoradas, para
  que a omissão seja visível e não vire surpresa.

## Honestidade técnica

- Marcar explicitamente como não verificado o que não foi executado ou lido.
  Não descrever como "funcionando" o que não foi rodado.
- Não inventar caminho de arquivo, número de linha, nome de método ou link de PR.
  Se não foi verificado, dizer que não foi.
- Ao registrar em card, separar o que foi observado do que é hipótese.

## Escopo

- Fazer o que foi pedido; não expandir o escopo por conta própria.
  Melhoria adicional identificada vira sugestão ou card novo, não commit silencioso.
- Não criar arquivo (README, doc, script auxiliar) que não foi pedido.
  - **Exceção — artefato temporário de execução:** arquivo criado para viabilizar
    um comando e descartado em seguida não é "arquivo novo" no sentido desta
    regra. Mas **prefira não criar**: se o comando aceita o conteúdo inline
    (heredoc), use inline. Se for inevitável, criar fora do repositório (nunca na
    raiz do projeto) e apagar ao final.
