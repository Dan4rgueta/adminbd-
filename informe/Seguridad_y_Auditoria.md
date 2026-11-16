# Seguridad y auditoría de GimnasioDB

## Organización y permisos

Los datos operativos y financieros se organizan en dos esquemas. `operacion` agrupa socios, entrenadores, clases, sesiones y reservas. `finanzas` contiene los pagos. Esta separación facilita identificar qué objetos necesita cada área y mantener sus permisos según la función del personal.

| Rol | Usuario de prueba | Permisos asignados |
|---|---|---|
| `rol_recepcion` | `usuario_recepcion` | Consulta y registra socios. Consulta clases, sesiones y reservas, y puede leer el identificador, nombres y apellidos de los entrenadores. Registra y cancela reservas mediante los procedimientos `operacion.RegistrarReserva` y `operacion.CancelarReserva`. |
| `rol_finanzas` | `usuario_finanzas` | Consulta `finanzas.Pago` y registra pagos mediante `finanzas.RegistrarPago`. De los socios puede consultar únicamente `SocioID`, `Nombres` y `Apellidos` para identificar a quien realiza el pago. |
| `rol_entrenador` | `usuario_entrenador` | El script de seguridad concede lectura de clases y sesiones. |
| `rol_analista` | `usuario_analista` | El script de seguridad concede lectura del esquema `reportes`. |

Se aplicó el principio de mínimo privilegio. Por ejemplo, recepción registra una reserva mediante un procedimiento que valida el cupo y comprueba que el socio esté activo. Para comprobar los permisos de recepción y finanzas se crearon usuarios de prueba con `WITHOUT LOGIN` y se ejecutaron consultas bajo la identidad de cada uno mediante `EXECUTE AS USER`.

## Auditoría de pagos

La auditoría del servidor `Auditoria_Gimnasio` escribe los eventos en `/var/opt/mssql/log/`. En `GimnasioDB`, la especificación `Auditoria_Pagos` registra las acciones `SELECT`, `INSERT`, `UPDATE` y `DELETE` sobre `finanzas.Pago`, y `EXECUTE` sobre `finanzas.RegistrarPago` para todos los usuarios de la base. Los eventos se consultaron con `sys.fn_get_audit_file`.

### Prueba 1. Consulta de pagos

Se ejecutó la misma consulta sobre `finanzas.Pago` con ambos usuarios. El registro muestra que SQL Server permitió el acceso a `usuario_finanzas` y se lo denegó a `usuario_recepcion`. Cada fila identifica al usuario, la hora UTC, el objeto consultado y el resultado de la comprobación del permiso.

![Consulta de pagos permitida a finanzas y denegada a recepción](../evidencias/Auditoria_Accesos_Pagos.png)

### Prueba 2. Registro de un pago mediante el procedimiento

Se ejecutó `finanzas.RegistrarPago` como `usuario_finanzas` con un monto de $1.00. El procedimiento devolvió el identificador 3 y la transacción de prueba se revirtió con `ROLLBACK`. La consulta del archivo de auditoría mostró el evento `EX` para el procedimiento, con permiso concedido.

![Pago de prueba registrado y revertido](../evidencias/RegistrarPago_Procedimiento.png)

![Ejecución del procedimiento registrada en la auditoría](../evidencias/Auditoria_Execute_RegistrarPago.png)

### Prueba 3. Intento de inserción directa

El mismo usuario intentó insertar una fila directamente en `finanzas.Pago`. SQL Server devolvió el error 229. Así se comprueba que las altas de pagos de finanzas pasan por el procedimiento que valida el monto y la existencia del socio.

![Inserción directa denegada al usuario de finanzas](../evidencias/RegistrarPago_Insert_Denegado.png)

