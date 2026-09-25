-- Código A.5 — Verificação: oferta isolando os três corredores preexistentes
-- Entrada: gps_brt com exclusão do TransBrasil
-- Processamento: mesma contagem do Código A.4, restrita aos três corredores
-- Saída: ano, veic_hora_pico
-- Resultado esperado: 278,64 em 2024 — crescimento de 190% sobre 2022

com_corredor AS (
  SELECT b.ano_mes, b.ano, b.dia, b.hora, b.id_veiculo
  FROM base b
  JOIN mapa m ON b.servico = m.servico
  WHERE m.corredor <> 'TransBrasil'
),

veic_hora_dia AS (
  SELECT ano_mes, ano, dia, hora,
         COUNT(DISTINCT id_veiculo) AS veiculos
  FROM com_corredor
  GROUP BY ano_mes, ano, dia, hora
),

por_mes AS (
  SELECT ano_mes, ano,
         AVG(veiculos) AS veic_hora_pico_mes,
         COUNT(*)      AS blocos_hora_dia
  FROM veic_hora_dia
  GROUP BY ano_mes, ano
)

SELECT
  ano,
  AVG(veic_hora_pico_mes) AS veic_hora_pico,
  COUNT(*)                AS meses,
  AVG(blocos_hora_dia)    AS media_blocos_hora_dia
FROM por_mes
GROUP BY ano
ORDER BY ano
