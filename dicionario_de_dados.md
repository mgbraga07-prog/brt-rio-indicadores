# Dicionário de dados

Estrutura padronizada: **campo · tipo · unidade · descrição · origem**. Todas as tabelas fato
estão no grão mensal ou anual; as dimensões carregam chave única no grão dos fatos.

Fontes: GPS do BRT (`rj-smtr.br_rj_riodejaneiro_veiculos.gps_brt`, Google BigQuery), feed GTFS da
Mobi-Rio (coleta de 10/06/2025), série de passageiros por estação do IPP/Data.Rio (2012–2024) e
repositório BRTData (WRI/ITDP).

## 6. Dicionário de dados

## 6.1 Tabelas fato

GPS_BRT — velocidade mensal agregada por serviço. Fonte: base de GPS no BigQuery. Nível de detalhe: serviço × mês.

| Coluna | Tipo | Descrição |
|---|---|---|
| ano_mes | string | Ano-mês no formato YYYY-MM |
| ano | int64 | Ano |
| mes | int64 | Mês |
| servico | string | Rota/serviço registrado no GPS |
| velocidade_media_kmh | double | Velocidade média em movimento no mês (km/h) |
| velocidade_minima_kmh | double | Velocidade mínima registrada no mês |
| velocidade_maxima_kmh | double | Velocidade máxima registrada no mês |
| desvio_padrao_velocidade | double | Desvio-padrão da velocidade no mês |
| total_registros_gps | int64 | Registros de GPS agregados; peso da ponderação |

GPS_BRT_frota — frota operante mensal. Nível de detalhe: mês.

| Coluna | Tipo | Descrição |
|---|---|---|
| ano_mes | string | Ano-mês |
| ano | int64 | Ano |
| mes | int64 | Mês |
| frota_operante_total | int64 | Veículos únicos (id_veiculo) em operação no mês |

GPS_BRT_oferta_corredor — oferta de veículos distintos por hora no pico. Nível de detalhe: corredor × mês.

| Coluna | Tipo | Descrição |
|---|---|---|
| ano_mes | string | Ano-mês |
| ano | int64 | Ano |
| mes | int64 | Mês |
| corredor | string | Corredor, já na grafia normalizada |
| veic_hora_pico | double | Média de veículos distintos por faixa horária de pico no mês |
| blocos_hora_dia | int64 | Pares dia × faixa horária que compõem a média; controle de cobertura |

GPS_BRT_oferta_sistema — oferta de veículos distintos por hora no pico, no nível do sistema. Nível de detalhe: mês.

| Coluna | Tipo | Descrição |
|---|---|---|
| ano_mes | string | Ano-mês |
| ano | int64 | Ano |
| mes | int64 | Mês |
| veic_hora_pico | double | Média de veículos distintos por faixa horária de pico no sistema |
| blocos_hora_dia | int64 | Pares dia × faixa horária que compõem a média |

Passageiros por Estação — série histórica de demanda. Fonte: Data.Rio / IPP. Nível de detalhe: estação × ano.

| Coluna | Tipo | Descrição |
|---|---|---|
| Corredor | string | Corredor da estação |
| Estações | string | Nome da estação |
| Ano | int64 | Ano de referência (2012–2024) |
| Passageiros | double | Total de passageiros transportados no ano |
| Periodo | string | Classificação: Pré-Intervenção / Transição / Pós-Intervenção |

## 6.2 Tabelas dimensão

d_Mes — dimensão de tempo no nível mensal; chave AnoMes única.

| Coluna | Descrição |
|---|---|
| AnoMes | Chave da dimensão, no formato YYYY-MM |
| Ano, MesNum, Mes, Trimestre | Atributos derivados da data |
| Periodo | Pré-Intervenção / Transição / Pós-Intervenção |
| Periodo Ordem | Versão numérica de Periodo, usada para ordenação (0/1/2) |
| Anomalia GPS | Sinaliza o mês excluído da análise de velocidade (Sim/Não) |

d_Ano — dimensão de tempo no nível anual; chave Ano única.

| Coluna | Descrição |
|---|---|
| Ano | Chave da dimensão |
| Periodo | Pré-Intervenção / Transição / Pós-Intervenção |
| Periodo Ordem | Versão numérica de Periodo, usada para ordenação |

d_Corredor — dimensão de corredor; chave Corredor única, com quatro linhas.

| Coluna | Descrição |
|---|---|
| Corredor | Chave da dimensão: TransOeste, TransCarioca, TransOlímpica, TransBrasil |
| Ordem | Ordenação por data de inauguração do corredor |
| Preexistente | Sim para os corredores anteriores à intervenção; Não para o TransBrasil |

d_Corredores X Rotas — associação entre serviço e corredor; chave route_short_name.

| Coluna | Descrição |
|---|---|
| route_short_name | Código da rota, chave da tabela (ex.: 42, 10) |
| corredor | Corredor associado, na grafia do GTFS |
| Corredor normalizado | Grafia unificada, com as variantes de conexão agregadas |

d_Rotas/Viagens (2022-2026) — dimensão de rotas e viagens do GTFS, com a velocidade planejada por viagem.

| Coluna | Descrição |
|---|---|
| route_id, route_short_name, route_long_name, route_desc, route_type | Atributos da rota (GTFS routes.txt) |
| agency_id | Operadora |
| fare_rules.fare_id, fare_attributes.price | Tarifa associada; filtrado para BRT e BRT Executivo |
| trip_id, service_id, trip_headsign | Identificação da viagem (GTFS trips.txt) |
| Horario Início, Horario Fim | Horário da primeira e da última parada da viagem |
| Distancia Viagem | Distância percorrida (m), de shape_dist_traveled |
| Tempo_Horas | Duração da viagem em horas |
| Velocidade Operacional Planejada | Distância dividida por tempo, em km/h |

d_Indicadores - [Corredor] Pré Intervenção — uma tabela por corredor (TransCarioca, TransOeste e TransOlímpica). Fonte primária: planilha brtdata-rio_de_janeiro.xlsx (WRI Brasil / ITDP), uma aba por corredor.

| Coluna | Descrição |
|---|---|
| Indicador | Nome do indicador no BRTData |
| Category | Categoria do indicador na fonte |
| Valor | Valor em texto bruto, que requer extração |
| Data | Ano de referência do indicador |
| Fonte | Fonte declarada na planilha do BRTData |

d_calendario — calendário diário de 2012 a 2030, origem das dimensões d_Mes e d_Ano. Permanece oculto e sem relacionamento com as tabelas fato.

| Coluna | Descrição |
|---|---|
| Date | Data-chave (01/01/2012 a 31/12/2030) |
| Ano, MesNum, Mes, AnoMes, Trimestre | Decomposições de data |
| Dia, DiaSemanaNum, DiaSemana, SemanaAno | Atributos de calendário adicionais |
| Periodo | Pré-Intervenção / Transição / Pós-Intervenção |

Este material suplementar acompanha o artigo referenciado na Seção 2.3.2 e deve ser consultado em conjunto com o texto principal para reprodução completa do pipeline.
