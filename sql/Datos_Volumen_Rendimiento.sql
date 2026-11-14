/* =====================================================================
   DATOS DE VOLUMEN PARA LAS PRUEBAS DE RENDIMIENTO (Companero A)
   Base: GimnasioDB (TU COPIA, nunca la que respalda las capturas del equipo)

   Con solo 5 socios, 3 sesiones, 1 reserva y 1 pago, un indice no
   puede mostrar mejora. Este script agrega datos ficticios de forma
   deterministica (sin azar) para poder medir antes y despues.

   Volumen que genera (documentarlo en el informe):
     - 3,000 socios nuevos (90 % activos), correo ...@volumen.test
     - 5 clases y 3 entrenadores nuevos
     - 10,000 sesiones en los ultimos 365 dias (algunas quedan sin reservas)
     - alrededor de 85,000 reservas (cerca del 14 % canceladas)
     - 60,000 pagos en los ultimos 365 dias

   IMPORTANTE: ejecutalo en una copia SIN la auditoria activa (solo el bloque
   A del script del equipo, lineas 1 a 457). Con la auditoria encendida, cada
   INSERT y SELECT sobre finanzas.Pago generaria un registro en el archivo.

   Se puede ejecutar una sola vez: si detecta que ya se cargo, no hace nada.
   ===================================================================== */
USE GimnasioDB;
GO
SET NOCOUNT ON;
GO

-- Proteccion contra una segunda ejecucion
IF EXISTS (SELECT 1 FROM operacion.Socio WHERE Correo LIKE N'%@volumen.test')
BEGIN
    PRINT N'Los datos de volumen ya estan cargados. No se ejecuta nada mas.';
    SET NOEXEC ON;
END;
GO

-- Tablas auxiliares de numeros
SELECT TOP (60000) CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS INT) AS n
INTO #N
FROM sys.all_objects AS a
CROSS JOIN sys.all_objects AS b;

SELECT TOP (30) n INTO #K FROM #N ORDER BY n;
GO

-- 1. Catalogos nuevos
INSERT INTO operacion.Clase (Nombre, Descripcion)
SELECT datos.Nombre, datos.Descripcion
FROM (VALUES
    (N'Crossfit',   N'Entrenamiento funcional de alta intensidad.'),
    (N'Pilates',    N'Fortalecimiento del centro del cuerpo.'),
    (N'Boxeo',      N'Tecnica y condicion fisica con guantes.'),
    (N'Funcional',  N'Circuitos de fuerza y movilidad.'),
    (N'Stretching', N'Estiramientos y recuperacion.')
) AS datos (Nombre, Descripcion)
WHERE NOT EXISTS (SELECT 1 FROM operacion.Clase AS c WHERE c.Nombre = datos.Nombre);

INSERT INTO operacion.Entrenador (Nombres, Apellidos, Correo)
SELECT datos.Nombres, datos.Apellidos, datos.Correo
FROM (VALUES
    (N'Andrea', N'Rivas',   N'andrea.rivas@volumen.test'),
    (N'Mauricio', N'Cruz',  N'mauricio.cruz@volumen.test'),
    (N'Karla',  N'Portillo', N'karla.portillo@volumen.test')
) AS datos (Nombres, Apellidos, Correo)
WHERE NOT EXISTS (SELECT 1 FROM operacion.Entrenador AS e WHERE e.Correo = datos.Correo);
GO

-- 2. Socios
INSERT INTO operacion.Socio (Nombres, Apellidos, Correo, FechaRegistro, Activo)
SELECT
    CHOOSE(n % 10 + 1, N'Carlos', N'Maria', N'Jose', N'Ana', N'Luis', N'Sofia', N'Miguel', N'Lucia', N'Jorge', N'Elena'),
    CHOOSE((n / 10) % 10 + 1, N'Lopez', N'Martinez', N'Hernandez', N'Garcia', N'Rodriguez', N'Perez', N'Gomez', N'Flores', N'Ramos', N'Cruz'),
    CONCAT(N'socio', n, N'@volumen.test'),
    DATEADD(DAY, -(n % 365), CONVERT(DATE, SYSDATETIME())),
    CASE WHEN n % 10 = 0 THEN 0 ELSE 1 END
FROM #N
WHERE n <= 3000;
GO

-- Numeracion de los catalogos (para repartir sesiones y reservas)
SELECT ROW_NUMBER() OVER (ORDER BY ClaseID)      AS rn, ClaseID      INTO #Clases      FROM operacion.Clase;
SELECT ROW_NUMBER() OVER (ORDER BY EntrenadorID) AS rn, EntrenadorID INTO #Entrenadores FROM operacion.Entrenador;
SELECT ROW_NUMBER() OVER (ORDER BY SocioID)      AS rn, SocioID      INTO #Socios       FROM operacion.Socio WHERE Activo = 1;
GO

-- 3. Sesiones: 10,000 repartidas en el ultimo ano, cupos de 10, 15, 20 y 25
INSERT INTO operacion.Sesion (ClaseID, EntrenadorID, FechaHoraInicio, FechaHoraFin, CupoMaximo)
SELECT c.ClaseID,
       e.EntrenadorID,
       x.Inicio,
       DATEADD(HOUR, 1, x.Inicio),
       10 + (n % 4) * 5
FROM #N
CROSS APPLY (
    SELECT DATEADD(HOUR, 6 + (n % 14),
               CAST(DATEADD(DAY, -((n * 7) % 365), CONVERT(DATE, SYSDATETIME())) AS DATETIME2(0))) AS Inicio
) AS x
JOIN #Clases      AS c ON c.rn = (n % (SELECT COUNT(*) FROM #Clases)) + 1
JOIN #Entrenadores AS e ON e.rn = (n % (SELECT COUNT(*) FROM #Entrenadores)) + 1
WHERE n <= 10000;
GO

-- 4. Reservas: cada sesion pasada recibe entre 0 y CupoMaximo reservas (las de 0 son sesiones vacias).
--    Una de cada siete se cancela. Nunca se supera el cupo y no se repite (SesionID, SocioID).
INSERT INTO operacion.Reserva (SocioID, SesionID, FechaReserva, FechaCancelacion)
SELECT so.SocioID,
       s.SesionID,
       f.FechaReserva,
       CASE WHEN (s.SesionID + k.n) % 7 = 0 THEN DATEADD(HOUR, 6, f.FechaReserva) END
FROM operacion.Sesion AS s
JOIN #K AS k
    ON k.n <= (s.SesionID * 7) % (s.CupoMaximo + 1)
CROSS APPLY (SELECT DATEADD(DAY, -2, s.FechaHoraInicio) AS FechaReserva) AS f
JOIN #Socios AS so
    ON so.rn = ((s.SesionID * 31 + k.n) % (SELECT COUNT(*) FROM #Socios)) + 1
WHERE s.FechaHoraInicio < SYSDATETIME();
GO

-- 5. Pagos: 60,000 en el ultimo ano
INSERT INTO finanzas.Pago (SocioID, Monto, FechaPago)
SELECT so.SocioID,
       CHOOSE(n % 4 + 1, 20.00, 25.00, 40.00, 60.00),
       DATEADD(MINUTE, (n * 37) % 1440,
           CAST(DATEADD(DAY, -((n * 11) % 365), CONVERT(DATE, SYSDATETIME())) AS DATETIME2(0)))
FROM #N
JOIN #Socios AS so ON so.rn = (n % (SELECT COUNT(*) FROM #Socios)) + 1
WHERE n <= 60000;
GO

DROP TABLE #N, #K, #Clases, #Entrenadores, #Socios;
GO

-- Estadisticas al dia despues de la carga masiva
EXEC sp_updatestats;
GO

-- Volumen final (copiar esta tabla al informe)
SELECT N'operacion.Socio'   AS Tabla, COUNT(*) AS Filas FROM operacion.Socio
UNION ALL SELECT N'operacion.Clase',   COUNT(*) FROM operacion.Clase
UNION ALL SELECT N'operacion.Sesion',  COUNT(*) FROM operacion.Sesion
UNION ALL SELECT N'operacion.Reserva', COUNT(*) FROM operacion.Reserva
UNION ALL SELECT N'finanzas.Pago',     COUNT(*) FROM finanzas.Pago;

SELECT COUNT(*) AS SesionesSinReservasActivas
FROM operacion.Sesion AS s
WHERE NOT EXISTS (
    SELECT 1 FROM operacion.Reserva AS r
    WHERE r.SesionID = s.SesionID AND r.FechaCancelacion IS NULL
);
GO

SET NOEXEC OFF;
GO
