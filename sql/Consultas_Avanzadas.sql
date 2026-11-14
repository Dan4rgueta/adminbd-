/* =====================================================================
   CONSULTAS AVANZADAS (Companero A)  -  sql/Consultas_Avanzadas.sql
   Base: GimnasioDB (TU COPIA local, no la del equipo)

   Tres consultas con funciones de ventana, guardadas como vistas del
   esquema reportes (Power BI lee de ellas):
     (a) ranking de clases por reservas activas ........ DENSE_RANK()
     (b) ingresos diarios con total acumulado .......... SUM() OVER
     (c) variacion de ocupacion vs sesion anterior ..... LAG()
   Una reserva es ACTIVA solo si FechaCancelacion IS NULL.
   No modifica tablas, procedimientos, roles, permisos ni auditoria.

   Orden: 1) este archivo   2) sql/Indices_Optimizacion.sql
   ===================================================================== */
USE GimnasioDB;
GO

/* ---------------------------------------------------------------------
   1. VISTAS (las tres consultas; Power BI lee de estas vistas)
   --------------------------------------------------------------------- */
IF SCHEMA_ID(N'reportes') IS NULL
    EXEC(N'CREATE SCHEMA reportes AUTHORIZATION dbo');
GO

-- (a) Ranking mensual de clases por reservas activas.
--     Se parte por mes para que el filtro de fecha de Power BI tenga sentido.
--     DENSE_RANK: los empates comparten posicion y la siguiente no se salta.
CREATE OR ALTER VIEW reportes.vw_RankingClases
AS
WITH ReservasMes AS
(
    SELECT  YEAR(s.FechaHoraInicio)  AS Anio,
            MONTH(s.FechaHoraInicio) AS Mes,
            c.ClaseID,
            c.Nombre                 AS Clase,
            COUNT(r.ReservaID)       AS ReservasActivas
    FROM operacion.Clase AS c
    JOIN operacion.Sesion AS s
         ON s.ClaseID = c.ClaseID
    LEFT JOIN operacion.Reserva AS r
         ON r.SesionID = s.SesionID
        AND r.FechaCancelacion IS NULL
    GROUP BY YEAR(s.FechaHoraInicio), MONTH(s.FechaHoraInicio), c.ClaseID, c.Nombre
)
SELECT  Anio, Mes, ClaseID, Clase, ReservasActivas,
        DENSE_RANK() OVER (PARTITION BY Anio, Mes ORDER BY ReservasActivas DESC) AS Posicion
FROM ReservasMes;
GO

-- (b) Ingresos por dia con total acumulado.
--     ROWS ... UNBOUNDED PRECEDING: suma desde el primer dia hasta el dia actual.
CREATE OR ALTER VIEW reportes.vw_IngresosDiarios
AS
WITH IngresosDia AS
(
    SELECT  CAST(FechaPago AS DATE) AS Fecha,
            SUM(Monto)              AS Ingresos,
            COUNT(*)                AS CantidadPagos
    FROM finanzas.Pago
    GROUP BY CAST(FechaPago AS DATE)
)
SELECT  Fecha, Ingresos, CantidadPagos,
        SUM(Ingresos) OVER (ORDER BY Fecha
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS IngresosAcumulados
FROM IngresosDia;
GO

-- (c) Ocupacion de cada sesion y su variacion contra la sesion anterior de la MISMA clase.
--     LEFT JOIN: las sesiones sin reservas aparecen con 0 (COUNT de una columna ignora NULL).
--     LAG(...) devuelve NULL en la primera sesion de cada clase (no hay anterior).
CREATE OR ALTER VIEW reportes.vw_OcupacionSesiones
AS
WITH OcupacionSesion AS
(
    SELECT  s.SesionID, s.ClaseID, c.Nombre AS Clase,
            s.FechaHoraInicio, s.CupoMaximo,
            COUNT(r.ReservaID) AS ReservasActivas
    FROM operacion.Sesion AS s
    JOIN operacion.Clase  AS c
         ON c.ClaseID = s.ClaseID
    LEFT JOIN operacion.Reserva AS r
         ON r.SesionID = s.SesionID
        AND r.FechaCancelacion IS NULL
    GROUP BY s.SesionID, s.ClaseID, c.Nombre, s.FechaHoraInicio, s.CupoMaximo
),
Porcentaje AS
(
    SELECT  SesionID, ClaseID, Clase, FechaHoraInicio, CupoMaximo, ReservasActivas,
            CAST(100.0 * ReservasActivas / CupoMaximo AS DECIMAL(5,2)) AS OcupacionPct
    FROM OcupacionSesion
)
SELECT  SesionID, Clase, FechaHoraInicio, CupoMaximo, ReservasActivas, OcupacionPct,
        LAG(OcupacionPct) OVER (PARTITION BY ClaseID
                                ORDER BY FechaHoraInicio, SesionID) AS OcupacionSesionAnterior,
        OcupacionPct - LAG(OcupacionPct) OVER (PARTITION BY ClaseID
                                               ORDER BY FechaHoraInicio, SesionID) AS VariacionPuntos
FROM Porcentaje;
GO

-- Prueba rapida de las tres vistas
SELECT TOP (10) * FROM reportes.vw_RankingClases       ORDER BY Anio DESC, Mes DESC, Posicion;
SELECT TOP (10) * FROM reportes.vw_IngresosDiarios     ORDER BY Fecha DESC;
SELECT TOP (10) * FROM reportes.vw_OcupacionSesiones   ORDER BY FechaHoraInicio DESC;
GO


/* ---------------------------------------------------------------------
   5. VERIFICACION: contrastar los resultados con el dashboard
   Cada par de numeros debe coincidir. Si Power BI muestra otro valor,
   revisa los filtros de fecha del dashboard.
   --------------------------------------------------------------------- */

-- (a) Reservas activas: suma de la vista = conteo directo
SELECT  (SELECT SUM(ReservasActivas) FROM reportes.vw_RankingClases)                AS TotalVista,
        (SELECT COUNT(*) FROM operacion.Reserva WHERE FechaCancelacion IS NULL)      AS TotalDirecto;

-- (b) Ingresos: suma de la vista = suma directa; el ultimo acumulado = total
SELECT  (SELECT SUM(Ingresos) FROM reportes.vw_IngresosDiarios)                      AS TotalVista,
        (SELECT SUM(Monto) FROM finanzas.Pago)                                       AS TotalDirecto,
        (SELECT TOP (1) IngresosAcumulados FROM reportes.vw_IngresosDiarios
          ORDER BY Fecha DESC)                                                       AS UltimoAcumulado;

-- (c) Sesiones: la vista debe tener TODAS las sesiones (tambien las vacias)
SELECT  (SELECT COUNT(*) FROM reportes.vw_OcupacionSesiones)                         AS SesionesVista,
        (SELECT COUNT(*) FROM operacion.Sesion)                                      AS SesionesDirecto,
        (SELECT COUNT(*) FROM reportes.vw_OcupacionSesiones
          WHERE ReservasActivas = 0)                                                 AS SesionesVacias;
GO
