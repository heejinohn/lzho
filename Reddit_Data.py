import pandas as pd, numpy as np, wrds, datetime, sqlite3, requests, os
import datetime as dt
from psaw import PushshiftAPI

option_list = pd.read_sas("/scratch/ou/option_ticker.sas7bdat",encoding="utf-8")

db = wrds.Connection()

om_name = (db.get_table('optionm','secnmd')
                .groupby(['secid','ticker','issuer'])['effect_date']
                .agg(['min','max'])
                .reset_index().rename({'min':'start','max':'end'},axis=1))

om_name['ticker'] = np.where(om_name['ticker']=='ZZZZ',np.NaN,om_name['ticker'])

ticker = list(om_name.ticker.dropna().unique())

api = PushshiftAPI()

if not os.path.exists('/content/drive/MyDrive/submission.parquet.gzip'):
    field = ['id','created','created_utc','num_comments','score',
            'upvote_ratio','full_link','title','selftext','link_flair_text']
    end_epoch = int(dt.datetime(2021,1,1).timestamp())
    gen = api.search_submissions(subreddit='wallstreetbets',
                                before=end_epoch)
    submission = pd.DataFrame([post.d_ for post in gen])[field]
    submission['date'] = pd.to_datetime(submission['created'], unit='s', utc=True)
    submission['date_utc'] = pd.to_datetime(submission['created_utc'], unit='s', utc=True)
    col = submission.columns.to_list()
    col = col[0:1] + col[-2:] + col[3:-2]
    submission = submission[col]
    #submission = pd.DataFrame([post.d_ for post in gen])
    submission.to_parquet('/content/drive/MyDrive/submission.parquet.gzip', compression='gzip')

submission = pd.read_parquet('/content/drive/MyDrive/submission.parquet.gzip')

submission.set_index(['id'],inplace=True)

from dask.distributed import Client, progress
client = Client(processes=False, threads_per_worker=4,
                n_workers=1, memory_limit='2GB')
client

%matplotlib inline
import matplotlib.pyplot as plt
import dask
import dask.array as da
import dask.dataframe as dd
from dask.diagnostics import ProgressBar

submission.shape

sub_dask = dd.from_pandas(submission, npartitions=1000)

b_set = set('$' + tic for tic in ticker)
c_set = set(ticker)
sub_dask['title_split'] = sub_dask['title'].str.split()
sub_dask['selftext_split'] = sub_dask['selftext'].str.split()

sub_dask['title_ticker'] = sub_dask.title.map_partitions(find_ticker)
sub_dask['title_ticker'] = sub_dask.selftext.map_partitions(find_ticker)

submission.to_parquet('/content/drive/MyDrive/submission_ticker.parquet.gzip', compression='gzip')
