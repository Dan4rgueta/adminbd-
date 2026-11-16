USE master;
GO
IF DB_ID(N'GimnasioDB') IS NULL
    CREATE DATABASE GimnasioDB;
GO
ALTER DATABASE GimnasioDB SET RECOVERY FULL;
GO
SELECT name, recovery_model_desc, state_desc
FROM sys.databases WHERE name = N'GimnasioDB';
GO
