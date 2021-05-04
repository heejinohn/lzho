import pandas as pd, numpy as np, wrds
import datetime as dt

db = wrds.Connection()

# Create a set including OptionMetrics tickers
om_name = (db.get_table('optionm','secnmd')
           .groupby(['secid','ticker','issuer'])['effect_date']
           .agg(['min','max']).reset_index().rename({'min':'start','max':'end'},axis=1))

om_name['ticker'] = np.where(om_name['ticker']=='ZZZZ',np.NaN,om_name['ticker'])

ticker = set(om_name.ticker.dropna().unique())
ticker.difference_update(set(['I','WSB','SEC']))

# Read data
submission = pd.read_parquet('/scratch/ou/hohn/sub2017.parquet.gzip')

# Remove [deleted] and [removed] indicators
submission['title'] = np.where(submission['title'].isin(['[deleted]','[removed]',None]),
                             '', submission['title'])
submission['selftext'] = np.where(submission['selftext'].isin(['[deleted]','[removed]',None]),
                                '', submission['selftext'])
# Remove unwanted symbols
submission['title'] =submission['title'].str.replace('[,.\?:\(\)]',' ',regex=True)
submission['selftext'] =submission['selftext'].str.replace('[,.\?:\(\)]',' ',regex=True)
submission['title'] =submission['title'].str.replace("'s","",regex=True)
submission['selftext'] =submission['selftext'].str.replace("'s","",regex=True)

# Split texts to lists
submission['title'] =  submission['title'].str.split(' ')
submission['selftext'] =  submission['selftext'].str.split(' ')

# Define function to be applied
def find_ticker(textlist):
    global ticker
    a_set = set('$' + tic for tic in ticker)
    if len(textlist) != 0:
        hit_1 = a_set.intersection(textlist)
        if len(hit_1) > 0:
            return [s[1:] for s in hit_1]
        else:
            num_upper = len([word for word in textlist if word.isupper()])
            if num_upper / len(textlist) > .8:
                return []
            else:
                hit_2 = ticker.intersection(textlist)
                if len(hit_2) > 0:
                    return [s for s in hit_2]
                else:
                    return []

# Find ticker in title and text
submission['ticker_a'] = submission['title'].apply(find_ticker)
submission['ticker_b'] = submission['selftext'].apply(find_ticker)

# Write to file
submission.to_parquet('/scratch/ou/hohn/ticker_2017.parquet.gzip', compression='gzip')
