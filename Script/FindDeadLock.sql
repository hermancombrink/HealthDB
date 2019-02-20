SELECT
   xed.value('@timestamp', 'datetime2(3)') as CreationDate,
   xed.query('.') AS XEvent
FROM
(
   SELECT CAST([target_data] AS XML) AS TargetData
   FROM sys.dm_xe_session_targets AS st
   INNER JOIN sys.dm_xe_sessions AS s
      ON s.address = st.event_session_address
   WHERE s.name = N'system_health'
         AND st.target_name = N'ring_buffer'
) AS Data
CROSS APPLY TargetData.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData (xed)
ORDER BY CreationDate DESC

----============

DECLARE @xml XML

SELECT @xml = target_data
--select *
FROM   sys.dm_xe_session_targets
JOIN sys.dm_xe_sessions
ON event_session_address = address
WHERE  name = 'system_health' AND target_name = 'ring_buffer'
and create_time between '12-JUL-2017 00:00:00' AND '12-JUL-2017 23:59:59'

SELECT CAST(XEventData.XEvent.value('(data/value)[1]', 'varchar(max)') AS XML)
FROM   (SELECT @xml AS TargetData) AS Data
CROSS APPLY TargetData.nodes ('RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData (XEvent)
