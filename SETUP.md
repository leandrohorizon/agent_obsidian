# Setup - Integração Obsidian + Claude Code

Este documento explica como configurar a integração entre seu vault Obsidian e Claude Code para gerenciar tarefas através de slash commands globais.

## Pré-requisitos

- Claude Code instalado
- Git instalado
- GitHub CLI (`gh`) instalado (opcional, para criar PRs automaticamente)
- Shell: bash, zsh ou PowerShell (Windows)

## Instalação

### 1. Configurar variável de ambiente

Adicione a seguinte linha ao seu arquivo de configuração do shell:

**Para zsh (macOS padrão):**
```bash
echo 'export OBSIDIAN_VAULT_PATH="/Users/user/workspace/obisidian/agent_obsidian"' >> ~/.zshrc
source ~/.zshrc
```

**Para bash:**
```bash
echo 'export OBSIDIAN_VAULT_PATH="/Users/user/workspace/obisidian/agent_obsidian"' >> ~/.bashrc
source ~/.bashrc
```

**Para PowerShell (Windows):**
```powershell
# Definir permanentemente (persiste entre sessões)
setx OBSIDIAN_VAULT_PATH "C:\Users\seu-usuario\workspace\agent_obsidian"

# Definir na sessão atual (necessário após setx para uso imediato)
$env:OBSIDIAN_VAULT_PATH = "C:\Users\seu-usuario\workspace\agent_obsidian"
```

> **Nota:** No Windows, `setx` define a variável permanentemente, mas só afeta **novas** sessões de terminal. Use o comando `$env:...` na sessão atual para que funcione imediatamente.

### 2. Verificar instalação

Os comandos já foram instalados em `~/.claude/commands/`. Verifique:

```bash
ls ~/.claude/commands/
```

Você deve ver:
- `board-status.md`
- `start-card.md`
- `work-on-card.md`
- `review-card.md`
- `review-pr.md`
- `complete-card.md`
- `condense-memory.md`

### 3. Testar configuração

Em qualquer projeto, execute:
```bash
claude
```

Depois dentro do Claude Code:
```
/board-status
```

Se estiver configurado corretamente, você verá o status do seu board Obsidian.

### 4. VS Code Copilot (skills)

O `sync-commands` grava as skills em `~/.agent_obsidian/skills/`. O VS Code
Copilot só as encontra se essa pasta estiver declarada — sem a configuração, ele
cai no padrão `~/.copilot/skills/`, que **não** é atualizado pelo sync e fica
desatualizado em silêncio.

Em `settings.json` do usuário (`Ctrl+Shift+P` → *Preferences: Open User Settings
(JSON)*):

```json
"chat.agentSkillsLocations": [
  "${userHome}/.agent_obsidian/skills"
]
```

Depois de configurar, **remova** `~/.copilot/skills/` para não manter duas
cópias divergentes. Recarregue a janela do VS Code e confirme que as skills do
Agent Obsidian aparecem na lista.

## Comandos Disponíveis

### `/board-status`
Mostra o status atual do board com quantidade de cards em cada estágio.

**Uso:**
```
/board-status
```

### `/start-card <nome>`
Inicia trabalho em um card, movendo para "in_progress"; só implementação cria branch git.

**Uso:**
```
cd ~/meu-projeto
/start-card "card-exemplo"
```

**O que faz:**
- Move card de `1.not_started/` → `2.in_progress/`
- Para implementação, detecta repositório Git, pergunta sobre a branch base, faz `git pull` e cria `feature/nome-do-card`
- Para relatório e investigação, não troca branch, faz pull ou cria branch; mantém `branch:` vazio
- Para experimento, não executa nenhum comando Git e mantém `repo:` e `branch:` vazios
- Atualiza o frontmatter conforme o tipo de trabalho

### `/work-on-card <nome>`
Trabalha nas tarefas do card, com contexto completo (guidelines + condensed memory + dependências).

**Uso:**
```
/work-on-card "card-exemplo"
```

**O que faz:**
- Lê o card pela leitura enxuta
- Carrega **todos** os arquivos de `guidelines/` para seguir padrões e regras de comportamento
- Carrega a memória de projeto e, quando aplicável, a de feature; `/work-on-card` também carrega a memória operacional
- Lê cards dependentes mencionados em `[[links]]`
- Executa tarefas pendentes `- [ ]`
- Marca tarefas como completas `- [x]`
- Documenta decisões e conhecimento no card
- Em cards `implementation`, faz commits por unidade lógica (`guidelines/commit guidelines.md`)
- Relatórios produzem documentos em `docs/{projeto}/reports/` no vault sem alterar código
- Investigações tratam o código do projeto como somente leitura e podem produzir documentos em `docs/{projeto}/investigations/`
- Experimentos criam ferramentas pequenas na pasta de trabalho atual; testes são opcionais, não usam Git nem escrevem na memória

### `/review-card <nome>`
Prepara card para revisão, move para "in_review" e auxilia na criação de PR.
Aplica-se somente a cards de implementação; relatórios, investigações e experimentos são concluídos diretamente.

**Uso:**
```
/review-card "card-exemplo"
```

**O que faz:**
- Valida se todas as tarefas foram completadas
- Verifica se documentação está completa
- Mostra `git status` e `git diff`
- Sugere commit se necessário
- Oferece criar PR com `gh pr create`
- Atualiza card com link do PR
- Move card de `2.in_progress/` → `3.in_review/`

### `/review-pr <pr>`
Revisa um PR recebido usando as guidelines do vault e as memórias do projeto, citando a regra por trás de cada achado — e mantém um card do board sincronizado com o ciclo de vida do PR.

**Uso:**
```
/review-pr 123
/review-pr https://github.com/org/repo/pull/123
```

**O que faz:**
- Lê o PR com `gh pr view` e recorta o diff com `gh pr diff --name-only`, lendo arquivo por arquivo
- Carrega todos os arquivos de `guidelines/` e a memória do repositório, quando existir
- Garante um card para o PR: localiza pelo `pr_url` ou cria (`work_type: implementation`), registrando `pr_author` (autor) e `feature:`
- Entrega achados com arquivo, linha, severidade e a regra citada; sugestão sem regra fica em seção separada
- Declara convenção desconhecida quando o repositório não tem memória e revisa só pela API quando não há clone
- Sincroniza o card com o estado do PR: aberto → `3.in_review`; draft não move; fechado sem merge → `5.archived`; mergeado → encaminha para `/complete-card`
- **Não publica nada no PR** — GitHub é somente leitura

### `/complete-card <nome>`
Finaliza um card, movendo para "done" e garantindo documentação completa.

**Uso:**
```
/complete-card "card-exemplo"
```

**O que faz:**
- Valida completude do card
- Para implementação, verifica se PR foi merged
- Adiciona timestamps de conclusão
- Move implementação de `3.in_review/` e relatório/investigação/experimento de `2.in_progress/` para `4.done/`
- Só para implementação, volta para a branch default, faz pull e tenta apagar a branch local
- Consolida memória automaticamente para implementação; nunca para relatório ou experimento; pede confirmação para investigação

### `/condense-memory`
Consolida implementações elegíveis em `4.done`; relatórios e experimentos nunca são incluídos e investigações precisam ser nomeadas explicitamente.

**Uso:**
```
/condense-memory
```

**O que faz:**
- Processa implementações pendentes em `4.done/`; não consolida relatórios nem experimentos
- Investigações só são processadas quando nomeadas explicitamente
- Extrai conhecimento das seções:
  - "Conhecimento Adquirido pela IA"
  - "Discussões"
  - "Descrição Técnica" (implementation) ou "Descobertas e Conclusões" (investigation)
- Roteia cada item para o eixo adequado:
  - Projeto: arquitetura, padrões e convenções, ferramentas, configuração e aprendizados
  - Feature: fluxo ponta a ponta, contratos entre serviços, regras de negócio e edge cases
- Atualiza `condensed memory/projects/{projeto}.md` e, quando aplicável, `condensed memory/features/{feature}.md`
- Marca cards como processados

## Fluxo de Trabalho Típico

### Relatório ou investigação sem Git

Crie o card com `work_type: report` ou `work_type: investigation` e inicie com
`/start-card`. O card vai de `2.in_progress/` diretamente para `4.done/` via
`/complete-card`, sem branch, commit, PR ou revisão em `3.in_review/`.
Relatórios ficam em `docs/{projeto}/reports/`; documentos de investigação são
opcionais em `docs/{projeto}/investigations/`, ambos no vault. A investigação
só é consolidada em memória após confirmação; relatórios nunca são consolidados.

### Experimento com ferramenta isolada

Crie o card com `work_type: experiment`, entre na pasta de trabalho do
experimento e use `/start-card`. O fluxo não executa nenhum comando Git. Crie e
valide a ferramenta nessa pasta; testes automatizados são opcionais. Use
`/complete-card` para concluir diretamente em `4.done`. Os arquivos permanecem
na pasta até limpeza manual e nunca são enviados para condensed memory.

```bash
# 1. Ver o que tem para fazer
/board-status

# 2. Ir para o projeto e iniciar card
cd ~/projetos/projeto-a
/start-card "card-exemplo"
# → Move para 2.in_progress sem checkout, pull ou branch

# 3. Trabalhar nas tarefas (pode executar múltiplas vezes)
/work-on-card "card-exemplo"
# → Relatório: salva em docs/{projeto}/reports/ no vault
# → Investigação: registra descobertas no card e pode salvar documento no vault

# 4. Quando terminar, concluir diretamente
/complete-card "card-exemplo"
# → Move de 2.in_progress para 4.done sem Git
# → Relatório nunca consolida memória; investigação pede confirmação
```

## Estrutura do Vault

```
$OBSIDIAN_VAULT_PATH/
├── board/
│   ├── 0.backlog/        # Ideias cruas (não refinadas/priorizadas)
│   ├── 1.not_started/    # Cards refinados aguardando início
│   ├── 2.in_progress/    # Cards em desenvolvimento
│   ├── 3.in_review/      # Cards aguardando review/merge
│   ├── 4.done/           # Cards finalizados
│   └── 5.archived/       # Cards antigos/cancelados
├── templates/
│   └── card/
│       ├── implementation.md
│       ├── report.md
│       ├── investigation.md
│       └── experiment.md
├── guidelines/           # Diretrizes do agente (todos os arquivos são carregados)
│   ├── conduct.md           # Regras de conduta do agente (precedência)
│   ├── code guidelines.md   # Padrões de desenvolvimento
│   ├── commit guidelines.md # Composição do histórico de commits
│   ├── IA best practices.md # Boas práticas de uso de IA por agentes
│   └── card work types.md   # Comportamento e ciclo de vida por work_type
├── docs/                 # Documentação de projeto (PDFs, specs)
└── condensed memory/     # Conhecimento em três eixos
    ├── README.md         # Especificação do formato (versionada)
    ├── projects/         # Memória por repositório (arquivo plano)
    │   ├── .gitkeep      # Mantém a pasta no clone (conteúdo é local)
    │   ├── projeto-a.md
    │   └── projeto-b.md
    ├── features/         # Memória por feature (atravessa repos)
    │   ├── .gitkeep
    │   └── feature-x.md
    └── operational/      # Memória de execução (falhou → funcionou)
        ├── .gitkeep
        └── {area}.md     # Local — git, github, shell, vscode
```

Só `condensed memory/README.md` é versionado como conteúdo. O que está em
`projects/`, `features/` e `operational/` é local, como os cards — cada máquina
constrói o seu. As três pastas existem no clone pelo `.gitkeep`; sem ele não
apareceriam, porque nenhum arquivo de conteúdo é versionado.

Na memória operacional, um arquivo por área, teto de ~40 linhas cada, criado na
primeira entrada que precisar dele. O nome do arquivo é a ferramenta concreta
(`git`, `github`, `shell`, `vscode`), não uma categoria.

## Arquivo de Estado `.agent_obsidian`

O sistema cria automaticamente um arquivo `.agent_obsidian` na **raiz de cada projeto** para rastrear qual card está ativo.

### Localização

O arquivo fica na raiz do seu projeto (não no vault):

```
/workspace/projeto-a/             (seu projeto)
├── .git/
├── .agent_obsidian               ← arquivo de estado (nunca commitado)
└── app/
```

### Estrutura

```json
{
  "version": "2.0",
  "vault_path": "/Users/you/workspace/obsidian/vault",
  "guidelines_path": "/Users/you/workspace/obsidian/vault/guidelines",
  "condensed_memory_path": "/Users/you/workspace/obsidian/vault/condensed memory/projects/projeto-a.md",
  "current_card": {
    "name": "card-exemplo",
    "path": "/Users/you/workspace/obsidian/vault/board/2.in_progress/card-exemplo.md"
  }
}
```

Quando não há card ativo:

```json
{
  "version": "2.0",
  "vault_path": "/Users/you/workspace/obsidian/vault",
  "guidelines_path": "/Users/you/workspace/obsidian/vault/guidelines",
  "condensed_memory_path": "/Users/you/workspace/obsidian/vault/condensed memory/projects/projeto-a.md",
  "current_card": null
}
```

### Criação Automática

O arquivo é criado automaticamente quando você usa qualquer comando:
- `/start-card` cria e registra o card iniciado
- `/work-on-card` cria se não existir
- `/complete-card` limpa o `current_card` (seta para `null`)

### Benefícios

1. **Comandos sem argumentos:** Após `/start-card`, você pode usar `/work-on-card` sem passar o nome do card
2. **Múltiplos projetos:** Cada projeto tem seu próprio estado independente
3. **Zero configuração manual:** Tudo é gerenciado automaticamente pela IA

### Importante

- Nunca commite o `.agent_obsidian` — é estado local da máquina (regra em `guidelines/conduct.md`)
- Não edite manualmente o arquivo (deixe a IA gerenciar)
- Se corrompido, será recriado automaticamente

## Troubleshooting

### Erro: "OBSIDIAN_VAULT_PATH não definida"
Execute:
```bash
echo $OBSIDIAN_VAULT_PATH
```
Se estiver vazio, verifique se adicionou ao arquivo correto (~/.zshrc ou ~/.bashrc) e executou `source`.

### Erro: "Card não encontrado"
- Verifique o nome exato do card (sem .md)
- Use `/board-status` para listar cards disponíveis
- O card pode estar em outro estágio do board

### Erro: "Não está em um repositório git"
Os cards de implementação exigem um repositório git para iniciar e revisar. Cards `report` e `investigation` não exigem Git; `experiment` não executa nenhum comando Git.

## Dicas

1. **Use tab completion**: Os nomes dos cards podem ter espaços, use aspas
2. **Commits por unidade lógica**: `/work-on-card` compõe o histórico conforme `guidelines/commit guidelines.md`, somente em cards `implementation`; experimentos nunca executam Git
3. **Contexto automático**: Todos os comandos carregam todos os arquivos de `guidelines/` e o condensed memory
4. **Dependências**: Use as propriedades `depends_on` e `dependents` com `[[nome-do-card]]` para referenciar cards relacionados (`guidelines/IA best practices.md` §8)
5. **Documentação**: Registre descobertas reutilizáveis de implementações/investigações; relatórios e experimentos não geram consolidação de memória

## Dashboard (opcional)

O fluxo funciona inteiro por comandos. Se quiser uma visão do board dentro do
Obsidian — Kanban por pasta, lista com filtros e painel do `current_card` de cada
projeto — existe um plugin à parte, em repositório próprio:
[dashboard-agent-obsidian](https://github.com/leandrohorizon/dashboard-agent-obsidian).

Instalação, configuração e desenvolvimento estão no README de lá. Este vault não
versiona o plugin; `.obsidian/plugins/dashboard-agent-obsidian/` guarda só o
artefato instalado, local como qualquer outro plugin do Obsidian.

## Próximos Passos

1. Execute `/board-status` para ver seus cards
2. Escolha um card de `1.not_started/` (ou refine um de `0.backlog/` com `/refine-card`)
3. Use `/start-card` para começar
4. Use `/work-on-card` quantas vezes precisar
5. Para implementação, finalize com `/review-card` e `/complete-card`; para relatório/investigação, use `/complete-card` diretamente
6. Periodicamente execute `/condense-memory`

> Para trabalhar em **todos** os cards de `1.not_started/` de uma vez, use
> `/orchestrate-cards` — ele roda um subagente por card e abre cada PR em draft.

---

Para mais informações sobre Claude Code, visite: https://docs.claude.com/
