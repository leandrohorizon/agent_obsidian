#!/usr/bin/env bash

# common.sh - Funções bash reutilizáveis para comandos do Agent Obsidian
# Este arquivo contém funções auxiliares que eliminam duplicação entre comandos

set -euo pipefail

# ============================================================================
# validate_agent_state()
# ============================================================================
# Valida e cria o arquivo .agent_obsidian se necessário
#
# Comportamento:
# - Se .agent_obsidian não existe, cria com estrutura padrão
# - Se existe mas JSON inválido, recria
# - Se vault_path no JSON difere de $OBSIDIAN_VAULT_PATH, atualiza
# - Retorna 0 se sucesso, 1 se erro
#
# Requer: $OBSIDIAN_VAULT_PATH definido
# Output: JSON válido em .agent_obsidian
# ============================================================================
validate_agent_state() {
  local vault_path="${OBSIDIAN_VAULT_PATH:-}"

  if [[ -z "$vault_path" ]]; then
    echo "❌ OBSIDIAN_VAULT_PATH não está definido" >&2
    echo "Configure: export OBSIDIAN_VAULT_PATH=\"/caminho/para/vault\"" >&2
    return 1
  fi

  local agent_file=".agent_obsidian"
  local project_name
  project_name=$(pwd | xargs basename | tr '[:upper:]' '[:lower:]' | tr '-' '_' | tr ' ' '_')

  local code_guidelines_path="${vault_path}/code guidelines.md"
  local condensed_memory_path="${vault_path}/condensed memory/${project_name}/condensed memory.md"

  # Se arquivo não existe ou não é JSON válido, criar
  if [[ ! -f "$agent_file" ]] || ! jq empty "$agent_file" 2>/dev/null; then
    cat > "$agent_file" <<EOF
{
  "version": "1.0",
  "vault_path": "${vault_path}",
  "code_guidelines_path": "${code_guidelines_path}",
  "condensed_memory_path": "${condensed_memory_path}",
  "current_card": null
}
EOF
    echo "✅ .agent_obsidian criado" >&2
  fi

  # Adicionar .agent_obsidian ao .gitignore se não estiver lá
  if [[ -f ".gitignore" ]] && ! grep -q "^\.agent_obsidian$" ".gitignore"; then
    echo -e "\n# Agent state file (local to each project)\n.agent_obsidian" >> ".gitignore"
    echo "✅ .agent_obsidian adicionado ao .gitignore" >&2
  fi

  return 0
}

# ============================================================================
# parse_frontmatter()
# ============================================================================
# Extrai campos do frontmatter YAML de um arquivo markdown
#
# Args:
#   $1: Path do arquivo markdown
#   $2: Nome do campo a extrair
#
# Output: Valor do campo (stdout)
# Return: 0 se encontrado, 1 se não encontrado
#
# Exemplo:
#   branch=$(parse_frontmatter "card.md" "branch")
# ============================================================================
parse_frontmatter() {
  local file="$1"
  local field="$2"

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  # Extrai frontmatter (entre --- e ---)
  # Procura linha com "field: value"
  awk -v field="$field" '
    BEGIN { in_frontmatter=0; found=0 }
    /^---$/ {
      if (in_frontmatter == 0) {
        in_frontmatter=1
      } else {
        exit
      }
      next
    }
    in_frontmatter && $0 ~ "^" field ":" {
      sub("^" field ": *", "")
      print
      found=1
      exit
    }
    END { exit !found }
  ' "$file"
}

# ============================================================================
# update_frontmatter()
# ============================================================================
# Atualiza ou adiciona campo no frontmatter YAML
#
# Args:
#   $1: Path do arquivo markdown
#   $2: Nome do campo
#   $3: Novo valor
#
# Comportamento:
# - Se frontmatter existe, atualiza campo (ou adiciona se não existir)
# - Se frontmatter não existe, cria no início do arquivo
#
# Return: 0 se sucesso, 1 se erro
# ============================================================================
update_frontmatter() {
  local file="$1"
  local field="$2"
  local value="$3"

  if [[ ! -f "$file" ]]; then
    echo "❌ Arquivo não encontrado: $file" >&2
    return 1
  fi

  local temp_file="${file}.tmp"

  # Verifica se tem frontmatter
  if head -n 1 "$file" | grep -q "^---$"; then
    # Tem frontmatter - atualiza ou adiciona campo
    awk -v field="$field" -v value="$value" '
      BEGIN { in_frontmatter=0; updated=0 }
      /^---$/ {
        if (in_frontmatter == 0) {
          print
          in_frontmatter=1
        } else {
          if (!updated) {
            print field ": " value
          }
          print
          in_frontmatter=2
        }
        next
      }
      in_frontmatter == 1 && $0 ~ "^" field ":" {
        print field ": " value
        updated=1
        next
      }
      { print }
    ' "$file" > "$temp_file"
  else
    # Não tem frontmatter - criar
    {
      echo "---"
      echo "$field: $value"
      echo "---"
      echo ""
      cat "$file"
    } > "$temp_file"
  fi

  mv "$temp_file" "$file"
  return 0
}

# ============================================================================
# get_git_info()
# ============================================================================
# Retorna informações do repositório git em formato JSON
#
# Output: JSON com campos repo, branch, remote
# Return: 0 se sucesso, 1 se não é repositório git
#
# Exemplo output:
# {
#   "repo": "git@github.com:user/repo.git",
#   "branch": "main",
#   "remote": "origin"
# }
# ============================================================================
get_git_info() {
  if ! git rev-parse --git-dir &>/dev/null; then
    echo "❌ Não é um repositório git" >&2
    return 1
  fi

  local repo
  local branch
  local remote="origin"

  repo=$(git remote get-url origin 2>/dev/null || echo "Local (sem remote configurado)")
  branch=$(git branch --show-current 2>/dev/null || echo "unknown")

  cat <<EOF
{
  "repo": "${repo}",
  "branch": "${branch}",
  "remote": "${remote}"
}
EOF

  return 0
}

# ============================================================================
# Exports para uso em scripts
# ============================================================================
export -f validate_agent_state
export -f parse_frontmatter
export -f update_frontmatter
export -f get_git_info
