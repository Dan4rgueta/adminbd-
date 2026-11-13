USE GimnasioDB;
GO

DECLARE @SocioID INT = (
    SELECT SocioID
    FROM operacion.Socio
    WHERE Correo = N'ana.martinez@example.com'
);

DECLARE @FechaPago DATETIME2(0) = '2026-11-13T10:00:00';
DECLARE @Monto DECIMAL(10,2) = 25.00;

IF @SocioID IS NULL
    THROW 50112, N'No se encontró a Ana. Revisá la importación de socios.', 1;

-- La fecha fija permite repetir el ejemplo sin duplicar el pago.
IF NOT EXISTS (
    SELECT 1
    FROM finanzas.Pago
    WHERE SocioID = @SocioID
      AND FechaPago = @FechaPago
      AND Monto = @Monto
)
BEGIN
    INSERT INTO finanzas.Pago (SocioID, FechaPago, Monto)
    VALUES (@SocioID, @FechaPago, @Monto);
END;

SELECT p.PagoID,
       CONCAT(s.Nombres, N' ', s.Apellidos) AS Socio,
       p.FechaPago,
       p.Monto
FROM finanzas.Pago AS p
JOIN operacion.Socio AS s ON s.SocioID = p.SocioID
WHERE p.SocioID = @SocioID
  AND p.FechaPago = @FechaPago
  AND p.Monto = @Monto;
GO