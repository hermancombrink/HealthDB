CREATE PROCEDURE [dbo].[BackupDatabase]
	@DBName			VARCHAR(255),
	@NoOfFiles		INT = 1,
	@BackupPath		VARCHAR(255),
	@BackupType     VARCHAR(1) = 'D'
AS

DECLARE
@Rows					INT,
@SQLStringFull1			NVARCHAR(4000), -- 17.03 Changed
@SQLStringFull2			NVARCHAR(4000), -- 17.03 Changed
@SQLStringDiff1			NVARCHAR(4000), -- 17.03 Changed
@SQLStringDiff2			NVARCHAR(4000), -- 17.03 Changed
@SQLStringToExecFull	NVARCHAR(4000),   -- 17.03 Changed
@SQLStringToExecDiff	NVARCHAR(4000),   -- 17.03 Changed
@Date					NVARCHAR(10),  -- 17.01 Added
@FullBackupCheck		CHAR(1)        -- 17.02 Added

SET @SQLStringFull1 = ''
SET @SQLStringFull2 = ''
SET @SQLStringDiff1 = ''
SET @SQLStringDiff2 = ''
SET @SQLStringToExecFull = ''
SET @SQLStringToExecDiff = ''
SET @Rows = 1
SET @Date = (SELECT REPLACE(CAST(CONVERT(char(10), GetDate(),126) AS VARCHAR(10)),'-','_'))  -- 17.01 Added

IF EXISTS (SELECT *	
			FROM msdb.dbo.backupset bup
			WHERE bup.backup_set_id IN
			  (SELECT MAX(backup_set_id) FROM msdb.dbo.backupset
			  WHERE database_name = ISNULL(@dbname, database_name) --if no dbname, then return all
			  AND type = 'D' --only interested in the time of last full backup
			  GROUP BY database_name) 
			AND bup.database_name IN (SELECT name FROM SYS.databases WHERE State = 0 AND Recovery_model = 1) -- Online and Full
			)
BEGIN
	SET @FullBackupCheck = 'Y'
END
ELSE
BEGIN
	SET @FullBackupCheck = 'N'
END


-- Loop through to create the statements
WHILE @Rows <= @NoOfFiles
BEGIN
	
	IF @BackupType = 'D'
	BEGIN
		SET @SQLStringFull1 =  'DISK = ''' + @BackupPath + @DBName + CAST(@rows AS VARCHAR(2)) + '_' + REPLACE(CONVERT(VARCHAR(8), GETDATE(), 112) + '_' + CONVERT(VARCHAR(8), GETDATE(), 114), ':','') + '.BAK'''
	END
	ELSE
	BEGIN
		SET @SQLStringDiff1 =  'DISK = ''' + @BackupPath + @DBName + CAST(@rows AS VARCHAR(2)) + '_' + REPLACE(CONVERT(VARCHAR(8), GETDATE(), 112) + '_' + CONVERT(VARCHAR(8), GETDATE(), 114), ':','') + '.DIF'''
	END
	
	-- Check the number of files to split so a comma is added to separate the number of files
	IF @Rows = @NoOfFiles
	BEGIN
		IF @BackupType = 'D'
		BEGIN
			SET @SQLStringFull2 = @SQLStringFull2 +  @SQLStringFull1  
		END
		ELSE
		BEGIN
			SET @SQLStringDiff2 = @SQLStringDiff2 +  @SQLStringDiff1  
		END
	END
	ELSE
	BEGIN
		IF @BackupType = 'D'
		BEGIN 
			SET @SQLStringFull2 = @SQLStringFull2 + @SQLStringFull1 + ','
		END
		ELSE
		BEGIN
			SET @SQLStringDiff2 = @SQLStringDiff2 + @SQLStringDiff1 + ','
		END
	END

    SET @Rows = @Rows + 1  -- Increment counter

END

-- For Full backups
IF @BackupType = 'D'
BEGIN
	
	SET @SQLStringToExecFull = 'BACKUP DATABASE [' + @DBName + '] TO ' +  @SQLStringFull2 + ' WITH NOFORMAT, NOINIT, NAME = N''' + @DBName + '-Full Database Backup''' + ', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10'
	--PRINT @SQLStringToExecFull
	EXECUTE SP_EXECUTESQL @SQLStringToExecFull
END
ELSE
-- For Differential backups
BEGIN
	
	SET @SQLStringToExecDiff = 'BACKUP DATABASE [' + @DBName + '] TO ' +  @SQLStringDiff2 + ' WITH DIFFERENTIAL, NOFORMAT, NOINIT, NAME = N''' + @DBName + '-Diff Database Backup''' + ', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10'
	--PRINT @SQLStringToExecDiff
	EXECUTE SP_EXECUTESQL @SQLStringToExecDiff
END


