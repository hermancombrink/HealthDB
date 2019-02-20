CREATE PROCEDURE [dbo].[SQLErrorLog]
AS
DECLARE @SQLErrorlog TABLE (LogDate datetime, ProcessorInfo VARCHAR (100),ErrorMSG VARCHAR(2000))
INSERT INTO @SQLErrorlog 
EXEC sp_executesql N'xp_readerrorlog'
select  * from  @SQLErrorlog  where errormsg like '%Failed%'order by LogDate desc
RETURN 0
