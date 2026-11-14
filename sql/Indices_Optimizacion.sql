/* =====================================================================
   INDICES Y OPTIMIZACION (Companero A)  -  sql/Indices_Optimizacion.sql
   Base: GimnasioDB (TU COPIA local, con el volumen cargado)
   Requiere haber ejecutado antes sql/Consultas_Avanzadas.sql.

   Metodo: medir ANTES, crear el indice, medir DESPUES con los mismos datos.
   Anotar logical reads, CPU y elapsed time. Si un indice no mejora, se
   documenta y se elimina (bloque final): no se conservan indices inutiles.
   ===================================================================== */
USE GimnasioDB;
GO

-- 0. Indices que ya existen (evitar duplicados; UX_Reserva_Activa no se toca)
SELECT  OBJECT_SCHEMA_NAME(i.object_id) AS Esquema,
        OBJECT_NAME(i.object_id)        AS Tabla,
        i.name, i.type_desc, i.is_unique, i.filter_definition
FROM sys.indexes AS i
WHERE i.object_id IN (OBJECT_ID(N'operacion.Reserva'),
                      OBJECT_ID(N'operacion.Sesion'),
                      OBJECT_ID(N'finanzas.Pago'))
  AND i.index_id > 0
ORDER BY Esquema, Tabla, i.name;
GO

/* ---------------------------------------------------------------------
   2. MEDICION "ANTES" (sin los indices nuevos)
   Anotar por consulta: logical reads de cada tabla y elapsed time.
   El indice UX_Reserva_Activa ya existe: forma parte del "antes".
   Activa el plan de ejecucion real en tu cliente (ver guia) antes de correr.
   --------------------------------------------------------------------- */
DROP INDEX IF EXISTS IX_Sesion_Clase_Inicio ON operacion.Sesion;
DROP INDEX IF EXISTS IX_Pago_FechaPago      ON finanzas.Pago;
GO

CHECKPOINT;
DBCC DROPCLEANBUFFERS;     -- cache fria; solo en entorno de pruebas
GO
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO
SELECT * FROM reportes.vw_RankingClases     ORDER BY Anio, Mes, Posicion, Clase;   -- ANTES (a)
GO
SELECT * FROM reportes.vw_IngresosDiarios   ORDER BY Fecha;                          -- ANTES (b)
GO
SELECT * FROM reportes.vw_OcupacionSesiones ORDER BY Clase, FechaHoraInicio;         -- ANTES (c)
GO
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* ---------------------------------------------------------------------
   3. INDICES
   --------------------------------------------------------------------- */

-- (a) y (c): ambas consultas agrupan o particionan por ClaseID y ordenan por fecha de inicio.
--     CupoMaximo viaja incluido, asi que el indice cubre la consulta (sin Key Lookup).
CREATE NONCLUSTERED INDEX IX_Sesion_Clase_Inicio
    ON operacion.Sesion (ClaseID, FechaHoraInicio)
    INCLUDE (CupoMaximo);
GO

-- (b): agrupa por dia y suma Monto. Un indice por FechaPago con Monto incluido
--      evita leer las demas columnas de la tabla.
CREATE NONCLUSTERED INDEX IX_Pago_FechaPago
    ON finanzas.Pago (FechaPago)
    INCLUDE (Monto);
GO

-- Reservas activas por sesion (a y c): ya las cubre UX_Reserva_Activa
-- (SesionID, SocioID) WHERE FechaCancelacion IS NULL. No se crea otro indice.

/* ---------------------------------------------------------------------
   4. MEDICION "DESPUES" (mismos datos, mismos filtros)
   --------------------------------------------------------------------- */
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
GO
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO
SELECT * FROM reportes.vw_RankingClases     ORDER BY Anio, Mes, Posicion, Clase;   -- DESPUES (a)
GO
SELECT * FROM reportes.vw_IngresosDiarios   ORDER BY Fecha;                          -- DESPUES (b)
GO
SELECT * FROM reportes.vw_OcupacionSesiones ORDER BY Clase, FechaHoraInicio;         -- DESPUES (c)
GO
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- Indices existentes y su uso (evidencia extra)
SELECT  OBJECT_SCHEMA_NAME(i.object_id) + N'.' + OBJECT_NAME(i.object_id) AS Tabla,
        i.name AS Indice, i.type_desc AS Tipo,
        ISNULL(us.user_seeks, 0) AS Seeks, ISNULL(us.user_scans, 0) AS Scans
FROM sys.indexes AS i
LEFT JOIN sys.dm_db_index_usage_stats AS us
       ON us.object_id = i.object_id AND us.index_id = i.index_id AND us.database_id = DB_ID()
WHERE i.name IN (N'IX_Sesion_Clase_Inicio', N'IX_Pago_FechaPago', N'UX_Reserva_Activa')
ORDER BY Tabla, Indice;
GO


/* ---------------------------------------------------------------------
   5. SI UN INDICE NO MEJORO LA MEDICION, QUITARLO (descomentar solo ese)
   --------------------------------------------------------------------- */
-- DROP INDEX IF EXISTS IX_Sesion_Clase_Inicio ON operacion.Sesion;
-- DROP INDEX IF EXISTS IX_Pago_FechaPago      ON finanzas.Pago;
GO
