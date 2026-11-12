#!/bin/bash

# Script para sincronizar comandos do board Kanban para Claude Code e Gemini CLI
# Uso: ./sync-commands.sh [claude|gemini|vscode|all]

set -e

# Configurações
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commands"
CLAUDE_TARGET_DIR="$HOME/.claude/commands"
GEMINI_TARGET_DIR="$HOME/.gemini/commands"
SKILLS_TARGET_DIR="$HOME/.copilot/skills"
LEGACY_SKILLS_DIR="$HOME/.agent_obsidian/skills"
TARGET_AI="${1:-all}" # claude, gemini, ou all (padrão)

# Função de ajuda
show_help() {
    echo "Uso: ./sync-commands.sh [opção]"
    echo ""
    echo "Opções:"
    echo "  claude    Sincroniza apenas comandos para o Claude Code (.md)"
    echo "  gemini    Sincroniza apenas comandos para o Gemini CLI (.toml)"
    echo "  vscode    Sincroniza apenas skills para o VS Code Copilot"
    echo "  all       Sincroniza para Claude Code, Gemini CLI e VS Code (padrão)"
    echo "  help      Mostra esta mensagem de ajuda"
    echo ""
}

if [ "$TARGET_AI" == "help" ] || [ "$TARGET_AI" == "--help" ] || [ "$TARGET_AI" == "-h" ]; then
    show_help
    exit 0
fi

# Validação do argumento
if [[ ! "$TARGET_AI" =~ ^(claude|gemini|vscode|all)$ ]]; then
    echo "❌ Erro: Opção inválida '$TARGET_AI'"
    show_help
    exit 1
fi

echo "🔄 Sincronizando comandos do board Kanban (Alvo: $TARGET_AI)..."
echo ""
echo "📂 Origem: $SOURCE_DIR"
[ "$TARGET_AI" != "gemini" ] && [ "$TARGET_AI" != "vscode" ] && echo "📂 Destino Claude: $CLAUDE_TARGET_DIR"
[ "$TARGET_AI" != "claude" ] && [ "$TARGET_AI" != "vscode" ] && echo "📂 Destino Gemini: $GEMINI_TARGET_DIR"
echo ""

# Criar diretórios de destino se não existirem
[ "$TARGET_AI" != "gemini" ] && [ "$TARGET_AI" != "vscode" ] && mkdir -p "$CLAUDE_TARGET_DIR"
[ "$TARGET_AI" != "claude" ] && [ "$TARGET_AI" != "vscode" ] && mkdir -p "$GEMINI_TARGET_DIR"
mkdir -p "$SKILLS_TARGET_DIR"

# Contar arquivos
total_files=$(find "$SOURCE_DIR" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
echo "📋 Encontrados $total_files comandos para processar"
echo ""

# Função para converter MD para TOML (formato Gemini)
# Idempotente: escreve em arquivo temporário e só substitui se o conteúdo mudou.
convert_to_toml() {
    local input_file="$1"
    local output_file="$2"
    local filename=$(basename "$input_file" .md)
    local tmp_file="${output_file}.tmp"

    # Extrai descrição (primeira linha limpa)
    local description=$(head -n 1 "$input_file" | sed -E 's/^# //; s/^Você é um assistente que //; s/\.$//; s/"/\\"/g')
    [ -z "$description" ] && description="$filename"

    # Cria o arquivo TOML temporário
    echo "description = \"$description\"" > "$tmp_file"
    echo "prompt = \"\"\"" >> "$tmp_file"
    # Escapa backslashes e aspas triplas
    sed 's/\\/\\\\/g; s/"""/\\"\\"\\"/g' "$input_file" >> "$tmp_file"
    echo "\"\"\"" >> "$tmp_file"

    # Só substitui se o conteúdo mudou
    if [ -f "$output_file" ] && cmp -s "$tmp_file" "$output_file"; then
        rm -f "$tmp_file"
        return 1  # inalterado
    fi
    mv -f "$tmp_file" "$output_file"
    return 0  # atualizado
}

# Função para converter MD para SKILL.md (formato VS Code)
# Estrutura esperada:
#   skills/
#   ├── skill1/
#   │   └── SKILL.md
# Cada SKILL.md precisa de frontmatter YAML com `name` (lowercase, hífens/números)
# exatamente igual ao nome da pasta.
# Idempotente: escreve em arquivo temporário e só substitui se o conteúdo mudou.
convert_to_skill() {
    local input_file="$1"
    local output_file="$2"
    local skill_name="$3"
    local tmp_file="${output_file}.tmp"

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
    } > "$tmp_file"

    # Só substitui se o conteúdo mudou
    if [ -f "$output_file" ] && cmp -s "$tmp_file" "$output_file"; then
        rm -f "$tmp_file"
        return 1  # inalterado
    fi
    mv -f "$tmp_file" "$output_file"
    return 0  # atualizado
}

# Verifica se a skill gerada está no formato que o VS Code descobre:
# pasta, SKILL.md e frontmatter com `name` igual ao nome da pasta.
# Fora desse formato o VS Code ignora a skill sem avisar.
assert_skill_valid() {
    local skill_name="$1"
    local skill_file="$SKILLS_TARGET_DIR/$skill_name/SKILL.md"

    [ -f "$skill_file" ] || return 1
    head -n 3 "$skill_file" | grep -qx "name: $skill_name"
}

# Função para sincronizar a pasta lib/ (common.sh) para um destino
sync_lib() {
    local src_lib="$SOURCE_DIR/lib"
    local dst_lib="$1"

    if [ -d "$src_lib" ]; then
        mkdir -p "$dst_lib"
        for lib_file in "$src_lib"/*; do
            if [ -f "$lib_file" ]; then
                local lib_name=$(basename "$lib_file")
                local dst_file="$dst_lib/$lib_name"
                if [ -f "$dst_file" ] && cmp -s "$lib_file" "$dst_file"; then
                    continue  # inalterado
                fi
                cp "$lib_file" "$dst_file"
                synced_lib=$((synced_lib + 1))
            fi
        done
    fi
}

synced_claude=0
synced_gemini=0
synced_skills=0
synced_lib=0
generated_skills=()

for file in "$SOURCE_DIR"/*.md; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        base_name="${filename%.md}"

        # --- Claude Sync (.md) ---
        if [ "$TARGET_AI" != "gemini" ] && [ "$TARGET_AI" != "vscode" ]; then
            target_claude="$CLAUDE_TARGET_DIR/$filename"
            if [ -f "$target_claude" ]; then
                if ! cmp -s "$file" "$target_claude"; then
                    cp "$file" "$target_claude"
                    synced_claude=$((synced_claude + 1))
                fi
            else
                cp "$file" "$target_claude"
                synced_claude=$((synced_claude + 1))
            fi
        fi

        # --- Gemini Sync (.toml) ---
        if [ "$TARGET_AI" != "claude" ] && [ "$TARGET_AI" != "vscode" ]; then
            target_gemini="$GEMINI_TARGET_DIR/$base_name.toml"
            if convert_to_toml "$file" "$target_gemini"; then
                synced_gemini=$((synced_gemini + 1))
            fi
        fi

        # --- VS Code Skills Sync (SKILL.md) ---
        # Validar nome da skill (lowercase, hífens/números)
        if [[ "$base_name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
            skill_dir="$SKILLS_TARGET_DIR/$base_name"
            skill_file="$skill_dir/SKILL.md"
            mkdir -p "$skill_dir"
            if convert_to_skill "$file" "$skill_file" "$base_name"; then
                synced_skills=$((synced_skills + 1))
            fi
            generated_skills+=("$base_name")
        fi

        echo "  ✅ Processado: $base_name"
    fi
done

# --- Sincronizar lib/ (common.sh) para destinos ---
if [ "$TARGET_AI" != "gemini" ] && [ "$TARGET_AI" != "vscode" ]; then
    sync_lib "$CLAUDE_TARGET_DIR/lib"
fi
sync_lib "$SKILLS_TARGET_DIR/lib"

invalid_skills=()
for skill_name in "${generated_skills[@]}"; do
    assert_skill_valid "$skill_name" || invalid_skills+=("$skill_name")
done

echo ""
echo "✅ Sincronização concluída!"
echo ""
echo "📊 Resumo:"
[ "$TARGET_AI" != "gemini" ] && [ "$TARGET_AI" != "vscode" ] && echo "  - Claude Code: $synced_claude arquivos atualizados/copiados"
[ "$TARGET_AI" != "claude" ] && [ "$TARGET_AI" != "vscode" ] && echo "  - Gemini CLI: $synced_gemini arquivos (.toml) gerados"
echo "  - VS Code Skills: $synced_skills skills (SKILL.md) geradas em $SKILLS_TARGET_DIR"
echo "  - lib/ (common.sh) sincronizados: $synced_lib"
echo ""
echo "💡 Comandos prontos!"
[ "$TARGET_AI" != "gemini" ] && [ "$TARGET_AI" != "vscode" ] && echo "   Claude: Use /start-card, /work-on-card, etc."
[ "$TARGET_AI" != "claude" ] && [ "$TARGET_AI" != "vscode" ] && echo "   Gemini: Use /start-card, /work-on-card, etc. (Dica: /commands reload)"
echo "   VS Code Copilot: Skills disponíveis em ~/.copilot/skills/"
echo ""

if [ -d "$LEGACY_SKILLS_DIR" ]; then
    echo "⚠️  $LEGACY_SKILLS_DIR existe e não é lido pelo VS Code Copilot — remova para não manter cópia divergente."
    echo ""
fi

if [ ${#invalid_skills[@]} -gt 0 ]; then
    echo "❌ Skills fora do formato que o VS Code descobre (name diferente da pasta ou SKILL.md ausente):"
    printf '   - %s\n' "${invalid_skills[@]}"
    exit 1
fi
