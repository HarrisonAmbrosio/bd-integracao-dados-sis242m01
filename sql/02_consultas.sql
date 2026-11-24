-- 1. Consumo por produto em fevereiro de 2025

SELECT
    produto_id,
    SUM(qtde_vendida) AS total_quantidade_vendida,
    SUM(qtde_vendida * valor_unitario) AS total_vendas_reais
FROM venda
WHERE data_emissao >= '2025-02-01'
  AND data_emissao < '2025-03-01'
GROUP BY produto_id
ORDER BY produto_id;