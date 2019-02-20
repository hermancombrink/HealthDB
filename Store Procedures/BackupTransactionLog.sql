CREATE PROCEDURE [dbo].[BackupTransactionLog]
    @DBName			NVARCHAR(50),
    @BackupPath		NVARCHAR(255)

AS

DECLARE
@SQLStringFull			NVARCHAR(4000), 
@SQLStringToExec		NVARCHAR(4000),
@FolderDate			NVARCHAR(20),
@Date				NVARCHAR(20)  

SET @SQLStringFull = ''
SET @SQLStringToExec = ''
SET @FolderDate = (SELECT REPLACE(CAST(CONVERT(char(10), GetDate(),126) AS VARCHAR(10)),'-','_'))  
SET @Date = (SELECT REPLACE(CONVERT(VARCHAR(8), GETDATE(), 112) + '_' + CONVERT(VARCHAR(8), GETDATE(), 114), ':',''))

-- Check the backup location is in the correct format
IF RIGHT(@BackupPath, 1) <> N'\'
BEGIN
    SET @BackupPath = @BackupPath + '\'
END

-- Check a full backup has been done
IF EXISTS (SELECT *	
			FROM msdb.dbo.backupset bup
			WHERE bup.backup_set_id IN
			  (SELECT MAX(backup_set_id) FROM msdb.dbo.backupset
			  WHERE database_name = ISNULL(@dbname, database_name) --if no dbname, then return all
			  AND type = 'D' --only interested in the time of last full backup
			  GROUP BY database_name) 
			AND bup.database_name IN (SELECT name FROM SYS.databases WHERE State = 0 AND Recovery_model = 1) -- Full
			)
BEGIN
	
   SET @SQLStringFull =  'DISK = N''' + @BackupPath + @DBName + '_backup_' + @Date + '.TRN'''

	SET @SQLStringToExec = 'BACKUP LOG [' + @DBName + '] TO ' + @SQLStringFull + ' WITH NOFORMAT, NOINIT, NAME = N''' + @DBName + '_BACKUP_' + @Date + ''', SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 10'

	--PRINT @SQLStringToExec
	EXECUTE SP_EXECUTESQL @SQLStringToExec
   
END
ELSE
BEGIN
	
   PRINT 'Full database backup is required for ' + @DBName

END

