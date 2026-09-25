// Código A.17 — Power Query M: dimensões de tempo e de corredor
// Entrada: calendário diário e mapeamento serviço-corredor · Saída: d_Mes, d_Ano, d_Corredor

d_calendario =
ADDCOLUMNS (
    CALENDAR ( DATE ( 2012, 1, 1 ), DATE ( 2030, 12, 31 ) ),
    "Ano", YEAR ( [Date] ),
    "MesNum", MONTH ( [Date] ),
    "Mes", FORMAT ( [Date], "MMMM" ),
    "AnoMes", FORMAT ( [Date], "YYYY-MM" ),
    "Trimestre", "T" & QUARTER ( [Date] ),
    "Dia", DAY ( [Date] ),
    "DiaSemanaNum", WEEKDAY ( [Date], 2 ),
    "DiaSemana", FORMAT ( [Date], "DDDD" ),
    "SemanaAno", WEEKNUM ( [Date], 2 )
)

Periodo =
IF(
    d_calendario[Ano] < 2022, "Pré-Intervenção",
    IF(
        d_calendario[Ano] = 2022, "Transição",
        "Pós-Intervenção"
    )
)

d_Mes =
ADDCOLUMNS (
    SUMMARIZE (
        d_calendario,
        d_calendario[AnoMes],
        d_calendario[Ano],
        d_calendario[MesNum],
        d_calendario[Mes],
        d_calendario[Trimestre]
    ),
    "Periodo",
        SWITCH (
            TRUE (),
            d_calendario[Ano] <= 2021, "Pré-Intervenção",
            d_calendario[Ano] = 2022, "Transição",
            "Pós-Intervenção"
        ),
    "Periodo Ordem",
        SWITCH (
            TRUE (),
            d_calendario[Ano] <= 2021, 0,
            d_calendario[Ano] = 2022, 1,
            2
        )
)

Anomalia GPS = IF ( d_Mes[AnoMes] = "2023-11", "Sim", "Não" )

d_Ano =
ADDCOLUMNS (
    DISTINCT ( SELECTCOLUMNS ( d_calendario, "Ano", d_calendario[Ano] ) ),
    "Periodo",
        SWITCH (
            TRUE (),
            [Ano] <= 2021, "Pré-Intervenção",
            [Ano] = 2022, "Transição",
            "Pós-Intervenção"
        ),
    "Periodo Ordem",
        SWITCH ( TRUE (), [Ano] <= 2021, 0, [Ano] = 2022, 1, 2 )
)

d_Corredor =
VAR Base =
    DISTINCT (
        SELECTCOLUMNS (
            'd_Corredores X Rotas',
            "Corredor", 'd_Corredores X Rotas'[Corredor normalizado]
        )
    )
RETURN
ADDCOLUMNS (
    Base,
    "Ordem",
        SWITCH (
            [Corredor],
            "TransOeste", 1,
            "TransCarioca", 2,
            "TransOlímpica", 3,
            "TransBrasil", 4,
            99
        ),
    "Preexistente", IF ( [Corredor] = "TransBrasil", "Não", "Sim" )
)
