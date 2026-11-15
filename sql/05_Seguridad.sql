-- Roles funcionales: mínimo privilegio.

USE GimnasioDB;
GO
IF DATABASE_PRINCIPAL_ID(N'rol_recepcion') IS NULL CREATE ROLE rol_recepcion AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'rol_finanzas') IS NULL CREATE ROLE rol_finanzas AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'rol_entrenador') IS NULL CREATE ROLE rol_entrenador AUTHORIZATION dbo;
IF DATABASE_PRINCIPAL_ID(N'rol_analista') IS NULL CREATE ROLE rol_analista AUTHORIZATION dbo;
GO
-- Recepción: conoce socios, sesiones y reservas, pero no datos monetarios.
GRANT SELECT, INSERT ON OBJECT::operacion.Socio TO rol_recepcion;
GRANT SELECT ON OBJECT::operacion.Clase TO rol_recepcion;
GRANT SELECT ON OBJECT::operacion.Sesion TO rol_recepcion;
GRANT SELECT ON OBJECT::operacion.Reserva TO rol_recepcion;
GRANT SELECT ON OBJECT::operacion.Entrenador(EntrenadorID,Nombres,Apellidos) TO rol_recepcion;
GRANT EXECUTE ON OBJECT::operacion.RegistrarReserva TO rol_recepcion;
GRANT EXECUTE ON OBJECT::operacion.CancelarReserva TO rol_recepcion;
GO
-- Finanzas: puede identificar socios, ver pagos y usar procedimiento controlado.
GRANT SELECT ON OBJECT::operacion.Socio(SocioID,Nombres,Apellidos) TO rol_finanzas;
GRANT SELECT ON OBJECT::finanzas.Pago TO rol_finanzas;
GRANT EXECUTE ON OBJECT::finanzas.RegistrarPago TO rol_finanzas;
GO
-- Entrenador: horario y ocupación, sin datos de contacto ni pagos.
GRANT SELECT ON OBJECT::operacion.Clase TO rol_entrenador;
GRANT SELECT ON OBJECT::operacion.Sesion TO rol_entrenador;
GO
-- Analista: vistas de reportes únicamente; acceso de base por cadena de propiedad dbo.
GRANT SELECT ON SCHEMA::reportes TO rol_analista;
GO
IF DATABASE_PRINCIPAL_ID(N'usuario_recepcion') IS NULL CREATE USER usuario_recepcion WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'usuario_finanzas') IS NULL CREATE USER usuario_finanzas WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'usuario_entrenador') IS NULL CREATE USER usuario_entrenador WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID(N'usuario_analista') IS NULL CREATE USER usuario_analista WITHOUT LOGIN;
GO
IF IS_ROLEMEMBER(N'rol_recepcion',N'usuario_recepcion') = 0 ALTER ROLE rol_recepcion ADD MEMBER usuario_recepcion;
IF IS_ROLEMEMBER(N'rol_finanzas',N'usuario_finanzas') = 0 ALTER ROLE rol_finanzas ADD MEMBER usuario_finanzas;
IF IS_ROLEMEMBER(N'rol_entrenador',N'usuario_entrenador') = 0 ALTER ROLE rol_entrenador ADD MEMBER usuario_entrenador;
IF IS_ROLEMEMBER(N'rol_analista',N'usuario_analista') = 0 ALTER ROLE rol_analista ADD MEMBER usuario_analista;
GO
-- Mostrar a qué rol pertenece cada identidad sin login.
SELECT u.name Usuario,r.name Rol FROM sys.database_role_members m
JOIN sys.database_principals u ON u.principal_id=m.member_principal_id
JOIN sys.database_principals r ON r.principal_id=m.role_principal_id
WHERE u.name LIKE N'usuario_%' ORDER BY u.name;
GO
