
SELECT TOP 100
    qs.total_elapsed_time / qs.execution_count / 1000000.0 AS average_seconds,
    qs.total_elapsed_time / 1000000.0 AS total_seconds,
    qs.execution_count,
    SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) AS individual_query,
    o.name AS object_name,
    DB_NAME(qt.dbid) AS database_name
  FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
    LEFT OUTER JOIN sys.objects o ON qt.objectid = o.object_id
where qt.dbid = DB_ID()
  ORDER BY average_seconds DESC;


---- Quries doing most I/O

SELECT TOP 100
    (total_logical_reads + total_logical_writes) / qs.execution_count AS average_IO,
    (total_logical_reads + total_logical_writes) AS total_IO,
    qs.execution_count AS execution_count,
    SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) AS indivudual_query,
    o.name AS object_name,
    DB_NAME(qt.dbid) AS database_name
  FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
    LEFT OUTER JOIN sys.objects o ON qt.objectid = o.object_id
where qt.dbid = DB_ID()
  ORDER BY average_IO DESC;


-----

SELECT
	r.session_id
,	r.start_time
,	TotalElapsedTime_ms = r.total_elapsed_time
,	r.[status]
,	r.command
,	DatabaseName = DB_Name(r.database_id)
,	r.wait_type
,	r.last_wait_type
,	r.wait_resource
,	r.cpu_time
,	r.reads
,	r.writes
,	r.logical_reads
,	t.[text] AS [executing batch]
,	SUBSTRING(
				t.[text], r.statement_start_offset / 2, 
				(	CASE WHEN r.statement_end_offset = -1 THEN DATALENGTH (t.[text]) 
						 ELSE r.statement_end_offset 
					END - r.statement_start_offset ) / 2 
			 ) AS [executing statement] 
,	p.query_plan
FROM
	sys.dm_exec_requests r
CROSS APPLY
	sys.dm_exec_sql_text(r.sql_handle) AS t
CROSS APPLY	
	sys.dm_exec_query_plan(r.plan_handle) AS p
ORDER BY 
	r.total_elapsed_time DESC;



