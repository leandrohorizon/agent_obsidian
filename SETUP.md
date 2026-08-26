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

## Comandos Disponíveis

### `/board-status`
Mostra o status atual do board com quantidade de cards em cada estágio.

**Uso:**
```
/board-status
```

### `/start-card <nome>`
Inicia trabalho em um card, movendo de "not_started" para "in_progress" e criando branch git.

**Uso:**
```
cd ~/meu-projeto
/start-card "card-exemplo"
```

**O que faz:**
- Move card de `1.not_started/` → `2.in_progress/`
- Detecta repositório git atual
- Sugere criar branch no formato `feature/nome-do-card`
- Atualiza card com informações do repositório

### `/work-on-card <nome>`
Trabalha nas tarefas do card, com contexto completo (code guidelines + condensed memory + dependências).

**Uso:**
```
/work-on-card "card-exemplo"
```

**O que faz:**
- Lê o card completo
- Carrega `code guidelines.md` para seguir padrões
- Carrega `condensed memory.md` com conhecimento acumulado
- Lê cards dependentes mencionados em `[[links]]`
- Executa tarefas pendentes `- [ ]`
- Marca tarefas como completas `- [x]`
- Documenta decisões e conhecimento no card
- Faz commits incrementais

### `/review-card <nome>`
Prepara card para revisão, move para "in_review" e auxilia na criação de PR.

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

### `/complete-card <nome>`
Finaliza um card, movendo para "done" e garantindo documentação completa.

**Uso:**
```
/complete-card "card-exemplo"
```

**O que faz:**
- Valida completude do card
- Verifica se PR foi merged
- Adiciona timestamps de conclusão
- Move card de `3.in_review/` → `4.done/`
- Marca como pronto para consolidação de memória

### `/condense-memory`
Processa todos os cards em "4.done" e consolida conhecimento em `condensed memory.md`.

**Uso:**
```
/condense-memory
```

**O que faz:**
- Lê todos os cards em `4.done/`
- Extrai conhecimento das seções:
  - "Conhecimento Adquirido pela IA"
  - "Discussões"
  - "Descrição Técnica"
- Categoriza por tipo:
  - Regras de Negócio
  - Padrões Técnicos
  - Integrações e APIs
  - Problemas e Soluções
  - Ferramentas
- Atualiza `condensed memory.md`
- Marca cards como processados

## Fluxo de Trabalho Típico

```bash
# 1. Ver o que tem para fazer
/board-status

# 2. Ir para o projeto e iniciar card
cd ~/projetos/projeto-a
/start-card "card-exemplo"

# 3. Trabalhar nas tarefas (pode executar múltiplas vezes)
/work-on-card "card-exemplo"

# 4. Quando terminar, preparar para revisão
/review-card "card-exemplo"

# 5. Após PR aprovado e merged, finalizar
/complete-card "card-exemplo"

# 6. Periodicamente, consolidar conhecimento
/condense-memory
```

## Estrutura do Vault

```
$OBSIDIAN_VAULT_PATH/
├── board/
│   ├── 1.not_started/    # Cards aguardando início
│   ├── 2.in_progress/    # Cards em desenvolvimento
│   ├── 3.in_review/      # Cards aguardando review/merge
│   └── 4.done/           # Cards finalizados
├── templates/
│   └── card template.md  # Template para novos cards
├── code guidelines.md    # Diretrizes de código (sempre carregadas)
└── condensed memory/     # Conhecimento consolidado em dois eixos
    ├── projects/         # Memória por repositório (arquivo plano)
    │   ├── projeto-a.md
    │   └── projeto-b.md
    └── features/         # Memória por feature (atravessa repos)
        └── feature-x.md
```

## Arquivo de Estado `.agent_obsidian`

O sistema cria automaticamente um arquivo `.agent_obsidian` na **raiz de cada projeto** para rastrear qual card está ativo.

### Localização

O arquivo fica na raiz do seu projeto (não no vault):

```
/workspace/projeto-a/             (seu projeto)
├── .git/
├── .agent_obsidian               ← arquivo de estado
├── .gitignore                    ← deve incluir .agent_obsidian
└── app/
```

### Estrutura

```json
{
  "version": "1.0",
  "vault_path": "/Users/you/workspace/obsidian/vault",
  "current_card": {
    "name": "card-exemplo",
    "path": "/Users/you/workspace/obsidian/vault/board/2.in_progress/card-exemplo.md"
  }
}
```

Quando não há card ativo:

```json
{
  "version": "1.0",
  "vault_path": "/Users/you/workspace/obsidian/vault",
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

- Adicione `.agent_obsidian` ao `.gitignore` do projeto (feito automaticamente pelo `/start-card`)
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
Os comandos `/start-card`, `/work-on-card` e `/review-card` precisam ser executados dentro de um repositório git.

## Dicas

1. **Use tab completion**: Os nomes dos cards podem ter espaços, use aspas
2. **Commits incrementais**: `/work-on-card` pode fazer commits automáticos
3. **Contexto automático**: Todos os comandos carregam code guidelines e condensed memory
4. **Dependências**: Use `[[nome-do-card]]` para referenciar cards relacionados
5. **Documentação**: Sempre preencha "Conhecimento Adquirido pela IA" para melhorar o condensed memory

## Próximos Passos

1. Execute `/board-status` para ver seus cards
2. Escolha um card de `1.not_started/`
3. Use `/start-card` para começar
4. Use `/work-on-card` quantas vezes precisar
5. Finalize com `/review-card` e `/complete-card`
6. Periodicamente execute `/condense-memory`

---

Para mais informações sobre Claude Code, visite: https://docs.claude.com/
