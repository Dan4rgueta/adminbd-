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

-- Carga de Entrenadores ficticios 
USE GimnasioDB;
GO

INSERT INTO operacion.Entrenador (Nombres, Apellidos, Correo)
SELECT datos.Nombres, datos.Apellidos, datos.Correo
FROM (VALUES
    (N'Carlos',  N'Mendoza', N'carlos.mendoza@example.com'),
    (N'Mariana', N'Flores',  N'mariana.flores@example.com'),
    (N'Gabriel', N'Castro',  N'gabriel.castro@example.com')
) AS datos (Nombres, Apellidos, Correo)
WHERE NOT EXISTS (
    SELECT 1
    FROM operacion.Entrenador AS entrenador
    WHERE entrenador.Correo = datos.Correo
);

SELECT @@ROWCOUNT AS EntrenadoresAgregados;

SELECT EntrenadorID, Nombres, Apellidos, Activo
FROM operacion.Entrenador
WHERE Correo IN (
    N'carlos.mendoza@example.com',
    N'mariana.flores@example.com',
    N'gabriel.castro@example.com'
)
ORDER BY Nombres;
GO

-- Programación inicial de sesiones
USE GimnasioDB;
GO

DECLARE @Sesiones TABLE (
    Clase NVARCHAR(100),
    CorreoEntrenador NVARCHAR(254),
    Inicio DATETIME2(0),
    Fin DATETIME2(0),
    Cupo INT
);

INSERT INTO @Sesiones (Clase, CorreoEntrenador, Inicio, Fin, Cupo)
VALUES
    (N'Spinning', N'carlos.mendoza@example.com',
     '2026-11-16T18:00:00', '2026-11-16T19:00:00', 12),
    (N'Yoga', N'mariana.flores@example.com',
     '2026-11-17T07:00:00', '2026-11-17T08:00:00', 15),
    (N'Zumba', N'gabriel.castro@example.com',
     '2026-11-18T17:00:00', '2026-11-18T18:00:00', 20);

INSERT INTO operacion.Sesion
    (ClaseID, EntrenadorID, FechaHoraInicio, FechaHoraFin, CupoMaximo)
SELECT c.ClaseID, e.EntrenadorID, p.Inicio, p.Fin, p.Cupo
FROM @Sesiones AS p
JOIN operacion.Clase AS c ON c.Nombre = p.Clase
JOIN operacion.Entrenador AS e ON e.Correo = p.CorreoEntrenador
WHERE NOT EXISTS (
    SELECT 1
    FROM operacion.Sesion AS s
    WHERE s.ClaseID = c.ClaseID
      AND s.EntrenadorID = e.EntrenadorID
      AND s.FechaHoraInicio = p.Inicio
);

SELECT @@ROWCOUNT AS SesionesAgregadas;

SELECT s.SesionID, c.Nombre AS Clase,
       CONCAT(e.Nombres, N' ', e.Apellidos) AS Entrenador,
       s.FechaHoraInicio, s.FechaHoraFin, s.CupoMaximo
FROM operacion.Sesion AS s
JOIN operacion.Clase AS c ON c.ClaseID = s.ClaseID
JOIN operacion.Entrenador AS e ON e.EntrenadorID = s.EntrenadorID
JOIN @Sesiones AS p ON p.Clase = c.Nombre
                   AND p.CorreoEntrenador = e.Correo
                   AND p.Inicio = s.FechaHoraInicio
ORDER BY s.FechaHoraInicio;
GO
-- Roles de seguridad del gimnasio
USE GimnasioDB;
GO

IF DATABASE_PRINCIPAL_ID(N'rol_recepcion') IS NULL
    CREATE ROLE rol_recepcion AUTHORIZATION dbo;

IF DATABASE_PRINCIPAL_ID(N'rol_finanzas') IS NULL
    CREATE ROLE rol_finanzas AUTHORIZATION dbo;
GO

SELECT name AS Rol
FROM sys.database_principals
WHERE type = 'R'
  AND name IN (N'rol_recepcion', N'rol_finanzas')
ORDER BY name;
GO
-- Permisos de recepción y finanzas
USE GimnasioDB;
GO

-- Recepción: alta de socios y consulta de clases, sesiones y reservas.
GRANT SELECT, INSERT ON OBJECT::operacion.Socio TO rol_recepcion;
GRANT SELECT ON OBJECT::operacion.Clase TO rol_recepcion;
GRANT SELECT ON OBJECT::operacion.Sesion TO rol_recepcion;
GRANT SELECT ON OBJECT::operacion.Entrenador (EntrenadorID, Nombres, Apellidos)
    TO rol_recepcion;
GRANT SELECT ON OBJECT::operacion.Reserva TO rol_recepcion;

-- Recepción registra y cancela reservas mediante los procedimientos.
GRANT EXECUTE ON OBJECT::operacion.RegistrarReserva TO rol_recepcion;
GRANT EXECUTE ON OBJECT::operacion.CancelarReserva TO rol_recepcion;

-- Finanzas: identificar al socio y registrar o consultar sus pagos.
GRANT SELECT ON OBJECT::operacion.Socio (SocioID, Nombres, Apellidos)
    TO rol_finanzas;
GRANT SELECT, INSERT ON OBJECT::finanzas.Pago TO rol_finanzas;
GO

-- Comprobar los permisos asignados a cada rol.
SELECT
    rol.name AS Rol,
    OBJECT_SCHEMA_NAME(p.major_id) AS Esquema,
    OBJECT_NAME(p.major_id) AS Objeto,
    COL_NAME(p.major_id, NULLIF(p.minor_id, 0)) AS Columna,
    p.permission_name AS Permiso
FROM sys.database_permissions AS p
JOIN sys.database_principals AS rol
    ON rol.principal_id = p.grantee_principal_id
WHERE rol.name IN (N'rol_recepcion', N'rol_finanzas')
  AND p.class = 1
ORDER BY Rol, Esquema, Objeto, Permiso, Columna;
GO

-- Usuarios de prueba para recepción y finanzas
USE GimnasioDB;
GO

IF DATABASE_PRINCIPAL_ID(N'usuario_recepcion') IS NULL
    CREATE USER usuario_recepcion WITHOUT LOGIN;

IF DATABASE_PRINCIPAL_ID(N'usuario_finanzas') IS NULL
    CREATE USER usuario_finanzas WITHOUT LOGIN;
GO

IF IS_ROLEMEMBER(N'rol_recepcion', N'usuario_recepcion') = 0
    ALTER ROLE rol_recepcion ADD MEMBER usuario_recepcion;

IF IS_ROLEMEMBER(N'rol_finanzas', N'usuario_finanzas') = 0
    ALTER ROLE rol_finanzas ADD MEMBER usuario_finanzas;
GO

-- Verificar a qué rol pertenece cada usuario.
SELECT
    usuario.name AS Usuario,
    rol.name AS Rol
FROM sys.database_role_members AS miembro
JOIN sys.database_principals AS usuario
    ON usuario.principal_id = miembro.member_principal_id
JOIN sys.database_principals AS rol
    ON rol.principal_id = miembro.role_principal_id
WHERE usuario.name IN (N'usuario_recepcion', N'usuario_finanzas')
ORDER BY usuario.name, rol.name;
GO