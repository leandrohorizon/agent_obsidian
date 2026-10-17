# Operacional — vscode

> Formato, escala de confiança e poda: `operational memory/README.md`. Teto: ~40 linhas.

### skills-do-vscode-copilot-vem-de-copilot-skills

**Situação:** alterar um comando em `commands/` e esperar que a mudança valha na sessão do VS Code Copilot.
**Padrão:** rodar `sync-commands.ps1` e assumir que a skill foi atualizada.
**Falhou porque:** o sync escreve em `~/.agent_obsidian/skills/`, mas o Copilot carrega de `~/.copilot/skills/` quando `chat.agentSkillsLocations` não está configurado. As pastas divergem em silêncio.
**Alternativa:** configurar `"chat.agentSkillsLocations": ["${userHome}/.agent_obsidian/skills"]` e aposentar `~/.copilot/skills`.
**Evidência:** `chat.agentSkillsLocations` ausente em `%APPDATA%\Code\User\settings.json` e em `.vscode/settings.json`; `start-card/SKILL.md` com 26/09 em `.copilot` contra 11/10 em `.agent_obsidian`.
**Confiança:** fato — a observação é direta; a eficácia da correção não foi verificada.
**Escopo:** VS Code Copilot com skills locais. Não se aplica a Claude Code nem Gemini CLI, cujos alvos o sync já cobre.
**Validado em:** 2026-10-17 · VS Code 1.x · Windows
**Origem:** [[memoria operacional da IA]]