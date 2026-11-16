-- Estrategia Full/Diff/Log. El contenedor usa un volumen persistente para backups.
USE GimnasioDB;
GO
CREATE OR ALTER PROCEDURE mantenimiento.usp_RealizarBackup
 @Tipo NVARCHAR(10)
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Ahora DATETIME2(0)=SYSDATETIME();
 DECLARE @Sufijo VARCHAR(20) = CONVERT(VARCHAR(8),@Ahora,112)+N'_'+REPLACE(CONVERT(VARCHAR(8),@Ahora,108),N':',N'');
 DECLARE @Ruta NVARCHAR(4000);
 IF @Tipo NOT IN (N'FULL',N'DIFF',N'LOG') OR @Tipo IS NULL
   THROW 50120,N'Tipo de backup: FULL, DIFF o LOG.',1;
 SET @Ruta=N'/var/opt/mssql/backup/GimnasioDB_'+@Tipo+N'_'+@Sufijo+
           CASE WHEN @Tipo=N'LOG' THEN N'.trn' ELSE N'.bak' END;
 IF @Tipo=N'FULL'
   BACKUP DATABASE GimnasioDB TO DISK=@Ruta WITH INIT,COMPRESSION,CHECKSUM,STATS=10;
 ELSE IF @Tipo=N'DIFF'
   BACKUP DATABASE GimnasioDB TO DISK=@Ruta WITH DIFFERENTIAL,INIT,COMPRESSION,CHECKSUM,STATS=10;
 ELSE
   BACKUP LOG GimnasioDB TO DISK=@Ruta WITH INIT,COMPRESSION,CHECKSUM,STATS=10;
 SELECT @Tipo AS TipoBackup,@Ruta AS Archivo, @Ahora AS MomentoServidor;
END;
GO
-- Primer full inicia cadena de restauración para base en recuperación FULL.
-- Ejecutar desde la instalación; al repetir puede crear otro backup con nueva fecha.
EXEC mantenimiento.usp_RealizarBackup @Tipo=N'FULL';
GO
