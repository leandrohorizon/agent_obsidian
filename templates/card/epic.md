---
repo:
branch:
work_type: epic
status:
  - Not Started
feature:
created:
started:
reviewed:
completed:
depends_on:
dependents:
---

### Descrição

> Explique de forma simples e objetiva o que é a tarefa, problema ou funcionalidade. Este campo deve fornecer contexto suficiente para qualquer pessoa entender rapidamente o propósito do card.

**Este card é um épico.** Ele não implementa código: fixa o escopo, cria os cards filhos e mantém a ordem em que eles devem ser executados. Quem executa o trabalho são os filhos, um por vez dentro de cada onda. `repo:` e `branch:` ficam vazios — o épico não altera repositório nenhum.



---

## Ondas

> **Formato lido pelo `/orchestrate-cards`. Esta seção é a fonte única da ordem de execução do épico.**
>
> - A região vai de `## Ondas` até o próximo heading `## `.
> - Cada `### Onda {N}` abre uma onda. A **ordem é a ordem de aparição**; o número é rótulo — número fora de sequência é divergência e aborta a execução.
> - Cada card entra como um wikilink por linha (`- [[card]]`), sem texto solto.
> - Onda 0 é implícita: o próprio épico. Não a escreva.
> - Visões parciais dos mesmos cards ("trilhos") ficam **fora** desta região, em heading próprio, para não serem lidas como onda.
> - Só entra card que existe em `1.not_started`, `2.in_progress`, `3.in_review` ou `4.done`, com `work_type: implementation` e este épico em `depends_on`.
> - Todo card que declara este épico em `dependents` precisa aparecer em alguma onda, e vice-versa: divergência entre as duas listas aborta a execução.
> - Seção ausente, vazia ou sem nenhum card → a ordem é derivada dos `depends_on` dos filhos.
>
> Exemplo de onda preenchida (ilustrativo, dentro do blockquote de propósito):
>
> ```
> ### Onda 1
> - [[{card-filho-1}]]
> - [[{card-filho-2}]]
>
> ### Onda 2
> - [[{card-filho-3}]]
> ```

---

### Tarefas

> Coloque todos os TODOs aqui. Serve como um lembrete do que precisa ser desenvolvido, validado ou revisado.

- [ ] Criar o card filho "..." (`work_type: implementation`, `feature`, `depends_on` a este épico) descrevendo: {escopo, entregável e o que fica fora}

- [ ] Registrar `depends_on`/`dependents` no frontmatter de cada filho e apontar este épico como pai

- [ ] Preencher `## Ondas` com os filhos na ordem de execução e confirmar que ela não contradiz os `depends_on` deles


---

### Discussões

> Registre decisões, dúvidas, alternativas avaliadas, alinhamentos realizados e observações relevantes que surgiram durante a análise ou desenvolvimento.



---
