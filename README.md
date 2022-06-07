# Literature review:
it summarizes contemporaneous papers focusing on Robinhood and Reddit data, and illustrates how our project is different from those studies.

# Merge Reddit with option volume:
Option trading was our initial focus of this project. I grab option trading volume data from OptionMetrics, merge it with CRSP and Reddit data, and try to see if the correlation between retail attention and option trading volume is positive.

# Option_Measures:
I read papers related to option trading and summarize option measures used in these studies. 

# Research design:
Our purpose of this project to to examine the price informativeness of retail investor trading and how it affects management disclosure (managerial learning). I propoased some research designs for this project, such as event study and diff-in-diff setting.

# Unusual option trading:
In this SAS file, I would like to identify unusual option trading. Again, I grab option trading data from OptionMetrics and define unusual option trading if the daily volume is greater than 200% of the last 30 days' average trading volume. 

# oclink:
This file is a SAS macro showing how to link OptionMetrics to CRSP. 

# Option trading-quarterly data:
This code is to obtain quarterly option trading data and merge with attention measures used in Da et al.(2011). Then I did PSM based on retail investor attention measures. In order to implement the diff-in-diff design, I use the year in which option trading is avaialble on Robinhood to identify control groups (2017). 

# Option trading:
This code is to obtain daily option trading data and merge with attention measures used in Da et al.(2011). I also did PSM based on retail investor attention measures used in Da et al.(2011).

# Option_wrds_cloud:
The purpose of this code to grab tickers from Optionm.secnmd file. 

# Project.bib:
In this file, I added references of contemporaneous papers using Robinhood and Rediit data. 

# Retail investor popularity-quarterly data:
In this code, I construct variables used in Da et al.(2011), including quarterly market capitalization, firm size, analyst coverage, quarterly return, trading volume turnover and institutional ownership. (the code might be incomplete since granger causality result was not done when I write this).  
