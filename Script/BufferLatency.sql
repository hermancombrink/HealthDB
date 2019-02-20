--Created on 2016-08-24 by Shekhar.Teke@theta.co.nz

--Script to retrieve Buffer and Latency Info
--How to use it: 
--Run script as is
--Result: table

--- Buffer Manager

SELECT cntr_value
  FROM sys.dm_os_performance_counters
  WHERE counter_name = 'Database pages'
    AND object_name LIKE '%Buffer Manager%';

--- CPU Usage

;WITH cte AS
(
  SELECT stat.[sql_handle],
         stat.statement_start_offset,
         stat.statement_end_offset,
         COUNT(*) AS [NumExecutionPlans],
         SUM(stat.execution_count) AS [TotalExecutions],
         ((SUM(stat.total_logical_reads) * 1.0) / SUM(stat.execution_count)) AS [AvgLogicalReads],
         ((SUM(stat.total_worker_time) * 1.0) / SUM(stat.execution_count)) AS [AvgCPU]
  FROM sys.dm_exec_query_stats stat
  GROUP BY stat.[sql_handle], stat.statement_start_offset, stat.statement_end_offset
)
SELECT CONVERT(DECIMAL(15, 5), cte.AvgCPU) AS [AvgCPU],
       CONVERT(DECIMAL(15, 5), cte.AvgLogicalReads) AS [AvgLogicalReads],
       cte.NumExecutionPlans,
       cte.TotalExecutions,
       DB_NAME(txt.[dbid]) AS [DatabaseName],
       OBJECT_NAME(txt.objectid, txt.[dbid]) AS [ObjectName],
       SUBSTRING(txt.[text], (cte.statement_start_offset / 2) + 1,
       (
         (CASE cte.statement_end_offset 
           WHEN -1 THEN DATALENGTH(txt.[text])
           ELSE cte.statement_end_offset
          END - cte.statement_start_offset) / 2
         ) + 1
       )
FROM cte
CROSS APPLY sys.dm_exec_sql_text(cte.[sql_handle]) txt
ORDER BY cte.AvgCPU DESC;

--- Check Latency

SELECT
    [ReadLatency] =
        CASE WHEN [num_of_reads] = 0
            THEN 0 ELSE ([io_stall_read_ms] / [num_of_reads]) END,
    [WriteLatency] =
        CASE WHEN [num_of_writes] = 0
            THEN 0 ELSE ([io_stall_write_ms] / [num_of_writes]) END,
    [Latency] =
        CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
            THEN 0 ELSE ([io_stall] / ([num_of_reads] + [num_of_writes])) END,
    [AvgBPerRead] =
        CASE WHEN [num_of_reads] = 0
            THEN 0 ELSE ([num_of_bytes_read] / [num_of_reads]) END,
    [AvgBPerWrite] =
        CASE WHEN [num_of_writes] = 0
            THEN 0 ELSE ([num_of_bytes_written] / [num_of_writes]) END,
    [AvgBPerTransfer] =
        CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
            THEN 0 ELSE
                (([num_of_bytes_read] + [num_of_bytes_written]) /
                ([num_of_reads] + [num_of_writes])) END,
    LEFT ([mf].[physical_name], 2) AS [Drive],
    DB_NAME ([vfs].[database_id]) AS [DB],
    [mf].[physical_name]
FROM
    sys.dm_io_virtual_file_stats (NULL,NULL) AS [vfs]
JOIN sys.master_files AS [mf]
    ON [vfs].[database_id] = [mf].[database_id]
    AND [vfs].[file_id] = [mf].[file_id]
-- WHERE [vfs].[file_id] = 2 -- log files
-- ORDER BY [Latency] DESC
-- ORDER BY [ReadLatency] DESC
ORDER BY [WriteLatency] DESC;
GO
