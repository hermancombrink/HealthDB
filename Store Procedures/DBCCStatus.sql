
CREATE PROCEDURE [dbo].[DBCCStatus]
AS
BEGIN

    CREATE TABLE #DBsName
        (
          ID INT IDENTITY(1, 1)
                 PRIMARY KEY ,
          DbName NVARCHAR(128) NULL
        )

	INSERT INTO #DBsName
	SELECT Name FROM master.dbo.sysdatabases where status not in (536, 4194844)
	
    IF OBJECT_ID('tempdb..#DBCCs') IS NOT NULL 
        DROP TABLE #DBCCs
        
    CREATE TABLE #DBCCs
        (
          ID INT IDENTITY(1, 1)
                 PRIMARY KEY ,
          ParentObject VARCHAR(255) ,
          Object VARCHAR(255) ,
          Field VARCHAR(255) ,
          Value VARCHAR(255) ,
          DbName NVARCHAR(128) NULL
        )

	DECLARE @DBsName as Varchar(128)	
	SELECT Top 1 @DBsName = DbName FROM #DBsName
	
	WHILE @DBsName IS NOT NULL
	BEGIN
		PRINT @DBsName
		INSERT INTO #DBCCs (ParentObject, Object, Field, Value)
		exec ('DBCC DBInfo(''' + @DBsName + ''') With TableResults, NO_INFOMSGS')
		
		UPDATE #DBCCs SET DBName = @DBsName WHERE DBName IS NULL
		DELETE FROM #DBsName where DbName = @DBsName 

		SET @DBsName = NULL
		SELECT Top 1 @DBsName = DbName FROM #DBsName
	END

SELECT DbName,CASE WHEN Value = '1900-01-01 00:00:00.000'  THEN '**Never**'
			  ELSE value
			  END 'DBCCLastExecuted'  

FROM #DBCCs
WHERE Field = 'dbi_dbccLastKnownGood'
--where dbname = 'sysmon'

DROP TABLE #DBCCs
DROP TABLE #DBsName

END
GO


