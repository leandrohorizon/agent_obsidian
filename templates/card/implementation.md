---
repo:
branch:
work_type: implementation
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



---

### Tarefas

> Coloque todos os TODOs aqui. Serve como um lembrete do que precisa ser desenvolvido, validado ou revisado.

- [ ] Tarefa 1

- [ ] Tarefa 2

- [ ] Tarefa 3


---

### Verificação Pós-Deploy

> Só preencha quando os **dois testes** passarem: o projeto tem deploy **e** a mudança é observável em execução (log, endpoint, banco, agendamento, consumo de recurso). Refactor sem mudança de comportamento, documentação e typo não passam no segundo teste. Quando um dos dois falhar, deixe a seção vazia — o `/complete-card` a ignora e não cria etapa nova.
>
> A **forma de consultar** não se repete aqui: aponte para a memória que já registra as consultas (ex: `condensed memory/features/deploy-n8n.md`, seções "Validação de memória pós-deploy (três sinais)" e "Retenção de imagens e rollback"). Aqui fica só onde olhar, o esperado, a janela e o que conta como falha.
>
> A seção fica **fora** de `### Tarefas` de propósito: o `/complete-card` exige toda tarefa `- [x]`, e verificação pós-deploy pode falhar sem que o card deixe de estar concluído. Falha **sugere** card de correção, **não bloqueia** a conclusão e **entra** em "Conhecimento Adquirido pela IA".
>
> **Nunca entra aqui:** limpeza de flag ou de código de compatibilidade (é trabalho de implementação do card original), execução de suíte de testes (valida o código, não o ambiente), rodar o deploy, e qualquer consulta sem fonte verificável no card, no código ou na memória.

| Onde olhar | O que se espera ver | Janela | Critério de falha |
| ---------- | ------------------- | ------ | ----------------- |
| {log, query, painel ou endpoint, com a fonte} | {valor, faixa, contagem ou ausência de erro} | {imediato após o deploy ou até as próximas Xh} | {o que significa "não funcionou" e a ação: rollback, card de correção} |

> **Desfecho por item**, registrado na própria linha: `verificado`, `falhou` ou `pendente (arquivo em tasks/)`. Item com prazo vira arquivo em `tasks/` (formato em `templates/tasks/verificacao-pos-deploy.md`) e é executado depois pelo `/check-tasks`.


---

### Discussões

> Registre decisões, dúvidas, alternativas avaliadas, alinhamentos realizados e observações relevantes que surgiram durante a análise ou desenvolvimento.



---

### Descrição Técnica do que Foi Feito

> Detalhe as alterações realizadas em nível técnico. Inclua arquivos modificados, componentes afetados, regras implementadas, mudanças de arquitetura, decisões técnicas e qualquer informação útil para manutenção futura.



---
### Conhecimento Adquirido pela IA

> Registre aprendizados, regras de negócio, padrões identificados, decisões recorrentes e informações relevantes descobertas durante a execução da tarefa. Este campo serve para fornecer contexto futuro à IA e evitar que o mesmo conhecimento precise ser redescoberto em tarefas relacionadas.



---
