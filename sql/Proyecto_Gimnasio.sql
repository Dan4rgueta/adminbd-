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