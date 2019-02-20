CREATE VIEW [dbo].[JobsLastRun]
AS
SELECT        TOP (100) PERCENT j.name, RIGHT(sjh.last_run_date / 10000, 4) + '/' + RIGHT(sjh.last_run_date / 100, 2) + '/' + RIGHT(sjh.last_run_date, 2) AS run_date, RIGHT('00' + RIGHT(sjh.last_run_time / 10000, 2), 2) 
                         + ':' + RIGHT(sjh.last_run_time / 100, 2) + ':' + RIGHT(sjh.last_run_time, 2) AS run_time, CONVERT(char(8), DATEADD(second, sjh.last_run_duration, ''), 114) AS duration
FROM            msdb.dbo.sysjobservers AS sjh INNER JOIN
                         msdb.dbo.sysjobs_view AS sj ON sj.job_id = sjh.job_id INNER JOIN
                         msdb.dbo.sysjobs AS j ON j.job_id = sjh.job_id
WHERE        (sj.enabled = 1)
ORDER BY j.name
GO
