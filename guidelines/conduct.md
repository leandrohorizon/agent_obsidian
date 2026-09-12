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
  **Exceção:** os comandos `/work-on-card` e `/review-card` são o pedido explícito
  de commit — o fluxo deles inclui commits incrementais e push da branch.
- Não abrir, fechar nem fazer merge de PR sem pedido.

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
