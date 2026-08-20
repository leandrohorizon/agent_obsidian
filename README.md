# Agent Obsidian

> Sistema de gerenciamento de tarefas com IA integrando Obsidian + Claude Code para fluxo de trabalho inteligente com retenção de conhecimento.

## O que é isso?

**Agent Obsidian** transforma seu vault Obsidian em um sistema inteligente de gerenciamento de tarefas onde o Claude Code:
- 🎯 Gerencia um board Kanban através de slash commands
- 🧠 Aprende com tarefas completadas e aplica conhecimento em trabalhos futuros
- 🤖 Executa tarefas seguindo suas code guidelines automaticamente
- 📝 Rastreia trabalho em múltiplos projetos com zero configuração
- 🔄 Gerencia o ciclo completo: start → work → review → complete → consolidate

## Exemplo Rápido

```bash
# Começar a trabalhar em um card
cd ~/meu-projeto
/start-card "implementar autenticação de usuário"
# ✅ Card movido para in_progress
# ✅ Branch git criada: feature/implementar-autenticacao-de-usuario
# ✅ Estado rastreado em .agent_obsidian

# Trabalhar no card (Claude carrega contexto e executa tarefas)
/work-on-card
# ✅ Carrega code guidelines
# ✅ Carrega conhecimento acumulado de tarefas anteriores
# ✅ Executa tarefas pendentes
# ✅ Documenta decisões e aprendizados

# Criar PR quando pronto
/review-card
# ✅ Valida conclusão
# ✅ Cria descrição inteligente do PR
# ✅ Move para in_review

# Completar após merge
/complete-card
# ✅ Move para done
# ✅ Consolida conhecimento para tarefas futuras
```

## Funcionalidades Principais

### 🎯 Kanban Board as Code
Suas tarefas são arquivos markdown fluindo através de estados:
```
1.not_started → 2.in_progress → 3.in_review → 4.done
```

### 🧠 Consolidação de Conhecimento
Cada tarefa completada contribui para uma **condensed memory** que o Claude carrega automaticamente em trabalhos futuros:
- Decisões arquiteturais com justificativas
- Padrões e convenções
- Lições aprendidas
- Edge cases e gotchas

### 🔄 Suporte Multi-Projetos
Um vault centralizado, estado independente por projeto:
```
~/workspace/
├── obsidian/leanddro/          # Vault centralizado (este repo)
│   ├── board/                   # Todos os cards
│   └── condensed memory/        # Conhecimento por projeto
│
├── projeto-A/
│   └── .agent_obsidian         # Estado do projeto A
│
└── projeto-B/
    └── .agent_obsidian         # Estado do projeto B
```

### 🤖 IA Que Não Esquece
Diferente de conversas tradicionais do Claude que perdem contexto, o Agent Obsidian:
- Salva aprendizados de cada tarefa em formato estruturado
- Carrega automaticamente conhecimento relevante ao trabalhar em novas tarefas
- Constrói expertise específica do projeto ao longo do tempo
- Documenta o "porquê" das decisões, não apenas o "o quê"

### 📋 Refinamento Inteligente de Cards
Cards começam vagos? Use `/refine-card` para:
- Analisar código real (não suposições)
- Gerar perguntas técnicas específicas
- Transformar tarefas genéricas em passos acionáveis
- Validar premissas contra implementação real

## Instalação

### Pré-requisitos
- [Claude Code](https://claude.ai/claude-code)
- Git
- [GitHub CLI](https://cli.github.com/) (opcional, para criação automática de PRs)

### Setup (2 minutos)

1. **Definir variável de ambiente:**
   ```bash
   # Adicione ao ~/.zshrc ou ~/.bashrc
   export OBSIDIAN_VAULT_PATH="/caminho/para/este/repo"
   source ~/.zshrc
   ```

2. **Sincronizar comandos:**
   ```bash
   ./sync-commands.sh
   ```
   Isso instala os slash commands globalmente no Claude Code.

3. **Verificar:**
   ```bash
   cd ~/qualquer-projeto
   claude
   # Depois no Claude:
   /board-status
   ```

Pronto! Os comandos criam arquivos de estado automaticamente conforme necessário.

## Comandos Disponíveis

| Comando | Propósito | Exemplo |
|---------|-----------|---------|
| `/board-status` | Mostra estado do board Kanban | `/board-status` |
| `/start-card <nome>` | Inicia trabalho, cria branch | `/start-card "adicionar feature"` |
| `/work-on-card [nome]` | Executa tarefas com contexto completo | `/work-on-card` |
| `/refine-card <nome>` | Clarifica cards vagos antes de iniciar | `/refine-card "adicionar feature"` |
| `/update-card <nome>` | Adiciona notas de discussão/decisão | `/update-card "adicionar feature" "Decidimos usar JWT"` |
| `/review-card [nome]` | Cria PR, move para review | `/review-card` |
| `/complete-card [nome]` | Finaliza, consolida conhecimento | `/complete-card` |
| `/load-context [nome]` | Carrega contexto completo (read-only) | `/load-context` |
| `/condense-memory [nome]` | Consolida conhecimento do card | `/condense-memory` |

**Nota:** Comandos com `[nome]` (opcional) usam o card ativo do `.agent_obsidian` se omitido.

## Exemplo de Workflow

### Cenário: Construindo um app calculadora

```bash
# No diretório do projeto
cd ~/projeto-calculadora

# Iniciar primeira feature
/start-card "operações básicas"
# Cria: board/2.in_progress/operações básicas.md
# Cria: .agent_obsidian (rastreia card atual)
# Cria: branch feature/operacoes-basicas

# Claude trabalha nas tarefas
/work-on-card
# Carrega: code guidelines.md
# Carrega: condensed memory/calculadora/condensed memory.md (vazio na primeira vez)
# Executa tarefas, escreve código seguindo guidelines
# Documenta decisões e aprendizados no card

# Pronto para review
/review-card
# Cria commit, faz push da branch
# Gera descrição do PR a partir de commits + contexto do card
# Move para: board/3.in_review/

# Depois do merge do PR
/complete-card
# Move para: board/4.done/
# Extrai conhecimento para: condensed memory/calculadora/condensed memory.md
# Limpa current card no .agent_obsidian

# Iniciar próxima feature
/start-card "modo científico"

# Agora Claude carrega conhecimento do card anterior!
/work-on-card
# Carrega condensed memory com aprendizados sobre:
#   - Como você estrutura operações da calculadora
#   - Seus padrões preferidos
#   - Edge cases descobertos nas operações básicas
#   - Decisões arquiteturais e por que foram tomadas
```

## Estrutura do Card

Cada card segue um template:

```markdown
---
repo: git@github.com:user/project.git
branch: feature/card-name
status: In Progress
started: 2026-01-15
---

## Descrição
O que precisa ser feito e por quê

## Dependências
- [[outro-card]] - o que ele fornece
- APIs externas, bibliotecas

## Tarefas
- [ ] Tarefa específica 1
- [ ] Tarefa específica 2
- [ ] Escrever testes

## Discussões
#### 2026-01-15 14:30
Decisão tomada: Usar X porque Y

## Descrição Técnica do que Foi Feito
Detalhes da implementação

## Conhecimento Adquirido pela IA
Regras de negócio, padrões, gotchas
(Isso alimenta a condensed memory)
```

## Formato da Condensed Memory

O conhecimento é estruturado para fácil consumo pela IA:

```markdown
# Condensed Memory - calculator

> Última atualização: 2026-01-15
> Cards processados: 3
> Origem: [basic-operations, scientific-mode, history-feature]

## 🏗️ Arquitetura

### Operation Pipeline
Operations flow through: validate → calculate → format
- Each operation is a pure function
- State managed in CalculatorState class

**Decisão:** Pure functions for testability and reliability

## 📋 Padrões e Convenções

### Error Handling
- Throw CalculatorError for invalid operations
- Division by zero returns Infinity (IEEE 754 standard)

**Rationale:** Consistency with JavaScript Math behavior

## 💡 Aprendizados Chave

- Floating point precision: Use decimal.js for financial calculations
- Edge case: 0^0 returns 1 (mathematical convention)
- User testing revealed need for operation history
```

## Por Que Agent Obsidian?

### Abordagem Tradicional ❌
- Tarefas espalhadas em várias ferramentas
- Contexto perdido entre sessões
- IA repete os mesmos erros
- Sem acumulação de aprendizado
- Transferência manual de conhecimento

### Agent Obsidian ✅
- Fonte única da verdade (vault Obsidian)
- Contexto persistente via condensed memory
- IA melhora a cada tarefa
- Consolidação automática de conhecimento
- Workflow multi-projetos sem fricção

## Funcionalidades Avançadas

### Gerenciamento Automático de Estado
O arquivo `.agent_obsidian` rastreia seu card atual:
```json
{
  "version": "1.0",
  "vault_path": "/caminho/para/vault",
  "current_card": {
    "name": "nome-da-feature",
    "path": "/caminho/absoluto/para/card.md"
  }
}
```

Benefícios:
- Comandos funcionam sem argumentos
- Acesso direto por path (sem buscas de arquivo)
- Auto-criado e mantido
- Adicionado automaticamente ao .gitignore

### Descrições Inteligentes de PR
`/review-card` cria descrições de PR ao:
1. Analisar histórico de commits desde a branch base
2. Ler contexto e tarefas do card
3. Detectar e preencher templates de PR
4. Agrupar mudanças relacionadas
5. Destacar impacto técnico e de negócio
6. Sugerir passos de teste

### Refinamento de Cards Antes do Trabalho
Use `/refine-card` em cards vagos para:
- Carregar implementação real do código (sem suposições)
- Gerar perguntas técnicas específicas
- Transformar "Tarefa 1, Tarefa 2" em ações concretas
- Validar integração com sistemas existentes
- Executar múltiplas vezes para análise mais profunda

## Documentação

- **[SETUP.md](SETUP.md)** - Instalação e configuração detalhada
- **[CLAUDE.md](CLAUDE.md)** - Arquitetura completa e referência de comandos
- **[code guidelines.md](code%20guidelines.md)** - Padrões de desenvolvimento
- **[templates/](templates/)** - Template de card

## Estrutura do Projeto

```
.
├── board/                      # Estados do Kanban
│   ├── 1.not_started/
│   ├── 2.in_progress/
│   ├── 3.in_review/
│   ├── 4.done/
│   └── 5.archived/
├── commands/                   # Definições dos slash commands
├── condensed memory/           # Bases de conhecimento por projeto
├── templates/                  # Template de card
├── code guidelines.md          # Padrões de desenvolvimento
├── sync-commands.sh            # Instala comandos no Claude
├── SETUP.md                    # Guia de setup detalhado
├── CLAUDE.md                   # Documentação da arquitetura
└── README.md                   # Este arquivo
```

## Contribuindo

Este é um sistema pessoal de gerenciamento de tarefas, mas sinta-se livre para fazer fork e adaptar às suas necessidades.

## Filosofia

> "O melhor sistema de produtividade é aquele que captura conhecimento e o torna reutilizável."

O Agent Obsidian é construído sobre estes princípios:
- **Zero Configuration:** Auto-cria o que precisa
- **Persistent Memory:** Nunca esqueça o que aprendeu
- **AI Collaboration:** Deixe o Claude lidar com tarefas rotineiras enquanto você foca nas decisões
- **Knowledge Compounds:** Cada tarefa torna a próxima mais fácil
- **Simplicity:** Arquivos markdown + slash commands + IA = workflow poderoso

## Licença

MIT

---

**Construído com:** [Obsidian](https://obsidian.md/) + [Claude Code](https://claude.ai/claude-code)
