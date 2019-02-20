CREATE PROCEDURE [dbo].[DatabaseSizeStatus]
AS
BEGIN

------------------------------Data file size----------------------------

create table #dbsize
(Dbname sysname, Database_id int, dbstatus varchar(50),Recovery_Model varchar(40) default ('NA'), file_Size_MB decimal(30,2)default (0),Space_Used_MB decimal(30,2)default (0),Free_Space_MB decimal(30,2) default (0))
 
insert into #dbsize(Dbname,Database_id,dbstatus,Recovery_Model,file_Size_MB,Space_Used_MB,Free_Space_MB)
exec sp_msforeachdb
'use [?];
  select DB_NAME() AS DbName, DB_ID() as Database_id,
    CONVERT(varchar(20),DatabasePropertyEx(''?'',''Status'')) , 
    CONVERT(varchar(20),DatabasePropertyEx(''?'',''Recovery'')), 
sum(size)/128.0 AS File_Size_MB,
sum(CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT))/128.0 as Space_Used_MB,
SUM( size)/128.0 - sum(CAST(FILEPROPERTY(name,''SpaceUsed'') AS INT))/128.0 AS Free_Space_MB 
from sys.database_files  where type=0 group by type'
 
 
-------------------log size--------------------------------------
create table #logsize
(Dbname sysname, Log_File_Size_MB decimal(38,2)default (0),log_Space_Used_MB decimal(30,2)default (0),log_Free_Space_MB decimal(30,2)default (0))
 
insert into #logsize(Dbname,Log_File_Size_MB,log_Space_Used_MB,log_Free_Space_MB)
exec sp_msforeachdb
'use [?];
  select DB_NAME() AS DbName,
sum(size)/128.0 AS Log_File_Size_MB,
sum(CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT))/128.0 as log_Space_Used_MB,
SUM( size)/128.0 - sum(CAST(FILEPROPERTY(name,''SpaceUsed'') AS INT))/128.0 AS log_Free_Space_MB 
from sys.database_files  where type=1 group by type'
 
--------------------------------database free size
create table #dbfreesize
(name sysname,
database_size varchar(50),
Freespace varchar(50)default (0.00))
 
insert into #dbfreesize(name,database_size,Freespace)
exec sp_msforeachdb
'use [?];SELECT database_name = db_name()
    ,database_size = ltrim(str((convert(DECIMAL(15, 2), dbsize) + convert(DECIMAL(15, 2), logsize)) * 8192 / 1048576, 15, 2) + ''MB'')
    ,''unallocated space'' = ltrim(str((
                CASE 
                    WHEN dbsize >= reservedpages
                        THEN (convert(DECIMAL(15, 2), dbsize) - convert(DECIMAL(15, 2), reservedpages)) * 8192 / 1048576
                    ELSE 0
                    END
                ), 15, 2) + '' MB'')
FROM (
    SELECT dbsize = sum(convert(BIGINT, CASE 
                    WHEN type = 0
                        THEN size
                    ELSE 0
                    END))
        ,logsize = sum(convert(BIGINT, CASE 
                    WHEN type <> 0
                        THEN size
                    ELSE 0
                    END))
    FROM sys.database_files
) AS files
,(
    SELECT reservedpages = sum(a.total_pages)
        ,usedpages = sum(a.used_pages)
        ,pages = sum(CASE 
                WHEN it.internal_type IN (
                        202
                        ,204
                        ,211
                        ,212
                        ,213
                        ,214
                        ,215
                        ,216
                        )
                    THEN 0
                WHEN a.type <> 1
                    THEN a.used_pages
                WHEN p.index_id < 2
                    THEN a.data_pages
                ELSE 0
                END)
    FROM sys.partitions p
    INNER JOIN sys.allocation_units a
        ON p.partition_id = a.container_id
    LEFT JOIN sys.internal_tables it
        ON p.object_id = it.object_id
) AS partitions'
-----------------------------------
create table #alldbstate 
(dbname sysname,
DBstatus varchar(55),
R_model Varchar(30))
  
--select * from sys.master_files
 
insert into #alldbstate (dbname,DBstatus,R_model)
select name,CONVERT(varchar(20),DATABASEPROPERTYEX(name,'status')),recovery_model_desc from sys.databases
--select * from #dbsize
 
insert into #dbsize(Dbname,dbstatus,Recovery_Model)
select dbname,dbstatus,R_model from #alldbstate where DBstatus <> 'online'
 
insert into #logsize(Dbname)
select dbname from #alldbstate where DBstatus <> 'online'
 
insert into #dbfreesize(name)
select dbname from #alldbstate where DBstatus <> 'online'
 
--variables to hold each 'iteration'
declare @query varchar(100)
declare @dbname sysname
declare @vlfs int

--table variable used to 'loop' over databases
declare @databases table (dbname sysname, database_id int)
insert into @databases
--only choose online databases
select name, database_id from sys.databases where state = 0


-----------------vlf count

--table variable to hold results
declare @vlfcounts table
	(
	database_id int,
	dbname sysname,
	vlfcount int)

-- Find SQL Version
	if object_id( N'tempdb..#v', N'U' ) is not null 
		drop table #v;
	
	create table #v(
		[Index] int
		, Name varchar( 30 )
		, Internal_Value bigint
		, Character_Value varchar( 100 )
		)
	
	insert #v
	execute master..xp_msver 'ProductVersion'
	;
	
	declare @Version varchar( 100 )
	select @Version = Character_Value
	from #v
	where
		Name = 'ProductVersion'
	;
	
	set @Version = left( @Version, charindex( '.', @Version, charindex( '.', @Version ) + 1 ) - 1 )
	declare @VersionNumber decimal( 9, 5 )
	set @VersionNumber = convert( decimal( 9, 5 ), @Version )


	if object_id( N'tempdb..#dbccloginfo', N'U' ) is not null 
		drop table #dbccloginfo;

--table varioable to capture DBCC loginfo output
CREATE TABLE #dbccloginfo 
(
	[col000] int,
	fileid tinyint,
	file_size bigint,
	start_offset bigint,
	fseqno int,
	[status] tinyint,
	parity tinyint,
	create_lsn numeric(25,0)
)

	IF @VersionNumber < 11.0
	alter table #dbccloginfo 
	drop column [col000]

declare @dbid as int
while exists(select top 1 dbname from @databases)
begin

	set @dbname = (select top 1 dbname from @databases)
	set @dbid = (select top 1 database_id from @databases)
	set @query = 'dbcc loginfo (' + '''' + @dbname + ''') '

	insert into #dbccloginfo
	exec (@query)

	set @vlfs = @@rowcount

	insert @vlfcounts
	values(@dbid, @dbname, @vlfs)

	delete from @databases where dbname = @dbname

end
------------end of vlf count
 
select 
 
d.Dbname,
vlf.vlfcount, 
--CAST ((SELECT COUNT(*) FROM msdb.dbo.log_shipping_monitor_primary ls WHERE ls.primary_database = d.Dbname) as bit) as WithLogShipping,
d.dbstatus,
d.Recovery_Model,
(file_size_mb + log_file_size_mb) as DBsize,
d.file_Size_MB,
d.file_Size_MB * 1024 as file_Size_KB,
d.Space_Used_MB,
d.Free_Space_MB,
l.Log_File_Size_MB,log_Space_Used_MB,l.log_Free_Space_MB,fs.Freespace as DB_Freespace
, case when file_size_mb > 0.0 then round(100*cast(replace(free_space_mb,'mb','') as float)/cast(replace(file_size_mb,'mb','') as float),2) end [DBFreeSpace %]
from #dbsize d 
join #logsize l 
on d.Dbname=l.Dbname join #dbfreesize fs 
on d.Dbname=fs.name
left join @vlfcounts vlf on vlf.database_id = d.database_id
order by [DBFreeSpace %],Dbname

END
GO


