CREATE PROCEDURE [dbo].[JobsStatus]
AS
BEGIN

declare @tempdate           datetime,
@tempyear           int,
@tempmonth          int,
@tempday            int,
@tempmonth2         int,
@tempdate2          nvarchar(10),
@tempdate3          int,
@currdate           int,
 @ndays int 
 set @ndays = 30
create table #tasks (
jobname      nvarchar(100) null,
id           varbinary(16) null,
owner        nvarchar(30) null,
dbname       nvarchar(256) null,
jobtype      nvarchar(60) null,
command      nvarchar(520) null,
strundate    int null,
struntime    int null,
runstatus    int null,
lastrundate  int null,
lastruntime  int null,
nextruntm    int null,
nextrundt    int null,
enabled      tinyint null,
status_desc  nvarchar (100) NULL)
set nocount on
/* In msdb tables, the job rundate and runtime, create date are stored */
/* in different format                                                 */
select @tempdate        = getdate()
select @tempyear        = YEAR(@tempdate)
select @tempmonth       = MONTH(@tempdate)
select @tempday         = DAY(@tempdate)
if @tempday < 10
begin
if @tempmonth < 10
select @tempdate2    = CAST(@tempyear  AS varchar(4)) + '0' +
CAST(@tempmonth AS char(1)) + '0' +
CAST(@tempday   AS char(1))
else
select @tempdate2    = CAST(@tempyear  AS varchar(4)) +
CAST(@tempmonth AS varchar(2)) + '0' +
CAST(@tempday   AS char(1))
end
else
begin
if @tempmonth < 10
select @tempdate2    = CAST(@tempyear  AS varchar(4)) + '0' +
CAST(@tempmonth AS char(1)) +
CAST(@tempday   AS varchar(2))
else
select @tempdate2    = CAST(@tempyear  AS varchar(4)) +
CAST(@tempmonth AS varchar(2)) +
CAST(@tempday   AS varchar(2))
end
select @currdate        = @tempdate2
-- print @currdate
-- get the current date - @ndays in the format yyyymmdd
select @tempdate        = getdate() - @ndays
select @tempyear        = YEAR(@tempdate)
select @tempmonth       = MONTH(@tempdate)
select @tempday         = DAY(@tempdate)
if @tempday < 10
begin
if @tempmonth < 10
select @tempdate2    = CAST(@tempyear  AS varchar(4)) + '0' +
CAST(@tempmonth AS char(1)) + '0' +
CAST(@tempday   AS char(1))
else
select @tempdate2    = CAST(@tempyear  AS varchar(4)) +
CAST(@tempmonth AS varchar(2)) + '0' +
CAST(@tempday   AS char(1))
end
else
begin
if @tempmonth < 10
select @tempdate2    = CAST(@tempyear  AS varchar(4)) + '0' +
CAST(@tempmonth AS char(1)) +
CAST(@tempday   AS varchar(2))
else
select @tempdate2    = CAST(@tempyear  AS varchar(4)) +
CAST(@tempmonth AS varchar(2)) +
CAST(@tempday   AS varchar(2))
end
select @tempdate3       = @tempdate2
--  print @tempdate3
insert into #tasks (jobname, id, owner, dbname, jobtype, command,
strundate, struntime,lastrundate, lastruntime,
nextruntm, nextrundt, enabled)
select convert(nvarchar(100),t.name),
convert(varbinary,t.job_id),
convert(nvarchar(30),suser_sname(t.owner_sid)),
database_name,
convert(nvarchar(60),subsystem),
convert(nvarchar(520), command),
r.active_start_date,
r.active_start_time,
last_run_date,
last_run_time,
q.next_run_time,
q.next_run_date,
t.enabled
from  msdb..sysjobs t, msdb..sysjobsteps s,msdb..sysschedules r,
msdb..sysjobschedules q
where t.job_id = s.job_id
and  t.job_id = q.job_id
and  r.schedule_id = q.schedule_id
and  s.step_id = 1
and  (t.date_created >= @tempdate
or  (last_run_date >= @tempdate3 and
last_run_date <= @currdate))
order by database_name, subsystem
/****************************************************************/
/* update the run_status of the jobs and also job description   */
/*   for all the jobs ran atleast once in sql server            */
/****************************************************************/
/* In sysjobhistory, the rundate and runtime for stepid = 0     */
/* contains the rundate and runtime for stepid = 1  and select  */
/* statement for the joblist selection selects the lastrundate  */
/* and lastruntime for the step_id = 1                          */
update #tasks
set #tasks.runstatus = h.run_status,
#tasks.status_desc =
case
when h.run_status = 0 THEN 'Failed'
when h.run_status = 1 THEN 'Succeeded'
when h.run_status = 2 THEN 'Retry'
when h.run_status = 3 THEN 'Canceled'
when h.run_status = 4 THEN 'In progress'
ELSE 'unknown'
end
from msdb..sysjobhistory h
where h.job_id = #tasks.id
and (h.run_time = #tasks.lastruntime or
h.run_time = (#tasks.lastruntime - 1))
and h.run_date = #tasks.lastrundate
and h.step_id  = 0
--and h.step_id  = 1
/******************************************************************/
/* update the status description of the jobs which didn't run yet */
/******************************************************************/
update #tasks
set status_desc = 'Did not run'
where runstatus is NULL
select jobname, status_desc,owner, dbname, jobtype, command, runstatus, 
lastrundate , lastruntime,
nextrundt,nextruntm,  enabled
from #tasks where enabled <> 0
drop table #tasks
set nocount off

END 
