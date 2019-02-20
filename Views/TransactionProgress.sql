select	R.percent_complete, R.session_id, R.Wait_Type, T.text, R.Status, R.Command, DatabaseName = db_name(R.database_id)
		, R.cpu_time, R.total_elapsed_time,  
		CASE WHEN CAST((R.total_elapsed_time/1000) as int) < 60 THEN '00:00:' + RIGHT(REPLICATE('0', 2) + CAST(CAST((R.total_elapsed_time/1000) as int) as varchar),2)
		ELSE 
		CAST(CAST((R.total_elapsed_time/1000/60/60) as int) as varchar) + ':' + 
		RIGHT(REPLICATE('0', 2) + CAST(CAST((R.total_elapsed_time/1000/60) as int) - (60* CAST((R.total_elapsed_time/1000/60/60) as int)) as varchar),2) + ':' +
		RIGHT(REPLICATE('0', 2) + CAST(CAST((R.total_elapsed_time/1000) as int) - (60 * CAST((R.total_elapsed_time/1000/60) as int)) - (60* CAST((R.total_elapsed_time/1000/60/60) as int)) as varchar),2)
		END
		as 'duration'
from	sys.dm_exec_requests R
		cross apply sys.dm_exec_sql_text(R.sql_handle) T
		where session_id <> @@SPID
