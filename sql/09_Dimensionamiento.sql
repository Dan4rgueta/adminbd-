-- Tamaño real por objeto + estimación de almacenamiento proyectado.
USE GimnasioDB;
GO
SELECT SCHEMA_NAME(t.schema_id) Esquema,t.name Tabla,
 SUM(CASE WHEN ps.index_id IN(0,1) THEN ps.row_count ELSE 0 END) Filas,
 CAST(SUM(CASE WHEN ps.index_id IN(0,1) THEN ps.used_page_count ELSE 0 END)*8.0/1024 AS DECIMAL(12,2)) MB_Datos,
 CAST(SUM(CASE WHEN ps.index_id>1 THEN ps.used_page_count ELSE 0 END)*8.0/1024 AS DECIMAL(12,2)) MB_Indices,
 CAST(SUM(ps.used_page_count)*8.0/1024 AS DECIMAL(12,2)) MB_Total
FROM sys.tables t JOIN sys.dm_db_partition_stats ps ON ps.object_id=t.object_id
WHERE SCHEMA_NAME(t.schema_id) IN(N'operacion',N'finanzas',N'importacion')
GROUP BY t.schema_id,t.name ORDER BY Esquema,Tabla;
GO
-- Supuestos matemáticos editables: bytes medios por fila y sobrecarga estimada por índices.
DECLARE @UsoPagina DECIMAL(8,4) = 0.80;
WITH Proyecciones AS (
 SELECT * FROM (VALUES
 (N'operacion.Socio',3000,180,0.35),
 (N'operacion.Entrenador',20,160,0.15),
 (N'operacion.Clase',15,240,0.15),
 (N'operacion.Sesion',10000,64,0.40),
 (N'operacion.Reserva',100000,48,0.45),
 (N'finanzas.Pago',60000,40,0.60),
 (N'importacion.SocioImportacion',3000,160,0.00)
 ) x(Tabla,FilasProyectadas,BytesFilaPromedio,FactorIndices)
)
SELECT Tabla,FilasProyectadas,BytesFilaPromedio,FactorIndices,
 CAST(CEILING(FilasProyectadas*BytesFilaPromedio/(8096.0*@UsoPagina))*8.0/1024 AS DECIMAL(12,2)) MB_DatosProyectados,
 CAST(CEILING((FilasProyectadas*BytesFilaPromedio/(8096.0*@UsoPagina))*FactorIndices)*8.0/1024 AS DECIMAL(12,2)) MB_IndicesProyectados,
 CAST((CEILING(FilasProyectadas*BytesFilaPromedio/(8096.0*@UsoPagina))+CEILING((FilasProyectadas*BytesFilaPromedio/(8096.0*@UsoPagina))*FactorIndices))*8.0/1024 AS DECIMAL(12,2)) MB_TotalProyectado
FROM Proyecciones ORDER BY Tabla;
GO
-- Archivos físicos: incluyen reservas, estructuras internas y log de transacciones.
SELECT name,type_desc,size*8.0/1024 AS TamanoAsignadoMB,physical_name
FROM sys.database_files;
GO
