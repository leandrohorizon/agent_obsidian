# Condensed Memory — especificação

Contrato único das três memórias. Toda escrita aqui segue este documento;
`commands/condense-memory.md` e `commands/work-on-card.md` executam o fluxo, não
redefinem o formato.

> Este `README.md` fica na raiz de `condensed memory/`, nunca em `projects/`,
> `features/` ou `operational/` — senão aparece como memória em quem lista a pasta.

## As três memórias

| Onde | Responde | Escopo | Escrita |
|---|---|---|---|
| `condensed memory/projects/{projeto}.md` | "como se escreve código neste repo?" | um repositório | após merge |
| `condensed memory/features/{feature}.md` | "como funciona X ponta a ponta?" | atravessa repositórios | após merge |
| `condensed memory/operational/{ferramenta}.md` | "que abordagem funciona nesta situação?" | qualquer projeto | durante a tarefa |

**Desempate projeto × feature:** o item descreve fluxo, contrato ou regra de
negócio que atravessa serviços? → feature. Descreve estrutura, convenção ou
setup do repo? → projeto.

**Desempate projeto × operacional:** o item continua verdadeiro num repositório
que não tem nenhum arquivo deste vault? → operacional. Depende de uma decisão
ou da estrutura do agent_obsidian? → projeto.

## Quando escrever

**Projeto e feature:** só depois do merge, pelo `/complete-card` →
`/condense-memory`. Card em `1.not_started/`, `2.in_progress/` ou
`3.in_review/` não gera escrita (`guidelines/conduct.md` §Condensed memory).

**Operacional:** durante a tarefa, pelo `/work-on-card`, na cadeia de fallback:

1. A IA aplica a abordagem padrão.
2. A abordagem **não atende aos requisitos** (erro, saída errada, requisito não cumprido).
3. A IA tenta a alternativa.
4. A alternativa **passa** → registra a entrada.

Se o passo 4 não acontecer, não há entrada. Tentativa que falhou e não teve
alternativa não é aprendizado reutilizável — fica na Discussão do card. **Fora de
escopo:** comparar alternativas por otimização (menos tokens, menos tempo).

## Nomes de arquivo

- Projeto: `basename` do repo, lowercase, hífen → underscore. `NotificationListener` → `notification_listener.md`
- Feature: slug lowercase com hífens, sem acento. `analise-pix-in` → `analise-pix-in.md`
- Operacional: a **ferramenta concreta**, em inglês. `git.md`, `github.md`, `shell.md`, `vscode.md`
- A feature nomeia a **análise ponta a ponta**, não o campo nem o repositório

**Regra de nome de área operacional:** nome de ferramenta, sem categoria
intermediária. `ferramentas.md` (balde genérico) e `testes.md` (categoria) foram
rejeitados: o primeiro não diz onde a entrada entra, o segundo obriga a decidir
"é teste ou é a ferramenta que roda o teste?". Área nova só nasce quando a
entrada não couber em nenhuma existente — e nasce como ferramenta.

## Cabeçalho do arquivo de projeto

```markdown
# Condensed Memory - {nome_projeto}

> Última atualização: YYYY-MM-DD
> Cards processados: N
> Origem: [card1, card2, card3]
```

## Cabeçalho do arquivo de feature

```markdown
# Feature - {slug-da-feature}

> Última atualização: YYYY-MM-DD
> Repositórios envolvidos: [repo1, repo2]
> Cards de origem: [card1, card2]
```

## Categorias de projeto (5)

| Categoria | Conteúdo |
|---|---|
| `## 🏗️ Arquitetura` | estrutura, subsistemas, integrações, decisões estruturais |
| `## 📋 Padrões e Convenções` | regras, nomenclatura, templates |
| `## 🛠️ Ferramentas e Comandos` | comandos, scripts, bibliotecas |
| `## ⚙️ Configuração` | variáveis de ambiente, setup, dependências |
| `## 💡 Aprendizados Chave` | problemas/soluções, trade-offs, gotchas **do repo** |

Esqueleto de item:

```markdown
### Nome do Subsistema
Descrição concisa (1-2 linhas)
- Detalhe técnico
- Exemplo inline quando relevante: `código ou comando`

**Decisão:** por que essa arquitetura foi escolhida e qual problema resolve.
```

## Categorias de feature (4 — não reaproveitar as de projeto)

| Categoria | Conteúdo |
|---|---|
| `## 🔀 Fluxo Ponta a Ponta` | sequência atravessando serviços, quem chama quem |
| `## 🤝 Contratos entre Serviços` | payloads, campos, formato de cada lado |
| `## 📐 Regras de Negócio` | regras e validações da feature |
| `## ⚠️ Edge Cases` | casos limite, intermitências, problemas conhecidos |

Esqueleto de item:

```markdown
### Nome do Fluxo
Sequência completa atravessando serviços/repositórios
- Etapa 1 (em {repo}): o que acontece
- Etapa 2 (em {repo}): o que acontece

**Decisão:** por que o fluxo é assim.
```

## Memória operacional

Arquivo por área, carregados inteiros pelo `/work-on-card`. Cabeçalho:

```markdown
# Operacional — {area}

> Formato, escala de confiança e poda: `condensed memory/README.md`. Teto: ~40 linhas.
```

### Formato da entrada

```markdown
### <situacao-em-kebab-case>

**Situação:** o que a IA está prestes a fazer — é o gatilho de reconhecimento.
**Padrão:** a abordagem que ela aplicaria sozinha, literal.
**Falhou porque:** o mecanismo do erro, não o relato.
**Alternativa:** o que funcionou.
**Evidência:** o que prova que passou (exit code, saída, arquivo criado).
**Confiança:** fato | verificado | preferência
**Escopo:** onde vale e onde não vale.
**Validado em:** YYYY-MM-DD · versão da ferramenta/SO
**Origem:** [[card]] ou `condensed memory (pré-migração)`
```

O título é a **situação**, não o comando: a IA não sabe que uma alternativa
existe, então só encontra a entrada se o gatilho for algo que ela reconhece.

### Escala de confiança

| Nível | Critério | A IA aplica sozinha? |
|---|---|---|
| `fato` | observação literal reproduzida (erro, saída) | sim, como observação |
| `verificado` | padrão falhou **e** alternativa passou, mesma condição, com evidência | sim |
| `preferência` | escolha sem baseline comparável | **não** — só consulta |

`verificado` não exige reprodução N vezes nem aprovação humana: exige o par
observado. O que não passa por esse par não é verificado.

### Exemplo

```markdown
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
```

Cada campo tem função: `Situação` é o gatilho reconhecido **antes** de digitar o
comando; `Padrão` é o que a IA faria sozinha; `Evidência` prova o passo 4;
`Escopo` impede que o aprendizado vaze para onde não vale.

Nos outros níveis, só estes campos mudam:

| Nível | `Confiança` | `Alternativa` e `Evidência` |
|---|---|---|
| `fato` | `fato — observação direta; correção não verificada` | alternativa ainda não rodou; evidência do que se observou |
| `preferência` | `preferência` | `Falhou porque: não falhou — só mais verboso`; `Evidência: nenhuma comparável` |

`fato` é o nível honesto para "observei isto" e não sobe para `verificado` sem o
par rodar. `preferência` a IA **consulta**, não aplica sozinha.

### O que não vira entrada operacional

| Tentativa | Problema | Onde deveria ficar |
|---|---|---|
| "O teste passou depois de limpar o cache." | resultado que o fluxo já verifica | nada — é saída, não aprendizado |
| "Timeout ao chamar a API externa." | falha transitória isolada | Discussões do card |
| "Use `--legacy-peer-deps`." | sem mecanismo nem escopo | inválida até ter `Falhou porque` |
| "Funciona melhor com `pnpm`." | sem baseline comparável | no máximo `preferência` |
| Header `Authorization` real colado | **segredo** | nunca — registrar só a forma do erro |
| "Na minha máquina o projeto fica em `C:\Users\...`." | detalhe local, sem valor reutilizável | nada |

### Poda operacional

- **Teto: ~40 linhas por arquivo.** Gatilho de ação, não aviso: ao atingir,
  remova ou funda a entrada mais fraca (mais antiga, mais específica ou em
  `preferência`) **antes** de acrescentar.
- **Entrada obsoleta é removida na hora**: a alternativa falhou de novo, a
  ferramenta mudou ou o usuário informou. Sem histórico, sem marca `obsoleto` —
  entrada morta é custo de contexto.
- Entrada nova para a mesma situação **substitui** a anterior.

## Regras de forma (projeto e feature)

1. **Origem uma vez no header** — não repetir o card de origem em cada item.
2. **Destacar o "por quê"** — usar `**Decisão:**` ou `**Rationale:**`.
3. **Hierarquia** — Categoria → item → detalhes → decisão.
4. **Compactar** — agrupar itens relacionados; a memória é resumo, não transcrição.
5. **Deduplicar por eixo** — antes de acrescentar, verificar se o item já existe;
   fundir em vez de criar um segundo.
6. **Emojis só nas categorias** — servem de navegação, não de decoração.

## Poda (projeto e feature)

Não há teto rígido, mas o tamanho é sintoma: arquivo acima de ~300 linhas indica
falta de deduplicação. Aprendizado de execução não fica aqui — migrar para
`operational/` é a poda natural.

## Salvaguardas

Vale para as três memórias. Nunca registrar, nem como exemplo, nem "mascarado":

- segredo, credencial, token, chave, cookie, connection string
- dado pessoal (nome, e-mail, telefone, documento)
- conteúdo de cliente, payload real, log de produção
- caminho absoluto que identifique a máquina, quando o relativo serve

Registre o **mecanismo e a forma do erro**, não a saída bruta. Exemplo: `exit 128
com "pathspec ... did not match"`, não o comando colado com token na query string.

## Versionamento

Só este `README.md` é versionado **como conteúdo**. `projects/`, `features/` e
`operational/` guardam conteúdo local — cada máquina constrói o seu, como os
cards. As três pastas existem no clone por um `.gitkeep` versionado
(`!condensed memory/**/.gitkeep` no `.gitignore`): sem ele a pasta não apareceria,
porque nenhum arquivo de conteúdo é versionado. É o mesmo arranjo das pastas de
estado do `board/`.

O `.gitkeep` só se justifica nesse cenário. Numa pasta com arquivo versionado
ela existe sozinha, e o `.gitkeep` passa a ser ruído.