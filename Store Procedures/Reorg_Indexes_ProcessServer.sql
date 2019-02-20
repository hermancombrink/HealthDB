CREATE PROCEDURE [dbo].[Reorg_Indexes_ProcessServer]
    @workTimeInMinutes decimal(18,2) = 1,
    @doProcess bit = 1
AS
BEGIN

    SET NOCOUNT ON 
    DECLARE @workTimeInSeconds decimal(18,2)
    SET @workTimeInSeconds = @workTimeInMinutes * 60

    print 'Allowed working time is ' + CAST(@workTimeInMinutes as varchar(10)) + 'minutes'

    --- Gather Index Work To Process ---

     CREATE TABLE #indexProcessStats
     (
      [IndexDefragID] bigint,
      [Database]  nvarchar(150), 
      [IndexName] nvarchar(150),
      [TableName] nvarchar(150),
      [FragmentationPerc] float,
      [FragmentCount] int,
      [PageCount] int, 
      [PrevFragmentationPerc] float,
      [PrevFragmentCount] int,
      [PrevPageCount] int, 
      [RunTime] int,
      [LastCompletedAt] datetime NULL,
      [WorkFactor] decimal(18,2) NULL
     )

     ;WITH historicWork as 
     (
       SELECT  
         IndexDefragID,
         IndexDefragDatabase, 
         IndexDefragIndexName, 
         IndexDefragTableName, 
         IndexDefragFragPercentage, 
         IndexDefragFragCount, 
         IndexDefragPageCount, 
         IndexDefragIsPending,
         IndexDefragCreatedAt,
         DATEDIFF(SECOND, IndexDefragStartedAt, IndexDefragCompletedAt) as RunTime,
         ROW_NUMBER() OVER (PARTITION BY IndexDefragDatabase, IndexDefragIndexName, IndexDefragTableName 
         ORDER BY IndexDefragCreatedAt DESC) AS IRank
        FROM IndexDefrag
     ), pendingwork as
     (
        SELECT 
         l.IndexDefragID,
         l.IndexDefragDatabase, 
         l.IndexDefragIndexName, 
         l.IndexDefragTableName, 
         l.IndexDefragFragPercentage, 
         l.IndexDefragFragCount, 
         l.IndexDefragPageCount,
         l.IndexDefragCreatedAt,
         l.RunTime,
         p.IndexDefragFragPercentage AS PrevIndexDefragFragPercentage, 
         p.IndexDefragFragCount AS PrevIndexDefragFragCount, 
         p.IndexDefragPageCount AS PrevIndexDefragPageCount
        FROM historicWork l
        LEFT JOIN historicWork p on l.IndexDefragDatabase = p.IndexDefragDatabase
            AND l.IndexDefragIndexName = p.IndexDefragIndexName
            AND l.IndexDefragTableName = p.IndexDefragTableName
            AND p.IRank = 2
        WHERE l.IRank = 1
        AND l.IndexDefragIsPending = 1
     )
     INSERT INTO #indexProcessStats
     SELECT 
         IndexDefragID,
         IndexDefragDatabase, 
         IndexDefragIndexName, 
         IndexDefragTableName, 
         IndexDefragFragPercentage, 
         IndexDefragFragCount, 
         IndexDefragPageCount,
         PrevIndexDefragFragPercentage,
         PrevIndexDefragFragCount,
         PrevIndexDefragPageCount,
         RunTime,
         NULL,
         NULL
     FROM pendingwork

     ;with lastcompleted as
     (
        SELECT MAX(IndexDefragCompletedAt) as LastCompletedAt,
        IndexDefragDatabase,
        IndexDefragTableName,
        IndexDefragIndexName
        FROM IndexDefrag
        WHERE IndexDefragCompletedAt IS NOT NULL
        GROUP BY 
        IndexDefragDatabase,
        IndexDefragTableName,
        IndexDefragIndexName
     )
     UPDATE p
     SET p.LastCompletedAt = i.LastCompletedAt
     FROM #indexProcessStats p
     INNER JOIN lastcompleted i on p.[Database] = i.IndexDefragDatabase
     and p.TableName = i.IndexDefragTableName
     and p.IndexName = i.IndexDefragIndexName

     UPDATE #indexProcessStats
     SET WorkFactor = dbo.GetIndexDefragFactor(FragmentationPerc,
      FragmentCount,
      PageCount, 
      PrevFragmentationPerc,
      PrevFragmentCount,
      PrevPageCount, 
      LastCompletedAt)
     
    --- Gather Index Work To Process ---
    
    IF @doProcess = 0
    BEGIN
        SELECT * FROM #indexProcessStats ORDER BY WorkFactor DESC
        RETURN
    END

    --- Update Indexes ---
   
    DECLARE @remainingTime decimal(18,2) = @workTimeInSeconds, 
    @DBNAME nvarchar(150), 
    @TABNAME nvarchar(150), 
    @IXNAME nvarchar(150),
    @RUNTIME decimal(18,2),
    @STIME datetime,
    @IXCOUNT int = (SELECT COUNT(*) FROM #indexProcessStats),
    @workId bigint,
    @batchId uniqueidentifier = NEWID()
    print 'Total indexes to process ' + CAST(@IXCOUNT as varchar(10))

    WHILE (@remainingTime > 0 AND (SELECT COUNT(*) FROM #indexProcessStats) > 0)
    BEGIN

        --this could be a possbile problem if the estimation blows this out from the start...
        --work time should there for always be more than a single index estimate
        DELETE FROM #indexProcessStats
        WHERE COALESCE(RunTime, 0) > @remainingTime -- Exclude all work that we dont have enough time for

        print 'Removed ' + CAST(@@ROWCOUNT as varchar(10)) + ' indexes due to time constraint'
     
        SET @IXCOUNT = (SELECT COUNT(*) FROM #indexProcessStats)

        print 'Remaining indexes to process ' + CAST(@IXCOUNT as varchar(10))
        print 'Remaining time to process ' + CAST(@remainingTime as varchar(10)) + 'sec'
  
        SELECT TOP 1 -- Get next index to process
        @workId  = IndexDefragID,
        @DBNAME  = [Database],
        @TABNAME = [TableName],
        @IXNAME  = [IndexName]
        FROM #indexProcessStats
        ORDER BY WorkFactor DESC

        SET @STIME = GETDATE()

        EXEC [dbo].[Reorg_Index_Item]  @DBNAME, @TABNAME, @IXNAME, @workId, @batchId

        DELETE #indexProcessStats
        WHERE IndexDefragID = @workId

        SET @RUNTIME = DATEDIFF(SECOND, @STIME, GETDATE()) -- update total run time for this index
        SET @remainingTime = @remainingTime - @RUNTIME -- set remainder for work time

        print 'Work finished for this run'

    END
    
    --- Update Indexes ---

    DROP TABLE #indexProcessStats
END

GO
