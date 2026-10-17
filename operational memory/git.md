# Operacional — git

> Formato, escala de confiança e poda: `operational memory/README.md`. Teto: ~40 linhas.

### git-mv-com-whitelist-de-gitignore

**Situação:** mover arquivo com `git mv` num repo cujo `.gitignore` começa com `*` e lista un-ignores explícitos.
**Padrão:** `git mv origem destino` → o destino cai no ignore e o arquivo sai do versionamento sem aviso.
**Falhou porque:** a regra de ignore é avaliada no caminho novo; pasta não listada na whitelist fica ignorada.
**Alternativa:** ajustar o `.gitignore` primeiro, rodar `git mv` e confirmar com `git check-ignore -v`.
**Evidência:** `git check-ignore -v` sem saída para o caminho novo; `git status` mostra o rename.
**Confiança:** verificado
**Escopo:** repo com whitelist de `.gitignore`. Ignore global e `.git/info/exclude` não são afetados.
**Validado em:** 2026-10-11 · git 2.43 · Windows
**Origem:** `condensed memory (pré-migração)`
