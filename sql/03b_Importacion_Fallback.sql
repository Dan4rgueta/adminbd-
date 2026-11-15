-- Alternativa manual 
USE GimnasioDB;
GO
TRUNCATE TABLE importacion.SocioImportacion;
INSERT INTO importacion.SocioImportacion(Nombres,Apellidos,Correo)
VALUES (N'Ana',N'Martínez',N'ana.martinez@example.com'),
(N'Luis',N'Hernández',N'luis.hernandez@example.com'),
(N'Sofía',N'López',N'sofia.lopez@example.com'),
(N'Diego',N'Ramírez',N'diego.ramirez@example.com'),
(N'Valeria',N'García',N'valeria.garcia@example.com');
INSERT INTO operacion.Socio(Nombres,Apellidos,Correo)
SELECT i.Nombres,i.Apellidos,i.Correo FROM importacion.SocioImportacion i
WHERE NOT EXISTS(SELECT 1 FROM operacion.Socio s WHERE s.Correo=i.Correo);
GO
