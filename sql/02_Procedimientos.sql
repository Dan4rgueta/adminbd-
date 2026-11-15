--Reglas transaccionales. Procedimientos accesibles por roles, no INSERT directo.
USE GimnasioDB;
GO
CREATE OR ALTER PROCEDURE operacion.RegistrarReserva
 @SocioID INT,
 @SesionID INT
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 DECLARE @Cupo INT, @Inicio DATETIME2(0), @ClaseID INT, @EntrenadorID INT, @ReservaID INT;
 BEGIN TRY
  BEGIN TRANSACTION;
  -- UPDLOCK + HOLDLOCK sobre la sesion serializa las solicitudes concurrentes
  -- del mismo cupo. Se cuenta y se escribe bajo el mismo bloqueo.
  SELECT @Cupo=CupoMaximo, @Inicio=FechaHoraInicio,
         @ClaseID=ClaseID, @EntrenadorID=EntrenadorID
  FROM operacion.Sesion WITH(UPDLOCK,HOLDLOCK)
  WHERE SesionID=@SesionID;
  IF @Cupo IS NULL THROW 50001,N'La sesión no existe.',1;
  IF @Inicio <= SYSDATETIME() THROW 50006,N'No se reservan sesiones ya iniciadas.',1;
  IF NOT EXISTS(SELECT 1 FROM operacion.Socio WHERE SocioID=@SocioID AND Activo=1)
     THROW 50002,N'Socio no encontrado o inactivo.',1;
  IF NOT EXISTS(SELECT 1 FROM operacion.Clase WHERE ClaseID=@ClaseID AND Activa=1)
     THROW 50007,N'La clase está inactiva.',1;
  IF NOT EXISTS(SELECT 1 FROM operacion.Entrenador WHERE EntrenadorID=@EntrenadorID AND Activo=1)
     THROW 50008,N'El entrenador está inactivo.',1;
  IF EXISTS(SELECT 1 FROM operacion.Reserva WHERE SocioID=@SocioID AND SesionID=@SesionID AND FechaCancelacion IS NULL)
     THROW 50003,N'Ya existe una reserva activa para este socio y sesión.',1;
  IF (SELECT COUNT_BIG(*) FROM operacion.Reserva WHERE SesionID=@SesionID AND FechaCancelacion IS NULL)>=@Cupo
     THROW 50004,N'No quedan cupos.',1;
  INSERT INTO operacion.Reserva(SocioID,SesionID) VALUES(@SocioID,@SesionID);
  SET @ReservaID = CONVERT(INT,SCOPE_IDENTITY());
  COMMIT TRANSACTION;
  SELECT @ReservaID AS ReservaID;
 END TRY
 BEGIN CATCH
  IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
  THROW;
 END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE operacion.CancelarReserva @ReservaID INT
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 UPDATE operacion.Reserva
 SET FechaCancelacion = SYSDATETIME()
 WHERE ReservaID=@ReservaID AND FechaCancelacion IS NULL;
 IF @@ROWCOUNT=0 THROW 50005,N'Reserva inexistente o ya cancelada.',1;
 SELECT @ReservaID AS ReservaCancelada;
END;
GO
CREATE OR ALTER PROCEDURE finanzas.RegistrarPago
 @SocioID INT, @Monto DECIMAL(10,2)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 IF @Monto IS NULL OR @Monto<=0 THROW 50021,N'El monto debe ser positivo.',1;
 IF NOT EXISTS(SELECT 1 FROM operacion.Socio WHERE SocioID=@SocioID)
    THROW 50022,N'El socio no existe.',1;
 INSERT INTO finanzas.Pago(SocioID,Monto) VALUES(@SocioID,@Monto);
 SELECT CONVERT(INT,SCOPE_IDENTITY()) AS PagoID;
END;
GO
