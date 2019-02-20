CREATE PROCEDURE [dbo].[Reorg_Index_Item]
    @dbName nvarchar(150), 
    @tabName nvarchar(150), 
    @ixName nvarchar(150),
    @workId bigint = NULL,
    @batchId uniqueidentifier = NULL
AS
BEGIN

    SET NOCOUNT ON 
    DECLARE @dynCommand nvarchar(max), 
    @sTime datetime = GETDATE()

    SET @dynCommand = 'USE [' + @DBNAME + ']; 
    ALTER INDEX ' + @IXNAME + ' 
    ON ' + @TABNAME + ' REORGANIZE'

    EXEC (@dynCommand)

    MERGE IndexDefrag AS target  
        USING (SELECT @workId) AS source (IndexDefragID)  
        ON (target.IndexDefragID = source.IndexDefragID)  
        WHEN MATCHED THEN   
            UPDATE SET 
            IndexDefragBatchGuid = @batchId,
            IndexDefragCompletedAt = GETDATE(),
            IndexDefragStartedAt = @sTime,
            IndexDefragIsCompleted = 1,
            IndexDefragIsPending = 0
    WHEN NOT MATCHED THEN  
            INSERT (IndexDefragDatabase, 
            IndexDefragTableName, 
            IndexDefragIndexName, 
            IndexDefragFragPercentage, 
            IndexDefragFragCount, 
            IndexDefragPageCount,
            IndexDefragIsPending, 
            IndexDefragIsCompleted, 
            IndexDefragStartedAt,
            IndexDefragCompletedAt,
            IndexDefragBatchGuid)  
            VALUES (@dbName, @tabName, @ixName, 0, 0, 0, 0, 1, @sTime, GETDATE(), @batchId);  
   
END

GO


