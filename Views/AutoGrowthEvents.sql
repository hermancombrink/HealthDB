CREATE VIEW [dbo].[AutoGrowthEvents]
AS
With logPath as
(
SELECT 
    REVERSE(SUBSTRING(REVERSE([path]), 
   CHARINDEX('\', REVERSE([path])), 260)) + N'log.trc' as path
FROM    sys.traces
WHERE   is_default = 1
)

SELECT TOP 100 PERCENT
   DatabaseName,
   [FileName],
   SPID,
   Duration,
   StartTime,
   EndTime,
   FileType = CASE EventClass 
       WHEN 92 THEN 'Data'
       WHEN 93 THEN 'Log'
   END
FROM sys.fn_trace_gettable((select top 1 path from logPath), DEFAULT)
WHERE
   EventClass IN (92,93)
   AND Year(StartTime) = Year(getdate())    --- Added by Shekhar to check current year auto-growth only
ORDER BY
   StartTime DESC;
GO
