// Código A.14 — Power Query M: tratamento do feed GTFS
// Entrada: arquivos do feed GTFS coletado em 10/06/2025 · Saída: rotas, viagens e velocidade planejada

agency =
let
    Fonte = Folder.Files("[CAMINHO_BASE]\GTFS_RIO-DE-JANEIRO"),
    #"...\_agency txt" = Fonte{[#"Folder Path"="...\GTFS_RIO-DE-JANEIRO\",Name="agency.txt"]}[Content],
    #"CSV Importado" = Csv.Document(#"...\_agency txt",[Delimiter=",", Columns=5, Encoding=1252, QuoteStyle=QuoteStyle.None]),
    #"Cabeçalhos Promovidos" = Table.PromoteHeaders(#"CSV Importado", [PromoteAllScalars=true]),
    #"Linhas Filtradas" = Table.SelectRows(#"Cabeçalhos Promovidos", each ([agency_id] = "20001"))
in
    #"Linhas Filtradas"

stop_times =
let
    Fonte = Folder.Files("[CAMINHO_BASE]\GTFS_RIO-DE-JANEIRO"),
    #"...\_stop_times txt" = Fonte{[#"Folder Path"="...\GTFS_RIO-DE-JANEIRO\",Name="stop_times.txt"]}[Content],
    #"CSV Importado" = Csv.Document(#"...\_stop_times txt",[Delimiter=",", Columns=8, Encoding=1252, QuoteStyle=QuoteStyle.None]),
    #"Cabeçalhos Promovidos" = Table.PromoteHeaders(#"CSV Importado", [PromoteAllScalars=true]),
    #"Tipo Alterado" = Table.TransformColumnTypes(#"Cabeçalhos Promovidos",{{"stop_sequence", Int64.Type}}),
    #"Linhas Classificadas" = Table.Sort(#"Tipo Alterado",{{"trip_id", Order.Ascending}, {"stop_sequence", Order.Ascending}}),
    #"Valor Substituído" = Table.ReplaceValue(#"Linhas Classificadas",".",",",Replacer.ReplaceText,{"shape_dist_traveled"}),
 
    #"Horários Ajustados" =
        Table.TransformColumns(
            #"Valor Substituído",
            {
                {"arrival_time", each let p=Text.Split(_,":"), h=Number.From(p{0}), nh=if h>=24 then h-24 else h in Text.PadStart(Text.From(nh),2,"0")&":"&p{1}&":"&p{2}, type text},
                {"departure_time", each let p=Text.Split(_,":"), h=Number.From(p{0}), nh=if h>=24 then h-24 else h in Text.PadStart(Text.From(nh),2,"0")&":"&p{1}&":"&p{2}, type text}
            }
        ),
 
    #"Tipo Hora" =
        Table.TransformColumnTypes(#"Horários Ajustados",{{"arrival_time", type time}, {"departure_time", type time}, {"shape_dist_traveled", type number}})
in
    #"Tipo Hora"

d_Velocidade_Operacional_Planejada (2022- =
let
    Fonte = Table.NestedJoin(
        stop_times_1a_Parada,
        {"trip_id"},
        stop_times_Ultima_Parada,
        {"trip_id"},
        "stop_times_Ultima_Parada",
        JoinKind.LeftOuter
    ),
 
    #"stop_times_Ultima_Parada Expandido" =
        Table.ExpandTableColumn(
            Fonte,
            "stop_times_Ultima_Parada",
            {"departure_time", "shape_dist_traveled"},
            {"stop_times_Ultima_Parada.departure_time", "stop_times_Ultima_Parada.shape_dist_traveled"}
        ),
 
    #"Duração Adicionada" =
        Table.AddColumn(
            #"stop_times_Ultima_Parada Expandido",
            "Duracao",
            each
                let
                    Dif = [stop_times_Ultima_Parada.departure_time] - [arrival_time]
                in
                    if Dif < #duration(0,0,0,0)
                    then Dif + #duration(1,0,0,0)
                    else Dif
        ),
 
    #"Tempo Horas Adicionado" =
        Table.AddColumn(#"Duração Adicionada", "Tempo_Horas", each Duration.TotalHours([Duracao]), type number),
    #"Colunas Removidas" = Table.RemoveColumns(#"Tempo Horas Adicionado",{"Duracao"}),
    #"Colunas Renomeadas" = Table.RenameColumns(#"Colunas Removidas",{{"stop_times_Ultima_Parada.shape_dist_traveled", "Distancia Viagem"}}),
    // velocidade planejada = distância (m) / tempo (h) / 1000 → km/h
    #"Personalização Adicionada" = Table.AddColumn(#"Colunas Renomeadas", "Velocidade Operacional Planejada", each [Distancia Viagem] / [Tempo_Horas] / 1000),
    #"Colunas Renomeadas1" = Table.RenameColumns(#"Personalização Adicionada",{{"arrival_time", "Horario Início"}, {"stop_times_Ultima_Parada.departure_time", "Horario Fim"}})
in
    #"Colunas Renomeadas1"

d_Rotas (2022-2026) =
let
    Fonte = Table.NestedJoin(routes, {"route_id"}, fare_rules, {"route_id"}, "fare_rules", JoinKind.LeftOuter),
    #"fare_rules Expandido" = Table.ExpandTableColumn(Fonte, "fare_rules", {"fare_id"}, {"fare_rules.fare_id"}),
    #"Linhas Filtradas" = Table.SelectRows(#"fare_rules Expandido", each ([fare_rules.fare_id] = "BRT" or [fare_rules.fare_id] = "BRT_Exec")),
    #"Consultas Mescladas" = Table.NestedJoin(#"Linhas Filtradas", {"fare_rules.fare_id"}, fare_attributes, {"fare_id"}, "fare_attributes", JoinKind.LeftOuter),
    #"fare_attributes Expandido" = Table.ExpandTableColumn(#"Consultas Mescladas", "fare_attributes", {"price"}, {"fare_attributes.price"}),
    #"Linhas Classificadas" = Table.Sort(#"fare_attributes Expandido",{{"route_short_name", Order.Ascending}}),
    #"Colunas Removidas" = Table.RemoveColumns(#"Linhas Classificadas",{"route_color", "route_text_color"}),
    #"Consultas Mescladas1" = Table.NestedJoin(#"Colunas Removidas", {"route_short_name"}, #"d_Corredores X Rotas", {"route_short_name"}, "d_Corredores X Rotas", JoinKind.LeftOuter),
    #"d_Corredores X Rotas Expandido" = Table.ExpandTableColumn(#"Consultas Mescladas1", "d_Corredores X Rotas", {"corredor"}, {"d_Corredores X Rotas.corredor"})
in
    #"d_Corredores X Rotas Expandido"

let
    Fonte = #table(
        type table [route_short_name = text, corredor = text],
        {
            {"10",  "Corredor Transoeste"},   {"11",  "Corredor Transoeste"},
            {"12",  "Corredor Transoeste"},   {"13",  "Corredor Transoeste"},
            {"14",  "Corredor Transoeste"},   {"15",  "Corredor Transoeste"},
            {"16",  "Corredor Transoeste"},   {"17",  "Corredor Transoeste"},
            {"18",  "Corredor Transoeste"},   {"19",  "Corredor Transoeste"},
            {"20",  "Corredor Transoeste"},   {"22",  "Corredor Transoeste"},
            {"25",  "Corredor Transoeste"},   {"25A", "Corredor Transoeste"},
            {"11N", "Corredor Transoeste"},   {"28",  "Corredor Transoeste (Conexão BRT)"},
            {"31",  "Corredor Transcarioca"}, {"35",  "Corredor Transcarioca"},
            {"35A", "Corredor Transcarioca"}, {"38",  "Corredor Transcarioca"},
            {"38N", "Corredor Transcarioca"}, {"40",  "Corredor Transcarioca"},
            {"40A", "Corredor Transcarioca"}, {"41",  "Corredor Transcarioca"},
            {"42",  "Corredor Transcarioca"}, {"42A", "Corredor Transcarioca"},
            {"43",  "Corredor Transcarioca"}, {"46",  "Corredor Transcarioca"},
            {"50",  "Corredor Transolímpica"},{"51",  "Corredor Transolímpica"},
            {"51A", "Corredor Transolímpica"},{"52",  "Corredor Transolímpica"},
            {"53",  "Corredor Transolímpica"},{"53A", "Corredor Transolímpica"},
            {"53B", "Corredor Transolímpica"},
            {"60",  "Corredor Transbrasil"},  {"61",  "Corredor Transbrasil"},
            {"67",  "Corredor Transbrasil (Conexão BRT)"},
            {"68",  "Corredor Transbrasil (Conexão BRT)"},
            {"70",  "Corredor Transbrasil"},  {"73",  "Corredor Transbrasil"},
            {"80",  "Corredor Transbrasil"},  {"90",  "Corredor Transbrasil"}
        }
    )
in
    Fonte

Corredor normalizado =
SWITCH(
    TRUE(),
    CONTAINSSTRING('d_Corredores X Rotas'[corredor], "Transoeste"),    "TransOeste",
    CONTAINSSTRING('d_Corredores X Rotas'[corredor], "Transcarioca"),  "TransCarioca",
    CONTAINSSTRING('d_Corredores X Rotas'[corredor], "Transolímpica"), "TransOlímpica",
    CONTAINSSTRING('d_Corredores X Rotas'[corredor], "Transbrasil"),   "TransBrasil",
    "Não classificado"
)
