# Operacional — github

> Formato, escala de confiança e poda: `operational memory/README.md`. Teto: ~40 linhas.

### github-mergeable-e-cache-nao-veredito

**Situação:** checar a mergeability de um PR pela API do GitHub logo após um push.
**Padrão:** ler `mergeable: CONFLICTING` e tratar como conflito real.
**Falhou porque:** o GitHub recalcula a mergeability de forma assíncrona; o primeiro valor pode ser o estado anterior.
**Alternativa:** reconsultar alguns segundos depois, esperando `MERGEABLE`/`CLEAN` antes de agir.
**Evidência:** mesmo PR retornando `CONFLICTING` e depois `MERGEABLE` sem mudança na branch.
**Confiança:** verificado
**Escopo:** API do GitHub. Outros provedores não foram verificados.
**Validado em:** 2026-10-11 · API REST do GitHub
**Origem:** `condensed memory (pré-migração)`