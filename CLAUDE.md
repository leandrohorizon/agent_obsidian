# Agent Obsidian - Task Management System

This repository implements a comprehensive task management system that integrates Obsidian with Claude Code through custom slash commands, enabling AI-assisted project management with knowledge consolidation.

## Architecture Overview

### Multi-Project State Management

This system uses a **distributed state architecture** with centralized knowledge:

```
~/workspace/
├── obsidian/user/              # Centralized vault (this repo)
│   ├── board/                    # Kanban board (all projects)
│   ├── condensed memory/         # Knowledge bases in three axes
│   │   ├── README.md             # Format spec (versioned)
│   │   ├── projects/             # Per-repository memory (.gitkeep)
│   │   ├── features/             # Per-feature memory (.gitkeep)
│   │   └── operational/          # Execution memory (.gitkeep)
│   ├── commands/                 # Slash command definitions
│   ├── guidelines/               # Agent directives (all files loaded)
│   │   ├── conduct.md            # Agent behavior rules (precedence)
│   │   ├── code guidelines.md    # Development standards
│   │   ├── IA best practices.md  # AI context and tooling practices
│   │   └── card work types.md
│   └── docs/                     # Project documentation (PDFs, specs)
│
├── project-example/           # Project 1
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
  "vault_path": "/Users/user/workspace/obsidian/user",
  "guidelines_path": "/Users/user/workspace/obsidian/user/guidelines",
  "condensed_memory_path": "/Users/user/workspace/obsidian/user/condensed memory/projects/agent_obsidian.md",
  "current_card": {
    "name": "card-name",
    "path": "/absolute/path/to/board/2.in_progress/card.md"
  }
}
```

**Version 2.0 (two-axis model):**
- `guidelines_path` points to the **folder** `guidelines/`, not to individual files — commands list the folder and read every file in it, so a new directive file is picked up without touching state
- `condensed_memory_path` points to `condensed memory/projects/{projeto}.md`
- The feature memory path is NOT stored in state — it's derived from the card's `feature:` field at load time via `get_feature_memory_path()`
- Migration: if an existing valid state has `version` < 2.0, `validate_agent_state()` rewrites `condensed_memory_path` to the new layout (instead of keeping the old path)
- Migration: `validate_agent_state()` also rewrites `guidelines_path` to the canonical folder and drops the obsolete per-file keys (`code_guidelines_path`, `conduct_path`)

**Lifecycle:**
- Created automatically by any command if missing
- Updated when card starts (`/start-card`) - stores current_card
- Cleared when card completes (`/complete-card`) - sets current_card to null
- Preserved during review (`/review-card`) - card still active

**Benefits:**
- Commands work without arguments when card is active
- Direct path access eliminates file searches (performance optimization)
- No manual configuration needed
- Never committed: keeping it out of version control is a conduct rule, not a `.gitignore` entry

### Kanban Board Structure

Cards flow through states represented as folders:

```
board/
├── 0.backlog/        # Raw ideas - not refined or prioritized yet
├── 1.not_started/    # Refined cards waiting to start
├── 2.in_progress/    # Active work - one card per project typically
├── 3.in_review/      # Code review - PR created, awaiting approval
├── 4.done/           # Completed - source for condensed memory
└── 5.archived/       # Old or cancelled cards
```

**Card flow:** `0.backlog` (raw idea) → `/refine-card` → `1.not_started` (refined) → `/start-card` → `2.in_progress` → `/review-card` → `3.in_review` → `/complete-card` → `4.done`

Reports and investigations skip Git setup and review: `/start-card` moves them
to `2.in_progress`, then `/complete-card` moves them directly to `4.done`.
Experiments never run Git commands and follow the same direct completion path.

**Card Metadata (YAML Frontmatter):**
```yaml
---
repo: git@github.com:org/project.git
branch: feature/card-name
work_type: implementation
status: In Progress
created: 2026-01-15
started: 2026-01-16
reviewed: 2026-01-17  # Added when moved to review
completed: 2026-01-18  # Added when moved to done
pr_url: https://github.com/org/project/pull/123
pr_status: Merged
---
```

### Card Work Types

`work_type` accepts `implementation`, `report`, `investigation` or `experiment`.
A card without this field keeps the implementation workflow; an unknown value is
an explicit error with no side effects. Each type may run only the actions
listed in its allowlist in `guidelines/card work types.md`.

| Type | Git and code | Deliverable and completion |
|---|---|---|
| `implementation` | Existing branch, commit and PR flow | Code changes; finish through review and merge; memory consolidation remains automatic |
| `report` | No branch, commit or project-code changes | Required report in `docs/{project}/reports/` in the central vault; complete directly from `2.in_progress` to `4.done`; never consolidate memory |
| `investigation` | No branch, commit or project-code changes | Findings and references in the card; optional document in `docs/{project}/investigations/`; complete directly; ask before memory consolidation |
| `experiment` | Never run Git commands | Small tools in the current work folder; tests optional; complete directly; never consolidate memory |

`{project}` is the normalized project directory name. A discovery that requires
code creates a separate related `implementation` card. `3.in_review` and
`/orchestrate-cards` remain for implementation. The full contract is in
`guidelines/card work types.md`.
Experiment files remain in the current folder until manually removed.

### Card Structure

Every card follows this template. Dependencies are frontmatter properties
(`depends_on` / `dependents`), not sections; the sections below them are legacy
and still readable:

```markdown
---
depends_on:
  - "[[other-card-name]]"
dependents:
  - "[[card-that-depends-on-this]]"
---

## Descrição
Brief description of what needs to be done and why

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
│   ├── project-example.md
│   └── ecommerce.md
└── features/                    # Per-feature memory (crosses repositories)
    ├── feature-x.md
    ├── feature-y.md
    └── feature-z.md
```

**Two-Axis Model:**
- **Project memory** (`projects/{projeto}.md`) — what is stable and transversal to the repository: architecture, code conventions, tools, setup, stack gotchas. **No feature knowledge.**
- **Feature memory** (`features/{feature}.md`) — business rules, end-to-end flow, contracts between services, decisions and edge cases of that feature, **crossing repositories**.

A card declares its feature in the frontmatter (`feature: feature-x`) and `/condense-memory` **routes** each extracted piece of knowledge to the correct axis, instead of dumping everything into one file. This solves the case where a feature (e.g. feature-x) spans three repositories — the full-flow knowledge lives in a single feature file, accessible from any project.

**Format of the project memory file:**

> Canonical spec: `condensed memory/README.md`. It defines headers, categories,
> formatting rules and the border between the three memories. This block is a
> summary; on divergence, the spec wins.
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
cd ~/workspace/project-example

# 2. Start working on a card
/start-card "implement example task"
# → Creates .agent_obsidian in project root
# → Moves card: 1.not_started → 2.in_progress
# → Creates git branch: feature/implement-example-task
# → Stores current_card in .agent_obsidian

# 3. Work on the card (no argument needed - reads from .agent_obsidian)
/work-on-card
# → Loads card from current_card.path directly
# → Loads all files in guidelines/
# → Loads condensed memory/projects/project-example.md (project memory)
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
3. Finds card in `1.not_started/`
4. For implementation cards, detects base branch (`main`/`master`)
5. For implementation cards, **asks the user** whether to switch to the base branch before creating the card branch (skipped when already on the base)
6. For implementation cards, **always runs `git pull`** on the base branch — aborts if it fails
7. Creates git branch `feature/card-name` only for implementation; report and investigation do not use Git branches; experiment does not run Git commands
8. Updates card frontmatter (repo, branch, status, started date)
9. Moves card: `1.not_started/` → `2.in_progress/`
10. Updates `.agent_obsidian` with current_card

**Important:** This is the entry point that initializes state for a project.

---

### `/work-on-card [nome]`
Executes tasks in a card with full context.

**Arguments:**
- `[nome]`: Optional - card name. If omitted, uses `.agent_obsidian`

**Context Loaded:**
1. Card content (via direct path if from state)
2. All files in `guidelines/` - includes the conduct rules, which take precedence over any other instruction
3. `condensed memory/projects/{project}.md` - project memory (architecture, conventions, tools)
4. `condensed memory/features/{feature}.md` - feature memory (if card has `feature:` frontmatter)
5. Dependent cards referenced as `[[card-name]]`
6. `condensed memory/operational/*.md` - execution memory (loaded only by this
   command): entries with `Confiança: verificado` or `fato` are applied;
   `preferência` is consulted only.

**Actions:**
- Identifies pending tasks (`- [ ]`)
- Executes tasks following the guidelines
- **Operational fallback:** when the standard approach fails and an alternative
  works, records the entry in `condensed memory/operational/{area}.md` (fields per
  `condensed memory/README.md`), respecting the ~40-line ceiling per file
- Marks tasks complete (`- [x]`)
- Documents decisions in "Discussões" section
- Updates "Descrição Técnica" and "Conhecimento Adquirido"
- Makes incremental git commits only for implementation

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
2. All files in `guidelines/`
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
8. Updates card frontmatter (pr_url, reviewed date)
9. Moves card: `2.in_progress/` → `3.in_review/`
10. **Does NOT clear `.agent_obsidian`** - card still active during review

Only applies to implementation. Reports, investigations and experiments skip
`3.in_review` and go directly from `2.in_progress` to `/complete-card`.

---

### `/review-pr <pr>`
Reviews a **received** pull request using the vault guidelines and the project/feature memories, so every finding cites the rule behind it. Read-only analysis: nothing is published on GitHub and no card is moved.

**Arguments:**
- `<pr>`: Required - PR number or URL
- `[caminho-do-clone]`: Optional - local clone path when the repository is not in `~/workspace/{repo}`

**Actions:**
1. Reads the PR with `gh pr view` (state, head SHA, base branch, files, body)
2. Loads all files in `guidelines/` — they apply to any repository
3. Finds the PR's card by `pr_url` in the board and derives the feature memory from its `feature:`; continues without a card when none exists
4. Classifies the repository case: cloned with memory, cloned without memory, or not cloned
5. Enumerates changed files with `gh pr diff --name-only`, then reads each file's patch, skipping lockfiles, generated code and binaries
6. Reports findings with `file:line`, severity, cited rule, evidence and a falsification step
7. Keeps findings without a citable rule in a separate **suggestions** section (concrete alternative plus how to test, max 5)
8. Declares `Convenção do repositório: desconhecida` when the repository has no memory instead of assuming its standards
9. Proposes a new card for code work, **always asking before writing**; without a clone the card stays in `0.backlog` as a proposal
10. Documents the findings in the PR card's `### Discussões` without touching status or folder
11. Never publishes: no `gh pr review`, `gh pr comment` or review/comment API calls

**Verification cases:** one finding that cites the violated guideline section, and one PR without a card and without a clone that still completes.

---

### `/complete-card [nome]`
Finalizes a card; implementation cards follow merge, while reports, investigations and experiments can finish directly.

**Arguments:**
- `[nome]`: Optional - uses `.agent_obsidian` if omitted

**Actions:**
1. Finds implementation cards in `3.in_review/`; reports, investigations and experiments can be completed from `2.in_progress/`
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
4. Moves implementation `3.in_review/` cards and non-code `2.in_progress/` cards to `4.done/`
5. **Clears `.agent_obsidian`:** Sets `current_card: null`
6. For implementation, **returns to the default branch and deletes the card branch:**
   - Detects the default branch (`main`/`master`), preferring `main`
   - Guards against uncommitted changes before the checkout (stops and warns)
   - Runs `git checkout {default}` then `git pull` (aborts on failure)
   - Deletes the card branch with `git branch -d` — never `-D`; if git refuses because of unmerged commits, stops and reports
   - Does **not** delete the remote branch — only prints the cleanup command, since deleting a remote branch is destructive and requires an explicit request
7. Automatically consolidates implementation memory; never consolidates reports or experiments; asks before consolidating investigation findings

---

### `/load-context [nome]`
Loads complete context for a card, or for the project when there is no card (read-only).

**Arguments:**
- `[nome]`: Optional - uses `.agent_obsidian` if omitted; when the state has `current_card: null` the command runs in **project mode** instead of asking for a card name

**Project mode (no card):**
1. Reads `$OBSIDIAN_VAULT_PATH`; an existing `.agent_obsidian` is read-only (no `/init-agent-state`, no `validate_agent_state()` repair)
2. Loads all files in `guidelines/` and the project memory (`condensed_memory_path`, or derived from the normalized directory name via `/detect-project`)
3. Reads git state only: `git branch --show-current`, `git status --short`, `git log -1 --oneline`, plus ahead/behind from `git status -sb`
4. Lists this repository's cards in `2.in_progress/` and `3.in_review/`, matched by normalizing both the card's `repo:` and the remote to `owner/repo` (handles `https://…` and `git@…`), grouped by folder so the state stays visible
5. **Writes nothing:** no `git checkout`/`git pull`/`git fetch`, no `current_card`, nothing written to `.agent_obsidian`
6. Excludes feature memory (needs the card's `feature:`), operational memory (reserved to `/work-on-card` by `conduct.md`), cards outside the two active folders and branch diffs

**Work type deviations (card mode):** steps 7 and 8 (branch sync, branch diff analysis) run only for `implementation`; `report`, `investigation`, `experiment` and unknown values skip both, while the git state read in step 6 still happens.

**Actions (card mode):**
1. Reads card (via direct path if from state)
2. Loads all files in `guidelines/`
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
7. **Syncs branch and state:**
   - Compares current branch with the card's `branch:` frontmatter
   - If they diverge, **asks the user** before switching (numbered prompt)
   - Guards against uncommitted changes (stops and warns)
   - Runs `git checkout {branch-do-card}` then **always `git pull`** (aborts on failure)
   - Updates `.agent_obsidian` (`current_card` name/path, corrects moved cards)
8. Presents comprehensive summary:
   - Card state and location
   - Branch sync status and pull result
   - Pending tasks
   - Dependencies
   - Recent discussions
   - Git context
   - Branch modifications (commits, staged, unstaged)
   - Guidelines loaded (all files in `guidelines/`)
   - Condensed memory categories (project + feature)

**Use Cases:**
- Start new work session
- Start a session in a repository that has no active card (project mode)
- Resume after interruption
- Review before PR
- Resume a card that lives on another branch

---

### `/orchestrate-cards [filtro]`
Works on **all** cards in `1.not_started/` at once, one subagent per card, opening each PR as a **draft**.

Processes only implementation cards (including legacy cards without
`work_type`); reports, investigations and experiments are skipped and listed in the result.

**Arguments:**
- `[filtro]`: Optional - partial name or list of cards. If omitted, processes all cards in `1.not_started/`.

**Actions:**
1. Validates config and warns if a card is already active in `.agent_obsidian`
2. Lists target cards and **asks for confirmation** before starting
3. Detects dependencies between target cards and warns about parallel conflicts
4. Runs **one subagent per card (in parallel)**, each executing the full sequence:
   - `/start-card` → `/work-on-card` → `/review-card`
   - The PR is created **as draft** (`gh pr create --draft`)
5. Consolidates results (completed / blocked / failed) into a report
6. Does **not** merge or consolidate memory — that is `/complete-card`'s job after human review

**Use Cases:**
- Batch-process a backlog of ready cards
- Parallelize independent work across cards

---

### `/condense-memory [nome-do-card]`
Consolidates knowledge from completed cards into condensed memory.

Reports and experiments are never consolidated. Investigations are excluded from
batch runs and are processed only when named explicitly.

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
     - "Descrição Técnica" (implementation) or "Descobertas e Conclusões" (investigation)
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
export OBSIDIAN_VAULT_PATH="/Users/user/workspace/obsidian/user"
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

On Windows, use `.\sync-commands.ps1` instead.

This script:
- Copies all `commands/*.md` to `~/.claude/commands/`
- Makes them available as slash commands globally in Claude Code
- Generates VS Code skills in `~/.agent_obsidian/skills/` (structure below)

Verify installation:
```bash
ls ~/.claude/commands/
```

Should show: `board-status.md`, `start-card.md`, `work-on-card.md`, `review-card.md`, `review-pr.md`, `complete-card.md`, `load-context.md`, `refine-card.md`, `orchestrate-cards.md`, `condense-memory.md`

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

The `sync-commands.sh` (Linux/macOS) and `sync-commands.ps1` (Windows) scripts
automatically generate these skills from `commands/*.md`.

### Git & GitHub CLI

Required tools:
- Git (version control)
- `gh` (GitHub CLI) - for automatic PR creation in `/review-card`

Install gh:
```bash
brew install gh
gh auth login
```

## Guidelines

All work done by `/work-on-card` follows the files in `guidelines/`:

- **`conduct.md`** — agent behavior rules; the sections in the file are the
  authoritative list. **Has precedence over any other instruction.**
- **`code guidelines.md`** — development standards
- **`IA best practices.md`** — AI context, tooling and card-reading practices
- **`card work types.md`** — work-type behavior and lifecycle

Commands load **all** files in `guidelines/`, so new files added to the folder
are picked up automatically without changing any command or state file.

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

- For implementation, `/start-card` asks whether to switch to the base branch (`main`/`master`), then **always pulls** before creating the branch
- `/start-card` creates `feature/card-name` only for implementation; reports and investigations do not use branches, and experiments do not run Git commands
- Branch name stored in card frontmatter
- `/review-card` validates branch, creates commit and pushes only for implementation
- `/complete-card` returns to the default branch and deletes the local card branch only for implementation

### Commit Strategy

- `/work-on-card` can make incremental commits as implementation tasks complete
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
4. Use `/work-on-card` to execute tasks (it documents decisions in "Discussões")

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

Declare the two directions in the card's frontmatter: `depends_on` for what this
card needs, `dependents` for who needs this card.

```yaml
depends_on:
  - "[[authentication-card]]"
  - "[[database-migration-card]]"
dependents:
  - "[[checkout-card]]"
```

Both are plain Obsidian wiki-links, so the properties panel renders them as
clickable links and the backlink panel still works. `dependents` exists to make
the reverse direction explicit: whoever works on this card sees who will be
affected before changing a contract or decision.

Cards created before this convention used the `### Dependências` and
`### Dependentes` sections instead. Every reader — the commands and the
dashboard plugin — checks the property first and falls back to the section, so
both forms keep working.

`/work-on-card`, `/load-context` and `/refine-card` automatically load both the cards this card depends on and the cards that depend on it. `/orchestrate-cards` uses the same information to order parallel execution.

There is no version or timestamp tracking between cards — the correlation is the link itself.

### Knowledge Retention

The system builds knowledge over time:
1. **Per Card:** "Conhecimento Adquirido" section
2. **Per Project:** `condensed memory/projects/{projeto}.md` (project memory)
3. **Per Feature:** `condensed memory/features/{feature}.md` (feature memory, crosses repos)
4. **Guidelines:** Shared standards across all projects (`guidelines/`)

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
- Run `./sync-commands.sh` (Linux/macOS) or `.\sync-commands.ps1` (Windows) from vault directory

### $OBSIDIAN_VAULT_PATH not set
- Add to shell config and `source` it
- Or set temporarily: `export OBSIDIAN_VAULT_PATH="/path/to/vault"`

### Card not found
- Use `/board-status` to see available cards
- Check spelling (case-sensitive)
- Ensure card is in expected folder for the command

### .agent_obsidian issues
- Commands will auto-recreate if missing
- Never commit it — it holds machine-local state (see `guidelines/conduct.md`)
- If corrupted, delete and let it regenerate

### PR creation fails
- Ensure `gh` is installed: `brew install gh`
- Authenticate: `gh auth login`
- Check remote exists: `git remote -v`

## File Structure Reference

```
/Users/user/workspace/obsidian/user/
├── board/
│   ├── 0.backlog/            # Raw ideas (not refined/prioritized)
│   ├── 1.not_started/        # Refined cards waiting to start
│   ├── 2.in_progress/        # Active cards
│   ├── 3.in_review/          # Cards in PR review
│   ├── 4.done/               # Completed cards (source for memory)
│   └── 5.archived/           # Old/cancelled cards
├── commands/                 # Slash command definitions (sync to ~/.claude/commands/)
│   ├── board-status.md
│   ├── start-card.md
│   ├── work-on-card.md
│   ├── refine-card.md
│   ├── review-card.md
│   ├── review-pr.md
│   ├── complete-card.md
│   ├── load-context.md
│   ├── orchestrate-cards.md
│   └── condense-memory.md
├── condensed memory/         # Knowledge bases in three axes
│   ├── README.md             # Format spec for the three axes (versioned)
│   ├── projects/             # Per-repository memory (stable, transversal)
│   │   ├── .gitkeep
│   │   ├── agent_obsidian.md
│   │   ├── {project1}.md
│   │   └── {project2}.md
│   ├── features/             # Per-feature memory (crosses repositories)
│   │   ├── .gitkeep
│   │   ├── feature-x.md
│   │   └── feature-y.md
│   └── operational/          # Execution memory — loaded only by /work-on-card
│       ├── .gitkeep
│       └── {area}.md         # Local, not versioned — git, github, shell, vscode
├── templates/
│   └── card/
│       ├── implementation.md
│       ├── report.md
│       ├── investigation.md
│       └── experiment.md
├── guidelines/               # Agent directives (all files loaded)
│   ├── conduct.md            # Agent behavior rules (precedence)
│   ├── code guidelines.md    # Development standards
│   ├── IA best practices.md  # AI context and tooling practices
│   └── card work types.md
├── docs/                     # Project documentation (PDFs, specs)
├── sync-commands.sh          # Sync commands to ~/.claude/commands/ (Linux/macOS)
├── sync-commands.ps1         # Sync commands to ~/.claude/commands/ (Windows)
├── SETUP.md                  # Setup instructions
└── CLAUDE.md                 # This file
```

## Summary

**Agent Obsidian** is a task management system that:
- Uses Obsidian as a Kanban board (folders = states)
- Integrates with Claude Code via custom slash commands
- Tracks state per project via `.agent_obsidian` files
- Consolidates knowledge via condensed memory (three axes: project, feature, operational)
- Automates git workflow (branches, commits, PRs)
- Builds long-term memory through completed cards
- Enables AI to work on tasks with full context and standards

The system is designed for **zero configuration** (auto-creates state), **multi-project support** (independent states), and **knowledge retention** (past learnings inform future work).
