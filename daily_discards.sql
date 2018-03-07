#standardSQL
select
  hostname,
  FORMAT_TIMESTAMP("%Y-%m-%d", TIMESTAMP_TRUNC(sample.timestamp, DAY)) AS day,
  UNIX_SECONDS(TIMESTAMP_TRUNC(sample.timestamp, DAY)) AS ts,
  SUM(sample.value) AS total_discards
from
  `mlab-sandbox.base_tables.switch*`,
  UNNEST(sample) AS sample
where
  --  hostname like '%mlab1.%02%'
  metric LIKE 'switch.discards.uplink.tx'
group by
  hostname, ts, day
order by
  hostname, ts, day
