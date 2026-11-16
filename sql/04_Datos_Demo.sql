-- Datos ficticios de demostración. Fechas relativas al día actual.
USE GimnasioDB;
GO
INSERT INTO operacion.Clase(Nombre,Descripcion)
SELECT v.Nombre,v.Descripcion FROM (VALUES
 (N'Spinning',N'Entrenamiento cardiovascular en bicicleta fija'),
 (N'Yoga',N'Posturas, respiración y flexibilidad'),
 (N'Zumba',N'Baile y acondicionamiento físico'),
 (N'Pilates',N'Entrenamiento de core y movilidad')
) v(Nombre,Descripcion)
WHERE NOT EXISTS(SELECT 1 FROM operacion.Clase c WHERE c.Nombre=v.Nombre);
INSERT INTO operacion.Entrenador(Nombres,Apellidos,Correo)
SELECT v.Nombres,v.Apellidos,v.Correo FROM (VALUES
 (N'Carlos',N'Mendoza',N'carlos.mendoza@example.com'),
 (N'Mariana',N'Flores',N'mariana.flores@example.com'),
 (N'Gabriel',N'Castro',N'gabriel.castro@example.com')
) v(Nombres,Apellidos,Correo)
WHERE NOT EXISTS(SELECT 1 FROM operacion.Entrenador e WHERE e.Correo=v.Correo);
GO
-- Diez sesiones en los 10 días siguientes; reejecución no duplica.
;WITH N AS (
 SELECT v.Num,v.Clase,v.Correo,v.Hora,v.Cupo FROM (VALUES
 (1,N'Spinning',N'carlos.mendoza@example.com',18,12),
 (2,N'Yoga',N'mariana.flores@example.com',7,15),
 (3,N'Zumba',N'gabriel.castro@example.com',17,20),
 (4,N'Pilates',N'mariana.flores@example.com',9,15),
 (5,N'Spinning',N'carlos.mendoza@example.com',18,12),
 (6,N'Zumba',N'gabriel.castro@example.com',16,20),
 (7,N'Yoga',N'mariana.flores@example.com',7,15),
 (8,N'Pilates',N'mariana.flores@example.com',11,15),
 (9,N'Spinning',N'carlos.mendoza@example.com',18,12),
 (10,N'Zumba',N'gabriel.castro@example.com',17,20)
 ) v(Num,Clase,Correo,Hora,Cupo)
), Pendientes AS (
 SELECT c.ClaseID,e.EntrenadorID,
 DATEADD(HOUR,n.Hora,CAST(DATEADD(DAY,n.Num,CONVERT(DATE,SYSDATETIME())) AS DATETIME2(0))) AS Inicio,
 n.Cupo FROM N n
 JOIN operacion.Clase c ON c.Nombre=n.Clase
 JOIN operacion.Entrenador e ON e.Correo=n.Correo
)
INSERT INTO operacion.Sesion(ClaseID,EntrenadorID,FechaHoraInicio,FechaHoraFin,CupoMaximo)
SELECT p.ClaseID,p.EntrenadorID,p.Inicio,DATEADD(HOUR,1,p.Inicio),p.Cupo
FROM Pendientes p
WHERE NOT EXISTS(SELECT 1 FROM operacion.Sesion s WHERE s.ClaseID=p.ClaseID
AND s.EntrenadorID=p.EntrenadorID AND s.FechaHoraInicio=p.Inicio);
GO
-- Tres reservas para demostrar el ciclo sin duplicarlas.
DECLARE @S1 INT=(SELECT TOP 1 SocioID FROM operacion.Socio ORDER BY SocioID);
DECLARE @S2 INT=(SELECT SocioID FROM operacion.Socio WHERE Correo=N'luis.hernandez@example.com');
DECLARE @S3 INT=(SELECT SocioID FROM operacion.Socio WHERE Correo=N'sofia.lopez@example.com');
DECLARE @Sesion INT=(SELECT TOP 1 SesionID FROM operacion.Sesion WHERE FechaHoraInicio>SYSDATETIME() ORDER BY FechaHoraInicio,SesionID);
IF @S1 IS NOT NULL AND @Sesion IS NOT NULL AND NOT EXISTS(SELECT 1 FROM operacion.Reserva WHERE SocioID=@S1 AND SesionID=@Sesion AND FechaCancelacion IS NULL)
  EXEC operacion.RegistrarReserva @SocioID=@S1,@SesionID=@Sesion;
IF @S2 IS NOT NULL AND @Sesion IS NOT NULL AND NOT EXISTS(SELECT 1 FROM operacion.Reserva WHERE SocioID=@S2 AND SesionID=@Sesion AND FechaCancelacion IS NULL)
  EXEC operacion.RegistrarReserva @SocioID=@S2,@SesionID=@Sesion;
IF @S3 IS NOT NULL AND @Sesion IS NOT NULL AND NOT EXISTS(SELECT 1 FROM operacion.Reserva WHERE SocioID=@S3 AND SesionID=@Sesion AND FechaCancelacion IS NULL)
  EXEC operacion.RegistrarReserva @SocioID=@S3,@SesionID=@Sesion;
GO
-- Cuatro pagos históricos y uno actual.
;WITH D AS (
 SELECT s.SocioID,v.Monto,CAST(v.Fecha AS DATETIME2(0)) AS FechaPago
 FROM (VALUES
 (N'ana.martinez@example.com',25.00,'2026-10-01T08:00:00'),
 (N'ana.martinez@example.com',25.00,'2026-11-01T08:00:00'),
 (N'luis.hernandez@example.com',40.00,'2026-10-03T09:00:00'),
 (N'sofia.lopez@example.com',30.00,'2026-11-04T10:00:00'),
 (N'diego.ramirez@example.com',20.00,'2026-11-05T11:00:00')
 ) v(Correo,Monto,Fecha) JOIN operacion.Socio s ON s.Correo=v.Correo
)
INSERT INTO finanzas.Pago(SocioID,Monto,FechaPago)
SELECT d.SocioID,d.Monto,d.FechaPago FROM D d WHERE NOT EXISTS
(SELECT 1 FROM finanzas.Pago p WHERE p.SocioID=d.SocioID AND p.Monto=d.Monto AND p.FechaPago=d.FechaPago);
GO
SELECT COUNT(*) AS Socios FROM operacion.Socio;
SELECT COUNT(*) AS Sesiones FROM operacion.Sesion;
SELECT COUNT(*) AS Reservas FROM operacion.Reserva;
SELECT COUNT(*) AS Pagos FROM finanzas.Pago;
GO
