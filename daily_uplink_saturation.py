#!/usr/bin/env python

#%%
import os
import math
import pandas as pd
import numpy as np
import matplotlib.dates as dates
import matplotlib.pyplot as plt
import matplotlib.ticker
import datetime
import collections

# Some matplotlib features are version dependent.
assert(matplotlib.__version__ >= '2.1.2')

# Depends on: pip install --upgrade google-cloud-bigquery
from google.cloud import bigquery

def run_query(query, project='mlab-sandbox'):
    client = bigquery.Client(project=project)
    job = client.query(query)

    results = collections.defaultdict(list)
    for row in job.result(timeout=300):
        for key in row.keys():
            results[key].append(row.get(key))

    return pd.DataFrame(results)

#%%
df_disco = run_query("""
#standardSQL
SELECT
  name AS hostname,
  FORMAT_TIMESTAMP("%Y-%m-%d", TIMESTAMP_TRUNC(sts, DAY)) AS day,
  UNIX_SECONDS(TIMESTAMP_TRUNC(sts, DAY)) AS ts,
  SUM(IF(metric = 'switch.octets.uplink.tx' AND (8 * value / 10000000 > 500), 1, 0)) AS uplink_saturation_500

FROM (
  SELECT
    metric,
    REGEXP_EXTRACT(hostname, r'(mlab[1-4].[a-z]{3}[0-9]{2}).*') AS name,
    sample.timestamp AS sts,
    sample.value AS value
  FROM
    `mlab-sandbox.base_tables.switch*`,
    UNNEST(sample) AS sample
  WHERE
    metric LIKE 'switch.octets.uplink.tx'
  GROUP BY
    hostname, metric, sts, value
)
WHERE
  name IS NOT NULL
GROUP BY
  hostname, day, ts
ORDER BY
  hostname, day, ts
""")
print 'Done', len(df_disco)

#%%

sites = [
    ['dfw', 'lga', 'iad'],
    ['lax', 'atl', 'den'],
    ['sea', 'nuq', 'ord'], # MIA is low utilization.
]

cols = len(sites[0])
fig = plt.figure(figsize=(4 * cols, 4 * cols))
axes = [
    [None] * cols,
    [None] * cols,
    [None] * cols,
]

for r, siter in enumerate(sites):
    for c, site in enumerate(siter):
            axes[r][c] = plt.subplot2grid((3, cols), (r, c))
            if c == 0:
                axes[r][c].set_ylabel('% Saturation Timebins')

            if r != 2:
                axes[r][c].set_xticklabels([])

            prefix = 'mlab1.' + site
            ds_sites = df_disco[ df_disco['hostname'].str.contains(prefix) ]
            for h in sorted(set(ds_sites['hostname'])):
                ds = ds_sites[ (ds_sites['hostname'].str.contains(h)) ]
                axes[r][c].plot_date(
                    dates.epoch2num(ds['ts']),
                    ds['uplink_saturation_500'] / 8640,
                    ls='-', ms=0, label=h[6:11])

            axes[r][c].set_title(site)
            #axes[r][c].set_ylim(100, 1000)
            axes[r][c].tick_params(axis='x', labelrotation=90)
            axes[r][c].grid(color='#dddddd')
            axes[r][c].legend(loc=2, fontsize='x-small', ncol=2)

fig.suptitle('Daily Percentile Rates')
plt.show()