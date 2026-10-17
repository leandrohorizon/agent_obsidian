# Operacional — shell

> Formato, escala de confiança e poda: `operational memory/README.md`. Teto: ~40 linhas.

Nenhuma entrada registrada ainda.

### comparar-texto-acentuado-em-script-no-powershell

**Situação:** comparar strings acentuadas (`Situação`, `Confiança`) num script PowerShell, ou passá-las como argumento pela linha de comando.
**Padrão:** `Select-String`/`-contains` com o literal acentuado escrito no comando → todas as comparações falham, como se o arquivo não tivesse o campo, embora ele esteja lá.
**Falhou porque:** o texto acentuado atravessa a fronteira do processo com encoding diferente do arquivo, então o literal chega corrompido e nunca casa com o conteúdo UTF-8.
**Alternativa:** derivar os literais do próprio arquivo (ler com `-Encoding UTF8` e extrair por regex) e comparar contra esses valores, em vez de digitá-los no comando.
**Evidência:** validação de contrato acusou 4 campos "ausentes" num arquivo onde `Select-String` os encontrava; após extrair os rótulos do arquivo, as 4 entradas passaram.
**Confiança:** verificado
**Escopo:** PowerShell no Windows. Em bash/zsh com UTF-8 a fronteira de argumento não corrompe.
**Validado em:** 2026-10-17 · PowerShell 5.1 · Windows
**Origem:** [[memoria operacional da IA]]

### mojibake-no-console-nao-e-arquivo-corrompido

**Situação:** ler `Get-Content` de um `.md` acentuado e ver `Ã§`/`Ã£` na saída do console.
**Padrão:** concluir que o arquivo está corrompido e "consertar" os acentos.
**Falhou porque:** não falhou — é artefato de encoding do terminal. O arquivo é UTF-8 e está íntegro.
**Alternativa:** ler com `Get-Content -Encoding UTF8` ou pela ferramenta de leitura de arquivos; conferir antes de editar qualquer coisa.
**Evidência:** o mesmo arquivo exibe acentos corretos ao ser lido com `-Encoding UTF8`; `git diff` sem alteração espúria.
**Confiança:** verificado
**Escopo:** console do Windows (PowerShell/cmd). Em terminal configurado em UTF-8 não ocorre.
**Validado em:** 2026-10-17 · PowerShell 5.1 · Windows
**Origem:** `condensed memory (pré-migração)`
