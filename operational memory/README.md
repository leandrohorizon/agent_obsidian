# Memória Operacional da IA

Conhecimento de **execução**: o que falhou, o que funcionou no lugar e sob quais
condições. Existe para que a IA não repita a mesma investigação em sessões
futuras, inclusive em outros projetos.

> Este arquivo é a **especificação** do mecanismo. Ele **não** é carregado a cada
> tarefa — só os arquivos de área são. O teto de linhas vale para as áreas.

## Fronteira com as outras memórias

| Onde | Responde | Exemplo |
|---|---|---|
| `operational memory/` | "que abordagem funciona nesta situação?" | `git mv` ignora whitelist do `.gitignore` |
| `condensed memory/projects/` | "como se escreve código neste repo?" | este vault lê guidelines por pasta |
| `condensed memory/features/` | "como funciona X ponta a ponta?" | contrato de status entre serviços |

**Régua:** se o aprendizado continua verdadeiro num repositório que não tem
nenhum arquivo deste vault, é operacional. Se depende da estrutura ou de uma
decisão do agent_obsidian, é projeto.

## Quando registrar

Cadeia de fallback, no momento em que acontece:

1. A IA aplica a abordagem padrão.
2. A abordagem **não atende aos requisitos** (erro, saída errada, requisito não cumprido).
3. A IA tenta a alternativa.
4. A alternativa **passa** → registra a entrada.

Se o passo 4 não acontecer, não há entrada. Tentativa que falhou e não teve
alternativa não é aprendizado reutilizável — fica na Discussão do card.

**Fora de escopo:** comparar alternativas por otimização (menos tokens, menos
tempo). A cadeia de fallback só registra o par `padrão falhou` → `alternativa
passou`; ela não descobre a alternativa ótima antes da escolha.

## Formato da entrada

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

## Escala de confiança

| Nível | Critério | A IA aplica sozinha? |
|---|---|---|
| `fato` | observação literal reproduzida (erro, saída) | sim, como observação |
| `verificado` | padrão falhou **e** alternativa passou, mesma condição, com evidência | sim |
| `preferência` | escolha sem baseline comparável | **não** — só consulta |

`verificado` não exige reprodução N vezes nem aprovação humana: exige o par
observado (passos 2 e 4). O que não passa por esse par não é verificado.

## Exemplo

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

Cada campo tem função: `Situação` é o gatilho que a IA reconhece **antes** de
digitar o comando; `Padrão` é o que ela faria sozinha; `Evidência` prova o passo
4; `Escopo` impede que o aprendizado vaze para onde não vale.

Nos outros níveis, só estes campos mudam:

| Nível | `Confiança` | `Alternativa` e `Evidência` |
|---|---|---|
| `fato` | `fato — observação direta; correção não verificada` | alternativa ainda não rodou; evidência do que se observou |
| `preferência` | `preferência` | `Falhou porque: não falhou — só mais verboso`; `Evidência: nenhuma comparável` |

`fato` é o nível honesto para "observei isto" e não sobe para `verificado` sem o
par rodar. `preferência` a IA **consulta**, não aplica sozinha.

### ❌ O que não vira entrada

| Tentativa | Problema | Onde deveria ficar |
|---|---|---|
| "O teste passou depois de limpar o cache." | resultado que o fluxo já verifica | nada — é saída, não aprendizado |
| "Timeout ao chamar a API externa." | falha transitória isolada | Discussões do card |
| "Use `--legacy-peer-deps`." | sem mecanismo nem escopo | inválida até ter `Falhou porque` |
| "Funciona melhor com `pnpm`." | sem baseline comparável | no máximo `preferência` |
| Header `Authorization` real colado como evidência | **segredo** | nunca — registrar só a forma do erro |
| "Na minha máquina o projeto fica em `C:\Users\...`." | detalhe local, sem valor reutilizável | nada |

## Áreas

Um arquivo por área, carregados inteiros pelo `/work-on-card`.

| Arquivo | Cobre |
|---|---|
| `git.md` | comportamento do git, branches, merge, index |
| `github.md` | API do GitHub, PRs, checks, mergeability |
| `shell.md` | shell, PowerShell, encoding, caminhos, redirecionamento |
| `vscode.md` | VS Code, sessão do Copilot, skills, extensões |

**Nenhum arquivo de área é versionado.** Só o `README.md` (este contrato) entra
no repositório — as entradas são conteúdo local, como os cards e as condensed
memories, e cada máquina constrói a sua. O README versionado já mantém a pasta
no clone; `.gitkeep` seria redundante. A área que ainda não existe é criada na
primeira entrada, com o cabeçalho `# Operacional — {area}` e a linha de teto.

**Regra de nome:** o arquivo leva o nome da **ferramenta concreta**, em inglês e
sem categoria intermediária. `ferramentas.md` (balde genérico) e `testes.md`
(categoria, não ferramenta) foram rejeitados: o primeiro não diz onde a entrada
entra, o segundo obriga a decidir entre "é teste ou é a ferramenta que roda o
teste?". Quando houver entrada de um runner real (`rspec.md`, `jest.md`), ela
nasce com esse nome.

Área nova só nasce quando a entrada não couber em nenhuma existente — e nasce
como ferramenta, não como arquivo avulso.

## Poda

- **Teto: ~40 linhas por arquivo.** O teto é gatilho de ação, não aviso: ao
  atingir, remova ou funda a entrada mais fraca (mais antiga, mais específica
  ou em `preferência`) **antes** de acrescentar.
- **Entrada obsoleta é removida na hora** em que a obsolescência é identificada:
  a alternativa falhou de novo, a ferramenta mudou ou o usuário informou. Sem
  seção de histórico, sem marca `obsoleto` — entrada morta é custo de contexto.
- Entrada nova para a mesma situação **substitui** a anterior em vez de criar
  uma segunda entrada.

## Salvaguardas

Nunca registrar, nem como exemplo, nem "mascarado":

- segredo, credencial, token, chave, cookie, connection string
- dado pessoal (nome, e-mail, telefone, documento)
- conteúdo de cliente, payload real, log de produção
- caminho absoluto que identifique a máquina, quando o relativo serve

Registre o **mecanismo e a forma do erro**, não a saída bruta. Exemplo: `exit 128
com "pathspec ... did not match"`, não o comando colado com token na query string.

