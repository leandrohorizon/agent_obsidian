# Agent Obsidian - Task Management System

This repository implements a comprehensive task management system that integrates Obsidian with Claude Code through custom slash commands, enabling AI-assisted project management with knowledge consolidation.

## Architecture Overview

### Multi-Project State Management

This system uses a **distributed state architecture** with centralized knowledge:

```
~/workspace/
├── obisidian/leanddro/          # Centralized vault (this repo)
│   ├── board/                    # Kanban board (all projects)
│   ├── condensed memory/         # Knowledge bases in two axes
│   │   ├── projects/             # Per-repository memory
│   │   └── features/             # Per-feature memory (crosses repos)
│   ├── commands/                 # Slash command definitions
│   └── code guidelines.md        # Development standards
│
├── project-calculator/           # Project 1
│   └── .agent_obsidian          # State: current card for this project
│
└── project-ecommerce/            # Project 2
    └── .agent_obsidian          # State: current card for this project
```

**Key Architectural Decisions:**

- **Centralized Vault:** Single Obsidian vault stores all cards and knowledge across projects
- **Distributed State:** Each project has its own `.agent_obsidian` file tracking current work
- **Two-Axis Knowledge:** Completed cards route knowledge to project memory (repo-specific) and feature memory (crosses repositories)
- **Zero Configuration:** State files auto-created on first command use

### The `.agent_obsidian` State File

**Location:** Root of each project (NOT in the vault)

**Purpose:** Tracks active card and vault location for the current project

**Structure:**
```json
{
  "version": "2.0",
  "vault_path": "/Users/leandrocoutomessias/workspace/obisidian/leanddro",
  "condensed_memory_path": "/Users/leandrocoutomessias/workspace/obisidian/leanddro/condensed memory/projects/agent_obsidian.md",
  "current_card": {
    "name": "card-name",
    "path": "/absolute/path/to/board/2.in_progress/card.md"
  }
}
```

**Version 2.0 (two-axis model):**
- `condensed_memory_path` points to `condensed memory/projects/{projeto}.md`
- The feature memory path is NOT stored in state — it's derived from the card's `feature:` field at load time via `get_feature_memory_path()`
- Migration: if an existing valid state has `version` < 2.0, `validate_agent_state()` rewrites `condensed_memory_path` to the new layout (instead of keeping the old path)

**Lifecycle:**
- Created automatically by any command if missing
- Updated when card starts (`/start-card`) - stores current_card
- Cleared when card completes (`/complete-card`) - sets current_card to null
- Preserved during review (`/review-card`) - card still active

**Benefits:**
- Commands work without arguments when card is active
- Direct path access eliminates file searches (performance optimization)
- Automatic gitignore management
- No manual configuration needed

### Kanban Board Structure

Cards flow through states represented as folders:

```
board/
├── 1.not_started/    # Backlog - cards waiting to start
├── 2.in_progress/    # Active work - one card per project typically
├── 3.in_review/      # Code review - PR created, awaiting approval
├── 4.done/           # Completed - source for condensed memory
└── 5.archived/       # Old or cancelled cards
```

**Card Metadata (YAML Frontmatter):**
```yaml
---
repo: git@github.com:org/project.git
branch: feature/card-name
status: In Progress
created: 2026-01-15
started: 2026-01-16
reviewed: 2026-01-17  # Added when moved to review
completed: 2026-01-18  # Added when moved to done
pr_number: 123
pr_url: https://github.com/org/project/pull/123
pr_status: Merged
---
```

### Card Structure

Every card follows this template:

```markdown
## Descrição
Brief description of what needs to be done and why

## Dependências
- [[other-card-name]] - what it provides
- External dependencies (APIs, services, libraries)

## Tarefas
- [ ] Specific actionable task 1
- [ ] Specific actionable task 2
- [ ] Write tests
- [ ] Update documentation

## Discussões
#### 2026-01-15 14:30
Discussion notes, decisions made, trade-offs considered

## PRs
- [PR #123 - Title](url) - Status: Open/Merged

## Descrição Técnica do que Foi Feito
Technical details of the implementation

## Conhecimento Adquirido pela IA
Business rules, patterns identified, gotchas, insights
(This section feeds into condensed memory)
```

### Knowledge Consolidation System

**Condensed Memory** is the system's long-term memory, organized in **two axes** with disjoint responsibilities:

```
condensed memory/
├── projects/                    # Per-repository memory (stable, transversal)
│   ├── agent_obsidian.md
│   ├── calculator.md
│   └── ecommerce.md
└── features/                    # Per-feature memory (crosses repositories)
    ├── analise-pix-in.md
    ├── analise-boleto-out.md
    └── consulta-balance.md
```

**Two-Axis Model:**
- **Project memory** (`projects/{projeto}.md`) — what is stable and transversal to the repository: architecture, code conventions, tools, setup, stack gotchas. **No feature knowledge.**
- **Feature memory** (`features/{feature}.md`) — business rules, end-to-end flow, contracts between services, decisions and edge cases of that feature, **crossing repositories**.

A card declares its feature in the frontmatter (`feature: boleto-out`) and `/condense-memory` **routes** each extracted piece of knowledge to the correct axis, instead of dumping everything into one file. This solves the case where a feature (e.g. boleto out) spans three repositories — the full-flow knowledge lives in a single feature file, accessible from any project.

**Format of the project memory file:**
```markdown
# Condensed Memory - {project_name}

> Última atualização: YYYY-MM-DD
> Cards processados: N
> Origem: [card1, card2, card3]

---

## 🏗️ Arquitetura

### Subsystem Name
Brief description (1-2 lines)
- Technical detail 1
- Technical detail 2
- Example: `code or command`

**Decisão:** Why this architecture was chosen and what problem it solves.

---

## 📋 Padrões e Convenções

### Pattern Name
How to do things consistently
- Rule 1
- Rule 2

**Rationale:** Why we follow this pattern.

---

## 🛠️ Ferramentas e Comandos

### /command-name
What it does (1 line)
- Parameter 1: description
- Parameter 2: description

---

## ⚙️ Configuração

### Environment Variables
- `VAR_NAME`: description and example value

---

## 💡 Aprendizados Chave

- Important insight about trade-off or decision
- Common problem and how to avoid
- Valuable edge case to know
```

**Format of the feature memory file (own categories, not reusing project's):**
```markdown
# Feature - {slug-da-feature}

> Última atualização: YYYY-MM-DD
> Repositórios envolvidos: [repo1, repo2, ...]
> Cards de origem: [card1, card2, ...]

---

## 🔀 Fluxo Ponta a Ponta

### Flow Name
Complete sequence crossing services/repositories
- Step 1 (in {repo}): what happens
- Step 2 (in {repo}): what happens

**Decisão:** Why the flow is this way.

---

## 🤝 Contratos entre Serviços

### Contract Name
What each side sends/consumes
- {service A} sends: fields, format
- {service B} consumes: fields, format

---

## 📐 Regras de Negócio

### Rule Name
Specific rule or validation of the feature
- Expected behavior in each scenario

---

## ⚠️ Edge Cases

- Edge case, intermittency or unexpected behavior
- Known problem and how it was solved
```

**Design Principles:**
- **Two-Axis Routing:** Classify each extracted item as project OR feature before writing, with explicit tie-break (does this knowledge help someone working in another repo of the same feature? → feature)
- **Deduplication:** Consolidate similar information from multiple cards within each axis
- **Highlight Decisions:** Always use `**Decisão:**` or `**Rationale:**` to explain "why"
- **Compact:** Group related items, avoid verbosity
- **Source Once:** List processed cards in header, don't repeat per item
- **Category Navigation:** Use emojis (🏗️📋🛠️⚙️💡 for project; 🔀🤝📐⚠️ for feature) for quick scanning

## Command Workflow

### Complete Lifecycle Example

```bash
# 1. In your project directory
cd ~/workspace/project-calculator

# 2. Start working on a card
/start-card "implement calculator"
# → Creates .agent_obsidian in project root
# → Moves card: 1.not_started → 2.in_progress
# → Creates git branch: feature/implement-calculator
# → Stores current_card in .agent_obsidian

# 3. Work on the card (no argument needed - reads from .agent_obsidian)
/work-on-card
# → Loads card from current_card.path directly
# → Loads code guidelines.md
# → Loads condensed memory/projects/calculator.md (project memory)
# → Loads condensed memory/features/{feature}.md (feature memory, if card has feature:)
# → Loads dependent cards
# → Executes tasks
# → Updates card with progress

# 4. Prepare for review
/review-card
# → Validates all tasks completed
# → Creates commit with meaningful message
# → Pushes branch
# → Creates PR with intelligent description
# → Moves card: 2.in_progress → 3.in_review
# → Updates frontmatter with PR info
# → current_card still active in .agent_obsidian

# 5. Complete the card after PR merge
/complete-card
# → Validates documentation complete
# → Moves card: 3.in_review → 4.done
# → Updates frontmatter (status: Done, pr_status: Merged)
# → Clears current_card in .agent_obsidian (sets to null)
# → Automatically calls /condense-memory to consolidate knowledge

# 6. Knowledge automatically available for future tasks
/work-on-card "add scientific mode"
# → Loads condensed memory with learnings from previous card
```

### Optional Arguments Pattern

Most commands accept optional card name. If omitted, they read from `.agent_obsidian`:

```bash
# With argument (searches for card by name)
/work-on-card "my-card-name"

# Without argument (uses current_card.path from .agent_obsidian)
/work-on-card
```

**Performance Optimization:** Using the path directly eliminates Glob searches, saving tokens and time.

## Command Reference

### `/board-status`
Shows current state of the Kanban board across all projects.

**Usage:**
```
/board-status
```

**Output:** Card counts in each folder, recent activity.

---

### `/start-card <nome>`
Initiates work on a card.

**Arguments:**
- `<nome>`: Card name (without .md extension) or partial path

**Actions:**
1. Verifies `$OBSIDIAN_VAULT_PATH` is set
2. Creates/validates `.agent_obsidian` in project root
3. Adds `.agent_obsidian` to `.gitignore`
4. Finds card in `1.not_started/`
5. Creates git branch: `feature/card-name`
6. Updates card frontmatter (repo, branch, status, started date)
7. Moves card: `1.not_started/` → `2.in_progress/`
8. Updates `.agent_obsidian` with current_card

**Important:** This is the entry point that initializes state for a project.

---

### `/work-on-card [nome]`
Executes tasks in a card with full context.

**Arguments:**
- `[nome]`: Optional - card name. If omitted, uses `.agent_obsidian`

**Context Loaded:**
1. Card content (via direct path if from state)
2. `code guidelines.md` - development standards
3. `condensed memory/projects/{project}.md` - project memory (architecture, conventions, tools)
4. `condensed memory/features/{feature}.md` - feature memory (if card has `feature:` frontmatter)
5. Dependent cards referenced as `[[card-name]]`

**Actions:**
- Identifies pending tasks (`- [ ]`)
- Executes tasks following code guidelines
- Marks tasks complete (`- [x]`)
- Documents decisions in "Discussões" section
- Updates "Descrição Técnica" and "Conhecimento Adquirido"
- Makes incremental git commits

**Path Resolution:**
```
If argument provided:
  Search in $OBSIDIAN_VAULT_PATH/board/2.in_progress/

If no argument:
  Read .agent_obsidian → Use current_card.path directly (no search!)
```

---

### `/refine-card <nome>`
Analyzes and refines vague or incomplete cards BEFORE starting work.

**Purpose:** Force deep analysis - don't let AI assume how code works, verify actual implementation.

**Context Loaded:**
1. Card
2. Code guidelines
3. Condensed memory
4. Dependent cards
5. **Related code in project** - reads actual implementation

**Actions:**
1. Analyzes card clarity (description, tasks, dependencies, discussions)
2. Identifies vague points and generates specific questions:
   - Implementation questions
   - Behavior questions
   - Integration questions
   - Code analysis findings
3. Adds questions to "Discussões" section with timestamp
4. **Validates/fills `feature:` in frontmatter** - ensures the card declares its feature (slug) so `/condense-memory` can route knowledge to the correct axis
5. **Converses with user** to resolve each question
6. Updates card during conversation:
   - Replaces generic tasks with specific actions
   - Updates description if needed
   - Marks questions as resolved
   - Adds identified dependencies

**Example Transformation:**
```
BEFORE:
- [ ] Tarefa 1
- [ ] Tarefa 2

AFTER:
- [ ] Create endpoint POST /api/users with email validation
- [ ] Implement UserService with createUser method
- [ ] Add unit tests for data validation
- [ ] Update API documentation
- [ ] Add migration for users table
```

**Multiple Executions:** If run again on the same card, goes deeper:
- More critical analysis
- Macro perspective (how card integrates with larger systems)
- Questions previous assumptions
- Identifies edge cases
- Validates previous resolutions still make sense

---

### `/update-card <nome> [conteúdo]`
Adds entries to the "Discussões" section.

**Arguments:**
- `<nome>`: Card name
- `[conteúdo]`: Optional - content to add. If omitted, prompts user.

**Actions:**
- Locates card across all board folders
- Adds timestamped entry to Discussões section
- Preserves all previous discussions

**Usage:**
```
/update-card "my-card" "Decided to use JWT because it scales better"
```

---

### `/review-card [nome]`
Prepares card for code review and creates PR.

**Arguments:**
- `[nome]`: Optional - uses `.agent_obsidian` if omitted

**Actions:**
1. Validates all tasks completed (`- [x]`)
2. Checks documentation sections filled
3. Reviews git status and diff
4. Suggests/creates commit if changes pending
5. Pushes branch
6. **Intelligently creates PR:**
   - Detects base branch (main/develop)
   - Gets relevant commits: `git log <base>..HEAD --oneline`
   - Ignores trivial commits (typo, lint, format)
   - Groups related commits
   - Detects PR template (`.github/PULL_REQUEST_TEMPLATE.md`)
   - Fills template completely (replaces all TODOs and placeholders)
   - If no template, uses standard format:
     ```markdown
     ## 🧾 Resumo
     [2-3 line summary]

     ## 🔧 O que foi feito
     - [Intelligent grouping of commits]

     ## 🧪 Como testar
     [Suggested steps]

     ## ⚠️ Observações
     [Risks, dependencies, notes]
     ```
   - Output in Portuguese (pt-BR)
   - Focuses on technical and business impact
7. Captures PR number and URL
8. Updates card frontmatter (pr_number, pr_url, reviewed date)
9. Moves card: `2.in_progress/` → `3.in_review/`
10. **Does NOT clear `.agent_obsidian`** - card still active during review

---

### `/complete-card [nome]`
Finalizes card after PR is merged.

**Arguments:**
- `[nome]`: Optional - uses `.agent_obsidian` if omitted

**Actions:**
1. Finds card in `3.in_review/`
2. Validates:
   - All tasks completed
   - "Descrição Técnica" filled
   - "Conhecimento Adquirido" filled
   - PR merged (if applicable)
3. Updates frontmatter:
   ```yaml
   status: Done
   completed: YYYY-MM-DD
   pr_status: Merged
   ```
4. Moves card: `3.in_review/` → `4.done/`
5. **Clears `.agent_obsidian`:** Sets `current_card: null`
6. **Automatically calls `/condense-memory`** to consolidate knowledge immediately

---

### `/load-context [nome]`
Loads complete context for a card (read-only, for understanding).

**Arguments:**
- `[nome]`: Optional - uses `.agent_obsidian` if omitted

**Actions:**
1. Reads card (via direct path if from state)
2. Loads code guidelines
3. Loads condensed memory (both axes: project + feature)
4. Loads dependent cards
5. Checks git status, branch, last commit
6. **Analyzes branch modifications:**
   - Lists commits: `git log origin/<base>..HEAD --oneline`
   - Lists modified files (committed and uncommitted)
   - Filters to show only files related to card:
     - Mentioned in card (description, tasks)
     - Match card keywords in path
     - Relevant extensions/directories
   - Excludes: `.obsidian/`, other cards, unrelated configs
   - Shows diff stats for related files
7. Presents comprehensive summary:
   - Card state and location
   - Pending tasks
   - Dependencies
   - Recent discussions
   - Git context
   - Branch modifications (commits, staged, unstaged)
   - Code guidelines loaded
   - Condensed memory categories (project + feature)

**Use Cases:**
- Start new work session
- Resume after interruption
- Review before PR

---

### `/condense-memory [nome-do-card]`
Consolidates knowledge from completed cards into condensed memory.

**Arguments:**
- `[nome-do-card]`: Optional - specific card in `4.done/`. If omitted, processes all unprocessed cards.

**Recommended:** Process cards individually right after completion.

**Actions:**
1. Gets vault path (from `.agent_obsidian` or `$OBSIDIAN_VAULT_PATH`)
2. Detects project: `basename $(pwd)` normalized (lowercase, underscores)
3. Reads the card's `feature:` from frontmatter to determine the target axis
4. For specified card or all unprocessed cards:
   - Extracts from sections:
     - "Descrição"
     - "Conhecimento Adquirido pela IA"
     - "Discussões"
     - "Descrição Técnica"
5. **Applies deduplication:**
   - Identifies repeated information
   - Consolidates related concepts
   - Prioritizes architectural decisions and "why" over implementation details
   - Generates compact summaries
6. **Routes each item to the correct axis** (two-axis model):
   - **Project memory** (`condensed memory/projects/{projeto}.md`) — stable, transversal to the repo:
     - 🏗️ **Arquitetura:** Structural decisions, patterns, integrations
     - 📋 **Padrões e Convenções:** Rules, code conventions, templates
     - 🛠️ **Ferramentas e Comandos:** Slash commands, scripts, libraries
     - ⚙️ **Configuração:** Environment variables, setup, dependencies
     - 💡 **Aprendizados Chave:** Problems/solutions, trade-offs, insights
   - **Feature memory** (`condensed memory/features/{feature}.md`) — crosses repositories:
     - 🔀 **Fluxo Ponta a Ponta:** Complete sequence crossing services/repos
     - 🤝 **Contratos entre Serviços:** What each side sends/consumes
     - 📐 **Regras de Negócio:** Specific rules and validations of the feature
     - ⚠️ **Edge Cases:** Intermittencies, known problems and solutions
   - **Tie-break:** does this knowledge help someone working in another repo of the same feature? → feature
7. Updates the target memory file(s) with the structured, emoji-categorized format
8. Marks processed cards:
   ```markdown
   ---
   > ✅ Conhecimento consolidado em condensed memory (projects/{projeto}.md e/ou features/{feature}.md) em YYYY-MM-DD
   ```

**Key Principles:**
- **Two-Axis Routing:** Classify each item as project OR feature before writing
- **Deduplicate:** If 3 cards mention git, consolidate into one section
- **Highlight Decisions:** Always use `**Decisão:**` or `**Rationale:**`
- **Be Compact:** Group related info, avoid verbosity
- **Source Once:** List processed cards in header, not per item

---

### `/init`
Analyzes codebase and creates CLAUDE.md file (standard onboarding command).

**Actions:**
- Explores repository structure
- Identifies key patterns and architecture
- Creates comprehensive CLAUDE.md documentation
- Focuses on "big picture" requiring multi-file understanding

---

## Environment Setup

### Required Environment Variable

Add to your shell config (`~/.zshrc` or `~/.bashrc`):

```bash
export OBSIDIAN_VAULT_PATH="/Users/leandrocoutomessias/workspace/obisidian/leanddro"
```

Verify:
```bash
echo $OBSIDIAN_VAULT_PATH
```

### Command Installation

Commands are defined in `commands/*.md` and synced to `~/.claude/commands/` via:

```bash
./sync-commands.sh
```

This script:
- Copies all `commands/*.md` to `~/.claude/commands/`
- Makes them available as slash commands globally in Claude Code
- Generates VS Code skills in `~/.agent_obsidian/skills/` (structure below)

Verify installation:
```bash
ls ~/.claude/commands/
```

Should show: `board-status.md`, `start-card.md`, `work-on-card.md`, `review-card.md`, `complete-card.md`, `load-context.md`, `update-card.md`, `refine-card.md`, `condense-memory.md`

### VS Code Skills Installation

Skills are installed in `~/.agent_obsidian/skills/` with the correct VS Code structure:

```
~/.agent_obsidian/skills/
├── board-status/
│   └── SKILL.md
├── start-card/
│   └── SKILL.md
├── work-on-card/
│   └── SKILL.md
└── ...
```

**Important:** Each skill must be in its own folder with a `SKILL.md` file. The `SKILL.md` must start with YAML frontmatter where `name` is **exactly equal to the folder name** (lowercase with hyphens/numbers):

```yaml
---
name: start-card
description: Skill do Agent Obsidian para gerenciar o board Kanban em Obsidian.
---
```

If the `name` doesn't match the folder name, VS Code may silently ignore the skill.

The `sync-commands.sh` script automatically generates these skills from `commands/*.md`.

### Git & GitHub CLI

Required tools:
- Git (version control)
- `gh` (GitHub CLI) - for automatic PR creation in `/review-card`

Install gh:
```bash
brew install gh
gh auth login
```

## Code Guidelines

All code written by `/work-on-card` follows principles in `code guidelines.md`:

**Core Principles:**
- SOLID principles
- DRY (Don't Repeat Yourself)
- KISS (Keep It Simple, Stupid)
- Clear, descriptive naming
- Small, focused functions
- Proper error handling
- Tests when necessary
- Lint before finishing

Commands automatically load and apply these guidelines when writing code.

## Integration with Git

### Branch Management

- `/start-card` creates branch: `feature/card-name`
- Branch name stored in card frontmatter
- `/review-card` validates branch, creates commit, pushes
- `/complete-card` assumes PR merged (doesn't delete branch)

### Commit Strategy

- `/work-on-card` can make incremental commits as tasks complete
- `/review-card` creates final commit with meaningful message from card context
- Follows conventional commits: `feat:`, `fix:`, `refactor:`, etc.

### PR Creation Intelligence

`/review-card` generates PR descriptions by:
1. Analyzing commit history since base branch
2. Reading card description and tasks
3. Detecting and filling PR templates
4. Grouping related changes
5. Highlighting business and technical impact
6. Suggesting test steps based on changes

## Best Practices

### Starting a New Task

1. Create card in Obsidian vault `board/1.not_started/`
2. If vague, run `/refine-card` to clarify before starting
3. Run `/start-card` in your project directory
4. Use `/work-on-card` to execute tasks
5. Update discussions with `/update-card` as you make decisions

### During Development

- Keep card updated with decisions in "Discussões"
- Mark tasks as complete as you finish them
- Document technical details in "Descrição Técnica"
- Document learnings in "Conhecimento Adquirido"
- Use `/load-context` if you lose track or switch contexts

### Before Review

- Ensure all tasks marked `- [x]`
- Fill "Descrição Técnica" and "Conhecimento Adquirido"
- Run `/review-card` to create PR

### After PR Merged

- Run `/complete-card`
- Knowledge automatically consolidated for future use

### Multiple Projects

Each project has its own:
- `.agent_obsidian` (independent state)
- Project memory file (`condensed memory/projects/{projeto}.md`)
- Active card (one per project)

Feature memory (`condensed memory/features/{feature}.md`) is **shared across projects** — a feature spanning multiple repos consolidates its knowledge in one file, accessible from any project.

Switch between projects by just `cd`-ing - commands adapt automatically.

## Advanced Topics

### Handling Dependencies Between Cards

Reference cards in "Dependências" section:
```markdown
## Dependências
- [[authentication-card]] - Provides user auth system
- [[database-migration-card]] - Creates required tables
```

`/work-on-card` and `/load-context` automatically load these cards for context.

### Knowledge Retention

The system builds knowledge over time:
1. **Per Card:** "Conhecimento Adquirido" section
2. **Per Project:** `condensed memory/projects/{projeto}.md` (project memory)
3. **Per Feature:** `condensed memory/features/{feature}.md` (feature memory, crosses repos)
4. **Code Guidelines:** Shared standards across all projects

This creates a feedback loop:
- New task → Load condensed memory (both axes)
- Complete task → Document learnings
- Finalize card → Consolidate into condensed memory (routed to project and/or feature)
- Future tasks → Benefit from past learnings

### Refinement Workflow for Vague Cards

New cards often lack detail. Use `/refine-card` to:
1. Load all context (code, guidelines, condensed memory)
2. Analyze actual code (not assumptions)
3. Generate specific technical questions
4. Converse with user to resolve ambiguity
5. Transform generic tasks into specific actions
6. Update card in real-time during conversation

Run multiple times for deeper analysis (macro view, edge cases, challenge assumptions).

### State Recovery

If `.agent_obsidian` is lost or corrupted:
- Any command will recreate it with defaults
- You'll need to manually specify card names until you start/resume a card
- No data loss - cards are in centralized vault

If you're unsure which card you were working on:
```
/board-status
# Look in 2.in_progress/ for your project's cards
```

## Troubleshooting

### Commands not found
- Check `~/.claude/commands/` exists and contains .md files
- Run `./sync-commands.sh` from vault directory

### $OBSIDIAN_VAULT_PATH not set
- Add to shell config and `source` it
- Or set temporarily: `export OBSIDIAN_VAULT_PATH="/path/to/vault"`

### Card not found
- Use `/board-status` to see available cards
- Check spelling (case-sensitive)
- Ensure card is in expected folder for the command

### .agent_obsidian issues
- Commands will auto-recreate if missing
- Check `.gitignore` includes `.agent_obsidian`
- If corrupted, delete and let it regenerate

### PR creation fails
- Ensure `gh` is installed: `brew install gh`
- Authenticate: `gh auth login`
- Check remote exists: `git remote -v`

## File Structure Reference

```
/Users/leandrocoutomessias/workspace/obisidian/leanddro/
├── board/
│   ├── 1.not_started/        # New cards
│   ├── 2.in_progress/        # Active cards
│   ├── 3.in_review/          # Cards in PR review
│   ├── 4.done/               # Completed cards (source for memory)
│   └── 5.archived/           # Old/cancelled cards
├── commands/                 # Slash command definitions (sync to ~/.claude/commands/)
│   ├── board-status.md
│   ├── start-card.md
│   ├── work-on-card.md
│   ├── refine-card.md
│   ├── update-card.md
│   ├── review-card.md
│   ├── complete-card.md
│   ├── load-context.md
│   └── condense-memory.md
├── condensed memory/         # Knowledge bases in two axes
│   ├── projects/             # Per-repository memory (stable, transversal)
│   │   ├── agent_obsidian.md
│   │   ├── {project1}.md
│   │   └── {project2}.md
│   └── features/             # Per-feature memory (crosses repositories)
│       ├── analise-pix-in.md
│       └── analise-boleto-out.md
├── templates/
│   └── card template.md      # Template for new cards
├── scripts/
│   ├── list_prs.rb          # List PRs
│   └── list_merged_prs.rb   # List merged PRs
├── code guidelines.md        # Development standards
├── sync-commands.sh          # Sync commands to ~/.claude/commands/
├── SETUP.md                  # Setup instructions
└── CLAUDE.md                 # This file
```

## Summary

**Agent Obsidian** is a task management system that:
- Uses Obsidian as a Kanban board (folders = states)
- Integrates with Claude Code via custom slash commands
- Tracks state per project via `.agent_obsidian` files
- Consolidates knowledge per project and per feature via condensed memory (two-axis model)
- Automates git workflow (branches, commits, PRs)
- Builds long-term memory through completed cards
- Enables AI to work on tasks with full context and standards

The system is designed for **zero configuration** (auto-creates state), **multi-project support** (independent states), and **knowledge retention** (past learnings inform future work).
