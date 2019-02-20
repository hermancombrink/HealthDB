DECLARE @Version Float, @str Varchar(2000)

SELECT @Version = CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS Varchar(250)),2) AS FLOAT)

SELECT @str = CASE WHEN @Version > 9 THEN 'SELECT ServerStartDate = sqlserver_start_time FROM sys.dm_os_sys_info;'
                   ELSE 'SELECT ServerStartDate = crdate from sysdatabases WHERE name = ''TempDB'''
			  END
EXEC (@str)
