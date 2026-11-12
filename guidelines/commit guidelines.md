# Commit guidelines

O histórico de commits é a explicação de como a solução evoluiu: cada commit
carrega uma responsabilidade e uma mensagem que comunica a intenção da mudança.
Quem lê o histórico — três meses depois, sem o card ao lado — entende o caminho
sem abrir o diff.

Quando commitar, o que nunca entra no commit e quando o histórico pode ser
reescrito são regras de conduta: `guidelines/conduct.md`.

## Unidade de commit

Um commit, uma responsabilidade. A unidade é lógica, não a tarefa do card.

- Tarefa do card é unidade de **trabalho**; commit é unidade de **mudança**. Uma
  tarefa rende mais de um commit quando atravessa responsabilidades distintas (a
  refatoração que prepara e a feature que usa); duas tarefas ficam no mesmo
  commit quando formam uma mudança só.
- Teste do desempate: o commit se reverte sozinho, sem arrastar o outro assunto?
  Se não, são dois assuntos. Se o sujeito precisa de "e" para descrever as duas
  metades, são dois commits.
- Divisão que deixa um commit intermediário quebrado não é divisão: agrupe até o
  estado ficar coerente (compila, teste passa).
- A sequência prepara a etapa seguinte: o commit anterior deixa o repositório
  pronto para receber o próximo. Mover a responsabilidade primeiro e trocar o
  ponto de chamada depois é uma ordem que se lê como narrativa.
- Commit de valor histórico nulo não é criado: `wip`, typo no próprio trabalho
  ainda não commitado, formatação de arquivo que o mesmo commit já toca, mensagem
  genérica. O que ainda não é um commit vira parte do próximo.

**Rationale:** "commit por tarefa" e "uma responsabilidade por commit" são
unidades diferentes, e a conversão entre elas é decisão de quem escreve o commit.
Sem critério escrito, a saída é um commit por checkbox — que não conta história —
ou nenhum.

## Mensagem

Forma: `{tipo}: {sujeito imperativo}` e, quando necessário, corpo com o porquê.

- `tipo` na lista: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`.
- `sujeito` em pt-BR, no presente, dizendo a intenção e não o arquivo tocado:
  `feat: introduz análise de fraude antes da execução da transferência`.
- `escopo` opcional — `feat(parser): ...` — quando o sujeito sozinho não localiza
  a mudança num repositório com mais de um subsistema.
- `corpo` explica o porquê, o trade-off ou o efeito que não cabe no sujeito. Se o
  sujeito já diz tudo, não há corpo.
- Português é o idioma do fluxo inteiro — card, discussões, descrição de PR e
  mensagem de commit.

**Decisão:** o prefixo continua e o imperativo entra no sujeito, em vez de a
convenção ser abandonada. Prefixo e sujeito imperativo são ortogonais: o que muda
é o sujeito deixar de ser substantivo ("implementação de X") e passar a dizer o
que o commit faz. Abandonar o prefixo romperia com o histórico existente e
perderia o tipo da mudança, que é o que permite separar `fix` de `feat` no log.

**Rationale:** a exigência de conventional commits existia em três comandos e no
`CLAUDE.md` sem justificativa registrada; a diretriz nova dialoga com ela em vez
de ignorá-la.

## Quando a narrativa é construída

Durante o `/work-on-card`, a cada unidade que fecha: é quando a mudança está
inteira na cabeça e o diff ainda está pequeno o suficiente para ser dividido sem
esforço.

O `/review-card` **verifica** o resultado; não reorganiza por conta própria.
Reorganização (rebase interativo, amend, squash) é operação destrutiva e segue
`guidelines/conduct.md`. Quando a verificação reprova, o comando aponta os
commits e **propõe** a reorganização: executar depende de autorização explícita.

## Verificação

O critério é a leitura: `git log <base>..HEAD` precisa ser compreensível para
quem acabou de entrar no repositório e não conhece o card. O histórico responde o
que mudou e por quê, na ordem em que a solução evoluiu, sem depender do diff.

O `/review-card` executa essa leitura. Histórico que só faz sentido com o card ao
lado reprova.

## Exemplos

**Mudanças não relacionadas no mesmo diff.** A tarefa pediu dois assuntos e a
working tree tem os dois:

```
feat: extrai a validação de limite para o serviço de transferência
feat: bloqueia transferência acima do limite diário
```

O primeiro move a responsabilidade sem mudar comportamento; o segundo usa o novo
ponto. Num commit só, reverter o bloqueio arrastaria a extração junto.

**Commit de valor histórico nulo.** Durante a tarefa o arquivo foi salvo com um
typo e corrigido minutos depois, sem nada commitado no meio. Não nasce um
`fix: corrige typo`: o commit da unidade sai já correto, e o typo nunca chega ao
histórico.
