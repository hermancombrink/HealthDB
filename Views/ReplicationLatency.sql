CREATE VIEW [dbo].[ReplicationLatency]
AS
SELECT        object_name, counter_name, instance_name, ROUND(cntr_value / 1000, 0) AS latency_sec
FROM            sys.dm_os_performance_counters
WHERE        (object_name LIKE '%Replica%') AND (counter_name LIKE '%Dist%latency%' OR
                         counter_name LIKE '%Logreader:%latency%')
GO
