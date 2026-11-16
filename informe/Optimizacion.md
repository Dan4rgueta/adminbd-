# Optimización de consultas de GimnasioDB

## Entorno y método

La prueba del 15 de noviembre de 2026 se ejecutó en `GimnasioDB_Rendimiento`, una base de pruebas con el modelo del gimnasio y datos ficticios. Se cargaron 3,000 socios, 5 clases, 10,000 sesiones, 84,812 reservas y 60,000 pagos. De las 10,000 sesiones, 1,144 tenían cero reservas activas.

Las vistas se crearon con una copia de [07_Consultas.sql](../sql/07_Consultas.sql). Para reproducir la medición, se usa una copia de [Pruebas_Rendimiento.sql](../sql/Pruebas_Rendimiento.sql) cuyo `USE` apunta a `GimnasioDB_Rendimiento`. El script ejecuta las mismas tres consultas antes y después de crear dos índices. Conserva el índice único de reservas activas durante toda la prueba.

Se registró una ejecución por consulta en cada condición con `SET STATISTICS IO ON` y `SET STATISTICS TIME ON`. Los tiempos de la comparación corresponden a la ejecución de los SELECT. La compilación y la creación de los índices se midieron por separado. El script no vacía la caché.

## Consultas evaluadas

| Vista del esquema reportes | Pregunta | Función de ventana |
|---|---|---|
| vw_RankingClases | ¿Qué clases tienen más reservas activas cada mes? | DENSE_RANK clasifica por reservas dentro de cada mes y asigna la misma posición a los empates. |
| vw_IngresosDiarios | ¿Cuánto se cobró cada día y cuánto se llevaba acumulado? | SUM con OVER acumula el ingreso diario en orden de fecha. |
| vw_OcupacionSesiones | ¿Cómo cambia la ocupación respecto a la sesión anterior de la misma clase? | LAG obtiene la ocupación anterior dentro de cada clase. |

## Resultados

Las lecturas lógicas representan accesos a páginas de datos en memoria. Los totales suman las lecturas de las tablas utilizadas por cada consulta. Las estructuras de trabajo reportaron cero lecturas lógicas.

| Consulta | Filas antes y después | Lecturas antes | Lecturas después | CPU antes (ms) | CPU después (ms) | Tiempo antes (ms) | Tiempo después (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|
| Ranking | 65 | 399 | 388 | 66 | 58 | 66 | 57 |
| Ingresos | 365 | 240 | 194 | 43 | 29 | 43 | 29 |
| Ocupación | 10,000 | 399 | 388 | 62 | 60 | 65 | 64 |

**Ranking.** Las lecturas de Sesion bajaron de 48 a 37. Clase registró 2 y Reserva registró 349 en ambas ejecuciones. Esto explica la reducción de 11 lecturas totales (2.8 %). El tiempo bajó 9 ms en esta corrida.

**Ingresos.** La consulta leyó 46 páginas lógicas menos de Pago, una reducción del 19.2 %. El tiempo bajó 14 ms. Fue la mayor reducción de lecturas entre las tres consultas.

**Ocupación.** Las lecturas de Sesion bajaron de 48 a 37. Reserva concentró 349 lecturas y Clase registró 2 en ambas ejecuciones. El tiempo pasó de 65 a 64 ms. Con una ejecución por condición, esa diferencia de 1 ms es insuficiente para afirmar una mejora consistente de tiempo.

## Índices evaluados

| Índice | Diseño y decisión |
|---|---|
| IX_Pago_FechaPago | Clave FechaPago e inclusión de Monto. Reúne las columnas necesarias para agrupar y sumar pagos. Se justifica conservarlo para este reporte por la reducción observada en las lecturas de Pago. |
| IX_Sesion_Clase_Inicio | Claves ClaseID y FechaHoraInicio e inclusión de CupoMaximo y EntrenadorID. Se conserva en la base de pruebas por la reducción observada en las lecturas de Sesion. Su beneficio sobre el tiempo de Ocupación fue pequeño. |
| UX_Reserva_Activa | Se conservó en ambas condiciones para impedir reservas activas duplicadas. |

## Evidencia y validación

[Salida completa de SSMS con las estadísticas antes y después](../evidencias/Rendimiento_Antes_Despues.txt).

Las tres consultas mantuvieron el mismo número de filas antes y después de crear los índices. Al comparar las vistas con las tablas de origen se obtuvieron 72,698 reservas activas, USD 2,175,000.00 en ingresos y 10,000 sesiones. El último ingreso acumulado coincide con el total y la vista incluye 1,144 sesiones sin reservas activas. [Resultados de la validación en SSMS](../evidencias/Validacion_Vistas_Rendimiento.png).

El dashboard mostró esos totales redondeados en las tarjetas de Resumen. [Captura de Power BI](../evidencias/PowerBI_Resumen.png).

Queda pendiente adjuntar los planes de ejecución reales para identificar los operadores de cada consulta antes y después de crear los índices.
