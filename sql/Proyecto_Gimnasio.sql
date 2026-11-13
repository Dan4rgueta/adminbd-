USE master;
GO

IF DB_ID(N'GimnasioDB') IS NULL
BEGIN
    CREATE DATABASE GimnasioDB;
END;
GO

USE GimnasioDB;
GO

SELECT DB_NAME() AS BaseDeDatosActual;

USE GimnasioDB;
GO

IF SCHEMA_ID(N'operacion') IS NULL
    EXEC(N'CREATE SCHEMA operacion AUTHORIZATION dbo');
GO

IF SCHEMA_ID(N'finanzas') IS NULL
    EXEC(N'CREATE SCHEMA finanzas AUTHORIZATION dbo');
GO

SELECT name AS Esquema
FROM sys.schemas
WHERE name IN (N'operacion', N'finanzas')
ORDER BY name;