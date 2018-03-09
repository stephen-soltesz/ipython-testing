#standardSQL
select
  --ROW_NUMBER() OVER() as row,
  case
  when _PARTITIONTIME = TIMESTAMP("2018-01-26 00:00:00") THEN '5w'
  when _PARTITIONTIME = TIMESTAMP("2018-02-02 00:00:00") THEN '4w'
  when _PARTITIONTIME = TIMESTAMP("2018-02-09 00:00:00") THEN '3w'
  when _PARTITIONTIME = TIMESTAMP("2018-02-16 00:00:00") THEN '2w'
  when _PARTITIONTIME = TIMESTAMP("2018-02-23 00:00:00") THEN '1w'
  when _PARTITIONTIME = TIMESTAMP("2018-03-02 00:00:00") THEN '0w'
  else 'err'
  end as period,
  web100_log_entry.snap.StartTimeStamp AS ts,
  REGEXP_EXTRACT(test_id, r"\d\d\d\d/\d\d/\d\d/(mlab[1-4].[a-z]{3}[0-9]{2})") AS hostname,
  8 * (web100_log_entry.snap.HCThruOctetsAcked /
    (web100_log_entry.snap.SndLimTimeRwin +
    web100_log_entry.snap.SndLimTimeCwnd +
    web100_log_entry.snap.SndLimTimeSnd)) as rate_mbps
from
  `measurement-lab.public.sidestream`
where
      (_PARTITIONTIME = TIMESTAMP("2018-01-26 00:00:00")
    OR _PARTITIONTIME = TIMESTAMP("2018-02-02 00:00:00")
    OR _PARTITIONTIME = TIMESTAMP("2018-02-09 00:00:00")
    OR _PARTITIONTIME = TIMESTAMP("2018-02-16 00:00:00")
    OR _PARTITIONTIME = TIMESTAMP("2018-02-23 00:00:00")
    OR _PARTITIONTIME = TIMESTAMP("2018-03-02 00:00:00"))
  AND REGEXP_CONTAINS(test_id, r"mlab1.(dfw02|lga03|dfw03|lga04)")
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

order by
  hostname, period, rate_mbps

