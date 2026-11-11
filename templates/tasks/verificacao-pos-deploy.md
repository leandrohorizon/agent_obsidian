---
card: "{nome-do-card}"
repo: "{repositório do card}"
ambiente: "{onde as consultas rodam — local, staging, homologação}"
memoria_consultas: "{caminho da memória que registra as consultas, ex: condensed memory/features/deploy-n8n.md}"
vencimento: "{YYYY-MM-DD}"
status: pendente
criado: "{YYYY-MM-DD}"
---

### Origem

> Card de origem, o que o deploy precisava provar e o ponteiro para a memória que guarda as consultas. Uma entrada curta: o detalhe fica no card e na memória, não é reescrito aqui.

### Consultas

> Uma linha por sinal a observar. A forma de executar mora na memória apontada em `memoria_consultas`; aqui fica só onde olhar, o que se espera e o que conta como falha.

| Onde olhar | O que se espera ver | Critério de falha |
| ---------- | ------------------- | ----------------- |
| {log, query, painel ou endpoint, com a fonte} | {valor, faixa, contagem ou ausência de erro} | {o que significa "não funcionou"} |

### Resultado

> Preenchido pelo `/check-tasks`. Registrar o que foi observado, onde e quando. Falha sugere card de correção e não bloqueia nada.
