CREATE VIEW [dbo].[ServerDiskStatus]
AS
SELECT DISTINCT TOP 100 PERCENT @@ServerName as ServerName,
(volume_mount_point) as drivename, 
total_bytes/1048576 as Size_in_MB, 
available_bytes/1048576 as Free_in_MB,
(select ((available_bytes/1048576* 1.0)/(total_bytes/1048576* 1.0) *100)) as FreePercentage,
getdate() as CapturedDate
FROM sys.master_files AS f CROSS APPLY 
sys.dm_os_volume_stats(f.database_id, f.file_id)
group by volume_mount_point, total_bytes/1048576, 
available_bytes/1048576 order by 1
GO

