-- 03_transformacoes
-- Nome:

-- 1

SELECT
    CONCAT(produto_id, ' - ', descricao_produto) AS produto,
    qtde_pedida AS quantidade_requisitada,
    data_pedido
FROM pedido_compra;

-- 2

SELECT
    CONCAT(produto_id, ' - ', descricao_produto) AS produto,
    qtde_pedida AS quantidade_requisitada,
    TO_CHAR(data_pedido, 'DD/MM/YYYY') AS data_solicitacao
FROM pedido_compra;

-- 3
-- FEVEREIRO DE 2025

SELECT
    CONCAT(produto_id, ' - ', MAX(descricao_produto)) AS produto,
    SUM(qtde_pedida) AS qtde_requisitada,
    TO_CHAR(data_pedido, 'DD/MM/YYYY') AS data_solicitacao
FROM pedido_compra
WHERE data_pedido >= '2025-02-01'
  AND data_pedido < '2025-03-01'
GROUP BY produto_id, data_pedido
HAVING SUM(qtde_pedida) > 10
ORDER BY data_pedido, produto_id;



