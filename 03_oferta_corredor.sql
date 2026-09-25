-- Código A.3 — Oferta de veículos distintos por hora no pico, no nível do corredor
-- Entrada: gps_brt · faixas horárias 7, 8, 17 e 18 · nov/2021 a dez/2024
-- Processamento: contagem distinta por corredor, hora e dia; média dos blocos hora-dia do mês
-- Saída: ano_mes, corredor, veic_hora_pico
-- Resultado esperado em 2024: TransOeste 148,96 · TransCarioca 93,55 · TransOlímpica 37,21

WITH mapa AS (
  SELECT * FROM UNNEST([
    STRUCT('10' AS servico, 'TransOeste' AS corredor),
    STRUCT('11','TransOeste'), STRUCT('11N','TransOeste'), STRUCT('12','TransOeste'),
    STRUCT('13','TransOeste'), STRUCT('14','TransOeste'), STRUCT('15','TransOeste'),
    STRUCT('16','TransOeste'), STRUCT('17','TransOeste'), STRUCT('18','TransOeste'),
    STRUCT('19','TransOeste'), STRUCT('20','TransOeste'), STRUCT('22','TransOeste'),
    STRUCT('25','TransOeste'), STRUCT('25A','TransOeste'), STRUCT('28','TransOeste'),
    STRUCT('31','TransCarioca'), STRUCT('35','TransCarioca'), STRUCT('35A','TransCarioca'),
    STRUCT('38','TransCarioca'), STRUCT('38N','TransCarioca'), STRUCT('40','TransCarioca'),
    STRUCT('40A','TransCarioca'), STRUCT('41','TransCarioca'), STRUCT('42','TransCarioca'),
    STRUCT('42A','TransCarioca'), STRUCT('43','TransCarioca'), STRUCT('46','TransCarioca'),
    STRUCT('50','TransOlímpica'), STRUCT('51','TransOlímpica'), STRUCT('51A','TransOlímpica'),
    STRUCT('52','TransOlímpica'), STRUCT('53','TransOlímpica'), STRUCT('53A','TransOlímpica'),
    STRUCT('53B','TransOlímpica'),
    STRUCT('60','TransBrasil'), STRUCT('61','TransBrasil'), STRUCT('67','TransBrasil'),
    STRUCT('68','TransBrasil'), STRUCT('70','TransBrasil'), STRUCT('73','TransBrasil'),
    STRUCT('80','TransBrasil'), STRUCT('90','TransBrasil')
  ])
),

base AS (
  SELECT
    FORMAT_DATE('%Y-%m', data) AS ano_mes,
    EXTRACT(YEAR  FROM data)   AS ano,
    EXTRACT(MONTH FROM data)   AS mes,
    DATE(data)                 AS dia,
    EXTRACT(HOUR FROM timestamp_gps) AS hora,
    servico,
    id_veiculo
  FROM `rj-smtr.br_rj_riodejaneiro_veiculos.gps_brt`
  WHERE flag_em_operacao = TRUE
    AND data BETWEEN '2021-11-01' AND '2024-12-31'
    AND EXTRACT(HOUR FROM timestamp_gps) IN (7, 8, 17, 18)
),

com_corredor AS (
  SELECT b.ano_mes, b.ano, b.mes, b.dia, b.hora, m.corredor, b.id_veiculo
  FROM base b
  JOIN mapa m ON b.servico = m.servico
),

veic_hora_dia AS (
  SELECT ano_mes, ano, mes, dia, hora, corredor,
         COUNT(DISTINCT id_veiculo) AS veiculos
  FROM com_corredor
  GROUP BY ano_mes, ano, mes, dia, hora, corredor
)

SELECT
  ano_mes,
  ano,
  mes,
  corredor,
  AVG(veiculos) AS veic_hora_pico,
  COUNT(*)      AS blocos_hora_dia
FROM veic_hora_dia
GROUP BY ano_mes, ano, mes, corredor
ORDER BY ano_mes, corredor
