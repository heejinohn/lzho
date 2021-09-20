import pandas as pd

df = pd.DataFrame()
for i in range(2012, 2020):
    global df
    globals()["data_" + str(i)] = pd.read_parquet(
        f'/scratch/ou/hohn/ticker_{i}.parquet.gzip')
    df = df.append(globals()["data_" + str(i)])
df.drop('date', axis=1, inplace=True)

df.date_utc = df.date_utc.dt.tz_convert('US/Central')
df.rename({'date_utc': 'date'}, inplace=True)
df.date = df.date.dt.tz_localize(None)

df.to_excel('/scratch/ou/hohn/ticker_combined.xlsx')
