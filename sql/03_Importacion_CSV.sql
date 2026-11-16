--Importación real del archivo UTF-8 datos/socios.csv.

USE GimnasioDB;
GO
TRUNCATE TABLE importacion.SocioImportacion;
GO
BULK INSERT importacion.SocioImportacion
FROM '/var/opt/mssql/import/socios.csv'
WITH (
 FORMAT='CSV',
 FIRSTROW=2,
 FIELDTERMINATOR=',',
 FIELDQUOTE='"',
 ROWTERMINATOR='0x0a',
 CODEPAGE='65001',
 TABLOCK
);
GO
;WITH Depurados AS (
 SELECT LTRIM(RTRIM(Nombres)) AS Nombres, LTRIM(RTRIM(Apellidos)) AS Apellidos,
        LTRIM(RTRIM(Correo)) AS Correo,
        ROW_NUMBER() OVER(PARTITION BY LOWER(LTRIM(RTRIM(Correo))) ORDER BY Nombres,Apellidos) AS rn
 FROM importacion.SocioImportacion
)
INSERT INTO operacion.Socio(Nombres,Apellidos,Correo)
SELECT d.Nombres,d.Apellidos,d.Correo
FROM Depurados d
WHERE d.rn=1 AND LEN(d.Nombres)>0 AND LEN(d.Apellidos)>0
  AND d.Correo LIKE N'%_@_%._%'
  AND NOT EXISTS(SELECT 1 FROM operacion.Socio s WHERE s.Correo=d.Correo);
GO
SELECT COUNT(*) AS FilasCSV FROM importacion.SocioImportacion;
SELECT COUNT(*) AS SociosTotales FROM operacion.Socio;
GO
