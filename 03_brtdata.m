// Código A.16 — Power Query M: indicadores históricos do BRTData
// Entrada: extração do repositório BRTData · Saída: benchmarks de velocidade por corredor

d_Indicadores - TransCarioca Pré Intervenção =
let
  Origem = Excel.Workbook(File.Contents("[CAMINHO_BASE]\brtdata-rio_de_janeiro.xlsx"), null, false),
  TransCarioca_sheet = Origem{[Item = "TransCarioca", Kind = "Sheet"]}[Data],
  #"Filtrar nulo e espaço em branco" = each List.Select(_, each _ <> null and (not (_ is text) or Text.Trim(_) <> "")),
  #"Coluna adicionada" = Table.AddColumn(TransCarioca_sheet, "IsEmptyRow", each try List.IsEmpty(#"Filtrar nulo e espaço em branco"(Record.FieldValues(_))) otherwise false),
  #"Índice adicionado" = Table.AddIndexColumn(#"Coluna adicionada", "Coluna de índice", -1),
  #"Coluna adicionada1" = Table.AddColumn(#"Índice adicionado", "Section", each if [IsEmptyRow] then -1 else if try #"Índice adicionado"[IsEmptyRow]{[Coluna de índice]} otherwise true then [Coluna de índice] else null),
  #"Linhas em branco removidas" = Table.SelectRows(#"Coluna adicionada1", each not [IsEmptyRow]),
  #"Preenchido abaixo" = Table.FillDown(#"Linhas em branco removidas", {"Section"}),
  #"Linhas agrupadas" = Table.Group(#"Preenchido abaixo", {"Section"}, {{"Todas as linhas", each _}}, GroupKind.Local),
  #"Grupo selecionado" = #"Linhas agrupadas"[Todas as linhas]{2},
  #"Colunas removidas" = Table.RemoveColumns(#"Grupo selecionado", {"IsEmptyRow", "Coluna de índice", "Section"}),
  #"Linhas superiores removidas" = Table.Skip(#"Colunas removidas", each try List.IsEmpty(List.Skip(#"Filtrar nulo e espaço em branco"(Record.FieldValues(_)), 1)) otherwise false),
  #"As outras colunas foram removidas" = Table.SelectColumns(#"Linhas superiores removidas", List.Select(Table.ColumnNames(#"Linhas superiores removidas"), each try not List.IsEmpty(#"Filtrar nulo e espaço em branco"(Table.Column(#"Linhas superiores removidas", _))) otherwise true)),
  #"Cabeçalhos Promovidos" = Table.PromoteHeaders(#"As outras colunas foram removidas", [PromoteAllScalars=true]),
  #"Tipo Alterado" = Table.TransformColumnTypes(#"Cabeçalhos Promovidos",{{"Indicador", type text}, {"Category", type text}, {"Valor", type any}, {"Data", Int64.Type}, {"Fonte", type text}})
in
  #"Tipo Alterado"
