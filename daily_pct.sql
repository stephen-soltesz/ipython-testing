select
  name as hostname,
  FORMAT_TIMESTAMP("%Y-%m-%d", TIMESTAMP_TRUNC(sts, DAY)) as day,
  UNIX_SECONDS(TIMESTAMP_TRUNC(sts, DAY)) as ts,
  countif(value > 0) / 8640 as total_discards
FROM (

  SELECT
    REGEXP_EXTRACT(hostname, r'(mlab[1-4].[a-z]{3}[0-9]{2}).*') as name,
    sample.timestamp as sts,
    sample.value as value
  from
    `mlab-sandbox.base_tables.switch*`,
    UNNEST(sample) as sample
  where
        (hostname like '%mlab1.dfw02%' OR hostname like '%mlab1.lga03%')
    AND metric like 'switch.discards.uplink.tx'
  group by
    hostname, sts, value

)
group by
  hostname, day, ts
order by
  hostname, day, ts
