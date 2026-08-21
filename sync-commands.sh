#!/bin/bash

# Script para sincronizar comandos do board Kanban para Claude Code e Gemini CLI
# Uso: ./sync-commands.sh [claude|gemini|all]

set -e

# Configurações
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commands"
CLAUDE_TARGET_DIR="$HOME/.claude/commands"
GEMINI_TARGET_DIR="$HOME/.gemini/commands"
SKILLS_TARGET_DIR="$HOME/.agent_obsidian/skills"
TARGET_AI="${1:-all}" # claude, gemini, ou all (padrão)

# Função de ajuda
show_help() {
    echo "Uso: ./sync-commands.sh [opção]"
    echo ""
    echo "Opções:"
    echo "  claude    Sincroniza apenas comandos para o Claude Code (.md)"
    echo "  gemini    Sincroniza apenas comandos para o Gemini CLI (.toml)"
    echo "  all       Sincroniza para ambas as plataformas (padrão)"
    echo "  help      Mostra esta mensagem de ajuda"
    echo ""
}

if [ "$TARGET_AI" == "help" ] || [ "$TARGET_AI" == "--help" ] || [ "$TARGET_AI" == "-h" ]; then
    show_help
    exit 0
fi

# Validação do argumento
if [[ ! "$TARGET_AI" =~ ^(claude|gemini|all)$ ]]; then
    echo "❌ Erro: Opção inválida '$TARGET_AI'"
    show_help
    exit 1
fi

echo "🔄 Sincronizando comandos do board Kanban (Alvo: $TARGET_AI)..."
echo ""
echo "📂 Origem: $SOURCE_DIR"
[ "$TARGET_AI" != "gemini" ] && echo "📂 Destino Claude: $CLAUDE_TARGET_DIR"
[ "$TARGET_AI" != "claude" ] && echo "📂 Destino Gemini: $GEMINI_TARGET_DIR"
echo ""

# Criar diretórios de destino se não existirem
[ "$TARGET_AI" != "gemini" ] && mkdir -p "$CLAUDE_TARGET_DIR"
[ "$TARGET_AI" != "claude" ] && mkdir -p "$GEMINI_TARGET_DIR"
mkdir -p "$SKILLS_TARGET_DIR"

# Contar arquivos
total_files=$(find "$SOURCE_DIR" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
echo "📋 Encontrados $total_files comandos para processar"
echo ""

# Função para converter MD para TOML (formato Gemini)
convert_to_toml() {
    local input_file="$1"
    local output_file="$2"
    local filename=$(basename "$input_file" .md)

    # Extrai descrição (primeira linha limpa)
    local description=$(head -n 1 "$input_file" | sed -E 's/^# //; s/^Você é um assistente que //; s/\.$//; s/"/\\"/g')
    [ -z "$description" ] && description="$filename"

    # Cria o arquivo TOML
    echo "description = \"$description\"" > "$output_file"
    echo "prompt = \"\"\"" >> "$output_file"
    # Escapa backslashes e aspas triplas
    sed 's/\\/\\\\/g; s/"""/\\"\\"\\"/g' "$input_file" >> "$output_file"
    echo "\"\"\"" >> "$output_file"
}

# Função para converter MD para SKILL.md (formato VS Code)
# Estrutura esperada:
#   skills/
#   ├── skill1/
#   │   └── SKILL.md
# Cada SKILL.md precisa de frontmatter YAML com `name` (lowercase, hífens/números)
# exatamente igual ao nome da pasta.
convert_to_skill() {
    local input_file="$1"
    local output_file="$2"
    local skill_name="$3"

    # Construir frontmatter YAML
    local description="Skill do Agent Obsidian para gerenciar o board Kanban em Obsidian."
    {
        echo "---"
        echo "name: $skill_name"
        echo "description: $description"
        echo "---"
        echo ""
        cat "$input_file"
        echo ""
    } > "$output_file"
}

synced_claude=0
synced_gemini=0
synced_skills=0

for file in "$SOURCE_DIR"/*.md; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        base_name="${filename%.md}"

        # --- Claude Sync (.md) ---
        if [ "$TARGET_AI" != "gemini" ]; then
            target_claude="$CLAUDE_TARGET_DIR/$filename"
            if [ -f "$target_claude" ]; then
                if ! cmp -s "$file" "$target_claude"; then
                    cp "$file" "$target_claude"
                    ((synced_claude++))
                fi
            else
                cp "$file" "$target_claude"
                ((synced_claude++))
            fi
        fi

        # --- Gemini Sync (.toml) ---
        if [ "$TARGET_AI" != "claude" ]; then
            target_gemini="$GEMINI_TARGET_DIR/$base_name.toml"
            # Sempre regeneramos o TOML para garantir consistência
            convert_to_toml "$file" "$target_gemini"
            ((synced_gemini++))
        fi

        # --- VS Code Skills Sync (SKILL.md) ---
        # Validar nome da skill (lowercase, hífens/números)
        if [[ "$base_name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
            skill_dir="$SKILLS_TARGET_DIR/$base_name"
            skill_file="$skill_dir/SKILL.md"
            mkdir -p "$skill_dir"
            convert_to_skill "$file" "$skill_file" "$base_name"
            ((synced_skills++))
        fi

        echo "  ✅ Processado: $base_name"
    fi
done

echo ""
echo "✅ Sincronização concluída!"
echo ""
echo "📊 Resumo:"
[ "$TARGET_AI" != "gemini" ] && echo "  - Claude Code: $synced_claude arquivos atualizados/copiados"
[ "$TARGET_AI" != "claude" ] && echo "  - Gemini CLI: $synced_gemini arquivos (.toml) gerados"
echo "  - VS Code Skills: $synced_skills skills (SKILL.md) geradas em $SKILLS_TARGET_DIR"
echo ""
echo "💡 Comandos prontos!"
[ "$TARGET_AI" != "gemini" ] && echo "   Claude: Use /start-card, /work-on-card, etc."
[ "$TARGET_AI" != "claude" ] && echo "   Gemini: Use /start-card, /work-on-card, etc. (Dica: /commands reload)"
echo "   VS Code: Skills disponíveis em ~/.agent_obsidian/skills/"
echo ""
