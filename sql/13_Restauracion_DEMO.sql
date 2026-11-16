/* RESTAURACIÓN DE PRUEBA (COPIA, NO TOCA GimnasioDB).
   1) Verificar el nombre exacto de un archivo FULL en sql/12_Pruebas.sql.
   2) Sustituir aquí <ARCHIVO_FULL_REAL> por el nombre listado; por seguridad
      el script no ejecuta RESTORE automáticamente con una ruta ficticia.
   3) RESTORE FILELISTONLY para verificar los nombres lógicos; normalmente
      GimnasioDB y GimnasioDB_log al crear la base de forma predeterminada.
   4) Confirmar rutas lógicas antes de ejecutar RESTORE DATABASE en SSMS.
*/
USE master;
GO
-- EJEMPLO: sustituir ruta y descomentar. No ejecutar sin verificar archivo.
-- RESTORE FILELISTONLY FROM DISK=N'/var/opt/mssql/backup/<ARCHIVO_FULL_REAL>.bak';
-- RESTORE VERIFYONLY FROM DISK=N'/var/opt/mssql/backup/<ARCHIVO_FULL_REAL>.bak' WITH CHECKSUM;
-- RESTORE DATABASE GimnasioDB_RestoreTest
-- FROM DISK=N'/var/opt/mssql/backup/<ARCHIVO_FULL_REAL>.bak'
-- WITH MOVE N'GimnasioDB' TO N'/var/opt/mssql/data/GimnasioDB_RestoreTest.mdf',
--      MOVE N'GimnasioDB_log' TO N'/var/opt/mssql/data/GimnasioDB_RestoreTest_log.ldf',
--      REPLACE,RECOVERY,STATS=10;
-- SELECT DB_NAME(database_id),state_desc FROM sys.databases WHERE name=N'GimnasioDB_RestoreTest';
GO
