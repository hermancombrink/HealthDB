CREATE VIEW [dbo].[BackupStatus]
AS
SELECT TOP 100 PERCENT  CASE WHEN  SERVERPROPERTY('instancename') IS NULL THEN SERVERPROPERTY('machinename')
ELSE
(SELECT   RTRIM(CONVERT(char(20), SERVERPROPERTY('machinename'))) + '_' + CONVERT(char(20), SERVERPROPERTY('instancename'))) 
END  instance,
sd.name as name,
bs.type,
bs.database_name,
MAX(bs.backup_start_date) as last_backup,
DATEDIFF(DAY, MAX(bs.backup_start_date), GETDATE()) as backup_age_days,
DATEDIFF(HOUR, MAX(bs.backup_start_date), GETDATE()) as backup_age_hours,
note = CASE
WHEN max(bs.backup_start_date) < GETDATE() - 7 THEN 'ALERT'
WHEN ISNULL(max(bs.backup_start_date),0) = 0 THEN 'ALERT'
ELSE '---'
END,
max(bmf.physical_device_name) as backup_path,
max(backup_size) as backup_size,
convert(decimal(18,3),(max(compressed_backup_size))/1024/1024/1024) as backup_size_GB,
max(backup_set_id) as backup_set ---,max(compressed_backup_size)
FROM    master..sysdatabases sd
Left outer join msdb..backupset bs on rtrim(bs.database_name) = rtrim(sd.name)
left outer JOIN msdb..backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE sd.name <> 'tempdb' and bs.type in('D','L','I') 
AND DATABASEPROPERTYEX(sd.name, 'Status')= 'ONLINE'
Group by sd.name,
bs.type,
bs.database_name
ORDER BY sd.name,last_backup
GO

