-- Código A.4 — Oferta de veículos distintos por hora no pico, no nível do sistema
-- Entrada: gps_brt · mesmas faixas horárias
-- Processamento: contagem distinta em toda a rede, sem agrupar por corredor
-- Saída: ano_mes, veic_hora_pico
-- Resultado esperado: 96,17 em 2022 e 298,93 em 2024 — não é a soma dos corredores

com_corredor AS (
  SELECT b.ano_mes, b.ano, b.mes, b.dia, b.hora, b.id_veiculo
  FROM base b
  JOIN mapa m ON b.servico = m.servico
),

veic_hora_dia AS (
  SELECT ano_mes, ano, mes, dia, hora,
         COUNT(DISTINCT id_veiculo) AS veiculos
  FROM com_corredor
  GROUP BY ano_mes, ano, mes, dia, hora
)

SELECT
  ano_mes,
  ano,
  mes,
  AVG(veiculos) AS veic_hora_pico,
  COUNT(*)      AS blocos_hora_dia
FROM veic_hora_dia
GROUP BY ano_mes, ano, mes
ORDER BY ano_mes
