CREATE FUNCTION [dbo].[Split](
          @delimited NVARCHAR(4000),
          @delimiter CHAR(1)
        ) RETURNS @t TABLE (val NVARCHAR(500))
        AS
        BEGIN
          DECLARE @xml XML
          SET @xml = N'<t>' + REPLACE(@delimited,@delimiter,'</t><t>') + '</t>'

          INSERT INTO @t(val)
          SELECT  r.value('.','varchar(MAX)') as item
          FROM  @xml.nodes('/t') as records(r)
          RETURN
        END

GO
