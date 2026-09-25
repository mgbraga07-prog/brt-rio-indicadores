# BRT Rio — indicadores operacionais a partir de dados públicos
 
Material técnico de suporte à monografia **"Análise comparativa de indicadores operacionais do
sistema BRT Rio antes e após sua reestruturação em 2022"**, apresentada ao MBA em Engenharia de
Dados da Escola Politécnica da UFRJ.
 
Autor: Matheus Graúdo Braga · Orientador: Manoel Villas Bôas Júnior, M. Sc.
 
O repositório reúne o pipeline completo — consultas SQL, medidas DAX, scripts Power Query M, código
Python e dicionário de dados — de modo que a análise possa ser reexecutada e auditada por terceiros.
A numeração dos arquivos corresponde à do Apêndice 1 da monografia.
 
## Fontes de dados
 
| Fonte | Onde obter | Cobertura | Indicadores |
|---|---|---|---|
| GPS do BRT | `rj-smtr.br_rj_riodejaneiro_veiculos.gps_brt` (Google BigQuery, público) | nov/2021 – dez/2024 | velocidade, frota, oferta |
| GTFS | Data.Rio / Mobi-Rio — feed coletado em 10/06/2025 | snapshot único | velocidade planejada, mapeamento serviço–corredor |
| Passageiros por estação | Instituto Pereira Passos / Data.Rio | 2012 – 2024 | demanda, cobertura |
| BRTData | WRI Brasil / ITDP | referência 2015 | benchmarks históricos de velocidade |
 
Os dois primeiros exigem acesso externo: a base de GPS é consultada diretamente no BigQuery e o
feed GTFS precisa ser baixado. As datas de coleta estão registradas nos cabeçalhos dos arquivos.
 
## Índice dos arquivos
 
Cada arquivo abre com um cabeçalho de quatro linhas — **entrada, processamento, saída e resultado
esperado** —, de modo que quem reexecutar saiba se chegou ao mesmo lugar.
 
### Consultas SQL — extração e agregação no BigQuery
 
| Código | Arquivo | O que produz |
|---|---|---|
| A.1 | `01_gps_brt_velocidade.sql` | velocidade média, mínima, máxima e desvio-padrão mensais por serviço |
| A.2 | `02_gps_brt_frota.sql` | veículos distintos em operação por mês |
| A.3 | `03_oferta_corredor.sql` | oferta na hora pico, no nível do corredor |
| A.4 | `04_oferta_sistema.sql` | oferta na hora pico, no nível do sistema |
| A.5 | `05_verif_tres_corredores.sql` | verificação: oferta isolando os três corredores preexistentes |
| A.6 | `06_verif_servicos_nao_mapeados.sql` | verificação: serviços ausentes do mapeamento |
| A.7 | `07_verif_cobertura_densidade.sql` | verificação: cobertura e densidade de telemetria mês a mês |
 
### Medidas DAX — modelo no Power BI
 
| Código | Arquivo | O que produz |
|---|---|---|
| A.8 | `01_velocidade.dax` | velocidade realizada, planejada e a diferença entre ambas |
| A.9 | `02_frota.dax` | frota média mensal e referências institucionais |
| A.10 | `03_oferta_pico.dax` | oferta na hora pico, por corredor e para o sistema |
| A.11 | `04_demanda.dax` | demanda total, índice de recuperação e passageiros por estação |
| A.12 | `05_heterogeneidade.dax` | crescimento e dispersão da demanda por estação |
| A.13 | `06_auxiliares.dax` | rótulos e medidas de apoio à visualização |
 
### Power Query M — transformação e dimensões
 
| Código | Arquivo | O que produz |
|---|---|---|
| A.14 | `01_gtfs.m` | tratamento do feed GTFS e velocidade planejada por viagem |
| A.15 | `02_passageiros_unpivot.m` | unpivot da série de passageiros por estação |
| A.16 | `03_brtdata.m` | benchmarks históricos do BRTData |
| A.17 | `04_dimensoes.m` | dimensões de mês, de ano e de corredor |
 
### Python — análise estatística
 
| Código | Arquivo | O que produz |
|---|---|---|
| A.18 | `analise_velocidade.py` | descritivas, intervalos de confiança, Mann-Whitney e autocorrelação |
 
Dependências em `requirements.txt`.
 
### Documentação
 
- `dicionario_de_dados.md` — campos, tipos, unidades, descrição e origem de cada tabela
- `relacionamentos.md` — relacionamentos do modelo dimensional
## Ordem de execução
 
1. **`01_gps_brt_velocidade.sql` a `04_oferta_sistema.sql`** — geram as quatro tabelas fato
   derivadas do GPS.
2. **`05_` a `07_`** — verificações: recorte dos três corredores preexistentes, serviços fora do
   mapeamento e densidade mensal da base (esta última sustenta a exclusão de novembro de 2023).
3. **Arquivos `.m`** — tratamento do GTFS, unpivot da série de passageiros, indicadores do BRTData
   e construção das dimensões.
4. **Arquivos `.dax`** — medidas sobre o modelo carregado, na ordem da numeração.
5. **`analise_velocidade.py`** — sobre o CSV de velocidade mensal exportado do modelo.
## Modelo dimensional
 
Esquema estrela com **cinco tabelas fato** — velocidade mensal, frota mensal, oferta por corredor,
oferta do sistema e passageiros por estação — e **seis dimensões**. As dimensões de mês e de ano
garantem unicidade de chave no grão dos fatos; o calendário diário permanece no modelo, oculto e
sem relacionamento. Oferta por corredor e oferta do sistema são tabelas separadas porque a contagem
de veículos distintos não é aditiva entre corredores.
 
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
 
