CREATE FUNCTION [dbo].[GetIndexWorkFactor]
(
    -- Add the parameters for the function here
    @nFragPercentage float, 
    @nFragCount int, 
    @nPageCount int,
    @nPrevFragPercentage float,
    @nPrevFragCount int,
    @nPrevPageCount int,
    @nPrevCompletedAt datetime
)
RETURNS decimal(18,2)
AS
BEGIN
    -- Declare the return variable here
    DECLARE @factor decimal(18,2)
    DECLARE @ageFactor float = 1, @baseFactor float = 1

    -- exponentially increase importance with age
    IF(@nPrevCompletedAt is not null)
     SET @ageFactor = 1 + (CAST(DATEDIFF(day, @nPrevCompletedAt, GETDATE()) as float) / 100)

    SET @baseFactor = CEILING(LOG10(@nPageCount)) -- index size as base value
     * (1 + 
     (
      (
       -- with current fragmentation
       @nFragPercentage / 100) +
       -- with fragmentation volatility 
       CASE WHEN @nFragPercentage > @nPrevFragPercentage THEN (@nFragPercentage - @nPrevFragPercentage) / 100 ELSE  0.00 END
      )
     )

    SET @factor = POWER(@baseFactor, @ageFactor)

    RETURN @factor

END

GO
