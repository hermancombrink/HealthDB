CREATE PROCEDURE [dbo].[ReplicationPublisherCheck]
AS
DECLARE @Detail CHAR(1)
 SET @Detail = 'Y'
 CREATE TABLE #tmp_replcationInfo (
 PublisherDB VARCHAR(128),
 PublisherName VARCHAR(128),
 TableName VARCHAR(128),
 SubscriberServerName VARCHAR(128),
 )
 EXEC sp_msforeachdb
 'use ?;
 IF DATABASEPROPERTYEX ( db_name() , ''IsPublished'' ) = 1
 insert into #tmp_replcationInfo
 select
 db_name() PublisherDB
 , sp.name as PublisherName
 , sa.name as TableName
 , UPPER(srv.srvname) as SubscriberServerName
 from dbo.syspublications sp
 join dbo.sysarticles sa on sp.pubid = sa.pubid
 join dbo.syssubscriptions s on sa.artid = s.artid
 join master.dbo.sysservers srv on s.srvid = srv.srvid
 '
 IF @Detail = 'Y'
 SELECT * FROM #tmp_replcationInfo
 ELSE
 SELECT DISTINCT
 PublisherDB
 ,PublisherName
 ,SubscriberServerName
 FROM #tmp_replcationInfo
 DROP TABLE #tmp_replcationInfo
