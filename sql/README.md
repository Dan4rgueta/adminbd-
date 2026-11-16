# Orden de ejecución del proyecto (SQL Server 2025 Developer)

Ejecutar en SSMS, conectado a la **instancia de desarrollo**, de uno en uno; detenerse ante cualquier error:

1. `00_Base.sql` — crear GimnasioDB y recuperación FULL.
2. `01_Modelo.sql` — cinco esquemas, seis tablas principales y tabla de importación.
3. `02_Procedimientos.sql` — reserva, cancelación y pago con transacciones.
4. `03_Importacion_CSV.sql` — `BULK INSERT` desde `datos/socios.csv` montado dentro de SQL Server. Si no hay acceso al CSV, `03b_Importacion_Fallback.sql` es una alternativa manual, **no evidencia una importación CSV**.
5. `04_Datos_Demo.sql` — datos ficticios para clases, sesiones, reservas y pagos.
6. `05_Seguridad.sql` — cuatro roles y usuarios de prueba.
7. `06_Auditoria.sql` — SQL Server Audit de pagos.
8. `07_Consultas.sql` — tres consultas/vistas con funciones ventana.
9. `08_Indices.sql` — índices no agrupados y filtrados.
10. `09_Dimensionamiento.sql` — tamaños actuales y proyección con factor por índices.
11. `10_Backup.sql` — procedimiento respaldos FULL, DIFF, LOG.
12. `11_Agent.sql` — trabajos automatizados y calendarios en SQL Server Agent.
13. `12_Pruebas.sql` — comprobaciones para las capturas de laboratorio.

**Por separado:** `13_Restauracion_DEMO.sql` es una plantilla comentada para restaurar a una segunda base, no una restauración ya ejecutada. `Pruebas_Rendimiento.sql` requiere una base de pruebas/volumen suficiente.

**No mezclar** con el legado `Proyecto_Gimnasio.sql` ni lanzar el antiguo `Indices_Optimizacion.sql` sobre un servidor compartido sin inspeccionarlo. Los scripts `03`, `06` y `10` usan rutas Linux de contenedor; en Windows nativo deben configurarse rutas del servidor accesibles a su cuenta de servicio. Los ejemplos de Docker están fuera de Git, en el paquete de entrega.
