/* REPRODUCIBLE SOLO EN COPIA DE PRUEBAS.
   1. Cargar datos de volumen (sql/Datos_Volumen_Rendimiento.sql, original)
   2. Capturar estadísticas y plan de ejecución real ANTES y DESPUÉS.
   3. Para la medición ANTES, quitar índices II; nunca quitar UX_Reserva_Activa.
   NOTA: El plan del optimizador depende de estadísticas y cardinalidad;
   no se puede garantizar que el índice siempre reduzca tiempos.
*/
USE GimnasioDB;
GO
DROP INDEX IF EXISTS IX_Sesion_Clase_Inicio ON operacion.Sesion;
DROP INDEX IF EXISTS IX_Pago_FechaPago ON finanzas.Pago;
GO
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO
PRINT N'ANTES - Ranking';
SELECT * FROM reportes.vw_RankingClases ORDER BY Anio,Mes,Posicion,Clase;
PRINT N'ANTES - Ingresos';
SELECT * FROM reportes.vw_IngresosDiarios ORDER BY Fecha;
PRINT N'ANTES - Ocupación';
SELECT * FROM reportes.vw_OcupacionSesiones ORDER BY Clase,FechaHoraInicio;
GO
CREATE NONCLUSTERED INDEX IX_Sesion_Clase_Inicio ON operacion.Sesion(ClaseID,FechaHoraInicio) INCLUDE(CupoMaximo,EntrenadorID);
CREATE NONCLUSTERED INDEX IX_Pago_FechaPago ON finanzas.Pago(FechaPago) INCLUDE(Monto);
GO
PRINT N'DESPUÉS - Ranking';
SELECT * FROM reportes.vw_RankingClases ORDER BY Anio,Mes,Posicion,Clase;
PRINT N'DESPUÉS - Ingresos';
SELECT * FROM reportes.vw_IngresosDiarios ORDER BY Fecha;
PRINT N'DESPUÉS - Ocupación';
SELECT * FROM reportes.vw_OcupacionSesiones ORDER BY Clase,FechaHoraInicio;
GO
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
