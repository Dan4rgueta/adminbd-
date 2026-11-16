-- Índices no clúster para optimizar tres consultas con ventana.
USE GimnasioDB;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'operacion.Sesion') AND name=N'IX_Sesion_Clase_Inicio')
 CREATE NONCLUSTERED INDEX IX_Sesion_Clase_Inicio
 ON operacion.Sesion(ClaseID,FechaHoraInicio) INCLUDE(CupoMaximo,EntrenadorID);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'finanzas.Pago') AND name=N'IX_Pago_FechaPago')
 CREATE NONCLUSTERED INDEX IX_Pago_FechaPago
 ON finanzas.Pago(FechaPago) INCLUDE(Monto);
GO

-- Índice secundario para referencias de pagos por socio y fechas.
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'finanzas.Pago') AND name=N'IX_Pago_Socio_Fecha')
 CREATE NONCLUSTERED INDEX IX_Pago_Socio_Fecha ON finanzas.Pago(SocioID,FechaPago) INCLUDE(Monto);
GO
SELECT OBJECT_SCHEMA_NAME(object_id) Esquema,OBJECT_NAME(object_id) Tabla,name Indice,
 is_unique,filter_definition
FROM sys.indexes WHERE name IN(N'UX_Reserva_Activa',N'IX_Sesion_Clase_Inicio',N'IX_Pago_FechaPago',N'IX_Pago_Socio_Fecha')
ORDER BY Esquema,Tabla,Indice;
GO
