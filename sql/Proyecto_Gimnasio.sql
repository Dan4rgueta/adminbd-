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