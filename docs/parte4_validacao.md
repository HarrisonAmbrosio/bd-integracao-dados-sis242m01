# Parte 4: Roteiro de validação com o cliente (fevereiro/2025)

**Dupla:** Mikael Coelho Ramos e Kauã Monteiro Coelho

**Objetivo da reunião:** o cliente sair com a certeza de que os dados de **fevereiro/2025** que estão no banco são os dados dele, completos e corretos, e saber exatamente quais pontos ainda dependem de uma decisão dele. Tudo o que for mostrado na reunião está em `sql/04_validacao.sql` e pode ser executado ao vivo.

**Como conduzir:** começamos pelo que fecha (para ganhar confiança), depois mostramos o que não fecha e por quê, sempre com a consulta e as linhas na tela. Cada ponto termina com uma pergunta objetiva ao cliente e uma decisão registrada na ata. Uma base de 33 vendas, 29 pedidos e 20 entradas é pequena o bastante para o cliente conferir linha a linha.

## 1. Pontos a validar

Em ordem de apresentação. A coluna "Consulta" indica o código em `sql/04_validacao.sql`.

| # | Ponto | O que mostramos e o que perguntamos ao cliente | Consulta |
| --- | --- | --- | --- |
| 1 | **Os números fecham?** | Em fevereiro/2025 há 14 vendas, 173,22 unidades e R$ 14.093,17, de 07/02 a 28/02, em 2 filiais. *Estes totais batem com o relatório do seu sistema?* Também confirmamos que as linhas por tabela são as da planilha (20, 20, 29, 20 e 33). | V01, V02, V03 |
| 2 | **Produtos vendidos sem cadastro** | 6 das 14 vendas de fevereiro (R$ 3.241,24 do total) são dos produtos P22 a P27, que não existem no cadastro de produtos. *São produtos novos que faltou cadastrar ou códigos errados?* No total da base são 13 vendas, dos produtos P21 a P28. | V05, V00 |
| 3 | **Filiais** | Há venda nas filiais 2 e 3, mas só a filial 1 tem produtos cadastrados (1 venda de fevereiro na filial 2). *As filiais 2 e 3 existem? Quais produtos elas vendem?* | V06, V03 |
| 4 | **Unidade de medida e quantidades** | 5 vendas têm quantidade fracionada em unidade UN (por exemplo 38,6), 2 delas em fevereiro. *Faltou a unidade correta (kg, litro) ou é erro de digitação?* | V19 |
| 5 | **Preços** | O preço praticado nas vendas difere do preço de venda do cadastro em todas as 20 vendas comparáveis, e 4 produtos (P1, P8, P15 e P18) têm preço de venda menor que o de compra. *Qual é a fonte do preço correta? O preço abaixo do custo é promoção ou erro?* | V17, V18 |
| 6 | **Requisições e ordens de compra** | 11 pedidos (19 a 29) têm `ordem_compra = 0`. *Ainda são requisições, ou faltou preencher a ordem?* Além disso, as entradas das ordens 19 e 20 não têm pedido correspondente. *Pertencem aos pedidos de P19 e P20?* | V07, V08 |
| 7 | **Possíveis duplicidades** | Os pedidos 21 a 29 repetem produto, datas, preço e fornecedor dos pedidos 12 a 20, com quantidades diferentes. *São lançamentos duplicados?* Isso muda o total de requisições e o resultado da Parte 3. | V09 |
| 8 | **Recebimento** | 7 entradas trazem mais mercadoria do que foi pedido, a quantidade entregue no pedido não bate com a recebida na entrada em nenhuma das 18 ordens comparáveis, e o custo da nota fiscal difere do preço do pedido nas mesmas 18. *Qual dos registros vale para o estoque e para o custo?* | V12, V13, V16 |
| 9 | **Datas** | 20 pedidos têm entrega anterior ao pedido e 9 entradas aconteceram antes de o pedido existir. *A "data de entrega" é a prevista ou a realizada? Houve lançamento retroativo?* | V14, V15 |
| 10 | **Fornecedores** | O fornecedor do produto difere do fornecedor do pedido em 22 de 29 linhas, e 3 fornecedores (F14, F15 e F16) não têm produto. Na planilha o código vinha como texto (`F8`) e foi convertido em número. *Qual cadastro de fornecedor vale? A conversão do código está correta?* | V10, V11 |
| 11 | **Dados fora da tabela** | Na aba de pedidos há 99 células preenchidas à direita da tabela, sem título de coluna (linhas 22 a 30). Não foram importadas. *Qual é o dado correto: o da tabela ou o dessa área?* | aviso do `importar.py` |
| 12 | **Definições de negócio** | Registramos como entendemos: *requisitado* = linha de pedido; *recebido* = entrada ligada pela `ordem_compra`; *requisição pendente* = pedido sem entrada. E "requisitado mais de 10 vezes" como quantidade requisitada maior que 10. *O entendimento está correto?* | `02_consultas.sql`, `03_transformacoes.sql` |

## 2. Técnicas para garantir exatidão e precisão

**Exatidão** é o dado estar certo (é o valor real); **precisão** é ele ter o nível de detalhe correto (casas decimais, formato, unidade). As técnicas, e como cada uma foi aplicada aqui:

- **Reconciliação por totais de controle.** Contagem de linhas e soma de quantidade e valor, comparadas com um relatório do sistema de origem do cliente (V01 e V02). Se os totais batem, a carga está íntegra; se não, a diferença localiza o problema.
- **Conferência por amostragem.** Sorteamos 5 a 10 vendas de fevereiro, incluindo as de maior valor e as com anomalia (por exemplo as de produto sem cadastro), e o cliente confere cada uma com o documento original (cupom ou nota fiscal).
- **Integridade referencial.** Cada código usado numa tabela deve existir na tabela de origem: chaves estrangeiras no banco e consultas `NOT EXISTS` para o que a carga não pode bloquear (V05, V06, V08, V10).
- **Validação de domínio e de faixa.** Procurar nulos, zeros, negativos e extremos em cada coluna numérica (V20), e valores que não fazem sentido para a unidade (quantidade fracionada em `UN`, V19).
- **Regras de negócio cruzadas entre tabelas.** Recebido não pode superar o pedido, entrada não pode anteceder o pedido, o custo da nota deve bater com o preço do pedido (V12 a V16).
- **Detecção de duplicidade.** Chaves primárias impedem duplicatas exatas; para "quase duplicatas" usamos auto-junção por produto, datas, preço e fornecedor (V09).
- **Precisão numérica.** Valores monetários em `numeric(12,4)` e não em `float`, que não representa centavos com exatidão; nas consultas, os totais saem arredondados em 2 casas (`DECIMAL(14,2)`).
- **Carga repetível e auditável.** O mesmo script, rodado em banco limpo, produz sempre o mesmo resultado; cada linha rejeitada é relatada com o número da linha do Excel e o motivo, e nenhum valor ausente é "preenchido" com zero.
- **Rastreabilidade.** As consultas ficam versionadas no Git e cada decisão do cliente é registrada na ata, com a consulta correspondente.
- **Dupla conferência.** Uma pessoa da equipe e uma do cliente conferem os mesmos números de forma independente antes do aceite.

## 3. Consultas preparadas para a reunião

(As consultas ficam em `sql/04_validacao.sql`. O que cada uma mostra:)

| Consulta | O que mostra | Como usar na reunião |
| --- | --- | --- |
| V00 | Painel com a contagem de cada problema (e quantos ocorrem em fevereiro). | Primeira tela: visão geral do que será discutido. |
| V01 | Linhas por tabela. | Comparar com a planilha: 20, 20, 29, 20 e 33. |
| V02 | Totais de controle das vendas de fevereiro/2025 (linhas, produtos, filiais, quantidade, valor e datas). | O cliente compara com o relatório dele. |
| V03 | Vendas de fevereiro por filial. | Confirmar quais filiais existem. |
| V04 | Pedidos feitos e mercadoria recebida em fevereiro. | Confirmar o movimento de compras do mês. |
| V05 | Vendas de produtos sem cadastro, com a marca de quais são de fevereiro. | Decidir se faltou cadastrar ou se o código está errado. |
| V06 | Vendas em filiais sem produto cadastrado. | Confirmar a existência das filiais 2 e 3. |
| V07 | Pedidos com `ordem_compra = 0`. | Definir se são requisições ou se faltou a ordem. |
| V08 | Entradas sem pedido correspondente. | Ligar as entradas das ordens 19 e 20 aos pedidos certos. |
| V09 | Pedidos que repetem outro pedido, lado a lado. | Decidir se são duplicatas. |
| V10 | Fornecedor do produto diferente do fornecedor do pedido. | Definir qual cadastro vale. |
| V11 | Fornecedores sem produto (informativo). | Confirmar se podem ser desativados. |
| V12 | Quantidade entregue no pedido diferente da recebida na entrada. | Definir qual registro vale para o estoque. |
| V13 | Entradas com mais mercadoria do que o pedido, com o excesso. | Confirmar se houve entrega a maior. |
| V14 | Pedidos com entrega anterior ao pedido. | Entender o significado da data de entrega. |
| V15 | Mercadoria que entrou antes de o pedido existir. | Verificar lançamentos retroativos. |
| V16 | Custo da entrada diferente do preço do pedido, com a diferença. | Definir qual preço vale para o custo. |
| V17 | Preço da venda diferente do preço do cadastro. | Definir a fonte do preço. |
| V18 | Produtos com preço de venda menor que o de compra. | Confirmar se é promoção ou erro. |
| V19 | Vendas com quantidade fracionada em `UN`. | Corrigir a unidade de medida. |
| V20 | Perfil das colunas numéricas (nulos, zeros, mínimo e máximo). | Cliente confirma se os extremos são plausíveis. |

## Erros encontrados nos dados

Todos os problemas que encontramos. Os três primeiros só aparecem na planilha (o banco já recebe os dados tratados); os demais estão no banco e são mostrados pela consulta indicada. As quantidades vêm do painel V00.

| Tabela | Problema | Quantidade | Consulta que mostra |
| --- | --- | --- | --- |
| pedido_compra (planilha) | Colunas M a W sem cabeçalho, com dados nas linhas Excel 22 a 30. Parecem uma cópia dos pedidos de P12 a P20 com `qtde_pendente` (7 das 9 linhas coincidem com os pedidos 12 a 18; P19 e P20 trazem `ordem_compra` 19 e 20). Não foram importadas. | 99 células em 9 linhas | O `importar.py` avisa ao rodar. No Python: `df.iloc[:, 12:].notna().sum().sum()`. No Excel: Ctrl+End na aba. |
| fornecedor e produtos_filial (planilha) | `idfornecedor` em texto com prefixo `F` (`F8`), enquanto `pedido_compra.fornecedor_id` é número e o PDF pede id numérico. Convertido na carga. | 40 valores (20 + 20) | No Python: `df["idfornecedor"].astype(str).str.startswith("F").sum()`. No Excel: filtro de texto "começa com F". |
| pedido_compra (planilha) | Falta a coluna `qtde_pendente`, que existe no DDL (NOT NULL). Calculada na carga como `qtde_pedida - qtde_entregue`. | 29 linhas | Comparar o cabeçalho da aba com o DDL. |
| pedido_compra | `ordem_compra = 0`: pedidos sem vínculo com nenhuma entrada (pedidos 19 a 29). | 11 | `V07` |
| pedido_compra | Pares de pedidos repetidos: os pedidos 21 a 29 repetem produto, datas, preço e fornecedor dos pedidos 12 a 20, com quantidades diferentes. | 9 pares | `V09` |
| entradas_mercadoria | `ordem_compra` sem pedido correspondente (ordens 19 e 20, cujos pedidos têm ordem 0). | 2 | `V08` |
| venda | Produto sem cadastro em `produtos_filial` (P21 a P28), com 6 em fevereiro/2025 e R$ 3.241,24 do total do mês. | 13 (6 em fevereiro) | `V05` |
| venda | Filial sem produto cadastrado (filiais 2 e 3), com 1 em fevereiro. | 4 (1 em fevereiro) | `V06` |
| venda | Quantidade fracionada com unidade `UN` (por exemplo 38,6), 2 delas em fevereiro. | 5 | `V19` |
| venda e produtos_filial | `valor_unitario` da venda diferente do `preco_venda` do cadastro. | 20 de 20 comparáveis | `V17` |
| produtos_filial | Preço de venda menor que o de compra (P1, P8, P15 e P18). | 4 | `V18` |
| entradas_mercadoria e pedido_compra | Entrada com `qtde_recebida` maior que a `qtde_pedida` (ordens 2, 3, 5, 7, 11, 15 e 16). | 7 | `V13` |
| entradas_mercadoria e pedido_compra | `qtde_entregue` do pedido diferente da `qtde_recebida` da entrada. | 18 de 18 comparáveis | `V12` |
| pedido_compra | `data_entrega` anterior à `data_pedido`. | 20 | `V14` |
| entradas_mercadoria e pedido_compra | `data_entrada` anterior à `data_pedido` (ordens 6, 7, 11, 12, 13, 14, 15, 16 e 18). | 9 | `V15` |
| entradas_mercadoria e pedido_compra | `custo_unitario` da entrada diferente do `preco_compra` do pedido. | 18 de 18 comparáveis | `V16` |
| produtos_filial e pedido_compra | Fornecedor do produto diferente do fornecedor do pedido. | 22 de 29 | `V10` |
| fornecedor | Fornecedores sem nenhum produto (F14, F15 e F16). Informativo. | 3 | `V11` |
| venda | Dados com aparência artificial: `horariomov` igual a `08:00:00` e `item` igual a 1 em todas as vendas. Informativo, para o cliente confirmar. | 33 de 33 | `SELECT COUNT(DISTINCT horariomov), COUNT(DISTINCT item) FROM venda;` |
