-- SQL Server Audit (en Docker/Linux). Exige sysadmin y ruta con permisos.
USE master;
GO
IF NOT EXISTS(SELECT 1 FROM sys.server_audits WHERE name=N'Auditoria_Gimnasio')
BEGIN
 CREATE SERVER AUDIT Auditoria_Gimnasio TO FILE
 (FILEPATH=N'/var/opt/mssql/log/',MAXSIZE=20 MB,MAX_ROLLOVER_FILES=10)
 WITH (QUEUE_DELAY=1000,ON_FAILURE=CONTINUE);
END;
GO
ALTER SERVER AUDIT Auditoria_Gimnasio WITH(STATE=ON);
GO
USE GimnasioDB;
GO
IF NOT EXISTS(SELECT 1 FROM sys.database_audit_specifications WHERE name=N'Auditoria_Pagos')
BEGIN
 CREATE DATABASE AUDIT SPECIFICATION Auditoria_Pagos
 FOR SERVER AUDIT Auditoria_Gimnasio
  ADD (SELECT ON OBJECT::finanzas.Pago BY public),
  ADD (INSERT ON OBJECT::finanzas.Pago BY public),
  ADD (UPDATE ON OBJECT::finanzas.Pago BY public),
  ADD (DELETE ON OBJECT::finanzas.Pago BY public),
  ADD (EXECUTE ON OBJECT::finanzas.RegistrarPago BY public);
END;
GO
ALTER DATABASE AUDIT SPECIFICATION Auditoria_Pagos WITH(STATE=ON);
GO
SELECT name,is_state_enabled FROM sys.database_audit_specifications
WHERE name=N'Auditoria_Pagos';
GO
