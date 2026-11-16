# GimnasioDB — Sistema de Reservas de Gimnasio

**Proyecto de cátedra:** Administración de Bases de Datos · **Motor:** SQL Server 2025 Developer.  
Escenario: socios, entrenadores, clases, sesiones, reservas y pagos.

## Qué contiene el repositorio

- `sql/00_Base.sql` a `sql/04_Datos_Demo.sql`: modelo, procedimientos y carga inicial.
- `sql/05_Seguridad.sql` y `sql/06_Auditoria.sql`: roles, permisos y trazabilidad.
- `sql/07_Consultas.sql`, `08_Indices.sql`, `09_Dimensionamiento.sql`: 3 consultas con ventanas, índices, estimación y mediciones.
- [Dashboard de Power BI](powerbi/Dashboard/GimnasioDB_Dashboard.pbix) con las páginas Resumen, Finanzas y Ocupación. [Captura de la página Resumen](evidencias/PowerBI_Resumen.png).
- `sql/10_Backup.sql` a `sql/13_Restauracion_DEMO.sql`: FULL/DIFF/LOG, SQL Server Agent y validaciones.
- `docs/`: política de respaldo, pendientes de evidencia y seguimiento de rúbrica.
- `diagramas/`: modelo relacional y cardinalidades.
- `informe/` contiene el diccionario, el dimensionamiento, la seguridad y las [mediciones de rendimiento](informe/Optimizacion.md). El informe final Word/PDF está pendiente de incorporación al repositorio.

## Orden de ejecución en SSMS

1. Conectarse a **SQL Server 2025 Developer** con permisos suficientes para crear BD, roles, auditoría y jobs.
2. Ejecutar `sql/00_Base.sql`, `01_Modelo.sql`, `02_Procedimientos.sql`.
3. Ejecutar `03_Importacion_CSV.sql`, y si falla porque falta acceso al archivo CSV, usar como **alternativa de prueba** `03b_Importacion_Fallback.sql` (no reemplaza evidencia de `BULK INSERT`).
4. Ejecutar `04_Datos_Demo.sql`, `05_Seguridad.sql`, `06_Auditoria.sql`.
5. Ejecutar `07_Consultas.sql`, `08_Indices.sql`, `09_Dimensionamiento.sql`.
6. Ejecutar `10_Backup.sql`, `11_Agent.sql`, `12_Pruebas.sql`.
7. Para recuperación de prueba, revisar y personalizar `13_Restauracion_DEMO.sql` **sin sobrescribir la base principal**.

**Rutas:** Los ejemplos de `BULK INSERT`, auditoría y respaldos usan rutas Linux (`/var/opt/mssql/...`). La entrega contiene en la carpeta externa **`Extras_NO_COMMIT/Entorno_Local_Opcional`** un Docker Compose opcional que monta el CSV y activa SQL Agent, pero **Docker y su instalación no forman parte de los cinco commits**. Con SQL Server nativo en Windows, modificar esas rutas según el servidor y sus permisos.

**No ejecutar** el script heredado `sql/Proyecto_Gimnasio.sql` junto con la cadena modular porque podría repetir objetos y datos. Se conserva para respetar el trabajo previo del grupo.

