#standardSQL
SELECT
  hostname,
  FORMAT_TIMESTAMP("%Y-%m-%d", TIMESTAMP_TRUNC(sample.timestamp, DAY)) AS day,
  UNIX_SECONDS(TIMESTAMP_TRUNC(sample.timestamp, DAY)) AS ts,
  -- regexp_extract(metric, r"switch.([a-z]+).uplink.tx") as metric,
  SUM(IF(metric = 'switch.discards.uplink.tx', sample.value, 0)) AS total_discards,
  SUM(IF(metric = 'switch.unicast.uplink.tx', sample.value, 0)) AS total_packets
  -- SUM(sample.value) AS total
FROM
  `mlab-sandbox.base_tables.switch*`,
  UNNEST(sample) AS sample
WHERE
     metric LIKE 'switch.discards.uplink.tx'
  OR metric LIKE 'switch.unicast.uplink.tx'
GROUP BY
  hostname, ts, day -- , metric
ORDER BY
  hostname, ts, day -- , metric
