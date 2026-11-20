# Parte 1: Documentação do processo de importação

## Ferramenta utilizada

- **Importação:** script Python `scripts/importar.py`, a versão corrigida do script do estagiário. Usa `pandas` e `openpyxl` para ler a planilha `dados/base_teste.xlsx`, `psycopg2` para gravar no PostgreSQL e `pymysql` para gravar no MySQL.
- **Bancos:** PostgreSQL local (versão 18.x) como banco principal, que é onde o README manda rodar o DDL. O DDL do MySQL (`sql/01_ddl_mysql.sql`) também foi escrito e usa só sintaxe comum ao MySQL 8 e ao MariaDB 10.11, onde foi executado sem erros.
- **VS Code** (extensão PostgreSQL): para rodar o DDL e as consultas e para conferir as contagens com `SELECT COUNT(*)`.
- **Claude Code:** refatoração, revisão e ambiente para executar os aquivos MySQL.
- **Copilot CLI:** debug.
- **Por que um script e não um assistente visual de importação:** a planilha tem problemas que um assistente visual não trata sozinho (ids de fornecedor com prefixo `F`, colunas sem cabeçalho, coluna `qtde_pendente` que não existe na planilha). O script faz esses tratamentos sempre do mesmo jeito, relata cada linha rejeitada e confere o resultado no banco, o que deixa o processo repetível e auditável.

Para reproduzir (a partir da raiz do repositório; a senha nunca fica no código):

```
pip install pandas openpyxl psycopg2-binary pymysql
set DB_PASSWORD=sua_senha            (PowerShell: $env:DB_PASSWORD="sua_senha")
set DB_NAME=teste
python scripts/importar.py --limpar
```

## Estrutura da planilha

A planilha tem 5 abas. Os tipos abaixo são os que a planilha realmente traz; a coluna Observação diz o que foi verificado e o tipo usado no banco.

| Aba | Coluna | Tipo | Observação |
| --- | --- | --- | --- |
| venda | venda_id | inteiro | 1 a 33, sem repetição. Faz parte da PK. |
| venda | data_emissao | data | Data real do Excel (não é texto). De 03/01/2025 a 28/03/2025; 14 vendas em fevereiro. |
| venda | horariomov | texto | Todas as 33 linhas têm `08:00:00`. |
| venda | produto_id | texto | P1 a P28. Os produtos P21 a P28 não existem em `produtos_filial`. |
| venda | qtde_vendida | decimal | 1 a 90. Cinco valores fracionados com unidade UN (ex.: 38,6). |
| venda | valor_unitario | decimal | 14,41 a 197,61. Vai para `numeric(12,4)`. |
| venda | filial_id | inteiro | 1, 2 e 3. Só a filial 1 tem produtos cadastrados. |
| venda | item | inteiro | Sempre 1. |
| venda | unidade_medida | texto | Sempre `UN`. |
| pedido_compra | pedido_id | inteiro | 1 a 29, sem repetição. |
| pedido_compra | data_pedido | data | De 02/01/2025 a 01/03/2025. |
| pedido_compra | item | inteiro | Sempre 1. |
| pedido_compra | produto_id | texto | P1 a P20. |
| pedido_compra | descricao_produto | texto | "Produto 1" a "Produto 20". |
| pedido_compra | ordem_compra | inteiro | 1 a 18 nos pedidos 1 a 18 e **0 nos pedidos 19 a 29**. É o vínculo com `entradas_mercadoria`. |
| pedido_compra | qtde_pedida | inteiro | 2 a 99. |
| pedido_compra | filial_id | inteiro | Sempre 1. |
| pedido_compra | data_entrega | data | De 01/01/2025 a 28/02/2025. |
| pedido_compra | qtde_entregue | inteiro | 0 a 91. |
| pedido_compra | preco_compra | decimal | 6,92 a 85,04. Vai para `numeric(12,4)`. |
| pedido_compra | fornecedor_id | inteiro | 1 a 20 (número, sem o prefixo `F`). |
| pedido_compra | (colunas M a W, sem cabeçalho) | misto | **99 células preenchidas nas linhas Excel 22 a 30**, 11 valores por linha. Parecem uma cópia dos pedidos de P12 a P20 com `qtde_pendente`. **Não foram importadas** (ver Tratamentos). |
| pedido_compra | qtde_pendente | não existe | Está no DDL (NOT NULL), mas não na planilha. É calculada: `qtde_pedida - qtde_entregue`. |
| entradas_mercadoria | data_entrada | data | De 01/01/2025 a 01/03/2025. |
| entradas_mercadoria | nro_nfe | texto | `NFE1` a `NFE20`. Faz parte da PK. |
| entradas_mercadoria | item | inteiro | Sempre 1. |
| entradas_mercadoria | produto_id | texto | P1 a P20. |
| entradas_mercadoria | descricao_produto | texto | "Produto 1" a "Produto 20". |
| entradas_mercadoria | ordem_compra | inteiro | 1 a 20. Liga a entrada ao pedido. Coluna que faltava no DDL do enunciado. |
| entradas_mercadoria | qtde_recebida | inteiro | 4 a 95. |
| entradas_mercadoria | filial_id | inteiro | Sempre 1. |
| entradas_mercadoria | custo_unitario | decimal | 10,32 a 98,99. |
| produtos_filial | filial_id | inteiro | Sempre 1. |
| produtos_filial | idproduto | texto | P1 a P20. No banco a coluna se chama `produto_id` (como no DDL). |
| produtos_filial | descricao | texto | "Produto 1" a "Produto 20". |
| produtos_filial | estoque | inteiro | 2 a 198. |
| produtos_filial | preco_unitario | decimal | 24,64 a 199,56. Vai para `numeric(12,4)`. |
| produtos_filial | preco_compra | decimal | 7,75 a 149,50. Vai para `numeric(12,4)`. |
| produtos_filial | preco_venda | decimal | 29,24 a 278,88. Vai para `numeric(12,4)`. |
| produtos_filial | idfornecedor | texto | `F1` a `F20` (17 distintos). **Texto com prefixo F**; no banco vira inteiro. |
| fornecedor | idfornecedor | texto | `F1` a `F20`. **Texto com prefixo F**; no banco vira inteiro. |
| fornecedor | razao_social | texto | "Fornecedor 1 LTDA" a "Fornecedor 20 LTDA". |

Nenhuma aba tem chave duplicada, valores negativos, espaços sobrando nas pontas ou células vazias (nas colunas com cabeçalho).

## Erros encontrados no DDL e como foram corrigidos

| Tabela | Erro | Correção |
| --- | --- | --- |
|  |  |  |

## Erros encontrados no script de importação e como foram corrigidos

| Erro | Efeito | Correção |
| --- | --- | --- |
|  |  |  |

## Tratamentos aplicados aos dados

(conversão de tipos, validações, normalizações)

## Conferência final

| Tabela | Linhas na planilha | Linhas no banco |
| --- | --- | --- |
| fornecedor |  |  |
| produtos_filial |  |  |
| pedido_compra |  |  |
| entradas_mercadoria |  |  |
| venda |  |  |
