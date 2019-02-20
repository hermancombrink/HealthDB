﻿CREATE VIEW [dbo].[WaitStats]
AS

WITH [Waits] AS 
   (SELECT 
    [wait_type], 
    [wait_time_ms] / 1000.0 AS [WaitS], 
    ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS], 
    [signal_wait_time_ms] / 1000.0 AS [SignalS], 
    [waiting_tasks_count] AS [WaitCount], 
    100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage], 
    ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum] 
   FROM sys.dm_os_wait_stats 
   WHERE [waiting_tasks_count] > 0 
   ) 
   SELECT 
    MAX ([W1].[wait_type]) AS [WaitType], 
    CAST (MAX ([W1].[WaitS]) AS DECIMAL (16,2)) AS [WaitSeconds], 
    CAST (MAX ([W1].[ResourceS]) AS DECIMAL (16,2)) AS [ResourceSeconds], 
    CAST (MAX ([W1].[SignalS]) AS DECIMAL (16,2)) AS [SignalSeconds], 
    MAX ([W1].[WaitCount]) AS [WaitCount], 
    CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2)) AS [Percentage], 
    CAST ((MAX ([W1].[WaitS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgWaitSeconds], 
    CAST ((MAX ([W1].[ResourceS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgResSeconds], 
    CAST ((MAX ([W1].[SignalS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgSigSeconds], 
    CAST ('https://www.sqlskills.com/help/waits/' + MAX ([W1].[wait_type]) as XML) AS [URL] 
   FROM [Waits] AS [W1] 
   INNER JOIN [Waits] AS [W2] 
    ON [W2].[RowNum] <= [W1].[RowNum] 
   GROUP BY [W1].[RowNum] HAVING SUM ([W2].[Percentage]) - MAX([W1].[Percentage]) < 95
GO
