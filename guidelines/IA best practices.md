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