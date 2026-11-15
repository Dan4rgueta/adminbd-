-- Checklist SQL: integridad, consultas, seguridad, auditoría, backups y jobs.
USE GimnasioDB;
GO
SELECT N'TABLAS PRINCIPALES' AS Area,COUNT(*) AS Valor
FROM sys.tables WHERE (SCHEMA_NAME(schema_id)=N'operacion' AND name IN(N'Socio',N'Entrenador',N'Clase',N'Sesion',N'Reserva'))
OR (SCHEMA_NAME(schema_id)=N'finanzas' AND name=N'Pago');
SELECT N'RESERVAS ACTIVAS' AS Area,COUNT(*) Valor FROM operacion.Reserva WHERE FechaCancelacion IS NULL;
SELECT N'INGRESOS' AS Area,COALESCE(SUM(Monto),0) Valor FROM finanzas.Pago;
GO
-- Integridad: no superar cupos.
SELECT s.SesionID,s.CupoMaximo,COUNT(r.ReservaID) ReservasActivas
FROM operacion.Sesion s LEFT JOIN operacion.Reserva r
ON r.SesionID=s.SesionID AND r.FechaCancelacion IS NULL
GROUP BY s.SesionID,s.CupoMaximo HAVING COUNT(r.ReservaID)>s.CupoMaximo;
GO
-- Comprobar que la suma de cada vista coincide con tablas transaccionales.
SELECT N'RESERVAS' Metrica,
 (SELECT COALESCE(SUM(ReservasActivas),0) FROM reportes.vw_RankingClases) ValorVista,
 (SELECT COUNT_BIG(*) FROM operacion.Reserva WHERE FechaCancelacion IS NULL) ValorTabla;
SELECT N'PAGOS' Metrica,
 (SELECT COALESCE(SUM(Ingresos),0) FROM reportes.vw_IngresosDiarios) ValorVista,
 (SELECT COALESCE(SUM(Monto),0) FROM finanzas.Pago) ValorTabla;
GO
-- Prueba de permiso permitido y denegado. Error 229 esperado para recepción.
EXECUTE AS USER=N'usuario_finanzas';
SELECT TOP 1 USER_NAME() AS UsuarioConAcceso,Monto FROM finanzas.Pago;
REVERT;
GO
EXECUTE AS USER=N'usuario_recepcion';
BEGIN TRY
 SELECT TOP 1 Monto FROM finanzas.Pago;
 SELECT N'FALLO: acceso indebido a pagos' AS Prueba;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()=229 SELECT N'OK: acceso a pagos denegado a recepción' AS Prueba,ERROR_NUMBER() Codigo;
 ELSE BEGIN REVERT; THROW; END;
END CATCH;
REVERT;
GO
-- Auditoría: después de las pruebas anteriores, registrar logs con posible retardo de escritura.
WAITFOR DELAY '00:00:02';
SELECT TOP(20) event_time,database_principal_name,action_id,succeeded,object_name,statement
FROM sys.fn_get_audit_file(N'/var/opt/mssql/log/Auditoria_Gimnasio_*.sqlaudit',DEFAULT,DEFAULT)
WHERE database_name=N'GimnasioDB' AND schema_name=N'finanzas' AND object_name=N'Pago'
ORDER BY event_time DESC;
GO
USE msdb;
GO
SELECT TOP(20) bs.database_name,bs.type AS Tipo,
 bs.backup_start_date,bs.backup_finish_date,bmf.physical_device_name
FROM dbo.backupset bs
JOIN dbo.backupmediafamily bmf ON bmf.media_set_id=bs.media_set_id
WHERE bs.database_name=N'GimnasioDB' ORDER BY bs.backup_finish_date DESC;
SELECT j.name AS Trabajo,h.run_date,h.run_time,h.run_status,h.message
FROM dbo.sysjobs j
LEFT JOIN dbo.sysjobhistory h ON h.job_id=j.job_id AND h.step_id=0
WHERE j.name LIKE N'GimnasioDB - %' ORDER BY Trabajo,h.run_date DESC,h.run_time DESC;
GO
