-- Ejecutar con la conexión de administrador del laboratorio en localhost,1434.
-- Genera una clave nueva para el lector dedicado de este proyecto en cada ejecución.
USE [GimnasioDB_Rendimiento];
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @lector sysname = N'lector_gym_dashboard_local';
DECLARE @sid varbinary(16) = 0xA1BB014D56294FAEAB37D04621018CA4;
DECLARE @clave nvarchar(100) = N'Gm!' + CONVERT(nvarchar(48), CRYPT_GEN_RANDOM(24), 2) + N'q7';
DECLARE @sql nvarchar(max);

IF OBJECT_ID(N'reportes.vw_Indicadores', N'V') IS NULL
    THROW 51000, N'Falta la vista reportes.vw_Indicadores en GimnasioDB_Rendimiento.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @lector AND sid <> @sid)
        THROW 51001, N'El nombre del lector ya pertenece a otra cuenta.', 1;

    IF SUSER_ID(@lector) IS NULL
        SET @sql = N'CREATE LOGIN ' + QUOTENAME(@lector) + N' WITH PASSWORD = ' + QUOTENAME(@clave, '''')
            + N', SID = 0xA1BB014D56294FAEAB37D04621018CA4, CHECK_POLICY = ON;';
    ELSE
        SET @sql = N'ALTER LOGIN ' + QUOTENAME(@lector) + N' WITH PASSWORD = ' + QUOTENAME(@clave, '''') + N';';
    EXEC sys.sp_executesql @sql;

    IF USER_ID(@lector) IS NULL
        CREATE USER [lector_gym_dashboard_local] FOR LOGIN [lector_gym_dashboard_local];
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @lector AND sid = @sid)
        THROW 51002, N'El usuario de la base está asociado a otra cuenta.', 1;

    GRANT SELECT ON SCHEMA::[reportes] TO [lector_gym_dashboard_local];
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

SELECT @lector AS Usuario, @clave AS Clave;
