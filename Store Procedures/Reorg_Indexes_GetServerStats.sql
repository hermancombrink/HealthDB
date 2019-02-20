CREATE PROCEDURE [dbo].[Reorg_Indexes_GetServerStats]
    @fragmentationLowerLimit decimal(18,2) = 1, -- perc,
    @excludeDbs nvarchar(2000) = '',
    @safeProcess bit = 1
AS
BEGIN

    SET NOCOUNT ON 
    
    IF @safeProcess = 1
    BEGIN
        IF EXISTS(SELECT 1 FROM IndexDefrag 
            WHERE IndexDefragCreatedAt > DATEADD(HOUR, -8, GETDATE()))
            RETURN
    END

    --- Gather Index Stats ---
     SELECT 
        database_id, name
     INTO #instanceDbs
     FROM sys.databases
     WHERE name not in (
        'master',
        'tempdb',
        'model',
        'msdb'
     )
     and name not in (
      SELECT val 
      FROM dbo.Split(@excludeDbs, ',')
     )

     CREATE TABLE #instanceIndexStats 
     (
      [Database]  nvarchar(150), 
      [IndexName] nvarchar(150),
      [TableName] nvarchar(150),
      [FragmentationPerc] float,
      [FragmentCount] int,
      [PageCount] int
     )

      DECLARE @indexCommand nvarchar(max) = '
         INSERT INTO #instanceIndexStats
         SELECT 
          DB_NAME()                                                                        AS [Database], 
          SI.name                                                                          AS [IndexName],
          ''['' + SCHEMA_NAME(ST.SCHEMA_ID) + ''].['' + OBJECT_NAME(IPS.OBJECT_ID) + '']'' AS [TableName],
          avg_fragmentation_in_percent                                                     AS [FragmentationPerc],
          fragment_count                                                                   AS [FragmentCount],
          page_count                                                                       AS [PageCount]
         FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL , NULL) IPS 
          JOIN sys.tables ST WITH (NOLOCK) ON IPS.OBJECT_ID = ST.OBJECT_ID 
          JOIN sys.indexes SI WITH (NOLOCK) ON IPS.OBJECT_ID = SI.OBJECT_ID AND IPS.index_id = SI.index_id 
         WHERE ST.is_ms_shipped = 0 AND SI.name IS NOT NULL
         AND avg_fragmentation_in_percent >= CONVERT(DECIMAL, ' + CAST(COALESCE(@fragmentationLowerLimit, 1) as nvarchar(10)) + ')'

    DECLARE @DBID int, @DBNAME nvarchar(150), @dynCommand nvarchar(max)
      DECLARE GatherCursor CURSOR FAST_FORWARD FOR
         SELECT database_id, name FROM #instanceDbs
    OPEN GatherCursor
    FETCH NEXT FROM GatherCursor INTO @DBID, @DBNAME
    WHILE @@FETCH_STATUS = 0
    BEGIN
        
        SET @dynCommand = 'USE [' + @DBNAME + '];' + @indexCommand

        EXEC (@dynCommand)

        FETCH NEXT FROM GatherCursor INTO @DBID, @DBNAME
    END
    CLOSE GatherCursor
    DEALLOCATE GatherCursor

    --- Gather Index Stats ---

    --- Close Prior Index Work ---

    DELETE FROM IndexDefrag WHERE
    IndexDefragCreatedAt < DATEADD(DAY, -200, GETDATE())

    UPDATE w
    SET IndexDefragIsPending = 0
    FROM IndexDefrag w
    INNER JOIN #instanceIndexStats s on w.IndexDefragDatabase = s.[Database]
    AND w.IndexDefragTableName = s.[TableName]
    AND w.IndexDefragIndexName = s.[IndexName]
    
    --- Close Prior Index Work ---

    --- Store Index Stats ---

    INSERT INTO IndexDefrag
    (IndexDefragDatabase, IndexDefragTableName, IndexDefragIndexName, IndexDefragFragPercentage, 
    IndexDefragFragCount, IndexDefragPageCount, IndexDefragIsPending, IndexDefragIsCompleted,
    IndexDefragCreatedAt)
    SELECT
    s.[Database], 
    s.[TableName], 
    s.[IndexName], 
    s.[FragmentationPerc], 
    s.[FragmentCount], 
    s.[PageCount],
    1, 
    0, 
    GETDATE()
    FROM #instanceIndexStats s
    
    --- Store Index Stats ---

    DROP TABLE #instanceDbs
    DROP TABLE #instanceIndexStats
END

GO


