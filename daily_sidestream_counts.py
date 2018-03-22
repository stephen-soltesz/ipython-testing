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
df_ss_count = run_query(
    """#standardSQL                                                                    
CREATE TEMPORARY FUNCTION sliceFromIP(test_id STRING, ipaddr STRING)
    AS (
        CASE
        WHEN REGEXP_CONTAINS(test_id, r"mlab1.(atl01|ord01|sea01|lga02)") AND MOD(CAST(REGEXP_EXTRACT(ipaddr, r'[:.]([0-9]+)$') AS INT64), 64) - 10 = 10
            THEN 7
        WHEN REGEXP_CONTAINS(test_id, r"mlab1.(dfw01|lax01)") AND MOD(CAST(REGEXP_EXTRACT(ipaddr, r'[:.]([0-9]+)$') AS INT64), 64) - 10 = 11
            THEN 7
        ELSE
            MOD(CAST(REGEXP_EXTRACT(ipaddr, r'[:.]([0-9]+)$') AS INT64), 64) - 10
        END
    );

SELECT
   hostname, ts, count(*) as count
FROM (
    SELECT
        REGEXP_EXTRACT(test_id, r"\d\d\d\d/\d\d/\d\d/(mlab[1-4].[a-z]{3}[0-9]{2})") AS hostname,
        UNIX_SECONDS(TIMESTAMP_TRUNC(log_time, DAY)) AS ts                            
    FROM
        `mlab-sandbox.gfr.sidestream_*`
    WHERE
      REGEXP_CONTAINS(test_id, r"mlab1.(dfw|lga|iad|lax|atl|den|sea|nuq|ord|mia)[0-9]{2}.*")
      -- AND sliceFromIP(test_id, web100_log_entry.connection_spec.local_ip) = 7
      AND web100_log_entry.snap.HCThruOctetsAcked >= 1000000
      AND (web100_log_entry.snap.SndLimTimeRwin +                                   
        web100_log_entry.snap.SndLimTimeCwnd +                                      
        web100_log_entry.snap.SndLimTimeSnd) >= 9000000                             
      AND (web100_log_entry.snap.SndLimTimeRwin +                                   
        web100_log_entry.snap.SndLimTimeCwnd +                                      
        web100_log_entry.snap.SndLimTimeSnd) < 600000000                            
      AND (web100_log_entry.snap.State = 1 OR                                       
        (web100_log_entry.snap.State >= 5 AND                                       
        web100_log_entry.snap.State <= 11))

    GROUP BY
      hostname, ts,
      web100_log_entry.connection_spec.remote_ip,
      web100_log_entry.connection_spec.remote_port,
      web100_log_entry.connection_spec.local_port,
      web100_log_entry.connection_spec.local_ip
)

GROUP BY
  hostname, ts
ORDER BY
  hostname, ts
    """)
print 'Done', len(df_ss_count)

#%%
sites = [
    ['dfw', 'lga', 'iad'],
    ['lax', 'atl', 'den'],
    ['sea', 'nuq', 'ord'], # MIA is low utilization.
]

# MIA, DEN, and SEA are relatively low utilization.
# NUQ, ORD show trends less dramatic than those below.
# LGA usage appeared to dramatically lower around 2018-01.

cols = len(sites[0])
fig = plt.figure(figsize=(4 * cols, 4 * cols))
axes = [
    [None] * cols,
    [None] * cols,
    [None] * cols,
]

for r, siter in enumerate(sites):
    for c, site in enumerate(siter):
        axes[r][c] = plt.subplot2grid((cols, cols), (r, c))

        if c == 0:
            axes[r][c].set_ylabel('Connection Counts')
        #else:
        #    axes[r][c].set_yticklabels([])

        if r != 2:
            axes[r][c].set_xticklabels([])

        prefix = 'mlab1.' + site
        ds_sites = df_ss_count[ df_ss_count['hostname'].str.contains(prefix) ]
        for host in sorted(set(ds_sites['hostname'])):
            ds = ds_sites[ (ds_sites['hostname'].str.contains(host)) ]
            axes[r][c].plot_date(
                dates.epoch2num(ds['ts']),
                ds['count'],
                ls='-', ms=0, label=host[6:11])

        axes[r][c].set_title(site)
        #axes[r][c].set_ylim(0, 25000)
        axes[r][c].tick_params(axis='x', labelrotation=90)
        axes[r][c].grid(color='#dddddd')
        axes[r][c].legend(loc=2, fontsize='x-small', ncol=2)

fig.suptitle('Daily TCP Connection Counts Per Metro - SamKnows Only')
plt.show()