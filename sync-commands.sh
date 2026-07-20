#!/bin/bash

# Script para sincronizar comandos do board Kanban para ~/.claude/commands
# Uso: ./sync-commands.sh

set -e

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/commands"
TARGET_DIR="$HOME/.claude/commands"

echo "🔄 Sincronizando comandos do board Kanban..."
echo ""
echo "📂 Origem: $SOURCE_DIR"
echo "📂 Destino: $TARGET_DIR"
echo ""

# Criar diretório de destino se não existir
mkdir -p "$TARGET_DIR"

# Contar arquivos
total_files=$(find "$SOURCE_DIR" -name "*.md" | wc -l | tr -d ' ')
echo "📋 Encontrados $total_files comandos para sincronizar"
echo ""

# Copiar cada arquivo .md
copied=0
updated=0
for file in "$SOURCE_DIR"/*.md; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        target_file="$TARGET_DIR/$filename"

        if [ -f "$target_file" ]; then
            # Arquivo existe, verificar se é diferente
            if ! cmp -s "$file" "$target_file"; then
                cp "$file" "$target_file"
                echo "  ✅ Atualizado: $filename"
                ((updated++))
            fi
        else
            # Arquivo novo
            cp "$file" "$target_file"
            echo "  ✨ Novo: $filename"
            ((copied++))
        fi
    fi
done

echo ""
echo "✅ Sincronização concluída!"
echo ""
echo "📊 Resumo:"
echo "  - Novos comandos: $copied"
echo "  - Comandos atualizados: $updated"
echo "  - Total de comandos: $total_files"
echo ""
echo "💡 Os comandos estão prontos para uso no Claude Code!"
echo "   Exemplos: /start-card, /work-on-card, /create-card, etc."
