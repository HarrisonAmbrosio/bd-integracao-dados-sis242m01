-- 03_transformacoes  
-- Nome: Mikael Coelho Ramos e Kauã Monteiro Coelho

-- 1 - Concatenar produto_id e descrição, "onde houver", no formato "12345 - Detergente"

-- 1a) pedido_compra 
SELECT p.pedido_id,
       CONCAT_WS(' - ', p.produto_id, NULLIF(TRIM(p.descricao_produto), '')) AS produto
FROM pedido_compra p
ORDER BY p.pedido_id;

-- 1b) venda 

SELECT v.venda_id,
       CONCAT_WS(' - ', v.produto_id, NULLIF(TRIM(d.descricao), '')) AS produto
FROM venda v
LEFT JOIN (SELECT produto_id, MIN(descricao) AS descricao
           FROM produtos_filial
           GROUP BY produto_id) d ON d.produto_id = v.produto_id
ORDER BY v.venda_id;

-- 1c) produtos_filial
SELECT pf.filial_id,
       CONCAT_WS(' - ', pf.produto_id, NULLIF(TRIM(pf.descricao), '')) AS produto
FROM produtos_filial pf
ORDER BY pf.filial_id, LENGTH(pf.produto_id), pf.produto_id;


-- 2 - Datas no formato DD/MM/YYYY

-- 2a) pedido_compra
SELECT p.pedido_id,
       TO_CHAR(p.data_pedido,  'DD/MM/YYYY') AS data_pedido,    
       TO_CHAR(p.data_entrega, 'DD/MM/YYYY') AS data_entrega    
FROM pedido_compra p
ORDER BY p.data_pedido, p.pedido_id;

-- 2b) venda
SELECT v.venda_id,
       TO_CHAR(v.data_emissao, 'DD/MM/YYYY') AS data_emissao    
ORDER BY v.data_emissao, v.venda_id;

-- 2c) entradas_mercadoria
SELECT e.nro_nfe,
       TO_CHAR(e.data_entrada, 'DD/MM/YYYY') AS data_entrada     
FROM entradas_mercadoria e
ORDER BY e.data_entrada, e.nro_nfe;

--  3 - Só os produtos requisitados mais de 10 vezes no período

SELECT produto_id, COUNT(*) AS vezes_requisitado
FROM pedido_compra
WHERE data_pedido BETWEEN DATE '2025-01-01' AND DATE '2025-03-31'
GROUP BY produto_id
HAVING COUNT(*) > 10;




