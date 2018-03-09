#standardSQL
select
  --ROW_NUMBER() OVER() as row,
  CASE
  WHEN (TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) >= TIMESTAMP("2017-07-26 00:00:00")
        AND TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) <= TIMESTAMP("2017-07-30 00:00:00")) THEN '07-26 to 29'
  WHEN (TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) >= TIMESTAMP("2017-08-05 00:00:00")
        AND TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) <= TIMESTAMP("2017-08-06 00:00:00")) THEN '08-05'
  WHEN ( TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) >= TIMESTAMP("2017-08-12 00:00:00")
        AND TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) <= TIMESTAMP("2017-08-16 00:00:00")) THEN '08-12 to 16'
  WHEN ( TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) >= TIMESTAMP("2017-11-29 00:00:00")
        AND TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) <= TIMESTAMP("2017-12-03 00:00:00")) THEN '11-29 to 12-03'
  WHEN ( TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) >= TIMESTAMP("2017-10-30 00:00:00")
        AND TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) <= TIMESTAMP("2017-11-02 00:00:00")) THEN '10-30 to 11-02'
  ELSE 'bad'
  END AS period,
  REGEXP_EXTRACT(test_id, r"\d\d\d\d/\d\d/\d\d/(mlab[1-4].[a-z]{3}[0-9]{2})") AS hostname,
  web100_log_entry.snap.StartTimeStamp AS ts,
  8 * (web100_log_entry.snap.HCThruOctetsAcked /
    (web100_log_entry.snap.SndLimTimeRwin +
    web100_log_entry.snap.SndLimTimeCwnd +
    web100_log_entry.snap.SndLimTimeSnd)) as rate_mbps
from
  `mlab-sandbox.batch.sidestream*`
where
  (
  (       TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) >= TIMESTAMP("2017-07-26 00:00:00")
      AND TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) <= TIMESTAMP("2017-07-30 00:00:00")
  ) OR (
          TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) >= TIMESTAMP("2017-08-05 00:00:00")
      AND TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) <= TIMESTAMP("2017-08-06 00:00:00")
  ) OR (
          TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) >= TIMESTAMP("2017-08-12 00:00:00")
      AND TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) <= TIMESTAMP("2017-08-16 00:00:00")
  ) OR (
          TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) >= TIMESTAMP("2017-11-29 00:00:00")
      AND TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) <= TIMESTAMP("2017-12-03 00:00:00")
  ) OR (
          TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) >= TIMESTAMP("2017-10-30 00:00:00")
      AND TIMESTAMP_SECONDS(web100_log_entry.snap.StartTimeStamp) <= TIMESTAMP("2017-11-02 00:00:00")
  )
)
  AND (test_id LIKE '%mlab1.dfw02%' OR test_id LIKE '%mlab1.lga03%')
  AND web100_log_entry.snap.HCThruOctetsAcked >= 81920
  AND (web100_log_entry.snap.SndLimTimeRwin +
    web100_log_entry.snap.SndLimTimeCwnd +
    web100_log_entry.snap.SndLimTimeSnd) >= 9000000
  AND (web100_log_entry.snap.SndLimTimeRwin +
    web100_log_entry.snap.SndLimTimeCwnd +
    web100_log_entry.snap.SndLimTimeSnd) < 600000000
  AND (web100_log_entry.snap.State = 1 OR
    (web100_log_entry.snap.State >= 5 AND
    web100_log_entry.snap.State <= 11))

group by
  hostname, period, ts, rate_mbps

--order by
--  hostname, period, ts, rate

