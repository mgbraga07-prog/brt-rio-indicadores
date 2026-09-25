# BRT Rio — indicadores operacionais a partir de dados públicos

Material técnico de suporte à monografia **"Análise comparativa de indicadores operacionais do
sistema BRT Rio antes e após sua reestruturação em 2022"**, apresentada ao MBA em Engenharia de
Dados da Escola Politécnica da UFRJ.

Autor: Matheus Graúdo Braga · Orientador: Manoel Villas Bôas Júnior, M. Sc.

O repositório reúne o pipeline completo — consultas SQL, medidas DAX, scripts Power Query M, código
Python e dicionário de dados — de modo que a análise possa ser reexecutada e auditada por terceiros.

## Fontes de dados

| Fonte | Onde obter | Cobertura | Indicadores |
|---|---|---|---|
| GPS do BRT | `rj-smtr.br_rj_riodejaneiro_veiculos.gps_brt` (Google BigQuery, público) | nov/2021 – dez/2024 | velocidade, frota, oferta |
| GTFS | Data.Rio / Mobi-Rio — feed coletado em 10/06/2025 | snapshot único | velocidade planejada, mapeamento serviço–corredor |
| Passageiros por estação | Instituto Pereira Passos / Data.Rio | 2012 – 2024 | demanda, cobertura |
| BRTData | WRI Brasil / ITDP | referência 2015 | benchmarks históricos de velocidade |

Os dois primeiros exigem acesso externo: a base de GPS é consultada diretamente no BigQuery e o
feed GTFS precisa ser baixado. As datas de coleta estão registradas nos cabeçalhos dos códigos.

## Estrutura

```
sql/          consultas de extração e agregação no BigQuery (Códigos A.1 a A.7)
dax/          medidas do modelo no Power BI (Códigos A.8 a A.13)
powerquery/   scripts M de transformação e dimensões (Códigos A.14 a A.17)
python/       análise estatística (Código A.18)
docs/         dicionário de dados e relacionamentos do modelo
```

Cada arquivo abre com um cabeçalho de quatro linhas — **entrada, processamento, saída e resultado
esperado** —, de modo que quem reexecutar saiba se chegou ao mesmo lugar.

## Ordem de execução

1. **`sql/01` a `sql/04`** — geram as quatro tabelas fato derivadas do GPS.
2. **`sql/05` a `sql/07`** — verificações: recorte dos três corredores preexistentes, serviços fora
   do mapeamento e densidade mensal da base (esta última sustenta a exclusão de novembro de 2023).
3. **`powerquery/`** — tratamento do GTFS, unpivot da série de passageiros, indicadores do BRTData e
   construção das dimensões de tempo e de corredor.
4. **`dax/`** — medidas sobre o modelo carregado, na ordem dos arquivos.
5. **`python/analise_velocidade.py`** — sobre o CSV de velocidade mensal exportado do modelo.

## Modelo dimensional

Esquema estrela com **cinco tabelas fato** — velocidade mensal, frota mensal, oferta por corredor,
oferta do sistema e passageiros por estação — e **seis dimensões**. As dimensões de mês e de ano
garantem unicidade de chave no grão dos fatos; o calendário diário permanece no modelo, oculto e
sem relacionamento. Oferta por corredor e oferta do sistema são tabelas separadas porque a contagem
de veículos distintos não é aditiva entre corredores.

Detalhamento em [`docs/dicionario_de_dados.md`](docs/dicionario_de_dados.md) e
[`docs/relacionamentos.md`](docs/relacionamentos.md).

## Valores de controle

Quem reexecutar o pipeline deve encontrar:

| Verificação | Valor |
|---|---|
| Registros brutos de GPS extraídos | 438.030.821 |
| Registros após os filtros operacionais | 215.088.299 (49,1%) |
| Veículos únicos no período | 969 |
| Oferta no pico, sistema, 2024 | 298,93 veíc./hora |
| Frota média mensal, 2024 | 583 veículos |
| Velocidade realizada, sistema, 2024 | 23,33 km/h |
| Mann-Whitney, três corredores | U = 257 / 264 / 251 de 276 comparações |

## Reprodutibilidade — o que é e o que não é coberto

**Reproduzível com este repositório:** todas as agregações sobre a base de GPS, o cálculo da
velocidade planejada a partir do feed GTFS, as transformações da série de passageiros, as medidas do
modelo e a análise estatística.

**Depende de acesso externo:** a consulta ao BigQuery exige projeto próprio com faturamento
habilitado (a base é pública, o custo de consulta não); o feed GTFS e a planilha do IPP precisam ser
baixados dos portais indicados. Como o GTFS é um snapshot e não há versões históricas publicadas, a
reexecução com um feed mais recente produzirá velocidades planejadas diferentes.

## Licença

Código sob licença MIT. Os dados pertencem às respectivas fontes públicas e estão sujeitos aos
termos de uso dos portais de origem.
