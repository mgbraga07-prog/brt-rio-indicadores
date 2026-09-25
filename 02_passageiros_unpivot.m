// Código A.15 — Power Query M: unpivot da série de passageiros por estação
// Entrada: planilha do IPP (2012–2024) · Saída: formato longitudinal com coluna de período

Passageiros por Estação =
let
    Fonte = Excel.Workbook(File.Contents("[CAMINHO_BASE]\Passageiros transportados no Sistema BRT.xls"), null, true),
    #"T 1" = Fonte{[Name="T 3603"]}[Data],
    #"Linhas Superiores Removidas" = Table.Skip(#"T 1",5),
    #"Cabeçalhos Promovidos" = Table.PromoteHeaders(#"Linhas Superiores Removidas", [PromoteAllScalars=true]),
    #"Colunas Renomeadas" = Table.RenameColumns(#"Cabeçalhos Promovidos",{{"Column1", "Estações"}}),
    #"Linhas Filtradas" = Table.SelectRows(#"Colunas Renomeadas", each (
        [Estações] <> null
        and [Estações] <> " -  Dado numérico igual a zero não resultante de arredondamento."
        and [Estações] <> " ... Dado numérico não disponível."
        and [Estações] <> "(1) - A estação Alvorada também atende ao Corredor Transcarioca."
        and [Estações] <> "De 2012 a 2014: Fetranspor - Federação das Empresas de Transportes de Passageiros do Estado do Rio de Janeiro."
        and [Estações] <> "De 2015 em diante: SMTR - Secretaria Municipal de Transportes da Cidade do Rio de Janeiro."
        and [Estações] <> "Fonte:"
        and [Estações] <> "Notas:     "
        and [Estações] <> "Total"
    )),
    // Identifica linhas de cabeçalho de corredor e preenche para baixo, associando cada estação ao seu corredor
    #"Corredor Criado" = Table.AddColumn(
        #"Linhas Filtradas",
        "Corredor",
        each if Text.StartsWith([Estações], "Corredor") then [Estações] else null,
        type text
    ),
    #"Corredor Preenchido" = Table.FillDown(#"Corredor Criado",{"Corredor"}),
    #"Linhas Filtradas1" = Table.SelectRows(#"Corredor Preenchido", each true),
    #"Linhas Filtradas2" = Table.SelectRows(#"Linhas Filtradas1", each not Text.Contains([Estações], "Corredor")),
    #"Valor Substituído" = Table.ReplaceValue(#"Linhas Filtradas2","-","null",Replacer.ReplaceValue,{"2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019", "2020", "2021", "2022", "2023", "2024", "Corredor"}),
    #"Valor Substituído1" = Table.ReplaceValue(#"Valor Substituído"," ","",Replacer.ReplaceText,{"2012"}),
    #"Tipo Alterado" = Table.TransformColumnTypes(#"Valor Substituído1",{{"2012", type number}, {"2013", type number}, {"2014", type number}, {"2015", type number}, {"2016", type number}, {"2017", type number}, {"2018", type number}, {"2019", type number}, {"2020", type number}, {"2021", type number}, {"2022", type number}, {"2023", type number}, {"2024", type number}}),
    #"Texto Aparado" = Table.TransformColumns(#"Tipo Alterado",{{"Estações", Text.Trim, type text}, {"Corredor", Text.Trim, type text}}),
    #"Colocar Cada Palavra Em Maiúscula" = Table.TransformColumns(#"Texto Aparado",{{"Estações", Text.Proper, type text}, {"Corredor", Text.Proper, type text}}),
    #"Colunas Removidas" = Table.RemoveColumns(#"Colocar Cada Palavra Em Maiúscula",{ "Column15", "Column16"}),
    // unpivot: transforma colunas de ano (2012...2024) em linhas
    #"Colunas Não Dinâmicas" = Table.UnpivotOtherColumns(#"Colunas Removidas", {"Estações", "Corredor"}, "Ano", "Passageiros"),
    #"Valor Substituído2" = Table.ReplaceValue(#"Colunas Não Dinâmicas","Corredor ","",Replacer.ReplaceText,{"Corredor"}),
    #"Tipo Alterado1" = Table.TransformColumnTypes(#"Valor Substituído2",{{"Ano", Int64.Type}, {"Passageiros", type number}}),
    // classificação em três categorias de período
    #"Periodo Adicionado" = Table.AddColumn(
        #"Tipo Alterado1",
        "Periodo",
        each if [Ano] < 2022 then "Pré-Intervenção"
        else if [Ano] = 2022 then "Transição"
        else "Pós-Intervenção",
        type text
    )
in
    #"Periodo Adicionado"
