
CREATE TABLE [dbo].[IndexDefrag](
    [IndexDefragID] [bigint] IDENTITY(1,1) NOT NULL,
    [IndexDefragDatabase] [nvarchar](150) NOT NULL,
    [IndexDefragTableName] [nvarchar](150) NOT NULL,
    [IndexDefragIndexName] [nvarchar](150) NOT NULL,
    [IndexDefragFragPercentage] [float] NOT NULL,
    [IndexDefragFragCount] [int] NOT NULL,
    [IndexDefragPageCount] [int] NOT NULL,
    [IndexDefragIsPending] [bit] NOT NULL,
    [IndexDefragIsCompleted] [bit] NOT NULL,
    [IndexDefragCreatedAt] [datetime] NULL,
    [IndexDefragStartedAt] [datetime] NULL,
    [IndexDefragCompletedAt] [datetime] NULL,
    [IndexDefragBatchGuid] [uniqueidentifier] NULL,
    [IndexDefragInSeconds]  AS (datediff(second,[IndexDefragStartedAt],[IndexDefragCompletedAt])),
 CONSTRAINT [PK_IndexDefrag] PRIMARY KEY CLUSTERED 
(
    [IndexDefragID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[IndexDefrag] ADD  CONSTRAINT [DF_IndexDefrag_IndexDefragCreatedAt]  DEFAULT (getdate()) FOR [IndexDefragCreatedAt]
GO

/****** Object:  Index [IX_IndexDefrag_CreatedAt]    Script Date: 19/10/2018 2:03:36 PM ******/
CREATE NONCLUSTERED INDEX [IX_IndexDefrag_CreatedAt] ON [dbo].[IndexDefrag]
(
	[IndexDefragCreatedAt] DESC,
	[IndexDefragIsPending] ASC
)
INCLUDE ( 	[IndexDefragID],
	[IndexDefragDatabase],
	[IndexDefragTableName],
	[IndexDefragIndexName],
	[IndexDefragFragPercentage],
	[IndexDefragFragCount],
	[IndexDefragPageCount]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
