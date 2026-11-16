--Modelo relacional normalizado. No destruye datos existentes.
USE GimnasioDB;
GO
IF SCHEMA_ID(N'operacion') IS NULL EXEC(N'CREATE SCHEMA operacion AUTHORIZATION dbo');
IF SCHEMA_ID(N'finanzas') IS NULL EXEC(N'CREATE SCHEMA finanzas AUTHORIZATION dbo');
IF SCHEMA_ID(N'importacion') IS NULL EXEC(N'CREATE SCHEMA importacion AUTHORIZATION dbo');
IF SCHEMA_ID(N'reportes') IS NULL EXEC(N'CREATE SCHEMA reportes AUTHORIZATION dbo');
IF SCHEMA_ID(N'mantenimiento') IS NULL EXEC(N'CREATE SCHEMA mantenimiento AUTHORIZATION dbo');
GO
IF OBJECT_ID(N'operacion.Socio', N'U') IS NULL
BEGIN
 CREATE TABLE operacion.Socio (
  SocioID INT IDENTITY(1,1) CONSTRAINT PK_Socio PRIMARY KEY,
  Nombres NVARCHAR(100) NOT NULL,
  Apellidos NVARCHAR(100) NOT NULL,
  Correo NVARCHAR(254) NOT NULL CONSTRAINT UQ_Socio_Correo UNIQUE,
  FechaRegistro DATE NOT NULL CONSTRAINT DF_Socio_FechaRegistro DEFAULT (CONVERT(DATE,SYSDATETIME())),
  Activo BIT NOT NULL CONSTRAINT DF_Socio_Activo DEFAULT (1),
  CONSTRAINT CK_Socio_Nombres CHECK (LEN(LTRIM(RTRIM(Nombres))) > 0),
  CONSTRAINT CK_Socio_Apellidos CHECK (LEN(LTRIM(RTRIM(Apellidos))) > 0)
 );
END;
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
IF OBJECT_ID(N'operacion.Sesion', N'U') IS NULL
BEGIN
 CREATE TABLE operacion.Sesion (
  SesionID INT IDENTITY(1,1) CONSTRAINT PK_Sesion PRIMARY KEY,
  ClaseID INT NOT NULL,
  EntrenadorID INT NOT NULL,
  FechaHoraInicio DATETIME2(0) NOT NULL,
  FechaHoraFin DATETIME2(0) NOT NULL,
  CupoMaximo INT NOT NULL,
  CONSTRAINT FK_Sesion_Clase FOREIGN KEY(ClaseID) REFERENCES operacion.Clase(ClaseID),
  CONSTRAINT FK_Sesion_Entrenador FOREIGN KEY(EntrenadorID) REFERENCES operacion.Entrenador(EntrenadorID),
  CONSTRAINT CK_Sesion_Horario CHECK(FechaHoraFin > FechaHoraInicio),
  CONSTRAINT CK_Sesion_Cupo CHECK(CupoMaximo BETWEEN 1 AND 1000)
 );
END;
GO
IF OBJECT_ID(N'operacion.Reserva', N'U') IS NULL
BEGIN
 CREATE TABLE operacion.Reserva (
  ReservaID INT IDENTITY(1,1) CONSTRAINT PK_Reserva PRIMARY KEY,
  SocioID INT NOT NULL,
  SesionID INT NOT NULL,
  FechaReserva DATETIME2(0) NOT NULL CONSTRAINT DF_Reserva_Fecha DEFAULT(SYSDATETIME()),
  FechaCancelacion DATETIME2(0) NULL,
  CONSTRAINT FK_Reserva_Socio FOREIGN KEY(SocioID) REFERENCES operacion.Socio(SocioID),
  CONSTRAINT FK_Reserva_Sesion FOREIGN KEY(SesionID) REFERENCES operacion.Sesion(SesionID),
  CONSTRAINT CK_Reserva_Cancelacion CHECK(FechaCancelacion IS NULL OR FechaCancelacion >= FechaReserva)
 );
END;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'operacion.Reserva') AND name=N'UX_Reserva_Activa')
 CREATE UNIQUE NONCLUSTERED INDEX UX_Reserva_Activa ON operacion.Reserva(SesionID,SocioID)
 WHERE FechaCancelacion IS NULL;
GO
IF OBJECT_ID(N'finanzas.Pago',N'U') IS NULL
BEGIN
 CREATE TABLE finanzas.Pago (
  PagoID INT IDENTITY(1,1) CONSTRAINT PK_Pago PRIMARY KEY,
  SocioID INT NOT NULL,
  Monto DECIMAL(10,2) NOT NULL,
  FechaPago DATETIME2(0) NOT NULL CONSTRAINT DF_Pago_Fecha DEFAULT(SYSDATETIME()),
  CONSTRAINT FK_Pago_Socio FOREIGN KEY(SocioID) REFERENCES operacion.Socio(SocioID),
  CONSTRAINT CK_Pago_MontoPositivo CHECK(Monto > 0)
 );
END;
GO
IF OBJECT_ID(N'importacion.SocioImportacion',N'U') IS NULL
BEGIN
 CREATE TABLE importacion.SocioImportacion (
  Nombres NVARCHAR(100) NULL,
  Apellidos NVARCHAR(100) NULL,
  Correo NVARCHAR(254) NULL
 );
END;
GO
-- Validar las seis tablas transaccionales y la tabla de trabajo para CSV.
SELECT SCHEMA_NAME(schema_id) AS Esquema, name AS Tabla
FROM sys.tables WHERE SCHEMA_NAME(schema_id) IN (N'operacion',N'finanzas',N'importacion')
ORDER BY Esquema,Tabla;
GO

-- AJUSTES_MODELO_EXISTENTE
-- Agrega restricciones faltantes en tablas ya creadas.
USE GimnasioDB;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = N'CK_Socio_Nombres'
      AND parent_object_id = OBJECT_ID(N'operacion.Socio')
)
BEGIN
    ALTER TABLE operacion.Socio WITH CHECK
    ADD CONSTRAINT CK_Socio_Nombres
    CHECK (LEN(LTRIM(RTRIM(Nombres))) > 0);
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = N'CK_Socio_Apellidos'
      AND parent_object_id = OBJECT_ID(N'operacion.Socio')
)
BEGIN
    ALTER TABLE operacion.Socio WITH CHECK
    ADD CONSTRAINT CK_Socio_Apellidos
    CHECK (LEN(LTRIM(RTRIM(Apellidos))) > 0);
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = N'CK_Sesion_Cupo'
      AND parent_object_id = OBJECT_ID(N'operacion.Sesion')
)
BEGIN
    ALTER TABLE operacion.Sesion WITH CHECK
    ADD CONSTRAINT CK_Sesion_Cupo
    CHECK (CupoMaximo BETWEEN 1 AND 1000);
END;
GO

