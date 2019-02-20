
CREATE PROCEDURE [dbo].[DatabaseActivity]
AS
BEGIN
	
	declare  @w   table(
			spid smallint
			, status nchar( 30 )
			, loginname nchar( 128 )
			, hostname nchar( 128 )
			, blk char( 5 )
			, dbname nchar( 128 )
			, commamd nchar( 16 )
			, CPITime int
			, DiskIO int
			, LastBatch varchar(128)
			, ProgramName nchar( 128 )
			, spid2 smallint
			, request_id int
		)
		
		insert @w
		execute sp_who2;
		
		DECLARE @tbl4Query TABLE(SPID int)
		INSERT INTO @tbl4Query
		select SPID from @w 
		
		DECLARE @tblText TABLE (SPID int, EventInfo varchar(4000))
		DECLARE @SPID AS INT
		DECLARE @sqltext VARBINARY(128)
		while exists(select * from @tbl4Query)
		begin
			SET @SPID = NULL
			SELECT @SPID = MIN(SPID) FROM @tbl4Query
			IF @SPID IS NOT NULL
			BEGIN
				SET @sqltext = NULL
				SELECT @sqltext = sql_handle FROM sys.sysprocesses WHERE spid = @SPID
				
				if @sqltext IS NOT NULL
				INSERT INTO @tblText
				SELECT @SPID, CONVERT(varchar(4000), TEXT) FROM sys.dm_exec_sql_text(@sqltext)
				DELETE FROM @tbl4Query where SPID = @SPID
			END
		end
		
		select 
		r.wait_type, DiskIO/1000 as 'Duration [s]'
		--w.*
		,w.spid
		,w.[status]
		,w.loginname
		,w.hostname
		,w.blk
		,w.dbname
		,w.commamd
		,w.CPITime
		,w.DiskIO
		,w.LastBatch
		,w.ProgramName
		,q.EventInfo as Query from @w w
		left join @tblText q on w.spid = q.SPID 
		left join sys.dm_exec_requests r on r.session_id=w.spid
		-- filter start here
		order by DiskIO desc

END
GO

