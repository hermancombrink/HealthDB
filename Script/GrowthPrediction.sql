SELECT  
    CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
    msdb.dbo.backupset.database_name,  
    msdb.dbo.backupset.backup_start_date,  
    msdb.dbo.backupset.backup_finish_date, 
    
    msdb.dbo.backupset.backup_size
	, cast(backup_size/1024/1024 as decimal(10,2)) as backup_size_MB
	, cast(compressed_backup_size/1024/1024 as decimal(10,2)) as compressed_backup_size_MB
	, Convert(smallDateTime, CAST(backup_start_date as varchar(11)), 101) as ReportDate
    FROM   msdb.dbo.backupmediafamily  
    INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id =    msdb.dbo.backupset.media_set_id 
    WHERE  (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 365) 
    AND msdb..backupset.type = 'D' 
AND  Convert(smallDateTime, CAST(backup_start_date as varchar(11)), 101)  BETWEEN GETDATE() AND DATEADD(DAY, 90, GETDATE())
    ORDER BY  
    msdb.dbo.backupset.database_name, 
    msdb.dbo.backupset.backup_finish_date
