import pandas as pd, numpy as np, wrds, datetime, sqlite3, requests, os
import datetime as dt
from psaw import PushshiftAPI

option_list = pd.read_sas("/scratch/ou/option_ticker.sas7bdat",encoding="utf-8")

om_name = (db.get_table('optionm','secnmd')
                .groupby(['secid','ticker','issuer'])['effect_date']
                .agg(['min','max'])
                .reset_index().rename({'min':'start','max':'end'},axis=1))

om_name['ticker'] = np.where(om_name['ticker']=='ZZZZ',np.NaN,om_name['ticker'])

ticker = list(om_name.ticker.dropna().unique())

def find_ticker(text):
    global ticker
    a_set = set('$' + tic for tic in ticker)
    b_set = set(tic for tic in ticker)
    text = set(text.split())
    hit_1 = a_set.intersection(text)
    hit_2 = b_set.intersection(text)
    if len(hit_1) > 0:
        return [s[1:] for s in hit_1]
    else:
        if len(hit_2) > 0:
            return [s for s in hit_2]
        else:
            return []

submission = pd.read_parquet('/scratch/ou/hohn/sub2020.parquet.gzip')
submission['title_ticker'] = submission['title'].apply(find_ticker)
submission['selftext_ticker'] = submission['selftext'].apply(find_ticker)

submission.to_parquet('/content/drive/MyDrive/ticker_2020.parquet.gzip', compression='gzip')
