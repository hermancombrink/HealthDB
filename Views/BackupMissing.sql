CREATE VIEW [dbo].[BackupMissing]
AS
SELECT TOP 100 PERCENT
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
   msdb.dbo.backupset.database_name, 
   MAX(msdb.dbo.backupset.backup_finish_date) AS last_db_backup_date, 
   DATEDIFF(hh, MAX(msdb.dbo.backupset.backup_finish_date), GETDATE()) AS [Backup Age (Hours)] 
FROM    msdb.dbo.backupset 
INNER JOIN master.sys.databases  on msdb.dbo.backupset.database_name =  master.sys.databases.name 
WHERE     msdb.dbo.backupset.type = 'D'  AND master.sys.databases.state = 0
GROUP BY msdb.dbo.backupset.database_name 
HAVING      (MAX(msdb.dbo.backupset.backup_finish_date) < DATEADD(hh, - 24, GETDATE()))  

UNION  

--Databases without any backup history 

SELECT TOP 100 PERCENT 
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server,  
   master.sys.databases.NAME AS database_name,  
   NULL AS [Last Data Backup Date],  
   9999 AS [Backup Age (Hours)]  
FROM 
   master.sys.databases LEFT JOIN msdb.dbo.backupset 
       ON master.sys.databases.name  = msdb.dbo.backupset.database_name 
WHERE msdb.dbo.backupset.database_name IS NULL AND master.sys.databases.name <> 'tempdb' 
AND master.sys.databases.state = 0
ORDER BY  
   msdb.dbo.backupset.database_name 
   
GO
