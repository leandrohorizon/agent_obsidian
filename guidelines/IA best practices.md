# Boas práticas de uso de IA por agentes

## 1. Gerenciamento de contexto

- Preserve o contexto principal, mantendo-o focado no objetivo atual e nas decisões relevantes.
    
- Delegue tarefas exploratórias, como `@Busca na web`, pesquisas amplas no código, análise de logs e comparação de alternativas, a subagentes sempre que possível.
    
- Retorne ao contexto principal apenas as conclusões relevantes, evidências, referências e próximos passos. Evite repassar todo o histórico da investigação.
    
- Não carregue arquivos, logs ou documentação extensos sem necessidade. Consulte apenas os trechos relevantes para a tarefa.
    

## 2. Uso eficiente de ferramentas

- Prefira buscas específicas a buscas amplas.
    
- Limite a quantidade de resultados retornados e aprofunde a investigação progressivamente.
    
- Evite repetir chamadas de ferramentas quando os resultados anteriores ainda forem válidos.
    
- Não execute pesquisas ou análises que não contribuam diretamente para o objetivo atual.
    

## 3. Delegação de tarefas

- Delegue atividades independentes e bem delimitadas a agentes especializados.
    
- Forneça a cada agente um objetivo claro, as restrições necessárias e o formato esperado da resposta.
    
- Evite delegar tarefas simples quando o custo da coordenação for maior que o benefício.
    
- Ao receber o resultado, valide as conclusões antes de utilizá-las como fatos.
    

## 4. Preservação de informações importantes

- Não descarte requisitos, restrições, decisões, evidências ou detalhes técnicos necessários à execução.
    
- Ao resumir uma investigação, preserve referências a arquivos, linhas de código, comandos, resultados de testes e fontes relevantes.
    
- Registre decisões duradouras e descobertas importantes em documentação apropriada, em vez de depender exclusivamente do histórico da conversa.
    

## 5. Critério geral

Priorize sempre o menor contexto suficiente para executar a tarefa corretamente. Reduza ruído e redundância sem sacrificar precisão, rastreabilidade ou informações necessárias para a tomada de decisão.

## 6. Leitura enxuta de cards

Card é artefato de execução e cresce durante a vida dele: `### Discussões` e `### Descrição Técnica do que Foi Feito` acumulam entradas a cada sessão. Ler o arquivo inteiro para saber qual é a próxima ação é o maior custo de contexto do fluxo.

**Regra:** leia o card por seção, não por arquivo. Comece pelo mapa de headings e leia só as faixas que mudam a próxima ação.

| Seção | Visão padrão |
|---|---|
| Frontmatter YAML | incluir |
| `### Descrição` | incluir |
| `### Dependências` / `### Dependentes` | incluir |
| `### Tarefas` — pendentes (`- [ ]`) | incluir |
| `### Tarefas` — concluídas (`- [x]`) | omitir |
| `### Discussões` | omitir por padrão; leitura opcional sob demanda |
| `### Descrição Técnica do que Foi Feito` | incluir — fonte principal para a IA |
| `### Conhecimento Adquirido pela IA` | incluir |
| `### Pull Requests` | omitir |

**Procedimento:**

1. Mapear os headings com `grep -n '^#{2,3} '` — barato e suficiente para achar as faixas.
2. Ler frontmatter, `### Descrição` e `### Dependências`/`### Dependentes`.
3. Ler `### Tarefas` e filtrar os pendentes **dentro da faixa**, não no arquivo todo.
4. Ler `### Descrição Técnica do que Foi Feito` e `### Conhecimento Adquirido pela IA`.

**Discussões é leitura opcional.** O humano lê `### Discussões`; a IA trabalha a partir de `### Descrição Técnica do que Foi Feito`. Se o trabalho travar, ler `### Discussões` é permitido — não é o padrão.

**Exceção — `/condense-memory`:** lê o card completo, incluindo `### Discussões`. Essa seção é a matéria-prima dele; sem a exceção, decisão que nunca foi promovida para `### Descrição Técnica` se perde em silêncio e de forma irreversível, porque o card é marcado como consolidado.

**Robustez do recorte:**

- Delimite a seção por **qualquer** heading, não só pelos canônicos — cards reais têm `## Objetivo`, `## Contexto`, `## Rascunho` no meio.
- Ignore headings dentro de blocos cercados por ` ``` `. Um card do board contém `## Segredos e credenciais` dentro de um bloco ` ```markdown `; um `grep` ingênuo acha quatro seções que não existem.
- `### Dependentes` é opcional — 8 dos 24 cards do board não têm a seção.
- Ao omitir tarefas concluídas, respeite a indentação: `  - [x]` aninhado sob um `- [x]` pai não pode ser removido sozinho, senão o item pai fica órfão.
- Nunca escreva a visão filtrada no arquivo original. O filtro é decisão de leitura, não transformação.
- Se nenhuma seção canônica for encontrada, leia o card completo e reporte — degradar para o arquivo inteiro é melhor que trabalhar com um recorte vazio.