# sync-commands.ps1 - Sincroniza comandos do board Kanban para Claude Code e Gemini CLI
# Uso: .\sync-commands.ps1 [claude|gemini|vscode|all]

param (
    [Parameter(Position = 0)]
    [ValidateSet("claude", "gemini", "vscode", "all", "help")]
    [string]$TargetAI = "all"
)

# Configuracoes
$SourceDir = Join-Path $PSScriptRoot "commands"
$HomeDir = [System.Environment]::GetFolderPath("UserProfile")
$ClaudeTargetDir = Join-Path $HomeDir ".claude\commands"
$GeminiTargetDir = Join-Path $HomeDir ".gemini\commands"
$SkillsTargetDir = Join-Path $HomeDir ".copilot\skills"
$LegacySkillsDir = Join-Path $HomeDir ".agent_obsidian\skills"

# Funcao de ajuda
function Show-Help {
    Write-Host "Uso: .\sync-commands.ps1 [opcao]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Opcoes:"
    Write-Host "  claude    Sincroniza apenas comandos para o Claude Code (.md)"
    Write-Host "  gemini    Sincroniza apenas comandos para o Gemini CLI (.toml)"
    Write-Host "  vscode    Sincroniza apenas skills para o VS Code Copilot"
    Write-Host "  all       Sincroniza para Claude Code, Gemini CLI e VS Code (padrao)"
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
if ($TargetAI -ne "gemini" -and $TargetAI -ne "vscode") { Write-Host "Destino Claude: $ClaudeTargetDir" }
if ($TargetAI -ne "claude" -and $TargetAI -ne "vscode") { Write-Host "Destino Gemini: $GeminiTargetDir" }
Write-Host ""

# Criar diretorios de destino se nao existirem
if ($TargetAI -ne "gemini" -and $TargetAI -ne "vscode") {
    if (-not (Test-Path $ClaudeTargetDir)) { New-Item -ItemType Directory -Force -Path $ClaudeTargetDir | Out-Null }
}
if ($TargetAI -ne "claude" -and $TargetAI -ne "vscode") {
    if (-not (Test-Path $GeminiTargetDir)) { New-Item -ItemType Directory -Force -Path $GeminiTargetDir | Out-Null }
}
if (-not (Test-Path $SkillsTargetDir)) { New-Item -ItemType Directory -Force -Path $SkillsTargetDir | Out-Null }

# Funcao para converter MD para TOML (formato Gemini)
# Idempotente: escreve em arquivo temporario e so substitui se o conteudo mudou.
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
    $tmpFile = "$OutputFile.tmp"
    Set-Content -Path $tmpFile -Value $toml -Encoding UTF8

    # So substitui se o conteudo mudou
    if ((Test-Path $OutputFile) -and (Get-FileHash $tmpFile).Hash -eq (Get-FileHash $OutputFile).Hash) {
        Remove-Item -Path $tmpFile -Force
        return $false  # inalterado
    }
    Move-Item -Path $tmpFile -Destination $OutputFile -Force
    return $true  # atualizado
}

# Funcao para converter MD para SKILL.md (formato VS Code)
# Estrutura esperada:
#   skills/
#   ├── skill1/
#   │   └── SKILL.md
# Cada SKILL.md precisa de frontmatter YAML com `name` (lowercase, hifens/numeros)
# exatamente igual ao nome da pasta.
# Idempotente: escreve em arquivo temporario e so substitui se o conteudo mudou.
function Convert-ToSkill {
    param($InputFile, $OutputFile, $SkillName)

    # Ler conteudo original
    $originalContent = Get-Content -Path $InputFile -Raw -Encoding UTF8

    # Construir frontmatter YAML
    $description = "Skill do Agent Obsidian para gerenciar o board Kanban em Obsidian."
    $frontmatter = "---`nname: $SkillName`ndescription: $description`n---`n`n"

    # Combinar frontmatter + conteudo original
    $newContent = $frontmatter + $originalContent.TrimEnd() + "`n"

    # Escrever em arquivo temporario
    $tmpFile = "$OutputFile.tmp"
    [System.IO.File]::WriteAllText($tmpFile, $newContent, [System.Text.UTF8Encoding]::new($false))

    # So substitui se o conteudo mudou
    if ((Test-Path $OutputFile) -and (Get-FileHash $tmpFile).Hash -eq (Get-FileHash $OutputFile).Hash) {
        Remove-Item -Path $tmpFile -Force
        return $false  # inalterado
    }
    Move-Item -Path $tmpFile -Destination $OutputFile -Force
    return $true  # atualizado
}

# Verifica se a skill gerada esta no formato que o VS Code descobre:
# pasta, SKILL.md e frontmatter com `name` igual ao nome da pasta.
# Fora desse formato o VS Code ignora a skill sem avisar.
function Test-SkillValid {
    param($SkillName)

    $skillFile = Join-Path (Join-Path $SkillsTargetDir $SkillName) "SKILL.md"
    if (-not (Test-Path $skillFile)) { return $false }

    $lines = Get-Content -Path $skillFile -TotalCount 3 -Encoding UTF8
    return $lines -contains "name: $SkillName"
}

# Funcao para sincronizar a pasta lib/ (common.sh) para um destino
function Sync-Lib {
    param($DestinationLib)

    $srcLib = Join-Path $SourceDir "lib"
    if (Test-Path $srcLib) {
        New-Item -ItemType Directory -Force -Path $DestinationLib | Out-Null
        Get-ChildItem -Path $srcLib -File | ForEach-Object {
            $dstFile = Join-Path $DestinationLib $_.Name
            if ((Test-Path $dstFile) -and (Get-FileHash $_.FullName).Hash -eq (Get-FileHash $dstFile).Hash) {
                return  # inalterado
            }
            Copy-Item -Path $_.FullName -Destination $dstFile -Force
            $script:syncedLib++
        }
    }
}

$files = Get-ChildItem -Path $SourceDir -Filter "*.md"
Write-Host "Encontrados $($files.Count) comandos para processar" -ForegroundColor Cyan
Write-Host ""

$syncedClaude = 0
$syncedGemini = 0
$syncedSkills = 0
$syncedLib = 0
$generatedSkills = @()

foreach ($file in $files) {
    $baseName = $file.BaseName

    # --- Claude Sync (.md) ---
    if ($TargetAI -ne "gemini" -and $TargetAI -ne "vscode") {
        $targetPath = Join-Path $ClaudeTargetDir $file.Name
        if ((Test-Path $targetPath) -and (Get-FileHash $file.FullName).Hash -eq (Get-FileHash $targetPath).Hash) {
            # inalterado
        } else {
            Copy-Item -Path $file.FullName -Destination $targetPath -Force
            $syncedClaude++
        }
    }

    # --- Gemini Sync (.toml) ---
    if ($TargetAI -ne "claude" -and $TargetAI -ne "vscode") {
        $targetPath = Join-Path $GeminiTargetDir "$baseName.toml"
        if (Convert-MdToToml -InputFile $file.FullName -OutputFile $targetPath) {
            $syncedGemini++
        }
    }

    # --- VS Code Skills Sync (SKILL.md) ---
    # Validar nome da skill (lowercase, hifens/numeros)
    if ($baseName -match '^[a-z0-9]+(-[a-z0-9]+)*$') {
        $skillDir = Join-Path $SkillsTargetDir $baseName
        $skillFile = Join-Path $skillDir "SKILL.md"
        New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
        if (Convert-ToSkill -InputFile $file.FullName -OutputFile $skillFile -SkillName $baseName) {
            $syncedSkills++
        }
        $generatedSkills += $baseName
    }

    Write-Host "  OK: $baseName" -ForegroundColor Green
}

# --- Sincronizar lib/ (common.sh) para destinos ---
if ($TargetAI -ne "gemini" -and $TargetAI -ne "vscode") {
    Sync-Lib -DestinationLib (Join-Path $ClaudeTargetDir "lib")
}
Sync-Lib -DestinationLib (Join-Path $SkillsTargetDir "lib")

$invalidSkills = @($generatedSkills | Where-Object { -not (Test-SkillValid $_) })

Write-Host ""
Write-Host "Sincronizacao concluida!" -ForegroundColor Green
Write-Host ""
Write-Host "Resumo:"
if ($TargetAI -ne "gemini" -and $TargetAI -ne "vscode") { Write-Host "  - Claude Code: $syncedClaude arquivos atualizados/copiados" }
if ($TargetAI -ne "claude" -and $TargetAI -ne "vscode") { Write-Host "  - Gemini CLI: $syncedGemini arquivos (.toml) gerados" }
Write-Host "  - VS Code Skills: $syncedSkills skills (SKILL.md) geradas em $SkillsTargetDir"
Write-Host "  - lib/ (common.sh) sincronizados: $syncedLib"
Write-Host ""
Write-Host "Comandos prontos!"
if ($TargetAI -ne "gemini" -and $TargetAI -ne "vscode") { Write-Host "   Claude: Use /start-card, /work-on-card, etc." }
if ($TargetAI -ne "claude" -and $TargetAI -ne "vscode") { Write-Host "   Gemini: Use /start-card, /work-on-card, etc. (Dica: /commands reload)" }
Write-Host "   VS Code Copilot: Skills disponiveis em ~/.copilot/skills/"
Write-Host ""

if (Test-Path $LegacySkillsDir) {
    Write-Host "$LegacySkillsDir existe e nao e lido pelo VS Code Copilot - remova para nao manter copia divergente." -ForegroundColor Yellow
    Write-Host ""
}

if ($invalidSkills.Count -gt 0) {
    Write-Host "Skills fora do formato que o VS Code descobre (name diferente da pasta ou SKILL.md ausente):" -ForegroundColor Red
    $invalidSkills | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    exit 1
}
