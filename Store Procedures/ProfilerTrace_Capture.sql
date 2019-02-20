CREATE PROCEDURE [dbo].[ProfilerTrace_Capture] @TraceFilePath nVarchar(250), @StopHoursAfter INT, 
@FilterDurationMS bigINT = 6000
AS
BEGIN
	SET NOCOUNT ON;

-- Create a Queue
	declare @rc int
	declare @TraceID int
	declare @maxfilesize bigint
	declare @stoptime datetime
	declare @filecount int
	declare @tracefile nVarchar(100)
	DECLARE @Today Varchar(10)
	--declare @TraceFilePath nVarchar(50)
	--set @TraceFilePath = 'I\Projects\Traces'
	SET @Today = CAST(Year(GETDATE()) AS Varchar(4))+ RIGHT('0'+CAST(Month(GETDATE()) AS Varchar(2)),2) 
				+ RIGHT('0'+CAST(Day(GETDATE()) AS Varchar(2)),2) 
				--+ RIGHT('0'+CAST(HOUR(GETDATE()) AS Varchar(2)),2)+ RIGHT('0'+CAST(Minutes(GETDATE()) AS Varchar(2)),2)
	SET @stoptime = DATEADD(hh, @StopHoursAfter, GETDATE()) --CONVERT(DATETIME, @Today + ' 09:42:59', 106)
	set @maxfilesize = 512
	SET @filecount = 4			---- Only useful when @options = 2 instead of 0 i.e. Trace_File_Rollover
	SET @tracefile = @TraceFilePath + '\TTAWSDB01_' + @Today + '_' + REPLACE(convert(varchar(5), GETDATE(), 14),':','')
	select @tracefile
	-- Mod 12.04 Start
	SELECT @TraceID = id FROM sys.traces WHERE path = @tracefile
	IF @TraceID IS NOT NULL					
	BEGIN
		EXEC sp_trace_setstatus @TraceId, 0
		EXEC sp_trace_setstatus @TraceId, 2
	END
	-- Mod 12.04 End
	exec @rc = sp_trace_create @TraceID output, 0, @tracefile, @maxfilesize, @stoptime--, @filecount 
	if (@rc != 0) goto error

------ Write current trace file to the table
	--EXEC dbo.usp_SQLProfilerTraceData_WriteToTable
	--INSERT INTO dbo.CurrentTraceFile VALUES (@tracefile+'.trc')
	UPDATE DatabaseHealth.dbo.CurrentTraceFile SET TrcFileName = @tracefile+'.trc'
------
	-- Set the events

	declare @on bit
	set @on = 1
	/*
	@EventId = 23 : Lock:Released
	*/
	--exec sp_trace_setevent @TraceID, 23, 1, @on -- TextData
	--exec sp_trace_setevent @TraceID, 23, 12, @on -- SPID
	--exec sp_trace_setevent @TraceID, 23, 13, @on -- Duration
	--exec sp_trace_setevent @TraceID, 23, 14, @on -- Start Time
	--exec sp_trace_setevent @TraceID, 23, 15, @on -- End Time
	--exec sp_trace_setevent @TraceID, 23, 16, @on -- Reads
	--exec sp_trace_setevent @TraceID, 23, 17, @on -- Writes
	--exec sp_trace_setevent @TraceID, 23, 48, @on -- Row Counts
	--exec sp_trace_setevent @TraceID, 23, 18, @on -- CPU
	--exec sp_trace_setevent @TraceID, 23, 6, @on -- NTUserName
	--exec sp_trace_setevent @TraceID, 23, 7, @on -- NTDomainName
	--exec sp_trace_setevent @TraceID, 23, 8, @on -- HostName
	--exec sp_trace_setevent @TraceID, 23, 10, @on -- ApplicationName
	--exec sp_trace_setevent @TraceID, 23, 11, @on -- LoginName
	--exec sp_trace_setevent @TraceID, 23, 26, @on -- Server Name
	--exec sp_trace_setevent @TraceID, 23, 30, @on -- Server State, in case of an error
	--exec sp_trace_setevent @TraceID, 23, 31, @on -- Error Number
	--exec sp_trace_setevent @TraceID, 23, 32, @on -- Lock mode of the lock acquired
	--exec sp_trace_setevent @TraceID, 23, 34, @on -- Object Name
	--exec sp_trace_setevent @TraceID, 23, 35, @on -- Database Name
	--exec sp_trace_setevent @TraceID, 23, 40, @on -- DB User Name
	--exec sp_trace_setevent @TraceID, 23, 46, @on -- Name of the OLE DB Provider
	--exec sp_trace_setevent @TraceID, 23, 47, @on -- Name of the OLE DB Method
	/*
	@EventId = 50 : SQL Transaction
	*/
	exec sp_trace_setevent @TraceID, 50, 1, @on -- TextData
	exec sp_trace_setevent @TraceID, 50, 12, @on -- SPID
	exec sp_trace_setevent @TraceID, 50, 13, @on -- Duration
	exec sp_trace_setevent @TraceID, 50, 14, @on -- Start Time
	exec sp_trace_setevent @TraceID, 50, 15, @on -- End Time
	exec sp_trace_setevent @TraceID, 50, 16, @on -- Reads
	exec sp_trace_setevent @TraceID, 50, 17, @on -- Writes
	exec sp_trace_setevent @TraceID, 50, 48, @on -- Row Counts
	exec sp_trace_setevent @TraceID, 50, 18, @on -- CPU
	exec sp_trace_setevent @TraceID, 50, 6, @on -- NTUserName
	exec sp_trace_setevent @TraceID, 50, 7, @on -- NTDomainName
	exec sp_trace_setevent @TraceID, 50, 8, @on -- HostName
	exec sp_trace_setevent @TraceID, 50, 10, @on -- ApplicationName
	exec sp_trace_setevent @TraceID, 50, 11, @on -- LoginName
	exec sp_trace_setevent @TraceID, 50, 26, @on -- Server Name
	exec sp_trace_setevent @TraceID, 50, 30, @on -- Server State, in case of an error
	exec sp_trace_setevent @TraceID, 50, 31, @on -- Error Number
	exec sp_trace_setevent @TraceID, 50, 32, @on -- Lock mode of the lock acquired
	exec sp_trace_setevent @TraceID, 50, 34, @on -- Object Name
	exec sp_trace_setevent @TraceID, 50, 35, @on -- Database Name
	exec sp_trace_setevent @TraceID, 50, 40, @on -- DB User Name
	exec sp_trace_setevent @TraceID, 50, 46, @on -- Name of the OLE DB Provider
	exec sp_trace_setevent @TraceID, 50, 47, @on -- Name of the OLE DB Method	
	/*
	@EventId = 61 : OLE DB Errors
	*/
	exec sp_trace_setevent @TraceID, 61, 1, @on -- TextData
	exec sp_trace_setevent @TraceID, 61, 12, @on -- SPID
	exec sp_trace_setevent @TraceID, 61, 13, @on -- Duration
	exec sp_trace_setevent @TraceID, 61, 14, @on -- Start Time
	exec sp_trace_setevent @TraceID, 61, 15, @on -- End Time
	exec sp_trace_setevent @TraceID, 61, 16, @on -- Reads
	exec sp_trace_setevent @TraceID, 61, 17, @on -- Writes
	exec sp_trace_setevent @TraceID, 61, 48, @on -- Row Counts
	exec sp_trace_setevent @TraceID, 61, 18, @on -- CPU
	exec sp_trace_setevent @TraceID, 61, 6, @on -- NTUserName
	exec sp_trace_setevent @TraceID, 61, 7, @on -- NTDomainName
	exec sp_trace_setevent @TraceID, 61, 8, @on -- HostName
	exec sp_trace_setevent @TraceID, 61, 10, @on -- ApplicationName
	exec sp_trace_setevent @TraceID, 61, 11, @on -- LoginName
	exec sp_trace_setevent @TraceID, 61, 26, @on -- Server Name
	exec sp_trace_setevent @TraceID, 61, 30, @on -- Server State, in case of an error
	exec sp_trace_setevent @TraceID, 61, 31, @on -- Error Number
	exec sp_trace_setevent @TraceID, 61, 32, @on -- Lock mode of the lock acquired
	exec sp_trace_setevent @TraceID, 61, 34, @on -- Object Name
	exec sp_trace_setevent @TraceID, 61, 35, @on -- Database Name
	exec sp_trace_setevent @TraceID, 61, 40, @on -- DB User Name
	exec sp_trace_setevent @TraceID, 61, 46, @on -- Name of the OLE DB Provider
	exec sp_trace_setevent @TraceID, 61, 47, @on -- Name of the OLE DB Method	

	/*
	@EventId = 181 : TM : Begin Tran Starting
	*/
	exec sp_trace_setevent @TraceID, 181, 1, @on -- TextData
	exec sp_trace_setevent @TraceID, 181, 12, @on -- SPID
	exec sp_trace_setevent @TraceID, 181, 13, @on -- Duration
	exec sp_trace_setevent @TraceID, 181, 14, @on -- Start Time
	exec sp_trace_setevent @TraceID, 181, 15, @on -- End Time
	exec sp_trace_setevent @TraceID, 181, 16, @on -- Reads
	exec sp_trace_setevent @TraceID, 181, 17, @on -- Writes
	exec sp_trace_setevent @TraceID, 181, 48, @on -- Row Counts
	exec sp_trace_setevent @TraceID, 181, 18, @on -- CPU
	exec sp_trace_setevent @TraceID, 181, 6, @on -- NTUserName
	exec sp_trace_setevent @TraceID, 181, 7, @on -- NTDomainName
	exec sp_trace_setevent @TraceID, 181, 8, @on -- HostName
	exec sp_trace_setevent @TraceID, 181, 10, @on -- ApplicationName
	exec sp_trace_setevent @TraceID, 181, 11, @on -- LoginName
	exec sp_trace_setevent @TraceID, 181, 26, @on -- Server Name
	exec sp_trace_setevent @TraceID, 181, 30, @on -- Server State, in case of an error
	exec sp_trace_setevent @TraceID, 181, 31, @on -- Error Number
	exec sp_trace_setevent @TraceID, 181, 32, @on -- Lock mode of the lock acquired
	exec sp_trace_setevent @TraceID, 181, 34, @on -- Object Name
	exec sp_trace_setevent @TraceID, 181, 35, @on -- Database Name
	exec sp_trace_setevent @TraceID, 181, 40, @on -- DB User Name
	exec sp_trace_setevent @TraceID, 181, 46, @on -- Name of the OLE DB Provider
	exec sp_trace_setevent @TraceID, 181, 47, @on -- Name of the OLE DB Method
	/*
	@EventId = 182 : TM : Begin Tran Completed
	*/
	exec sp_trace_setevent @TraceID, 182, 1, @on -- TextData
	exec sp_trace_setevent @TraceID, 182, 12, @on -- SPID
	exec sp_trace_setevent @TraceID, 182, 13, @on -- Duration
	exec sp_trace_setevent @TraceID, 182, 14, @on -- Start Time
	exec sp_trace_setevent @TraceID, 182, 15, @on -- End Time
	exec sp_trace_setevent @TraceID, 182, 16, @on -- Reads
	exec sp_trace_setevent @TraceID, 182, 17, @on -- Writes
	exec sp_trace_setevent @TraceID, 182, 48, @on -- Row Counts
	exec sp_trace_setevent @TraceID, 182, 18, @on -- CPU
	exec sp_trace_setevent @TraceID, 182, 6, @on -- NTUserName
	exec sp_trace_setevent @TraceID, 182, 7, @on -- NTDomainName
	exec sp_trace_setevent @TraceID, 182, 8, @on -- HostName
	exec sp_trace_setevent @TraceID, 182, 10, @on -- ApplicationName
	exec sp_trace_setevent @TraceID, 182, 11, @on -- LoginName
	exec sp_trace_setevent @TraceID, 182, 26, @on -- Server Name
	exec sp_trace_setevent @TraceID, 182, 30, @on -- Server State, in case of an error
	exec sp_trace_setevent @TraceID, 182, 31, @on -- Error Number
	exec sp_trace_setevent @TraceID, 182, 32, @on -- Lock mode of the lock acquired
	exec sp_trace_setevent @TraceID, 182, 34, @on -- Object Name
	exec sp_trace_setevent @TraceID, 182, 35, @on -- Database Name
	exec sp_trace_setevent @TraceID, 182, 40, @on -- DB User Name
	exec sp_trace_setevent @TraceID, 182, 46, @on -- Name of the OLE DB Provider
	exec sp_trace_setevent @TraceID, 182, 47, @on -- Name of the OLE DB Method
	/*
	@EventId = 185 : TM : Commit Tran Starting
	*/
	exec sp_trace_setevent @TraceID, 185, 1, @on -- TextData
	exec sp_trace_setevent @TraceID, 185, 12, @on -- SPID
	exec sp_trace_setevent @TraceID, 185, 13, @on -- Duration
	exec sp_trace_setevent @TraceID, 185, 14, @on -- Start Time
	exec sp_trace_setevent @TraceID, 185, 15, @on -- End Time
	exec sp_trace_setevent @TraceID, 185, 16, @on -- Reads
	exec sp_trace_setevent @TraceID, 185, 17, @on -- Writes
	exec sp_trace_setevent @TraceID, 185, 48, @on -- Row Counts
	exec sp_trace_setevent @TraceID, 185, 18, @on -- CPU
	exec sp_trace_setevent @TraceID, 185, 6, @on -- NTUserName
	exec sp_trace_setevent @TraceID, 185, 7, @on -- NTDomainName
	exec sp_trace_setevent @TraceID, 185, 8, @on -- HostName
	exec sp_trace_setevent @TraceID, 185, 10, @on -- ApplicationName
	exec sp_trace_setevent @TraceID, 185, 11, @on -- LoginName
	exec sp_trace_setevent @TraceID, 185, 26, @on -- Server Name
	exec sp_trace_setevent @TraceID, 185, 30, @on -- Server State, in case of an error
	exec sp_trace_setevent @TraceID, 185, 31, @on -- Error Number
	exec sp_trace_setevent @TraceID, 185, 32, @on -- Lock mode of the lock acquired
	exec sp_trace_setevent @TraceID, 185, 34, @on -- Object Name
	exec sp_trace_setevent @TraceID, 185, 35, @on -- Database Name
	exec sp_trace_setevent @TraceID, 185, 40, @on -- DB User Name
	exec sp_trace_setevent @TraceID, 185, 46, @on -- Name of the OLE DB Provider
	exec sp_trace_setevent @TraceID, 185, 47, @on -- Name of the OLE DB Method
	/*
	@EventId = 186 : TM : Commit Tran Completed
	*/
	exec sp_trace_setevent @TraceID, 186, 1, @on -- TextData
	exec sp_trace_setevent @TraceID, 186, 12, @on -- SPID
	exec sp_trace_setevent @TraceID, 186, 13, @on -- Duration
	exec sp_trace_setevent @TraceID, 186, 14, @on -- Start Time
	exec sp_trace_setevent @TraceID, 186, 15, @on -- End Time
	exec sp_trace_setevent @TraceID, 186, 16, @on -- Reads
	exec sp_trace_setevent @TraceID, 186, 17, @on -- Writes
	exec sp_trace_setevent @TraceID, 186, 48, @on -- Row Counts
	exec sp_trace_setevent @TraceID, 186, 18, @on -- CPU
	exec sp_trace_setevent @TraceID, 186, 6, @on -- NTUserName
	exec sp_trace_setevent @TraceID, 186, 7, @on -- NTDomainName
	exec sp_trace_setevent @TraceID, 186, 8, @on -- HostName
	exec sp_trace_setevent @TraceID, 186, 10, @on -- ApplicationName
	exec sp_trace_setevent @TraceID, 186, 11, @on -- LoginName
	exec sp_trace_setevent @TraceID, 186, 26, @on -- Server Name
	exec sp_trace_setevent @TraceID, 186, 30, @on -- Server State, in case of an error
	exec sp_trace_setevent @TraceID, 186, 31, @on -- Error Number
	exec sp_trace_setevent @TraceID, 186, 32, @on -- Lock mode of the lock acquired
	exec sp_trace_setevent @TraceID, 186, 34, @on -- Object Name
	exec sp_trace_setevent @TraceID, 186, 35, @on -- Database Name
	exec sp_trace_setevent @TraceID, 186, 40, @on -- DB User Name
	exec sp_trace_setevent @TraceID, 186, 46, @on -- Name of the OLE DB Provider
	exec sp_trace_setevent @TraceID, 186, 47, @on -- Name of the OLE DB Method
	/*
	@EventId = 187 : TM : Rollback Tran Starting
	*/
	exec sp_trace_setevent @TraceID, 187, 1, @on -- TextData
	exec sp_trace_setevent @TraceID, 187, 12, @on -- SPID
	exec sp_trace_setevent @TraceID, 187, 13, @on -- Duration
	exec sp_trace_setevent @TraceID, 187, 14, @on -- Start Time
	exec sp_trace_setevent @TraceID, 187, 15, @on -- End Time
	exec sp_trace_setevent @TraceID, 187, 16, @on -- Reads
	exec sp_trace_setevent @TraceID, 187, 17, @on -- Writes
	exec sp_trace_setevent @TraceID, 187, 48, @on -- Row Counts
	exec sp_trace_setevent @TraceID, 187, 18, @on -- CPU
	exec sp_trace_setevent @TraceID, 187, 6, @on -- NTUserName
	exec sp_trace_setevent @TraceID, 187, 7, @on -- NTDomainName
	exec sp_trace_setevent @TraceID, 187, 8, @on -- HostName
	exec sp_trace_setevent @TraceID, 187, 10, @on -- ApplicationName
	exec sp_trace_setevent @TraceID, 187, 11, @on -- LoginName
	exec sp_trace_setevent @TraceID, 187, 26, @on -- Server Name
	exec sp_trace_setevent @TraceID, 187, 30, @on -- Server State, in case of an error
	exec sp_trace_setevent @TraceID, 187, 31, @on -- Error Number
	exec sp_trace_setevent @TraceID, 187, 32, @on -- Lock mode of the lock acquired
	exec sp_trace_setevent @TraceID, 187, 34, @on -- Object Name
	exec sp_trace_setevent @TraceID, 187, 35, @on -- Database Name
	exec sp_trace_setevent @TraceID, 187, 40, @on -- DB User Name
	exec sp_trace_setevent @TraceID, 187, 46, @on -- Name of the OLE DB Provider
	exec sp_trace_setevent @TraceID, 187, 47, @on -- Name of the OLE DB Method
	/*
	@EventId = 188 : TM : Rollback Tran Completed
	*/
	exec sp_trace_setevent @TraceID, 188, 1, @on -- TextData
	exec sp_trace_setevent @TraceID, 188, 12, @on -- SPID
	exec sp_trace_setevent @TraceID, 188, 13, @on -- Duration
	exec sp_trace_setevent @TraceID, 188, 14, @on -- Start Time
	exec sp_trace_setevent @TraceID, 188, 15, @on -- End Time
	exec sp_trace_setevent @TraceID, 188, 16, @on -- Reads
	exec sp_trace_setevent @TraceID, 188, 17, @on -- Writes
	exec sp_trace_setevent @TraceID, 188, 48, @on -- Row Counts
	exec sp_trace_setevent @TraceID, 188, 18, @on -- CPU
	exec sp_trace_setevent @TraceID, 188, 6, @on -- NTUserName
	exec sp_trace_setevent @TraceID, 188, 7, @on -- NTDomainName
	exec sp_trace_setevent @TraceID, 188, 8, @on -- HostName
	exec sp_trace_setevent @TraceID, 188, 10, @on -- ApplicationName
	exec sp_trace_setevent @TraceID, 188, 11, @on -- LoginName
	exec sp_trace_setevent @TraceID, 188, 26, @on -- Server Name
	exec sp_trace_setevent @TraceID, 188, 30, @on -- Server State, in case of an error
	exec sp_trace_setevent @TraceID, 188, 31, @on -- Error Number
	exec sp_trace_setevent @TraceID, 188, 32, @on -- Lock mode of the lock acquired
	exec sp_trace_setevent @TraceID, 188, 34, @on -- Object Name
	exec sp_trace_setevent @TraceID, 188, 35, @on -- Database Name
	exec sp_trace_setevent @TraceID, 188, 40, @on -- DB User Name
	exec sp_trace_setevent @TraceID, 188, 46, @on -- Name of the OLE DB Provider
	exec sp_trace_setevent @TraceID, 188, 47, @on -- Name of the OLE DB Method


	/*
	@EventId = 24 : Lock:Acquired
	*/
	exec sp_trace_setevent @TraceID, 24, 1, @on -- TextData
	exec sp_trace_setevent @TraceID, 24, 12, @on -- SPID
	exec sp_trace_setevent @TraceID, 24, 13, @on -- Duration
	exec sp_trace_setevent @TraceID, 24, 14, @on -- Start Time
	exec sp_trace_setevent @TraceID, 24, 15, @on -- End Time
	exec sp_trace_setevent @TraceID, 24, 16, @on -- Reads
	exec sp_trace_setevent @TraceID, 24, 17, @on -- Writes
	exec sp_trace_setevent @TraceID, 24, 48, @on -- Row Counts
	exec sp_trace_setevent @TraceID, 24, 18, @on -- CPU
	exec sp_trace_setevent @TraceID, 24, 6, @on -- NTUserName
	exec sp_trace_setevent @TraceID, 24, 7, @on -- NTDomainName
	exec sp_trace_setevent @TraceID, 24, 8, @on -- HostName
	exec sp_trace_setevent @TraceID, 24, 10, @on -- ApplicationName
	exec sp_trace_setevent @TraceID, 24, 11, @on -- LoginName
	exec sp_trace_setevent @TraceID, 24, 26, @on -- Server Name
	exec sp_trace_setevent @TraceID, 24, 30, @on -- Server State, in case of an error
	exec sp_trace_setevent @TraceID, 24, 31, @on -- Error Number
	exec sp_trace_setevent @TraceID, 24, 32, @on -- Lock mode of the lock acquired
	exec sp_trace_setevent @TraceID, 24, 34, @on -- Object Name
	exec sp_trace_setevent @TraceID, 24, 35, @on -- Database Name
	exec sp_trace_setevent @TraceID, 24, 40, @on -- DB User Name
	exec sp_trace_setevent @TraceID, 24, 46, @on -- Name of the OLE DB Provider
	exec sp_trace_setevent @TraceID, 24, 47, @on -- Name of the OLE DB Method
	/*
	@EventId = 137 : Blocked Process Report
	*/
	exec sp_trace_setevent @TraceID, 137, 1, @on -- TextData
	exec sp_trace_setevent @TraceID, 137, 12, @on -- SPID
	exec sp_trace_setevent @TraceID, 137, 13, @on -- Duration
	exec sp_trace_setevent @TraceID, 137, 14, @on -- Start Time
	exec sp_trace_setevent @TraceID, 137, 15, @on -- End Time
	exec sp_trace_setevent @TraceID, 137, 16, @on -- Reads
	exec sp_trace_setevent @TraceID, 137, 17, @on -- Writes
	exec sp_trace_setevent @TraceID, 137, 48, @on -- Row Counts
	exec sp_trace_setevent @TraceID, 137, 18, @on -- CPU
	exec sp_trace_setevent @TraceID, 137, 6, @on -- NTUserName
	exec sp_trace_setevent @TraceID, 137, 7, @on -- NTDomainName
	exec sp_trace_setevent @TraceID, 137, 8, @on -- HostName
	exec sp_trace_setevent @TraceID, 137, 10, @on -- ApplicationName
	exec sp_trace_setevent @TraceID, 137, 11, @on -- LoginName
	exec sp_trace_setevent @TraceID, 137, 26, @on -- Server Name
	exec sp_trace_setevent @TraceID, 137, 30, @on -- Server State, in case of an error
	exec sp_trace_setevent @TraceID, 137, 31, @on -- Error Number
	exec sp_trace_setevent @TraceID, 137, 32, @on -- Lock mode of the lock acquired
	exec sp_trace_setevent @TraceID, 137, 34, @on -- Object Name
	exec sp_trace_setevent @TraceID, 137, 35, @on -- Database Name
	exec sp_trace_setevent @TraceID, 137, 40, @on -- DB User Name
	exec sp_trace_setevent @TraceID, 137, 46, @on -- Name of the OLE DB Provider
	exec sp_trace_setevent @TraceID, 137, 47, @on -- Name of the OLE DB Method
	/*
	@EventId = 148 : Deadlock Graph
	*/
	exec sp_trace_setevent @TraceID, 148, 1, @on -- TextData
	exec sp_trace_setevent @TraceID, 148, 12, @on -- SPID
	exec sp_trace_setevent @TraceID, 148, 13, @on -- Duration
	exec sp_trace_setevent @TraceID, 148, 14, @on -- Start Time
	exec sp_trace_setevent @TraceID, 148, 15, @on -- End Time
	exec sp_trace_setevent @TraceID, 148, 16, @on -- Reads
	exec sp_trace_setevent @TraceID, 148, 17, @on -- Writes
	exec sp_trace_setevent @TraceID, 148, 48, @on -- Row Counts
	exec sp_trace_setevent @TraceID, 148, 18, @on -- CPU
	exec sp_trace_setevent @TraceID, 148, 6, @on -- NTUserName
	exec sp_trace_setevent @TraceID, 148, 7, @on -- NTDomainName
	exec sp_trace_setevent @TraceID, 148, 8, @on -- HostName
	exec sp_trace_setevent @TraceID, 148, 10, @on -- ApplicationName
	exec sp_trace_setevent @TraceID, 148, 11, @on -- LoginName
	exec sp_trace_setevent @TraceID, 148, 26, @on -- Server Name
	exec sp_trace_setevent @TraceID, 148, 30, @on -- Server State, in case of an error
	exec sp_trace_setevent @TraceID, 148, 31, @on -- Error Number
	exec sp_trace_setevent @TraceID, 148, 32, @on -- Lock mode of the lock acquired
	exec sp_trace_setevent @TraceID, 148, 34, @on -- Object Name
	exec sp_trace_setevent @TraceID, 148, 35, @on -- Database Name
	exec sp_trace_setevent @TraceID, 148, 40, @on -- DB User Name
	exec sp_trace_setevent @TraceID, 148, 46, @on -- Name of the OLE DB Provider
	exec sp_trace_setevent @TraceID, 148, 47, @on -- Name of the OLE DB Method
	/*
	@EventId = 25 : Lock:Deadlock
	*/
	exec sp_trace_setevent @TraceID, 25, 1, @on -- TextData
	exec sp_trace_setevent @TraceID, 25, 12, @on -- SPID
	exec sp_trace_setevent @TraceID, 25, 13, @on -- Duration
	exec sp_trace_setevent @TraceID, 25, 14, @on -- Start Time
	exec sp_trace_setevent @TraceID, 25, 15, @on -- End Time
	exec sp_trace_setevent @TraceID, 25, 16, @on -- Reads
	exec sp_trace_setevent @TraceID, 25, 17, @on -- Writes
	exec sp_trace_setevent @TraceID, 25, 48, @on -- Row Counts
	exec sp_trace_setevent @TraceID, 25, 18, @on -- CPU
	exec sp_trace_setevent @TraceID, 25, 6, @on -- NTUserName
	exec sp_trace_setevent @TraceID, 25, 7, @on -- NTDomainName
	exec sp_trace_setevent @TraceID, 25, 8, @on -- HostName
	exec sp_trace_setevent @TraceID, 25, 10, @on -- ApplicationName
	exec sp_trace_setevent @TraceID, 25, 11, @on -- LoginName
	exec sp_trace_setevent @TraceID, 25, 26, @on -- Server Name
	exec sp_trace_setevent @TraceID, 25, 30, @on -- Server State, in case of an error
	exec sp_trace_setevent @TraceID, 25, 31, @on -- Error Number
	exec sp_trace_setevent @TraceID, 25, 32, @on -- Lock mode of the lock acquired
	exec sp_trace_setevent @TraceID, 25, 34, @on -- Object Name
	exec sp_trace_setevent @TraceID, 25, 35, @on -- Database Name
	exec sp_trace_setevent @TraceID, 25, 40, @on -- DB User Name
	exec sp_trace_setevent @TraceID, 25, 46, @on -- Name of the OLE DB Provider
	exec sp_trace_setevent @TraceID, 25, 47, @on -- Name of the OLE DB Method
	/*
	@EventId = 59 : Lock:Deadlock Chain
	*/
	exec sp_trace_setevent @TraceID, 59, 1, @on -- TextData
	exec sp_trace_setevent @TraceID, 59, 12, @on -- SPID
	exec sp_trace_setevent @TraceID, 59, 13, @on -- Duration
	exec sp_trace_setevent @TraceID, 59, 14, @on -- Start Time
	exec sp_trace_setevent @TraceID, 59, 15, @on -- End Time
	exec sp_trace_setevent @TraceID, 59, 16, @on -- Reads
	exec sp_trace_setevent @TraceID, 59, 17, @on -- Writes
	exec sp_trace_setevent @TraceID, 59, 48, @on -- Row Counts
	exec sp_trace_setevent @TraceID, 59, 18, @on -- CPU
	exec sp_trace_setevent @TraceID, 59, 6, @on -- NTUserName
	exec sp_trace_setevent @TraceID, 59, 7, @on -- NTDomainName
	exec sp_trace_setevent @TraceID, 59, 8, @on -- HostName
	exec sp_trace_setevent @TraceID, 59, 10, @on -- ApplicationName
	exec sp_trace_setevent @TraceID, 59, 11, @on -- LoginName
	exec sp_trace_setevent @TraceID, 59, 26, @on -- Server Name
	exec sp_trace_setevent @TraceID, 59, 30, @on -- Server State, in case of an error
	exec sp_trace_setevent @TraceID, 59, 31, @on -- Error Number
	exec sp_trace_setevent @TraceID, 59, 32, @on -- Lock mode of the lock acquired
	exec sp_trace_setevent @TraceID, 59, 34, @on -- Object Name
	exec sp_trace_setevent @TraceID, 59, 35, @on -- Database Name
	exec sp_trace_setevent @TraceID, 59, 40, @on -- DB User Name
	exec sp_trace_setevent @TraceID, 59, 46, @on -- Name of the OLE DB Provider
	exec sp_trace_setevent @TraceID, 59, 47, @on -- Name of the OLE DB Method
	/*
	@EventId = 27 : Lock:Timeout 
	*/
	exec sp_trace_setevent @TraceID, 27, 1, @on -- TextData
	exec sp_trace_setevent @TraceID, 27, 12, @on -- SPID
	exec sp_trace_setevent @TraceID, 27, 13, @on -- Duration
	exec sp_trace_setevent @TraceID, 27, 14, @on -- Start Time
	exec sp_trace_setevent @TraceID, 27, 15, @on -- End Time
	exec sp_trace_setevent @TraceID, 27, 16, @on -- Reads
	exec sp_trace_setevent @TraceID, 27, 17, @on -- Writes
	exec sp_trace_setevent @TraceID, 27, 48, @on -- Row Counts
	exec sp_trace_setevent @TraceID, 27, 18, @on -- CPU
	exec sp_trace_setevent @TraceID, 27, 6, @on -- NTUserName
	exec sp_trace_setevent @TraceID, 27, 7, @on -- NTDomainName
	exec sp_trace_setevent @TraceID, 27, 8, @on -- HostName
	exec sp_trace_setevent @TraceID, 27, 10, @on -- ApplicationName
	exec sp_trace_setevent @TraceID, 27, 11, @on -- LoginName
	exec sp_trace_setevent @TraceID, 27, 26, @on -- Server Name
	exec sp_trace_setevent @TraceID, 27, 30, @on -- Server State, in case of an error
	exec sp_trace_setevent @TraceID, 27, 31, @on -- Error Number
	exec sp_trace_setevent @TraceID, 27, 32, @on -- Lock mode of the lock acquired
	exec sp_trace_setevent @TraceID, 27, 34, @on -- Object Name
	exec sp_trace_setevent @TraceID, 27, 35, @on -- Database Name
	exec sp_trace_setevent @TraceID, 27, 40, @on -- DB User Name
	exec sp_trace_setevent @TraceID, 27, 46, @on -- Name of the OLE DB Provider
	exec sp_trace_setevent @TraceID, 27, 47, @on -- Name of the OLE DB Method
	/*
	@EventId = 10 : RPC:Completed
	*/
	exec sp_trace_setevent @TraceID, 10, 1, @on -- TextData
	exec sp_trace_setevent @TraceID, 10, 12, @on -- SPID
	exec sp_trace_setevent @TraceID, 10, 13, @on -- Duration
	exec sp_trace_setevent @TraceID, 10, 14, @on -- Start Time
	exec sp_trace_setevent @TraceID, 10, 15, @on -- End Time
	exec sp_trace_setevent @TraceID, 10, 16, @on -- Reads
	exec sp_trace_setevent @TraceID, 10, 17, @on -- Writes
	exec sp_trace_setevent @TraceID, 10, 48, @on -- Row Counts
	exec sp_trace_setevent @TraceID, 10, 18, @on -- CPU
	exec sp_trace_setevent @TraceID, 10, 6, @on -- NTUserName
	exec sp_trace_setevent @TraceID, 10, 7, @on -- NTDomainName
	exec sp_trace_setevent @TraceID, 10, 8, @on -- HostName
	exec sp_trace_setevent @TraceID, 10, 10, @on -- ApplicationName
	exec sp_trace_setevent @TraceID, 10, 11, @on -- LoginName
	exec sp_trace_setevent @TraceID, 10, 26, @on -- Server Name
	exec sp_trace_setevent @TraceID, 10, 30, @on -- Server State, in case of an error
	exec sp_trace_setevent @TraceID, 10, 31, @on -- Error Number
	exec sp_trace_setevent @TraceID, 10, 32, @on -- Lock mode of the lock acquired
	exec sp_trace_setevent @TraceID, 10, 34, @on -- Object Name
	exec sp_trace_setevent @TraceID, 10, 35, @on -- Database Name
	exec sp_trace_setevent @TraceID, 10, 40, @on -- DB User Name
	exec sp_trace_setevent @TraceID, 10, 46, @on -- Name of the OLE DB Provider
	exec sp_trace_setevent @TraceID, 10, 47, @on -- Name of the OLE DB Method
	/*
	@EventId = 12 : SQL:BatchCompleted
	*/
	exec sp_trace_setevent @TraceID, 12, 1, @on -- TextData
	exec sp_trace_setevent @TraceID, 12, 12, @on -- SPID
	exec sp_trace_setevent @TraceID, 12, 13, @on -- Duration
	exec sp_trace_setevent @TraceID, 12, 14, @on -- Start Time
	exec sp_trace_setevent @TraceID, 12, 15, @on -- End Time
	exec sp_trace_setevent @TraceID, 12, 16, @on -- Reads
	exec sp_trace_setevent @TraceID, 12, 17, @on -- Writes
	exec sp_trace_setevent @TraceID, 12, 48, @on -- Row Counts
	exec sp_trace_setevent @TraceID, 12, 18, @on -- CPU
	exec sp_trace_setevent @TraceID, 12, 6, @on -- NTUserName
	exec sp_trace_setevent @TraceID, 12, 7, @on -- NTDomainName
	exec sp_trace_setevent @TraceID, 12, 8, @on -- HostName
	exec sp_trace_setevent @TraceID, 12, 10, @on -- ApplicationName
	exec sp_trace_setevent @TraceID, 12, 11, @on -- LoginName
	exec sp_trace_setevent @TraceID, 12, 26, @on -- Server Name
	exec sp_trace_setevent @TraceID, 12, 30, @on -- Server State, in case of an error
	exec sp_trace_setevent @TraceID, 12, 31, @on -- Error Number
	exec sp_trace_setevent @TraceID, 12, 32, @on -- Lock mode of the lock acquired
	exec sp_trace_setevent @TraceID, 12, 34, @on -- Object Name
	exec sp_trace_setevent @TraceID, 12, 35, @on -- Database Name
	exec sp_trace_setevent @TraceID, 12, 40, @on -- DB User Name
	exec sp_trace_setevent @TraceID, 12, 46, @on -- Name of the OLE DB Provider
	exec sp_trace_setevent @TraceID, 12, 47, @on -- Name of the OLE DB Method
	/*
	@EventId = 41 : SQL:StmtCompleted
	*/
	exec sp_trace_setevent @TraceID, 41, 1, @on -- TextData
	exec sp_trace_setevent @TraceID, 41, 12, @on -- SPID
	exec sp_trace_setevent @TraceID, 41, 13, @on -- Duration
	exec sp_trace_setevent @TraceID, 41, 14, @on -- Start Time
	exec sp_trace_setevent @TraceID, 41, 15, @on -- End Time
	exec sp_trace_setevent @TraceID, 41, 16, @on -- Reads
	exec sp_trace_setevent @TraceID, 41, 17, @on -- Writes
	exec sp_trace_setevent @TraceID, 41, 48, @on -- Row Counts
	exec sp_trace_setevent @TraceID, 41, 18, @on -- CPU
	exec sp_trace_setevent @TraceID, 41, 6, @on -- NTUserName
	exec sp_trace_setevent @TraceID, 41, 7, @on -- NTDomainName
	exec sp_trace_setevent @TraceID, 41, 8, @on -- HostName
	exec sp_trace_setevent @TraceID, 41, 10, @on -- ApplicationName
	exec sp_trace_setevent @TraceID, 41, 11, @on -- LoginName
	exec sp_trace_setevent @TraceID, 41, 26, @on -- Server Name
	exec sp_trace_setevent @TraceID, 41, 30, @on -- Server State, in case of an error
	exec sp_trace_setevent @TraceID, 41, 31, @on -- Error Number
	exec sp_trace_setevent @TraceID, 41, 32, @on -- Lock mode of the lock acquired
	exec sp_trace_setevent @TraceID, 41, 34, @on -- Object Name
	exec sp_trace_setevent @TraceID, 41, 35, @on -- Database Name
	exec sp_trace_setevent @TraceID, 41, 40, @on -- DB User Name
	exec sp_trace_setevent @TraceID, 41, 46, @on -- Name of the OLE DB Provider
	exec sp_trace_setevent @TraceID, 41, 47, @on -- Name of the OLE DB Method

-- Set the Filters
	declare @intfilter int
	declare @bigintfilter bigint
	declare @filterColId int
	declare @filterColValue1 nVarchar(50)
	declare @filterColValue2 nVarchar(50)

	set @filterColId = 35 -- DatabaseName

	set @bigintfilter = @FilterDurationMS			
	exec sp_trace_setfilter @TraceID, 13, 0, 4, @bigintfilter				--- Set Duration for long running queries

-- Set the trace status to start
	exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
	select TraceID=@TraceID
	--TRUNCATE TABLE dbo.LatestTrace
	--INSERT INTO dbo.LatestTrace (TraceId) VALUES (@TraceId)

	error: 
	select ErrorCode=@rc
END

GO


