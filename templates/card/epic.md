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

> **Plano lido pelo `/orchestrate-cards`. Esta seção é a fonte única das ondas e dos PRs do épico.**
>
> **Resumo:** {N} cards · {X} ondas · {Y} PRs — preenchido no refinamento; é conferência humana, o parser lê os blocos abaixo.
>
> - A região vai de `## Ondas` até o próximo heading `## `. Headings dentro de bloco cercado por ` ``` ` e linhas de blockquote (`>`) são ignorados.
> - Cada `### Onda {N}` abre uma onda. A **ordem é a ordem de aparição**; número fora de sequência é divergência e aborta a execução.
> - Dentro da onda, cada `**PR {nome}**` abre um grupo: os cards abaixo dele viram **um PR só**, executados em sequência no mesmo worktree.
> - Card solto, sem bloco `**PR …**` acima, é um grupo de um card — um PR por card. É o fallback.
> - Onda 0 é implícita: o próprio épico. Não a escreva.
> - Visões parciais dos mesmos cards ("trilhos") ficam **fora** desta região, em heading próprio, para não serem lidas como onda.
> - Só entra card que existe em `1.not_started`, `2.in_progress`, `3.in_review` ou `4.done`, com `work_type: implementation` e listado em `dependents` deste épico.
> - **Nenhum card em dois grupos.** Dois cards que tocam o mesmo arquivo não podem ficar em grupos diferentes da mesma onda (`guidelines/IA best practices.md` §9): ou estão no mesmo `**PR …**`, ou em ondas diferentes.
> - O `dependents` do épico é a mão autoritativa: todo card listado nele precisa aparecer no plano, e todo card do plano precisa estar nele. Divergência aborta a execução.
> - `depends_on` do filho apontando para o épico é opcional — quando existe, é parentesco, não dependência de execução.
> - Seção ausente, vazia ou sem nenhum card → a ordem é derivada dos `depends_on` dos filhos, um PR por card.
>
> Exemplo do formato (ilustrativo, dentro do blockquote de propósito):
>
> ```
> ### Onda 1
> **PR base**
> - [[{card-filho-1}]]
> - [[{card-filho-2}]]
>
> **PR autonomo**
> - [[{card-filho-3}]]
>
> ### Onda 2
> - [[{card-filho-4}]]
> ```
>
> No exemplo: 4 cards, 2 ondas, 3 PRs — `{card-filho-4}` não tem bloco `**PR …**` e por isso é um PR próprio.

---

### Tarefas

> Coloque todos os TODOs aqui. Serve como um lembrete do que precisa ser desenvolvido, validado ou revisado.

- [ ] Criar o card filho "..." (`work_type: implementation`, `feature`, `depends_on` a este épico) descrevendo: {escopo, entregável e o que fica fora}

- [ ] Registrar `depends_on`/`dependents` no frontmatter de cada filho e apontar este épico como pai

- [ ] Fechar o plano em `## Ondas`: ondas, grupos de PR acordados com o usuário, resumo `{N} cards · {X} ondas · {Y} PRs` e ausência de card em dois grupos


---

### Discussões

> Registre decisões, dúvidas, alternativas avaliadas, alinhamentos realizados e observações relevantes que surgiram durante a análise ou desenvolvimento.



---
