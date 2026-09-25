# Relacionamentos do modelo dimensional

d_Mes[AnoMes]              →  GPS_BRT[ano_mes]
d_Mes[AnoMes]              →  GPS_BRT_frota[ano_mes]
d_Mes[AnoMes]              →  GPS_BRT_oferta_corredor[ano_mes]
d_Mes[AnoMes]              →  GPS_BRT_oferta_sistema[ano_mes]
d_Ano[Ano]                 →  d_Mes[Ano]
d_Ano[Ano]                 →  Passageiros por Estação[Ano]
d_Corredor[Corredor]       →  d_Corredores X Rotas[Corredor normalizado]
d_Corredor[Corredor]       →  GPS_BRT_oferta_corredor[corredor]
d_Corredor[Corredor]       →  Passageiros por Estação[Corredor]
d_Corredores X Rotas[route_short_name]  →  GPS_BRT[servico]
d_Corredores X Rotas[route_short_name]  →  d_Rotas/Viagens (2022-2026)[route_short_name]
