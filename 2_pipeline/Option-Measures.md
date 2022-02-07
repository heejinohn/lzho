::: {.container-fluid .main-container}
::: {.row-fluid}
::: {.col-xs-12 .col-sm-4 .col-md-3}
::: {#TOC .tocify}
:::
:::

::: {.toc-content .col-xs-12 .col-sm-8 .col-md-9}
::: {#header .fluid-row}
::: {.btn-group .pull-right}
Code []{.caret}

-   [Show All Code](#){#rmd-show-all-code}
-   [Hide All Code](#){#rmd-hide-all-code}
:::

# Option Measures {#option-measures .title .toc-ignore}

#### Ling Zhang {#ling-zhang .author}

#### 3/21/2021 {#section .date}
:::

::: {#mergers-and-acquisitions .section .level1}
# Mergers and Acquisitions

::: {#augustin-brenner-and-subrahmanyam-ms-2019 .section .level2}
## Augustin, Brenner and Subrahmanyam MS 2019

::: {#research-question .section .level3}
### Research question

They study the sources of the preannouncement run-up in option volumes
around takeovers.
:::

::: {#measures .section .level3}
### Measures

Abnormal trading volumes: they use a market model for volume to identify
abnormal trading volumes. This model accounts for the market volume in
options, the CBOE volatility index and the returns on the S&P index.

They restrict the study to deals aimed at affecting a change of control
and eliminate deals with a transaction value below \$1 million. They
require a minimum of 90 days of valid stock and option price and volume
information on the target prior to and including the announcement date.
:::
:::

::: {#caochen-and-griffin-jb-2005 .section .level2}
## Cao,Chen and Griffin JB 2005

::: {#research-question-1 .section .level3}
### Research question

They examine the information embedded in the stock and option markets
prior to takeover announcements.
:::

::: {#measures-1 .section .level3}
### Measures

Call-option volume imbalances: the difference between buyer- and seller-
initiated volume divided by the average volume in the benchmark period
\[-200,-100\] (they assign a trade as a buy if it occur above the
bid-ask midpoint)

They define the announcement date as the first day an official bid is
received. They only examine target firms that had received no other
offers in the previous year.

Intraday option prices and volume are obtained from the Berkeley Options
Database (BODB). Firms are required to have at lease 200 trading days of
valid preannouncement option and stock data.

Moneyness and maturity: by convention, a call option is said to be
at-the-money(ATM) if S/K is between 0.95 and 1.05; out-of-the-money(OTM)
if S/K is greater than 0.95; and in-the-money(ITM) if S/K is greater
than 1.05, where S is the stock price and K is the strike price. An
option is said to be short-term(long-term) if it has less(greater) than
2 months to expire.
:::
:::

::: {#chan-ge-and-lin-jfqa-2015 .section .level2}
## Chan, Ge and Lin JFQA 2015

::: {#research-question-2 .section .level3}
### Research question

They study the informational content of options trading on acquirer
announcement returns
:::

::: {#measures-2 .section .level3}
### Measures

The IV spread: the average difference in implied volatilities between
call and put options on the same security with the same strike price and
maturity.

[\\(IV
spread\_{i,t}=IV\_{i,t}\^{calls}-IV\_{i,t}\^{puts}=\\sum\_{j=1}\^{N\_{i,t}}W\_{j,t}\^{i}(IV\_{j,t}\^{i,call}-IV\_{j,t}\^{i,put})\\)]{.math
.inline}

Where [\\(N\_{i,t}\\)]{.math .inline} is the total number of valid pairs
for each stock i on day t; and [\\(W\_{j,t}\^{i}\\)]{.math .inline} is
the weight, where they use the average open interest of call and put in
each pair. [\\(IV\_{j,t}\^{i}\\)]{.math .inline} represents the Black
and Scholes IV for each call and put option.

They exclude those options with 0 open interest or 0 best bid price.
They keep only short-term options with time to maturity from 10 to 60
days. They require option volume to be positive. To make the filters
consistent between IV spread and IV skew, we further restrict stock
volume to be positive, stock price to be greater than \$5, IV of options
to be between 3% and 200%, and an option average bid and ask price to be
higher than \$0.125.

IV skew: the difference in implied volatilities between the
out-of-the-money (OTM) put and the at-the-money (ATM) call.

They exclude cases in which the same acquirer announces a merger with
several different target firms on the same day because the acquirer
return is affected by several announcements simultaneously.

OTM puts are defined as put options with moneyness between 0.8 and 0.95.
If there are multiple OTM puts and ATM calls, they select one OTM put
with moneyness closest to 0.95 and one ATM call with moneyness closest
to 1.
:::
:::
:::

::: {#earnings-annoucements .section .level1}
# Earnings annoucements

::: {#jin-livnat-and-zhang-jae-2012 .section .level2}
## Jin, Livnat and Zhang JAE 2012

::: {#research-question-3 .section .level3}
### Research question

Whether predictive ability of option volatility shews and volatility
spreads is driven by option traders' information advantage?
:::

::: {#measures-3 .section .level3}
### Measures

Option implied skews (obtained from OptionMetrics): the implied
volatility of the OTM put option minus the implied volatility of the ATM
call option

Volatility spreads: the weighted average of the difference in implied
volatility between matched call and put options

They identify for each day all options of a firm with an expiration date
between 10 and 60 days away. We include only options with
greater-than-zero open interest. They select all call options that have
a delta in the range of \[0.4, 0.7\], and choose the one closest to 0.5.
They then select all put options that have a delta in the range of
\[--0.45, --0.15\], and choose the one closest to --0.3.
:::
:::

::: {#chordia-lin-and-xiang-jfqa-2020 .section .level2}
## Chordia, Lin and Xiang JFQA 2020

::: {#research-question-4 .section .level3}
### Research question

The relation between risk-neutral skewness(RNS) and subsequent stock
returns and whether informed option trading accounts for the RNS-return
relation.
:::

::: {#measures-4 .section .level3}
### Measures

Risk-neutral skewness

They obtain options data for 30-day maturity standardized options
contracts from OptionMetrics volatility surface dataset. They require
that at least two OTM call and put options exist on day t. An OTM
call(put) option is defined as options with delta greater than
0.2(-0.375) and less than 0.375(-0.2). Second, the OTM call and put
options must have the same absolute delta. Options are listed by delta
in fixed increments of 0.05, from 0.2 to 0.8 for call options and from
-0.8 to -0.2 for put options. Therefore, they can avoid asymmetric
strike-to-spot price distance between OTM put and call options.
:::
:::

::: {#roll-schwartz-and-subrahmanyam-jfe-2010 .section .level2}
## Roll, Schwartz and Subrahmanyam JFE 2010

::: {#research-question-5 .section .level3}
### Research question

They study the time-series properties and the determinants of the
option/stock trading volume ratio(O/S).
:::

::: {#measure .section .level3}
### Measure

The options/stock trading volume ratio

They calculate the total daily dollar options volume for each firm by
multiplying the total contracts traded in each option by the end-of-day
quote midpoints and then aggregating across all options listed on the
stock. Then they take a log value.
:::
:::

::: {#johnson-and-so-jfe-2012 .section .level2}
## Johnson and So JFE 2012

::: {#research-question-6 .section .level3}
### Research question

They examine the information content of option and equity volumes when
trade direction is unobserved.
:::

::: {#measure-1 .section .level3}
### Measure

The options/stock trading volume ratio: total option volume equals the
total volume in option contracts across all strikes for options expiring
in the 30 trading days beginning five days after the trade date. They
report equity volumes in round lots of 100 to make it more comparable to
the quantity of option contracts that each pertain to 100 shares.

They restrict the sample to firm-weeks with at least 25 call and 25 put
contracts traded to reduce measurement problems related to illiquid
option markets. They also require each observation to have a minimum of
six months of past weekly option and equity volumes, and they eliminate
closed-end funds, real estate investment trusts, American depository
receipts and firms with a stock price below \$1.
:::
:::
:::
:::
:::
:::
