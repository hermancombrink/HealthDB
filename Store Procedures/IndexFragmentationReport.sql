CREATE PROCEDURE [dbo].[IndexFragmentationReport]
AS
SET NOCOUNT ON
DECLARE @temptable TABLE  (
	dbname VARCHAR(500)
	,FRAG FLOAT
	,page_count INT
	,IndexName VARCHAR(500)
	,TableName VARCHAR(500)
	,IndexType VARCHAR(500)
	,SizeMB bigint
	,UsageCount int
	,Fill_Factor int
	,Partition_Number int
	)



DECLARE AllDatabases CURSOR
FOR
SELECT [name]
FROM master.dbo.sysdatabases
WHERE dbid > '4';

OPEN AllDatabases;

DECLARE @DBNameVar NVARCHAR(200)
	,@STATEMENT NVARCHAR(MAX)
	,@offline bit
	,@Online sql_variant

FETCH NEXT
FROM AllDatabases
INTO @DBNameVar

WHILE (@@FETCH_STATUS = 0)
BEGIN
	--print @DBNameVar
	SELECT @Online = DATABASEPROPERTYEX(@DBNameVar,'STATUS')
	IF @Online = 'ONLINE' 
	BEGIN
			SET @STATEMENT = N'USE [' + @DBNameVar + ']' +
				N'	SELECT	DB_NAME() AS dbname, 
						a.avg_fragmentation_in_percent AS FRAG,
						a.page_count,
						b.name as IndexName,
						OBJECT_NAME(a.object_id) as TableName,
						b.type_desc as IndexType,
						(a.page_count * 8)/1024 as SizeMB,
						ISNULL(us.USER_SEEKS,0)+ISNULL(us.USER_SCANS,0)+ISNULL(us.USER_LOOKUPS,0)+ISNULL(us.USER_UPDATES,0) as UsageCount,
						b.fill_factor as Fill_Factor,
						a.partition_number as Partition_Number
						
					FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, ''LIMITED'') a
					JOIN sys.indexes b on a.object_id = b.object_id and a.index_id = b.index_id
				        LEFT JOIN sys.dm_db_index_usage_stats us on a.index_id = us.index_id and us.object_id=a.object_id and a.database_id = us.database_id
					WHERE b.type > 0 --heap
					ORDER BY OBJECT_NAME(a.object_id), a.index_id, b.name, b.type_desc, a.partition_number
					
				'

			--print @STATEMENT
			INSERT INTO @temptable
			EXEC SP_EXECUTESQL @STATEMENT
	END
	FETCH NEXT
	FROM AllDatabases
	INTO @DBNameVar
END

CLOSE AllDatabases

DEALLOCATE AllDatabases

SELECT dbname AS 'Database',
	STR(page_count) AS 'Page Count',
	IndexName AS 'Index',
	TableName AS 'Table',
	IndexType AS 'Index Type',
	SizeMB as 'Size in MB',
	STR(UsageCount) AS 'Usage',
	STR(Fill_Factor) AS 'Fill_Factor',
	STR(Partition_Number)AS 'Partition_number' ,
	STR(FRAG) AS 'Fragmentation in Percent',
	CASE  
		WHEN frag >= 30 and page_count > 1000 THEN 'Rebuild'
		WHEN frag < 30 and frag > 5 and page_count > 1000 THEN  'Reorg'
		ELSE 'No Action'
	END AS 'ACTION'
FROM @temptable
ORDER BY dbname,TableName,IndexName,Partition_number 

