﻿	SELECT c.name AS ColumnName, t.name as ColumnType, 
	CStatement = '        public ' + case t.name
		when 'bigint' then 'long'
		when 'binary' then 'bool'
		when 'bit' then 'bool'
		when 'char' then 'char'
		when 'date' then 'DateTime'
		when 'datetime' then 'DateTime'
		when 'datetime2' then 'DateTime'
		when 'datetimeoffset' then 'decimal'
		when 'decimal' then 'decimal'
		when 'float' then 'decimal'
		when 'int' then 'int'
		when 'money' then 'decimal'
		when 'nchar' then 'char'
		when 'numeric' then 'decimal'
		when 'nvarchar' then 'string'
		when 'real' then 'decimal'
		when 'smalldatetime' then 'DateTime'
		when 'smallint' then 'short'
		when 'smallmoney' then 'decimal'
		when 'time' then 'DateTime'
		when 'timestamp' then 'DateTime'
		when 'tinyint' then 'short'
		when 'uniqueidentifier' then 'Guid'
		when 'varchar' then 'string'
		when 'xml' then 'string'
		else 'N/A' end +
	' ' + c.name + ' { get; set; }', 
	JsStatement = c.name + ' : ' +case t.name
		when 'bigint' then '0'
		when 'binary' then 'false'
		when 'bit' then 'false'
		when 'char' then '""'
		when 'date' then '""'
		when 'datetime' then '""'
		when 'datetime2' then '""'
		when 'datetimeoffset' then '""'
		when 'decimal' then '0'
		when 'float' then '0'
		when 'int' then '0'
		when 'money' then '0'
		when 'nchar' then '""'
		when 'numeric' then '0'
		when 'nvarchar' then '""'
		when 'real' then '0'
		when 'smalldatetime' then '""'
		when 'smallint' then '0'
		when 'smallmoney' then '0'
		when 'time' then '""'
		when 'timestamp' then '""'
		when 'tinyint' then '0'
		when 'uniqueidentifier' then '""'
		when 'varchar' then '""'
		when 'xml' then '""'
		else 'N/A' end
		 + ','
	FROM syscolumns c, systypes t
	WHERE c.xusertype = t.xusertype
	and id = (SELECT id FROM sysobjects WHERE [Name] = 'NotificationTemplate')
