USE GimnasioDB;
GO

INSERT INTO operacion.Socio (Nombres, Apellidos, Correo)
SELECT origen.Nombres, origen.Apellidos, origen.Correo
FROM dbo.SocioImportacion AS origen
WHERE NOT EXISTS (
    SELECT 1
    FROM operacion.Socio AS socio
    WHERE socio.Correo = origen.Correo
);

SELECT @@ROWCOUNT AS SociosAgregados;

SELECT socio.SocioID, socio.Nombres, socio.Apellidos, socio.Correo
FROM operacion.Socio AS socio
JOIN dbo.SocioImportacion AS origen
    ON origen.Correo = socio.Correo
ORDER BY socio.Nombres;