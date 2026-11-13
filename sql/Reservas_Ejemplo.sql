USE GimnasioDB;
GO

DECLARE @SocioID INT = (
    SELECT SocioID
    FROM operacion.Socio
    WHERE Correo = N'ana.martinez@example.com'
);

DECLARE @SesionID INT = (
    SELECT s.SesionID
    FROM operacion.Sesion AS s
    JOIN operacion.Clase AS c ON c.ClaseID = s.ClaseID
    JOIN operacion.Entrenador AS e ON e.EntrenadorID = s.EntrenadorID
    WHERE c.Nombre = N'Spinning'
      AND e.Correo = N'carlos.mendoza@example.com'
      AND s.FechaHoraInicio = '2026-11-16T18:00:00'
);

IF @SocioID IS NULL
    THROW 50110, N'No se encontró a Ana. Revisá la importación de socios.', 1;

IF @SesionID IS NULL
    THROW 50111, N'No se encontró la sesión de Spinning del 16 de noviembre.', 1;

-- Crear la reserva de ejemplo una sola vez.
IF NOT EXISTS (
    SELECT 1
    FROM operacion.Reserva
    WHERE SocioID = @SocioID AND SesionID = @SesionID
)
BEGIN
    EXEC operacion.RegistrarReserva @SocioID = @SocioID, @SesionID = @SesionID;
END;

SELECT r.ReservaID,
       CONCAT(s.Nombres, N' ', s.Apellidos) AS Socio,
       c.Nombre AS Clase,
       se.FechaHoraInicio AS Inicio,
       CASE WHEN r.FechaCancelacion IS NULL
            THEN N'Activa' ELSE N'Cancelada' END AS Estado
FROM operacion.Reserva AS r
JOIN operacion.Socio AS s ON s.SocioID = r.SocioID
JOIN operacion.Sesion AS se ON se.SesionID = r.SesionID
JOIN operacion.Clase AS c ON c.ClaseID = se.ClaseID
WHERE r.SocioID = @SocioID AND r.SesionID = @SesionID;
GO