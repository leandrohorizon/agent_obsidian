## Princípios Gerais
- Priorizar código simples e legível.
- Evitar duplicação de código (DRY - Don't Repeat Yourself).
- Seguir o princípio KISS (Keep It Simple, Stupid).
- Aplicar SOLID quando fizer sentido.
- Preferir composição em vez de herança.

## Nomenclatura
- Utilizar nomes claros e descritivos para variáveis, funções e classes.
- Evitar abreviações desnecessárias.
- Manter consistência nos padrões de nomenclatura.

## Funções
- Devem possuir responsabilidade única.
- Devem ser pequenas e focadas.
- Evitar efeitos colaterais sempre que possível.
- Preferir retorno explícito.

## Estrutura do Código
- Organizar arquivos e pastas por domínio ou funcionalidade.
- Remover código morto e comentários obsoletos.
- Evitar lógica complexa aninhada.
- **Seguir o Stepdown Rule (Top-Down Rule)** - organizar funções em níveis decrescentes de abstração.
  - Código deve ser lido como uma narrativa de cima para baixo.
  - Funções de alto nível no topo, detalhes de implementação abaixo.
  - Cada função deve chamar funções um nível abaixo em abstração.
  - Exemplo: `processOrder()` → `validateOrder()` → `checkInventory()` → `queryDatabase()`

## Tratamento de Erros
- Não ignorar exceções silenciosamente.
- Registrar erros relevantes em logs.
- Retornar mensagens de erro claras e consistentes.

## Testes
- Criar testes unitários para regras de negócio.
- Garantir cobertura das funcionalidades críticas.
- Testes devem ser independentes e reproduzíveis.
- Corrigir testes quebrados antes de adicionar novas funcionalidades.
- **Testar caminhos de erro, não apenas caminho feliz** - testes que só passam não detectam bugs reais.
- **Evitar duplicação em specs** - usar `shared_context`, `shared_examples` e helpers para setup comum.
- **Specs devem validar comportamento real** - se você introduzir um bug e os testes continuarem passando, os testes estão mockando demais.
- **Jobs assíncronos devem ter specs** - validar tratamento de erro e notificações.
- **Helpers devem ser extraídos quando há 3+ repetições** - exemplo: `mock_error`, `setup_mocks`.

## Qualidade
- Executar lint antes de realizar commits.
- Resolver warnings relevantes do lint.
- Utilizar formatação automática do projeto.
- Evitar dependências desnecessárias.

## Performance
- Priorizar legibilidade antes de otimizações prematuras.
- Medir gargalos antes de otimizar.
- Evitar consultas, loops ou operações redundantes.

## Queries e ActiveRecord
- **Sempre usar `.includes` para eager loading** - evita N+1 queries quando acessar associações.
  - Exemplo: `BankAccount.includes(:account).find_by(...)` ao invés de `BankAccount.find_by(...)`
- **Usar `.joins` quando não precisar dos dados da associação** - apenas para filtrar.
- **Preferir queries específicas a lazy loading** - carregar dados de uma vez ao invés de múltiplas queries.

## Pull Requests
- Manter PRs pequenos e focados.
- Incluir descrição clara das alterações.
- Garantir que testes e lint estejam passando.