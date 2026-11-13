USE master;
GO

IF DB_ID(N'GimnasioDB') IS NULL
BEGIN
    CREATE DATABASE GimnasioDB;
END;
GO

USE GimnasioDB;
GO
SELECT DB_NAME() AS BaseDeDatosActual;

-- Esquemas del gym 

USE GimnasioDB;
GO

IF SCHEMA_ID(N'operacion') IS NULL
    EXEC(N'CREATE SCHEMA operacion AUTHORIZATION dbo');
GO

IF SCHEMA_ID(N'finanzas') IS NULL
    EXEC(N'CREATE SCHEMA finanzas AUTHORIZATION dbo');
GO

SELECT name AS Esquema
FROM sys.schemas
WHERE name IN (N'operacion', N'finanzas')
ORDER BY name;

-- Tabla Operacion Socio
USE GimnasioDB;
GO

IF OBJECT_ID(N'operacion.Socio', N'U') IS NULL
BEGIN
    CREATE TABLE operacion.Socio (
        SocioID INT IDENTITY(1,1) CONSTRAINT PK_Socio PRIMARY KEY,
        Nombres NVARCHAR(100) NOT NULL,
        Apellidos NVARCHAR(100) NOT NULL,
        Correo NVARCHAR(254) NOT NULL CONSTRAINT UQ_Socio_Correo UNIQUE,
        FechaRegistro DATE NOT NULL CONSTRAINT DF_Socio_FechaRegistro
            DEFAULT (CONVERT(DATE, SYSDATETIME())),
        Activo BIT NOT NULL CONSTRAINT DF_Socio_Activo DEFAULT (1)
    );
END;
GO

SELECT name AS Columna
FROM sys.columns
WHERE object_id = OBJECT_ID(N'operacion.Socio', N'U')
ORDER BY column_id;

-- Tabla Operacion Entrenador
USE GimnasioDB;
GO

IF OBJECT_ID(N'operacion.Entrenador', N'U') IS NULL
BEGIN
    CREATE TABLE operacion.Entrenador (
        EntrenadorID INT IDENTITY(1,1) CONSTRAINT PK_Entrenador PRIMARY KEY,
        Nombres NVARCHAR(100) NOT NULL,
        Apellidos NVARCHAR(100) NOT NULL,
        Correo NVARCHAR(254) NOT NULL CONSTRAINT UQ_Entrenador_Correo UNIQUE,
        Activo BIT NOT NULL CONSTRAINT DF_Entrenador_Activo DEFAULT (1)
    );
END;
GO

SELECT name AS Columna
FROM sys.columns
WHERE object_id = OBJECT_ID(N'operacion.Entrenador', N'U')
ORDER BY column_id;
-- Tabla operacion Clase (Tipos de clases en el gym) 
USE GimnasioDB;
GO

IF OBJECT_ID(N'operacion.Clase', N'U') IS NULL
BEGIN
    CREATE TABLE operacion.Clase (
        ClaseID INT IDENTITY(1,1) CONSTRAINT PK_Clase PRIMARY KEY,
        Nombre NVARCHAR(100) NOT NULL CONSTRAINT UQ_Clase_Nombre UNIQUE,
        Descripcion NVARCHAR(300) NULL,
        Activa BIT NOT NULL CONSTRAINT DF_Clase_Activa DEFAULT (1)
    );
END;
GO

SELECT name AS Columna
FROM sys.columns
WHERE object_id = OBJECT_ID(N'operacion.Clase', N'U')
ORDER BY column_id;
-- Tabla operacion Sesion 
USE GimnasioDB;
GO

IF OBJECT_ID(N'operacion.Sesion', N'U') IS NULL
BEGIN
    CREATE TABLE operacion.Sesion (
        SesionID INT IDENTITY(1,1) CONSTRAINT PK_Sesion PRIMARY KEY,
        ClaseID INT NOT NULL,
        EntrenadorID INT NOT NULL,
        FechaHoraInicio DATETIME2(0) NOT NULL,
        FechaHoraFin DATETIME2(0) NOT NULL,
        CupoMaximo INT NOT NULL,

        CONSTRAINT FK_Sesion_Clase
            FOREIGN KEY (ClaseID) REFERENCES operacion.Clase (ClaseID),
        CONSTRAINT FK_Sesion_Entrenador
            FOREIGN KEY (EntrenadorID) REFERENCES operacion.Entrenador (EntrenadorID),
        CONSTRAINT CK_Sesion_Horario
            CHECK (FechaHoraFin > FechaHoraInicio),
        CONSTRAINT CK_Sesion_CupoMaximo
            CHECK (CupoMaximo > 0)
    );
END;
GO

SELECT
    name AS ClaveForanea,
    OBJECT_NAME(referenced_object_id) AS TablaReferenciada
FROM sys.foreign_keys
WHERE parent_object_id = OBJECT_ID(N'operacion.Sesion', N'U')
ORDER BY name;
-- Tabla Reserva
USE GimnasioDB;
GO

IF OBJECT_ID(N'operacion.Reserva', N'U') IS NULL
BEGIN
    CREATE TABLE operacion.Reserva (
        ReservaID INT IDENTITY(1,1) CONSTRAINT PK_Reserva PRIMARY KEY,
        SocioID INT NOT NULL,
        SesionID INT NOT NULL,
        FechaReserva DATETIME2(0) NOT NULL
            CONSTRAINT DF_Reserva_FechaReserva DEFAULT (SYSDATETIME()),
        FechaCancelacion DATETIME2(0) NULL,

        CONSTRAINT FK_Reserva_Socio
            FOREIGN KEY (SocioID) REFERENCES operacion.Socio (SocioID),
        CONSTRAINT FK_Reserva_Sesion
            FOREIGN KEY (SesionID) REFERENCES operacion.Sesion (SesionID),
        CONSTRAINT CK_Reserva_FechaCancelacion
            CHECK (FechaCancelacion IS NULL OR FechaCancelacion >= FechaReserva)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'operacion.Reserva', N'U')
      AND name = N'UX_Reserva_Activa'
)
BEGIN
    CREATE UNIQUE INDEX UX_Reserva_Activa
        ON operacion.Reserva (SesionID, SocioID)
        WHERE FechaCancelacion IS NULL;
END;
GO

SELECT
    name AS Indice,
    is_unique AS EsUnico,
    filter_definition AS Filtro
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'operacion.Reserva', N'U')
  AND name = N'UX_Reserva_Activa';
-- Tabla Finanzas 
USE GimnasioDB;
GO

IF OBJECT_ID(N'finanzas.Pago', N'U') IS NULL
BEGIN
    CREATE TABLE finanzas.Pago (
        PagoID INT IDENTITY(1,1) CONSTRAINT PK_Pago PRIMARY KEY,
        SocioID INT NOT NULL,
        Monto DECIMAL(10,2) NOT NULL,
        FechaPago DATETIME2(0) NOT NULL
            CONSTRAINT DF_Pago_FechaPago DEFAULT (SYSDATETIME()),

        CONSTRAINT FK_Pago_Socio
            FOREIGN KEY (SocioID) REFERENCES operacion.Socio (SocioID),
        CONSTRAINT CK_Pago_MontoPositivo
            CHECK (Monto > 0)
    );
END;
GO

SELECT
    SCHEMA_NAME(schema_id) AS Esquema,
    name AS Tabla
FROM sys.tables
WHERE schema_id IN (SCHEMA_ID(N'operacion'), SCHEMA_ID(N'finanzas'))
ORDER BY Esquema, Tabla;
-- Comprobacion registro de Reserva
USE GimnasioDB;
GO

CREATE OR ALTER PROCEDURE operacion.RegistrarReserva
    @SocioID INT,
    @SesionID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CupoMaximo INT;
    DECLARE @ReservaID INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @CupoMaximo = CupoMaximo
        FROM operacion.Sesion WITH (UPDLOCK, HOLDLOCK)
        WHERE SesionID = @SesionID;

        IF @CupoMaximo IS NULL
            THROW 50001, N'La sesión indicada no existe.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM operacion.Socio WITH (HOLDLOCK)
            WHERE SocioID = @SocioID AND Activo = 1
        )
            THROW 50002, N'El socio no existe o está inactivo.', 1;

        IF EXISTS (
            SELECT 1
            FROM operacion.Reserva
            WHERE SesionID = @SesionID
              AND SocioID = @SocioID
              AND FechaCancelacion IS NULL
        )
            THROW 50003, N'El socio ya tiene una reserva activa para esta sesión.', 1;

        IF (
            SELECT COUNT(*)
            FROM operacion.Reserva
            WHERE SesionID = @SesionID
              AND FechaCancelacion IS NULL
        ) >= @CupoMaximo
            THROW 50004, N'La sesión ya alcanzó su cupo máximo.', 1;

        INSERT INTO operacion.Reserva (SocioID, SesionID)
        VALUES (@SocioID, @SesionID);

        SET @ReservaID = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT @ReservaID AS ReservaID;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

SELECT name AS Procedimiento
FROM sys.procedures
WHERE object_id = OBJECT_ID(N'operacion.RegistrarReserva', N'P');

-- Comprobacion que el cupo se asigna 1 vez
USE GimnasioDB;
GO

DECLARE @Socio1 INT, @Socio2 INT, @Entrenador INT, @Clase INT, @Sesion INT;
DECLARE @Etiqueta VARCHAR(36) = CONVERT(VARCHAR(36), NEWID());
DECLARE @Inicio DATETIME2(0) = DATEADD(DAY, 1, SYSDATETIME());
DECLARE @ProbandoSegundoSocio BIT = 0;

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO operacion.Socio (Nombres, Apellidos, Correo)
    VALUES (N'Ana', N'Prueba', CONCAT('ana-', @Etiqueta, '@example.com'));
    SET @Socio1 = CONVERT(INT, SCOPE_IDENTITY());

    INSERT INTO operacion.Socio (Nombres, Apellidos, Correo)
    VALUES (N'Luis', N'Prueba', CONCAT('luis-', @Etiqueta, '@example.com'));
    SET @Socio2 = CONVERT(INT, SCOPE_IDENTITY());

    INSERT INTO operacion.Entrenador (Nombres, Apellidos, Correo)
    VALUES (N'Carlos', N'Prueba', CONCAT('carlos-', @Etiqueta, '@example.com'));
    SET @Entrenador = CONVERT(INT, SCOPE_IDENTITY());

    INSERT INTO operacion.Clase (Nombre)
    VALUES (CONCAT(N'Spinning de prueba ', @Etiqueta));
    SET @Clase = CONVERT(INT, SCOPE_IDENTITY());

    INSERT INTO operacion.Sesion
        (ClaseID, EntrenadorID, FechaHoraInicio, FechaHoraFin, CupoMaximo)
    VALUES
        (@Clase, @Entrenador, @Inicio, DATEADD(HOUR, 1, @Inicio), 1);
    SET @Sesion = CONVERT(INT, SCOPE_IDENTITY());

    -- Ana toma el único cupo.
    EXEC operacion.RegistrarReserva @SocioID = @Socio1, @SesionID = @Sesion;

    IF NOT EXISTS (
        SELECT 1
        FROM operacion.Reserva
        WHERE SocioID = @Socio1
          AND SesionID = @Sesion
          AND FechaCancelacion IS NULL
    )
        THROW 50100, N'Falló la prueba: no se registró la reserva de Ana.', 1;

    -- Luis intenta reservar la misma sesión.
    SET @ProbandoSegundoSocio = 1;
    EXEC operacion.RegistrarReserva @SocioID = @Socio2, @SesionID = @Sesion;

    THROW 50101, N'Falló la prueba: se aceptó una reserva por encima del cupo.', 1;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    IF @ProbandoSegundoSocio = 1 AND ERROR_NUMBER() = 50004
        SELECT N'Prueba aprobada' AS Resultado,
               ERROR_NUMBER() AS Codigo,
               ERROR_MESSAGE() AS Motivo;
    ELSE
        THROW;
END CATCH;

-- Cancelar y liberar cupo

USE GimnasioDB;
GO

CREATE OR ALTER PROCEDURE operacion.CancelarReserva
    @ReservaID INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE operacion.Reserva
    SET FechaCancelacion = SYSDATETIME()
    WHERE ReservaID = @ReservaID
      AND FechaCancelacion IS NULL;

    IF @@ROWCOUNT = 0
        THROW 50005, N'La reserva indicada no existe o ya fue cancelada.', 1;

    SELECT @ReservaID AS ReservaCancelada;
END;
GO

SELECT name AS Procedimiento
FROM sys.procedures
WHERE object_id = OBJECT_ID(N'operacion.CancelarReserva', N'P');

-- Carga de datos iniciales del gimnasio
USE GimnasioDB;
GO

INSERT INTO operacion.Clase (Nombre, Descripcion)
SELECT datos.Nombre, datos.Descripcion
FROM (VALUES
    (N'Spinning', N'Entrenamiento cardiovascular en bicicleta fija.'),
    (N'Yoga',     N'Práctica de posturas, respiración y flexibilidad.'),
    (N'Zumba',    N'Entrenamiento cardiovascular con baile.')
) AS datos (Nombre, Descripcion)
WHERE NOT EXISTS (
    SELECT 1
    FROM operacion.Clase AS clase
    WHERE clase.Nombre = datos.Nombre
);

SELECT Nombre, Activa
FROM operacion.Clase
WHERE Nombre IN (N'Spinning', N'Yoga', N'Zumba')
ORDER BY Nombre;
GO