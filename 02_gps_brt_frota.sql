-- Código A.2 — GPS_BRT_frota: veículos distintos em operação por mês
-- Entrada: gps_brt · nov/2021 a dez/2024
-- Processamento: contagem distinta de id_veiculo por mês
-- Saída: ano_mes, frota_operante_total
-- Resultado esperado: 38 linhas; média mensal de 583 veículos em 2024

SELECT
  FORMAT_DATE('%Y-%m', data) AS ano_mes,
  EXTRACT(YEAR FROM data) AS ano,
  EXTRACT(MONTH FROM data) AS mes,
 
  COUNT(DISTINCT id_veiculo) AS frota_operante_total
 
FROM `rj-smtr.br_rj_riodejaneiro_veiculos.gps_brt`
 
WHERE flag_em_operacao = TRUE
  AND data BETWEEN '2019-01-01' AND '2024-12-31'
 
GROUP BY
  ano_mes,
  ano,
  mes
 
ORDER BY
  ano_mes
