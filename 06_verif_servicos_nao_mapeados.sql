-- Código A.6 — Verificação: serviços presentes na base e ausentes do mapeamento
-- Entrada: gps_brt confrontado com o mapeamento serviço-corredor
-- Processamento: anti-join contra a lista de serviços mapeados
-- Saída: servico, registros, participação percentual
-- Resultado esperado: resíduo inferior a 0,05% dos registros do período

SELECT
  EXTRACT(YEAR FROM data) AS ano,
  servico,
  COUNT(*)                    AS registros_pico,
  COUNT(DISTINCT id_veiculo)  AS veiculos_distintos
FROM `rj-smtr.br_rj_riodejaneiro_veiculos.gps_brt`
WHERE flag_em_operacao = TRUE
  AND data BETWEEN '2021-11-01' AND '2024-12-31'
  AND EXTRACT(HOUR FROM timestamp_gps) IN (7, 8, 17, 18)
  AND servico NOT IN (
    '10','11','11N','12','13','14','15','16','17','18','19','20','22','25','25A','28',
    '31','35','35A','38','38N','40','40A','41','42','42A','43','46',
    '50','51','51A','52','53','53A','53B',
    '60','61','67','68','70','73','80','90'
  )
GROUP BY ano, servico
ORDER BY ano, servico
