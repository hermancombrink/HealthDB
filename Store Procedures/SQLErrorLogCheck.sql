CREATE PROCEDURE [dbo].[SQLErrorLogCheck]
	@start DATETIME = NULL,
	@end DATETIME  = NULL
AS
 SET @start = ISNULL(@start, DATEADD(MINUTE,-60,GETDATE()))
 SET @end= ISNULL(@end, GETDATE())
 
EXEC xp_readerrorlog 0, 1,NULL,NULL,@start,@end,'Desc'
RETURN 0
