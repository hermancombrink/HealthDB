CREATE TABLE #Temp_Regression
(
ID integer IDENTITY(1,1),
ServerName Varchar(100),
DatabaseName Varchar(100),
Backup_Size_MB decimal(12,2),
ReportDate DateTime,
Trend Decimal(38,10)
)

DECLARE @StartDate datetime, @EndDate datetime
SET @StartDate = GETDATE()
SET @EndDate = DATEADD(DAY, 90, GETDATE())

INSERT into #Temp_Regression
SELECT  
    CONVERT(Varchar(100), SERVERPROPERTY('Servername')) AS ServerName, 
    msdb.dbo.backupset.database_name,  
	avg(cast(backup_size/1024/1024 as decimal(12,2))) as backup_size_MB,
    convert(datetime,cast(msdb.dbo.backupset.backup_start_date as varchar(11)),101) as ReportDate
	, Trend = CONVERT(DECIMAL(38, 10), NULL)

    FROM   msdb.dbo.backupmediafamily  
    INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id =    msdb.dbo.backupset.media_set_id 
    WHERE  (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 40)  
	and msdb..backupset.type = 'D'
	--and physical_device_name like 'https%'
	and backup_start_date between @StartDate and @EndDate
	group by database_name, convert(datetime,cast(msdb.dbo.backupset.backup_start_date as varchar(11)),101)
    ORDER BY  
    msdb.dbo.backupset.database_name
    
/* declare all variables*/ 

--DECLARE @sample_size INT; 
DECLARE @intercept DECIMAL(38, 10); 
DECLARE @slope DECIMAL(38, 10); DECLARE @sumX DECIMAL(38, 10); DECLARE @sumY DECIMAL(38, 10); DECLARE @sumXX DECIMAL(38, 10); DECLARE @sumYY DECIMAL(38, 10); 
DECLARE @sumXY DECIMAL(38, 10);
/* calculate sample size and the different sums*/ 
DECLARE @sample_size as TABLE
(
	ServerName Varchar(100),
	DatabaseName Varchar(100),
	Sample_Size int,
	SumX int,
	SumY Decimal(12,2),
	SumXX int,
	SumYY Decimal(24,2),
	SumXY Decimal(12,2),
	Slope Decimal(12,2),
	Intercept Decimal(12,2)
)
INSERT INTO @sample_size
SELECT ServerName, DatabaseName, sample_size = COUNT(*), sumX = SUM(ID), sumY = SUM(Backup_Size_MB), sumXX = SUM(ID * ID), 
       sumYY = SUM(Backup_Size_MB * Backup_Size_MB), sumXY = SUM(ID * Backup_Size_MB), NULL, NULL
FROM            #Temp_Regression
Group by ServerName, DatabaseName

/* calculate the slope and intercept*/

UPDATE @sample_size
	SET slope = CASE WHEN sample_size = 1 THEN 0 ELSE (sample_size * sumXY - sumX * sumY) / (sample_size * sumXX - POWER(sumX, 2)) END
UPDATE @sample_size
	SET intercept = (sumY - (slope * sumX)) / sample_size

--select * FROM @sample_size

/* calculate trend line*/ 
UPDATE #Temp_Regression
	SET Trend = (slope * ID) + intercept 
FROM #Temp_Regression T
INNER JOIN @sample_size S ON T.ServerName = S.ServerName and T.DatabaseName = S.DatabaseName	

--SELECT * FROM #Temp_Regression;

CREATE TABLE #Predict_Period
(
ID integer IDENTITY(1,1),
ServerName Varchar(100),
DatabaseName Varchar(100),
ReportDate DateTime
)

INSERT INTO #Predict_Period
SELECT ServerName, DatabaseName, ReportDate FROM #Temp_Regression ORDER BY ID ASC;

declare @dt datetime, @dtEnd datetime
set @dt = @EndDate
set @dtEnd = dateadd(day, 30, @dt)

INSERT INTO #Predict_Period
select ServerName, DatabaseName, convert(datetime,cast(dateadd(day, number, @dt) as varchar(11)),101)
from 
    (select distinct number from master.dbo.spt_values
     where name is null
    ) n
    cross join
    (
    SELECT distinct ServerName, DatabaseName  FROM #Temp_Regression
    ) t --on n.reportdate = t.reportdate
where dateadd(day, number, @dt) < @dtEnd
 
SELECT  p.ID, p.ServerName, p.DatabaseName, p.ReportDate,
            Backup_Size_MB, Trend, 
            Forecast = CASE 
            WHEN Trend IS NOT NULL AND p.ID <> 
                  (SELECT MAX(ID)
                FROM            #Temp_Regression r1 WHERE r.ServerName = r1.ServerName and r.DatabaseName = r1.DatabaseName ) THEN NULL /* value as the trendline (instead of NULL). This prevents a gap in the line charts in SSRS.*/ 
                WHEN Trend IS NOT NULL AND p.ID = r.ID THEN Trend
            --(SELECT        MAX(ID)
            --    FROM            #Temp_Regression r1 WHERE r.ServerName = r1.ServerName and r.DatabaseName = r1.DatabaseName) THEN Trend /* a forecast for January as well. Only for the last 3 months of the year in this example.*/ 
                WHEN Trend IS NULL AND r.ID IS NULL
            --(SELECT        MAX(ID)
            --    FROM            #Temp_Regression r1 WHERE r.ServerName = r1.ServerName and r.DatabaseName = r1.DatabaseName) 
                THEN (slope * (p.ID % 100)) + intercept ELSE NULL END
FROM  #Predict_Period p LEFT JOIN
        #Temp_Regression r ON p.ServerName = r.ServerName and p.DatabaseName = r.DatabaseName and p.ReportDate = r.ReportDate
        left JOIN @sample_size s ON p.ServerName = S.ServerName and p.DatabaseName = S.DatabaseName
order by p.ServerName, p.DatabaseName, p.ReportDate 
/* clean-up*/ 
		
	DROP TABLE #Temp_Regression;
	DROP TABLE #Predict_Period;
