
CREATE VIEW [dbo].[MirrorStatus]
AS
SELECT        TOP (100) PERCENT DB_NAME(m.database_id) AS DatabaseName, d.state_desc, m.mirroring_role_desc, CASE WHEN mirroring_guid IS NULL THEN 'Mirroring not set' ELSE mirroring_state_desc END AS State, 
                         m.mirroring_connection_timeout, m.mirroring_redo_queue
FROM            master.dbo.sysdatabases AS sb LEFT OUTER JOIN
                         sys.databases AS d ON sb.dbid = d.database_id LEFT OUTER JOIN
                         sys.database_mirroring AS m ON sb.dbid = m.database_id
WHERE        (sb.name NOT IN ('master', 'tempdb', 'model', 'msdb')) AND (m.mirroring_role_desc IS NOT NULL)
ORDER BY DatabaseName
GO
