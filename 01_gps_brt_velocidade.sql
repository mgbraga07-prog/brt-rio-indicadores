-- Código A.1 — GPS_BRT: velocidade média, mínima, máxima e desvio-padrão mensais por serviço
-- Entrada: rj-smtr.br_rj_riodejaneiro_veiculos.gps_brt · janela nov/2021 a dez/2024
-- Processamento: filtros operacionais, agregação mensal por serviço e ponderação por registros
-- Saída: ano_mes, servico, velocidade média, mínima, máxima, desvio-padrão e nº de registros
-- Resultado esperado: 124 linhas corredor-mês após o mapeamento de serviços

SELECT
  FORMAT_DATE('%Y-%m', data)                  AS ano_mes,
  EXTRACT(YEAR FROM data)                     AS ano,
  EXTRACT(MONTH FROM data)                    AS mes,
  servico,
 
  ROUND(AVG(velocidade_estimada_10_min), 1)    AS velocidade_media_kmh,
  ROUND(MIN(velocidade_estimada_10_min), 1)    AS velocidade_minima_kmh,
  ROUND(MAX(velocidade_estimada_10_min), 1)    AS velocidade_maxima_kmh,
  ROUND(STDDEV(velocidade_estimada_10_min), 1) AS desvio_padrao_velocidade,
  COUNT(*)                                     AS total_registros_gps
 
FROM `rj-smtr.br_rj_riodejaneiro_veiculos.gps_brt`
 
WHERE flag_em_operacao = TRUE
  AND flag_em_movimento = TRUE
  AND velocidade_estimada_10_min > 0
  AND data BETWEEN '2019-01-01' AND '2024-12-31'
 
GROUP BY
  ano_mes,
  ano,
  mes,
  servico
 
ORDER BY
  ano_mes,
  servico
