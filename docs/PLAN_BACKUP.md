# Política de respaldo, restauración y continuidad

## Objetivo de recuperación

- **RPO objetivo: 15 minutos.** Pérdida máxima de información esperada de hasta 15 minutos cuando el último respaldo de log esté sano. Es un objetivo, no una garantía sin pruebas periódicas.
- **RTO objetivo: 2 horas.** Tiempo objetivo para reponer el servicio desde el fallo, condicionado al volumen, rendimiento del disco y disponibilidad del equipo de soporte. Debe medirse con restauraciones de prueba.
- **Modelo de recuperación:** FULL (`sql/00_Base.sql`). Con `SIMPLE` no existe respaldo regular del log; por eso se fija `FULL`.

## Calendario de SQL Server Agent

| Tipo | Frecuencia y hora DEL SERVIDOR | Archivo y retención propuesta |
|---|---|---|
| FULL | diario 02:00 | `GimnasioDB_FULL_YYYYMMDD_HHMMSS.bak` · conservar 7 días |
| DIFERENCIAL | diario 08:00, 14:00, 20:00 | `GimnasioDB_DIFF_*.bak` · conservar 7 días |
| LOG | cada 15 minutos, 24/7 | `GimnasioDB_LOG_*.trn` · conservar 48 horas |

**Nota:** se crean trabajos de respaldo, pero la retención anterior es **política documental**: no se incluye un borrado automático para evitar destruir cadenas de recuperación por error. La limpieza segura y la copia a un destino externo deben implementarse y probarse antes de producción. El volumen Docker no protege contra pérdida completa del equipo; la práctica 3-2-1 requiere copia fuera del host.

**Zona horaria:** los horarios se interpretan según la configuración del sistema de SQL Server. Si el contenedor usa UTC, 02:00 UTC equivale a las 20:00 del día anterior en El Salvador (UTC-6). Verificar `SELECT SYSDATETIME(),SYSUTCDATETIME();` y adaptar los jobs si se requieren 02:00 hora local.

## Ejecutar y evidenciar

1. Ejecutar `sql/10_Backup.sql` para crear procedimiento y un respaldo FULL.
2. Ejecutar `sql/11_Agent.sql`; verificar las 3 agendas en SSMS.
3. Ejecutar manualmente un diferencial y un log:
   ```sql
   USE GimnasioDB;
   EXEC mantenimiento.usp_RealizarBackup N'DIFF';
   EXEC mantenimiento.usp_RealizarBackup N'LOG';
   ```
4. Comprobar `sql/12_Pruebas.sql` (tablas `msdb.dbo.backupset` y `sysjobhistory`).
5. En **SSMS**, hacer clic derecho en SQL Server Agent → Jobs → iniciar job, revisar historial. Guardar imagen que muestre finalización correcta (no maqueta).
6. Ejecutar `RESTORE HEADERONLY` y `RESTORE VERIFYONLY` sobre un archivo real de FULL del volumen; para restauración ver `sql/13_Restauracion_DEMO.sql`.

## Secuencia de recuperación para un momento determinado

1. Elegir FULL anterior al fallo.
2. Elegir el último diferencial **basado en ese FULL**, si existe. Las fechas solas no garantizan pertenecer a la misma base diferencial: verificar `backupset.differential_base_lsn`/información de cadena.
3. Obtener todos los LOG consecutivos hasta el momento objetivo; no debe haber saltos en LSN. Si la base de origen aún está disponible, intentar tail-log backup antes de restaurar.
4. Restaurar FULL `WITH NORECOVERY`, luego DIFF `WITH NORECOVERY`, luego LOG en orden (`WITH NORECOVERY` excepto el último, que usa `WITH RECOVERY`).
5. Para recuperación puntual, `RESTORE LOG ... WITH STOPAT = ...` según disponibilidad de los registros.
6. Verificar integridad y conteo de socios, reservas, pagos y permiso de roles, y registrar tiempo transcurrido para comprobar RTO.

**No se crea una cadena de restauración ficticia:** cada ambiente tendrá nombres de archivos y LSN distintos. Tomar evidencia de una restauración real a `GimnasioDB_RestoreTest` para cumplir la defensa.
