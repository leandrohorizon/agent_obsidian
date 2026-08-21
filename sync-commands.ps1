# sync-commands.ps1 - Sincroniza comandos do board Kanban para Claude Code e Gemini CLI
# Uso: .\sync-commands.ps1 [claude|gemini|all]

param (
    [Parameter(Position = 0)]
    [ValidateSet("claude", "gemini", "all", "help")]
    [string]$TargetAI = "all"
)

# Configuracoes
$SourceDir = Join-Path $PSScriptRoot "commands"
$HomeDir = [System.Environment]::GetFolderPath("UserProfile")
$ClaudeTargetDir = Join-Path $HomeDir ".claude\commands"
$GeminiTargetDir = Join-Path $HomeDir ".gemini\commands"
$SkillsTargetDir = Join-Path $HomeDir ".agent_obsidian\skills"

# Funcao de ajuda
function Show-Help {
    Write-Host "Uso: .\sync-commands.ps1 [opcao]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Opcoes:"
    Write-Host "  claude    Sincroniza apenas comandos para o Claude Code (.md)"
    Write-Host "  gemini    Sincroniza apenas comandos para o Gemini CLI (.toml)"
    Write-Host "  all       Sincroniza para ambas as plataformas (padrao)"
    Write-Host "  help      Mostra esta mensagem de ajuda"
    Write-Host ""
}

if ($TargetAI -eq "help") {
    Show-Help
    exit
}

Write-Host "--- Sincronizando comandos do board Kanban (Alvo: $TargetAI) ---" -ForegroundColor Yellow
Write-Host ""
Write-Host "Origem: $SourceDir"
if ($TargetAI -ne "gemini") { Write-Host "Destino Claude: $ClaudeTargetDir" }
if ($TargetAI -ne "claude") { Write-Host "Destino Gemini: $GeminiTargetDir" }
Write-Host ""

# Criar diretorios de destino se nao existirem
if ($TargetAI -ne "gemini") {
    if (-not (Test-Path $ClaudeTargetDir)) { New-Item -ItemType Directory -Force -Path $ClaudeTargetDir | Out-Null }
}
if ($TargetAI -ne "claude") {
    if (-not (Test-Path $GeminiTargetDir)) { New-Item -ItemType Directory -Force -Path $GeminiTargetDir | Out-Null }
}
if (-not (Test-Path $SkillsTargetDir)) { New-Item -ItemType Directory -Force -Path $SkillsTargetDir | Out-Null }

# Funcao para converter MD para TOML (formato Gemini)
function Convert-MdToToml {
    param($InputFile, $OutputFile)

    $filename = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
    $lines = Get-Content $InputFile

    # Extrai descricao (primeira linha limpa)
    $firstLine = $lines[0]
    $description = $firstLine -replace '^# ', '' -replace '^Voce e um assistente que ', '' -replace '\.$', ''
    $description = $description.Replace('"', '\"')
    if ([string]::IsNullOrWhiteSpace($description)) { $description = $filename }

    # Prepara o conteudo escapando backslashes e aspas triplas
    $content = $lines -join "`n"
    $escapedContent = $content.Replace('\', '\\').Replace('"""', '\"\"\"')

    $toml = "description = `"$description`"`nprompt = `"`"`"`n$escapedContent`n`"`"`"`n"
    Set-Content -Path $OutputFile -Value $toml -Encoding UTF8
}

# Funcao para converter MD para SKILL.md (formato VS Code)
# Estrutura esperada:
#   skills/
#   ├── skill1/
#   │   └── SKILL.md
# Cada SKILL.md precisa de frontmatter YAML com `name` (lowercase, hifens/numeros)
# exatamente igual ao nome da pasta.
function Convert-ToSkill {
    param($InputFile, $OutputFile, $SkillName)

    # Ler conteudo original
    $originalContent = Get-Content -Path $InputFile -Raw -Encoding UTF8

    # Construir frontmatter YAML
    $description = "Skill do Agent Obsidian para gerenciar o board Kanban em Obsidian."
    $frontmatter = "---`nname: $SkillName`ndescription: $description`n---`n`n"

    # Combinar frontmatter + conteudo original
    $newContent = $frontmatter + $originalContent.TrimEnd() + "`n"

    # Escrever SKILL.md
    [System.IO.File]::WriteAllText($OutputFile, $newContent, [System.Text.UTF8Encoding]::new($false))
}

$files = Get-ChildItem -Path $SourceDir -Filter "*.md"
Write-Host "Encontrados $($files.Count) comandos para processar" -ForegroundColor Cyan
Write-Host ""

$syncedClaude = 0
$syncedGemini = 0
$syncedSkills = 0

foreach ($file in $files) {
    $baseName = $file.BaseName

    # --- Claude Sync (.md) ---
    if ($TargetAI -ne "gemini") {
        $targetPath = Join-Path $ClaudeTargetDir $file.Name
        Copy-Item -Path $file.FullName -Destination $targetPath -Force
        $syncedClaude++
    }

    # --- Gemini Sync (.toml) ---
    if ($TargetAI -ne "claude") {
        $targetPath = Join-Path $GeminiTargetDir "$baseName.toml"
        Convert-MdToToml -InputFile $file.FullName -OutputFile $targetPath
        $syncedGemini++
    }

    # --- VS Code Skills Sync (SKILL.md) ---
    # Validar nome da skill (lowercase, hifens/numeros)
    if ($baseName -match '^[a-z0-9]+(-[a-z0-9]+)*$') {
        $skillDir = Join-Path $SkillsTargetDir $baseName
        $skillFile = Join-Path $skillDir "SKILL.md"
        New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
        Convert-ToSkill -InputFile $file.FullName -OutputFile $skillFile -SkillName $baseName
        $syncedSkills++
    }

    Write-Host "  OK: $baseName" -ForegroundColor Green
}

Write-Host ""
Write-Host "Sincronizacao concluida!" -ForegroundColor Green
Write-Host ""
Write-Host "Resumo:"
if ($TargetAI -ne "gemini") { Write-Host "  - Claude Code: $syncedClaude arquivos atualizados/copiados" }
if ($TargetAI -ne "claude") { Write-Host "  - Gemini CLI: $syncedGemini arquivos (.toml) gerados" }
Write-Host "  - VS Code Skills: $syncedSkills skills (SKILL.md) geradas em $SkillsTargetDir"
Write-Host ""
Write-Host "Comandos prontos!"
if ($TargetAI -ne "gemini") { Write-Host "   Claude: Use /start-card, /work-on-card, etc." }
if ($TargetAI -ne "claude") { Write-Host "   Gemini: Use /start-card, /work-on-card, etc. (Dica: /commands reload)" }
Write-Host "   VS Code: Skills disponiveis em ~/.agent_obsidian/skills/"
Write-Host ""
