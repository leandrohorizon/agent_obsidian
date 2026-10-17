# Condensed Memory — especificação

Contrato dos arquivos de memória consolidada. Toda escrita aqui segue este
documento; `commands/condense-memory.md` executa o fluxo, não redefine o formato.

> `README.md` fica na raiz de `condensed memory/`, nunca em `projects/` ou
> `features/` — senão aparece como "projeto" ou "feature" em quem lista a pasta.

## As três memórias

| Onde | Responde | Escopo |
|---|---|---|
| `condensed memory/projects/{projeto}.md` | "como se escreve código neste repo?" | um repositório |
| `condensed memory/features/{feature}.md` | "como funciona X ponta a ponta?" | atravessa repositórios |
| `operational memory/{ferramenta}.md` | "que abordagem funciona nesta situação?" | qualquer projeto |

**Desempate projeto × feature:** o item descreve fluxo, contrato ou regra de
negócio que atravessa serviços? → feature. Descreve estrutura, convenção ou
setup do repo? → projeto.

**Desempate projeto × operacional:** o item continua verdadeiro num repositório
que não tem nenhum arquivo deste vault? → operacional. Depende de uma decisão
ou da estrutura do agent_obsidian? → projeto.

## Quando escrever

Só depois do merge, pelo `/complete-card` → `/condense-memory`. Card em
`1.not_started/`, `2.in_progress/` ou `3.in_review/` não gera escrita aqui
(`guidelines/conduct.md` §Condensed memory). A exceção de escrita durante a
tarefa vale **apenas** para `operational memory/`.

## Nomes de arquivo

- Projeto: `basename` do repo, lowercase, hífen → underscore. `NotificationListener` → `notification_listener.md`
- Feature: slug lowercase com hífens, sem acento. `analise-pix-in` → `analise-pix-in.md`
- A feature nomeia a **análise ponta a ponta**, não o campo nem o repositório

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

## Regras de forma

1. **Origem uma vez no header** — não repetir o card de origem em cada item.
2. **Destacar o "por quê"** — usar `**Decisão:**` ou `**Rationale:**`.
3. **Hierarquia** — Categoria → item → detalhes → decisão.
4. **Compactar** — agrupar itens relacionados; a memória é resumo, não transcrição.
5. **Deduplicar por eixo** — antes de acrescentar, verificar se o item já existe;
   fundir em vez de criar um segundo.
6. **Emojis só nas categorias** — servem de navegação, não de decoração.

## Poda

Não há teto rígido, mas o tamanho é sintoma: arquivo acima de ~300 linhas indica
que falta deduplicação. O conhecimento de execução não fica aqui — migrar para
`operational memory/` é a poda natural.

## Fronteira com `operational memory/`

O §💡 Aprendizados Chave guarda o aprendizado **do repo** (decisão, convenção,
gotcha deste código). Aprendizado sobre ferramenta, comando ou API que vale em
qualquer repositório vai para `operational memory/` — ver
`operational memory/README.md`.
