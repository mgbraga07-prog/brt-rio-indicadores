# Código A.18 — Estatísticas descritivas, teste de Mann-Whitney e autocorrelação de primeira ordem
# Entrada: CSV exportado do Power BI com corredor, AnoMes e velocidade média mensal
# Processamento: descritivas por período, IC por t de Student, Mann-Whitney e ACF de ordem 1
# Saída: tabelas impressas no console
# Resultado esperado: U = 257 / 264 / 251 de 276 comparações; p = 0,00004 / 0,00001 / 0,00009

# -*- coding: utf-8 -*-
"""
Análise estatística da velocidade média realizada por corredor — BRT Rio.

Entrada : CSV exportado do Power BI com as colunas AnoMes, corredor e
          "Vel Media Ponderada" (velocidade média ponderada do corredor no mês).
Saída   : estatísticas descritivas por período, com intervalo de confiança de 95%
          calculado pela distribuição t de Student, e teste de Mann-Whitney U
          comparando o período de transição (2022) ao período pós-intervenção
          consolidado (2023-2024).

Novembro de 2023 é excluído da amostra principal por densidade anômala de registros
na base de GPS — critério objetivo descrito na Seção 4.1.5. O teste é repetido com o
mês incluído, como análise de sensibilidade.

Nível de significância: alfa = 0,05.
"""
import sys
import numpy as np
import pandas as pd
from scipy import stats

ARQUIVO = sys.argv[1] if len(sys.argv) > 1 else 'velocidade_mensal.csv'
COL_VEL = 'Vel Media Ponderada'
CORREDORES = ['TransCarioca', 'TransOeste', 'TransOlímpica']

# ---------------------------------------------------------------- ambiente
print('Versões utilizadas')
print('  Python :', sys.version.split()[0])
print('  pandas :', pd.__version__)
print('  NumPy  :', np.__version__)
print('  SciPy  :', __import__('scipy').__version__)
print()

# ---------------------------------------------------------------- leitura
def carregar(caminho):
    """Le a exportacao do Power BI em qualquer combinacao de separador e decimal."""
    for sep, dec in ((',', '.'), (';', ','), ('\t', ',')):
        try:
            tabela = pd.read_csv(caminho, encoding='utf-8-sig', sep=sep, decimal=dec)
        except Exception:
            continue
        if tabela.shape[1] >= 3:
            return tabela
    raise SystemExit('Nao consegui ler %s. Confira se o arquivo tem tres colunas.' % caminho)


df = carregar(ARQUIVO)

# Os nomes das colunas variam conforme a exportacao; normaliza para AnoMes, corredor e a
# coluna de velocidade.
renomear = {}
for coluna in df.columns:
    chave = coluna.strip().lower()
    if chave in ('anomes', 'ano_mes', 'ano mes'):
        renomear[coluna] = 'AnoMes'
    elif chave.startswith('corredor'):
        renomear[coluna] = 'corredor'
    elif 'vel' in chave:
        renomear[coluna] = COL_VEL
df = df.rename(columns=renomear)
faltando = [c for c in ('AnoMes', 'corredor', COL_VEL) if c not in df.columns]
if faltando:
    raise SystemExit('Colunas ausentes: %s. Colunas lidas: %s'
                     % (faltando, list(df.columns)))

df['AnoMes'] = df['AnoMes'].astype(str).str.strip()
df[COL_VEL] = pd.to_numeric(df[COL_VEL], errors='coerce')
df = df.dropna(subset=[COL_VEL])

# Padroniza a grafia do corredor (a exportação pode vir com ou sem acento e com o
# prefixo "Corredor"), para que o agrupamento não se quebre por variação de rótulo.
def normaliza(nome):
    n = str(nome).strip().replace('Corredor ', '')
    chave = (n.lower().replace('á', 'a').replace('í', 'i')
                      .replace('é', 'e').replace('ô', 'o').replace('ç', 'c'))
    mapa = {'transoeste': 'TransOeste', 'transcarioca': 'TransCarioca',
            'transolimpica': 'TransOlímpica', 'transbrasil': 'TransBrasil'}
    return mapa.get(chave, n)


df['corredor'] = df['corredor'].apply(normaliza)


def periodo(ano_mes):
    ano = int(str(ano_mes)[:4])
    if ano <= 2021:
        return 'Pré-Intervenção'
    if ano == 2022:
        return 'Transição'
    return 'Pós-Intervenção'


df['periodo'] = df['AnoMes'].apply(periodo)

df_sem_nov23 = df[df['AnoMes'] != '2023-11'].copy()

# ------------------------------------------------- estatísticas descritivas
def descritivas(dados):
    linhas = []
    for corredor in CORREDORES:
        for per in ['Pré-Intervenção', 'Transição', 'Pós-Intervenção']:
            x = dados[(dados['corredor'] == corredor) &
                      (dados['periodo'] == per)][COL_VEL].values
            n = len(x)
            if n == 0:
                continue
            media = x.mean()
            dp = x.std(ddof=1) if n > 1 else np.nan
            cv = dp / media * 100 if n > 2 else np.nan
            if n > 1:
                t_crit = stats.t.ppf(0.975, df=n - 1)
                margem = t_crit * dp / np.sqrt(n)
            else:
                margem = np.nan
            linhas.append({
                'Corredor': corredor, 'Período': per, 'n': n,
                'Média': round(media, 2),
                'Desv. Padrão': round(dp, 2) if n > 1 else None,
                'CV (%)': round(cv, 2) if n > 2 else None,
                'IC 95% Inf.': round(media - margem, 2) if n > 1 else None,
                'IC 95% Sup.': round(media + margem, 2) if n > 1 else None,
            })
    return pd.DataFrame(linhas)


print('Estatísticas descritivas (novembro/2023 excluído)')
print(descritivas(df_sem_nov23).to_string(index=False))
print()
print('Nota: o CV não é reportado para o período Pré-Intervenção, composto por apenas')
print('duas observações mensais, uma delas com sete dias de registros.')
print()

# ------------------------------------------------------- Mann-Whitney U
def mann_whitney(dados, rotulo):
    print('Teste de Mann-Whitney U — Transição (2022) vs. Pós-Intervenção (2023–2024) — %s'
          % rotulo)
    for corredor in CORREDORES:
        a = dados[(dados['corredor'] == corredor) &
                  (dados['periodo'] == 'Transição')][COL_VEL].values
        b = dados[(dados['corredor'] == corredor) &
                  (dados['periodo'] == 'Pós-Intervenção')][COL_VEL].values
        u, p = stats.mannwhitneyu(a, b, alternative='two-sided')
        z = stats.norm.isf(p / 2)
        r = z / np.sqrt(len(a) + len(b))
        print('  %-14s U = %6.1f   p = %.5f   n_trans = %2d   n_pos = %2d   r = %.3f'
              % (corredor, u, p, len(a), len(b), r))
    print()


mann_whitney(df_sem_nov23, 'amostra principal')
mann_whitney(df, 'sensibilidade, com novembro/2023')

# ------------------------------------------- autocorrelação de primeira ordem
print('Autocorrelação de primeira ordem da série mensal (jan/2022 a dez/2024)')
for corredor in CORREDORES:
    serie = df_sem_nov23[(df_sem_nov23['corredor'] == corredor) &
                         (df_sem_nov23['AnoMes'] >= '2022-01')].sort_values('AnoMes')
    x = serie[COL_VEL].values
    # Estimador amostral padrão da função de autocorrelação (ACF), com a média e a
    # variância calculadas sobre toda a série.
    media_serie = x.mean()
    r1 = (np.sum((x[:-1] - media_serie) * (x[1:] - media_serie)) /
          np.sum((x - media_serie) ** 2))
    limite = 1.96 / np.sqrt(len(x))
    print('  %-14s r1 = %+.3f   n = %2d   limite 5%% = ±%.3f   %s'
          % (corredor, r1, len(x), limite,
             'significativa' if abs(r1) > limite else 'não significativa'))
