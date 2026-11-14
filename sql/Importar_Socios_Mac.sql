/* Alternativa para Mac al asistente "Importar archivo plano" de SSMS.
   Crea dbo.SocioImportacion y carga los mismos 5 socios de datos/socios.csv.
   Despues se ejecuta sql/Importar_Socios.sql del repo, sin cambios. */
USE GimnasioDB;
GO

IF OBJECT_ID(N'dbo.SocioImportacion', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.SocioImportacion (
        Nombres   NVARCHAR(100) NULL,
        Apellidos NVARCHAR(100) NULL,
        Correo    NVARCHAR(254) NULL
    );
END;
GO

INSERT INTO dbo.SocioImportacion (Nombres, Apellidos, Correo)
SELECT datos.Nombres, datos.Apellidos, datos.Correo
FROM (VALUES
    (N'Ana',     N'Martínez', N'ana.martinez@example.com'),
    (N'Luis',    N'Hernández', N'luis.hernandez@example.com'),
    (N'Sofía',   N'López',    N'sofia.lopez@example.com'),
    (N'Diego',   N'Ramírez',  N'diego.ramirez@example.com'),
    (N'Valeria', N'García',   N'valeria.garcia@example.com')
) AS datos (Nombres, Apellidos, Correo)
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.SocioImportacion AS i
    WHERE i.Correo = datos.Correo
);
GO

SELECT Nombres, Apellidos, Correo FROM dbo.SocioImportacion ORDER BY Nombres;
GO
