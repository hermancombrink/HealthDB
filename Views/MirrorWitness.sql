CREATE VIEW [dbo].[MirrorWitness]
AS
SELECT        DB_NAME(database_id) AS 'DatabaseName', mirroring_role_desc AS 'DatabaseRole', mirroring_role_sequence AS 'FailoverCount', mirroring_partner_instance AS 'MirroringInstance', mirroring_state_desc AS 'MirroringState', 
                         mirroring_connection_timeout AS 'MirroringConnectionTimeoutInSeconds', mirroring_witness_name AS 'WitnessInstance', mirroring_witness_state_desc AS 'WitnessState'
FROM            master.sys.database_mirroring
WHERE        (mirroring_guid IS NOT NULL)
GO
