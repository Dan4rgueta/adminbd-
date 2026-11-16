/* Crear lector SQL sólo después de definir la contraseña local.
   El script ABORTA si se deja la clave de muestra */
USE master;
GO
DECLARE @Clave NVARCHAR(128)=N'CAMBIAR_POR_CLAVE_PERSONAL_FUERTE_2026!';
IF @Clave LIKE N'CAMBIAR_%' THROW 51000,N'Debe sustituir la clave de ejemplo antes de crear el login.',1;
IF NOT EXISTS(SELECT 1 FROM sys.sql_logins WHERE name=N'lector_powerbi')
BEGIN
 DECLARE @Comando NVARCHAR(MAX)=N'CREATE LOGIN [lector_powerbi] WITH PASSWORD=N'''+
 REPLACE(@Clave,N'''',N'''''')+N''',CHECK_POLICY=ON;';
 EXEC sys.sp_executesql @Comando;
END;
GO
USE GimnasioDB;
GO
IF DATABASE_PRINCIPAL_ID(N'lector_powerbi') IS NULL
 CREATE USER lector_powerbi FOR LOGIN lector_powerbi;
IF IS_ROLEMEMBER(N'rol_analista',N'lector_powerbi')=0
 ALTER ROLE rol_analista ADD MEMBER lector_powerbi;
GO
SELECT name FROM sys.database_principals WHERE name=N'lector_powerbi';
GO
