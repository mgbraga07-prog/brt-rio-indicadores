-- Código A.7 — Verificação: cobertura e densidade de telemetria mês a mês
-- Entrada: gps_brt · nov/2021 a dez/2024
-- Processamento: contagem de registros, de veículos distintos e de dias com operação
-- Saída: ano_mes, corredor, registros, veiculos, dias
-- Resultado esperado: mediana de 563 registros por veículo-dia; nov/2023 com 9.650

SELECT
  FORMAT_DATE('%Y-%m', data)     AS ano_mes,
  COUNT(*)                       AS registros,
  COUNT(DISTINCT id_veiculo)     AS veiculos,
  COUNT(DISTINCT DATE(data))     AS dias_com_registro,
  SAFE_DIVIDE(
    COUNT(*),
    COUNT(DISTINCT id_veiculo) * COUNT(DISTINCT DATE(data))
  )                              AS densidade_registros_por_veiculo_dia
FROM `rj-smtr.br_rj_riodejaneiro_veiculos.gps_brt`
WHERE flag_em_operacao = TRUE
  AND data BETWEEN '2021-11-01' AND '2024-12-31'
GROUP BY ano_mes
ORDER BY ano_mes
