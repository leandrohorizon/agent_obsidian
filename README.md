# Agent Obsidian

> Sistema de gerenciamento de tarefas com IA integrando Obsidian + Claude Code para fluxo de trabalho inteligente com retenção de conhecimento.

## O que é isso?

**Agent Obsidian** transforma seu vault Obsidian em um sistema inteligente de gerenciamento de tarefas onde o Claude Code:
- 🎯 Gerencia um board Kanban através de slash commands
- 🧠 Aprende com tarefas completadas e aplica conhecimento em trabalhos futuros
- 🤖 Executa tarefas seguindo todos os arquivos de `guidelines/` automaticamente
- 📝 Rastreia trabalho em múltiplos projetos com zero configuração
- 🔄 Gerencia o ciclo completo: start → work → review → complete → consolidate

## Exemplo Rápido

```bash
# Começar a trabalhar em um card
cd ~/meu-projeto
/start-card "implementar autenticação de usuário"
# ✅ Pergunta se deve mudar para main/master antes de criar a branch
# ✅ Faz pull da branch base
# ✅ Card movido para in_progress
# ✅ Branch git criada: feature/implementar-autenticacao-de-usuario
# ✅ Estado rastreado em .agent_obsidian

# Trabalhar no card (Claude carrega contexto e executa tarefas)
/work-on-card
# ✅ Carrega todos os arquivos de guidelines/
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
# ✅ Verifica pós-deploy antes de concluir (quando o projeto tem deploy)
# ✅ Move para done
# ✅ Volta para a branch default e apaga a branch do card
# ✅ Consolida conhecimento para tarefas futuras

# Verificações com prazo, depois do deploy
/check-tasks
# ✅ Executa as verificações vencidas de tasks/
```

## Tipos de trabalho

Cards declaram `work_type: implementation`, `work_type: report`,
`work_type: investigation` ou `work_type: experiment`. Cards antigos sem o campo
continuam sendo implementações; um valor fora da lista interrompe o comando sem
efeito colateral. Cada tipo executa somente as ações da sua allowlist (ver
[guidelines/card work types.md](guidelines/card%20work%20types.md)). Relatórios,
investigações e experimentos são concluídos diretamente, sem branch, commit ou
PR. Relatórios e experimentos nunca consolidam memória; investigações só
consolidam após confirmação. Relatórios e investigações podem produzir
documentos no vault; um experimento cria ferramentas pequenas na pasta de
trabalho atual, sem executar comandos Git, e mantém seus arquivos até a limpeza
manual. Consulte
[guidelines/card work types.md](guidelines/card%20work%20types.md).

## Funcionalidades Principais

### 🎯 Kanban Board as Code
Suas tarefas são arquivos markdown fluindo através de estados:
```
0.backlog → 1.not_started → 2.in_progress → 3.in_review → 4.done
```

- **`0.backlog`** — ideias cruas, ainda não refinadas nem priorizadas
- **`1.not_started`** — cards refinados, prontos para iniciar

### 🧠 Consolidação de Conhecimento (dois eixos)
Implementações concluídas e mergeadas, além de investigações concluídas com confirmação, podem contribuir para uma **condensed memory** que o Claude carrega automaticamente em trabalhos futuros. Relatórios nunca são consolidados. O conhecimento é particionado em **dois eixos** com responsabilidades disjuntas:

- **Memória de projeto** (`condensed memory/projects/{projeto}.md`) — o que é estável e transversal ao repositório: arquitetura, convenções de código, ferramentas, setup, gotchas do stack. **Sem conhecimento de feature.**
- **Memória de feature** (`condensed memory/features/{feature}.md`) — regra de negócio, fluxo ponta a ponta, contratos entre serviços, decisões e edge cases daquela feature, **atravessando repositórios**.

O card declara sua feature no frontmatter (`feature: feature-x`) e o `/condense-memory` **roteia** cada pedaço de conhecimento para o eixo correto, em vez de despejar tudo num arquivo só. Isso resolve o caso em que uma feature (ex: feature-x) atravessa três repositórios — o conhecimento do fluxo completo fica num único arquivo de feature, acessível de qualquer projeto.

### 🔄 Suporte Multi-Projetos
Um vault centralizado, estado independente por projeto:
```
~/workspace/
├── obsidian/user/              # Vault centralizado (este repo)
│   ├── board/                   # Todos os cards
│   └── condensed memory/        # Conhecimento em dois eixos
│       ├── projects/            # Memória por repositório
│       └── features/            # Memória por feature (atravessa repos)
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

2. **Sincronizar comandos e skills:**
   ```bash
   ./sync-commands.sh
   ```
   No Windows, use `.\sync-commands.ps1`.
   Isso instala os slash commands no Claude Code e as skills do VS Code Copilot
   em `~/.copilot/skills/`. Para sincronizar somente as skills do VS Code, use
   `./sync-commands.sh vscode` ou `.\sync-commands.ps1 vscode`.

3. **Verificar:**
   ```bash
   cd ~/qualquer-projeto
   claude
   # Depois no Claude:
   /board-status
   ```

Pronto! Os comandos criam arquivos de estado automaticamente conforme necessário.

## Comandos Disponíveis

| Comando                   | Propósito                              | Exemplo                                                 |
| ------------------------- | -------------------------------------- | ------------------------------------------------------- |
| `/board-status`           | Mostra estado do board Kanban          | `/board-status`                                         |
| `/start-card <nome>`      | Inicia o card; branch só para implementação | `/start-card "adicionar feature"`                    |
| `/refine-card <nome>`     | Clarifica cards vagos antes de iniciar | `/refine-card "adicionar feature"`                      |
| `/work-on-card [nome]`    | Executa tarefas com contexto completo  | `/work-on-card`                                         |
| `/review-card [nome]`     | Cria PR para implementação              | `/review-card`                                          |
| `/complete-card [nome]`   | Finaliza; memória e verificação dependem do tipo | `/complete-card`                                 |
| `/review-pr <pr>`         | Revisa PR com guidelines e memórias    | `/review-pr 123`                                        |
| `/load-context [nome]`    | Carrega contexto do card ou do projeto; sincroniza branch só para implementação | `/load-context`                           |
| `/check-tasks`            | Executa verificações pós-deploy vencidas de `tasks/` | `/check-tasks`                            |
| `/orchestrate-cards [filtro]` | Orquestra implementações (PR em draft) | `/orchestrate-cards`                              |
| `/condense-memory [nome]` | Consolida memória conforme tipo         | `/condense-memory`                                      |

**Nota:** Comandos com `[nome]` (opcional) usam o card ativo do `.agent_obsidian` se omitido. Sem card ativo, o `/load-context` roda no modo de projeto: carrega guidelines, memória do projeto, estado do Git (só leitura) e os cards deste repositório em `2.in_progress`/`3.in_review`, sem pedir nome de card e sem alterar o `.agent_obsidian`.

## Exemplo de Workflow

### Cenário: Construindo um app calculadora

```bash
# No diretório do projeto
cd ~/projeto-calculadora

# Iniciar primeira feature
/start-card "operações básicas"
# Pergunta se deve mudar para main/master e faz pull da base
# Cria: board/2.in_progress/operações básicas.md
# Cria: .agent_obsidian (rastreia card atual)
# Cria: branch feature/operacoes-basicas

# Claude trabalha nas tarefas
/work-on-card
# Carrega: todos os arquivos de guidelines/
# Carrega: condensed memory/projects/calculadora.md (memória de projeto)
# Carrega: condensed memory/features/{feature}.md (memória da feature do card)
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
# Verifica pós-deploy: espera o deploy com janela limitada, roda o que é imediato e
# grava o que tem prazo em tasks/ (não conclui se o deploy não tiver rodado)
# Volta para a branch default e apaga a branch do card
# Roteia conhecimento para: condensed memory/projects/calculadora.md e condensed memory/features/{feature}.md
# Limpa current card no .agent_obsidian

# Verificações com prazo, dias depois
/check-tasks
# Lista todas as vencidas de tasks/ (data ≤ hoje) e executa as confirmadas
# Sugere card de correção quando uma falha

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
feature: feature-x
started: 2026-01-15
depends_on:
  - "[[outro-card]]"
dependents:
  - "[[card-que-depende-deste]]"
---

## Descrição
O que precisa ser feito e por quê

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

Dependências ficam no frontmatter (`depends_on` e `dependents`), não em seção:
o Obsidian as trata como links nativos e o plugin consegue lê-las sem parsear
markdown. Cards criados antes dessa convenção usam as seções `### Dependências` /
`### Dependentes` e continuam funcionando por fallback.

### Verificação pós-deploy

Card de implementação cujo projeto tem deploy **e** cuja mudança é observável em
execução ganha a seção `### Verificação Pós-Deploy`, **fora** de `### Tarefas`
(verificação pode falhar sem que o card deixe de estar concluído). Cada linha
declara onde olhar, o que se espera ver, a janela de observação e o critério de
falha — e aponta para a memória que já registra a consulta, em vez de duplicá-la.

A verificação tem dois tempos:

- **Imediata** (log depois do deploy, uptime, healthcheck, estado no banco) roda
  dentro do `/complete-card`, antes do `4.done`;
- **Com prazo** ("conferir daqui a 24h") vira arquivo em `tasks/`, na raiz do
  vault, e é executada depois pelo `/check-tasks`.

Falha não bloqueia a conclusão: sugere card de correção e entra na memória
consolidada. Se a janela de espera pelo deploy fechar sem deploy, o card **não**
é concluído e o comando pede para ser chamado de novo. `tasks/` fica fora do
board de propósito: é fila de verificação com data, não estado de card.

## Formato da Condensed Memory

> Contrato canônico: **[condensed memory/README.md](condensed%20memory/README.md)**.
> Ele define cabeçalhos, categorias, regras de forma e a fronteira entre as três
> memórias. O que segue é resumo; em caso de divergência, a especificação vence.

O conhecimento é estruturado em **dois eixos** para fácil consumo pela IA.

### Memória de Projeto (`condensed memory/projects/{projeto}.md`)

O que é estável e transversal ao repositório — arquitetura, convenções, ferramentas, setup. **Sem conhecimento de feature.**

```markdown
# Condensed Memory - project-example

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

### Memória de Feature (`condensed memory/features/{feature}.md`)

Regra de negócio, fluxo ponta a ponta, contratos entre serviços e edge cases daquela feature, **atravessando repositórios**. Categorias próprias (não reaproveita as de projeto).

```markdown
# Feature - feature-x

> Última atualização: 2026-01-15
> Repositórios envolvidos: [service-a, service-b, service-c]
> Cards de origem: [card-feature-x-a, card-feature-x-b, card-feature-x-c]

## 🔀 Fluxo Ponta a Ponta

### Enriquecimento de feature-x
- service-a envia dados de enriquecimento
- service-b repassa ao service-c
- service-c consome payload e para de consultar

## 🤝 Contratos entre Serviços

### campo_status
- service-a envia: {campos}
- service-c consome: {campos}

## 📐 Regras de Negócio

### Consulta de status
- Regra específica da feature

## ⚠️ Edge Cases

- Intermitência na consulta e como foi resolvida
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
  "version": "2.0",
  "vault_path": "/caminho/para/vault",
  "condensed_memory_path": "/caminho/para/vault/condensed memory/projects/meu-projeto.md",
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
- Nunca commitado — manter fora do versionamento é regra de conduta, não entrada no `.gitignore`
- `version: 2.0` indica o modelo de dois eixos; o path da memória de feature é derivado do campo `feature:` do card em tempo de carga (não fica no estado)

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

### Dashboard do Board (opcional)

O fluxo funciona inteiro por comandos — o dashboard é conveniência, não
dependência. Quem quiser ver o board dentro do Obsidian tem um plugin à parte,
em repositório próprio: **[dashboard-agent-obsidian](https://github.com/leandrohorizon/dashboard-agent-obsidian)**.

- Kanban cujas colunas são as pastas de estado, e lista com filtros por projeto,
  feature, texto e data de modificação
- Painel do `current_card` de cada projeto, lido do `.agent_obsidian` fora do vault
- Ações que apenas **copiam** o comando do fluxo — o plugin não executa nada
- Não move card entre pastas: quem muda estado são `/start-card`, `/review-card` e `/complete-card`

Instalação, configuração e desenvolvimento estão no README do repositório do
plugin. Este vault não versiona o plugin; `.obsidian/plugins/` guarda só o
artefato instalado, local como qualquer outro plugin do Obsidian.

## Documentação

- **[SETUP.md](SETUP.md)** - Instalação e configuração detalhada
- **[CLAUDE.md](CLAUDE.md)** - Arquitetura completa e referência de comandos
- **[guidelines/](guidelines/)** - Diretrizes do agente (todos os arquivos são carregados)
- **[templates/](templates/)** - Templates de implementação, relatório, investigação e experimento
- **[Dashboard do board](https://github.com/leandrohorizon/dashboard-agent-obsidian)** - Plugin de Obsidian, em repositório próprio

## Estrutura do Projeto

```
.
├── board/                      # Estados do Kanban
│   ├── 0.backlog/
│   ├── 1.not_started/
│   ├── 2.in_progress/
│   ├── 3.in_review/
│   ├── 4.done/
│   └── 5.archived/
├── tasks/                      # Verificações pós-deploy com prazo (fila, fora do board)
├── commands/                   # Definições dos slash commands
├── condensed memory/           # Bases de conhecimento em três eixos
│   ├── README.md               # Especificação do formato (versionada)
│   ├── projects/               # Memória por repositório (.gitkeep)
│   ├── features/               # Memória por feature (.gitkeep)
│   └── operational/            # Memória de execução (.gitkeep)
├── templates/                  # Templates de card (implementação, relatório, investigação, experimento) e de verificação em `tasks/`
├── guidelines/                 # Diretrizes do agente (todos os arquivos são carregados)
│   ├── conduct.md              # Regras de conduta do agente (precedência)
│   ├── code guidelines.md      # Padrões de desenvolvimento
│   ├── commit guidelines.md    # Composição do histórico de commits
│   ├── IA best practices.md    # Boas práticas de uso de IA por agentes
│   └── card work types.md      # Comportamento e ciclo de vida por work_type
├── docs/                       # Documentação de projeto (PDFs, specs)
├── sync-commands.sh            # Instala comandos no Claude (Linux/macOS)
├── sync-commands.ps1           # Instala comandos no Claude (Windows)
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
