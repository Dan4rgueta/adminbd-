# Optimización de consultas — GimnasioDB (Compañero A)

## 1. Volumen de datos de la prueba

Las pruebas se hicieron en una copia local de GimnasioDB, no en la base compartida. Se cargaron datos ficticios con `sql/Datos_Volumen_Rendimiento.sql`.

| Tabla | Filas |
|---|---|
| operacion.Socio | (completar) |
| operacion.Clase | (completar) |
| operacion.Sesion | (completar) |
| operacion.Reserva | (completar) |
| finanzas.Pago | (completar) |

Sesiones sin reservas activas: (completar).

## 2. Consultas (sql/Consultas_Avanzadas.sql)

| Consulta | Vista | Pregunta de negocio | Función de ventana |
|---|---|---|---|
| (a) | reportes.vw_RankingClases | ¿Qué clases tienen más reservas activas cada mes? | `DENSE_RANK() OVER (PARTITION BY Anio, Mes ORDER BY ReservasActivas DESC)` |
| (b) | reportes.vw_IngresosDiarios | ¿Cuánto se cobra por día y cuánto va acumulado? | `SUM(Ingresos) OVER (ORDER BY Fecha ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)` |
| (c) | reportes.vw_OcupacionSesiones | ¿La ocupación sube o baja respecto a la sesión anterior de la misma clase? | `LAG(OcupacionPct) OVER (PARTITION BY ClaseID ORDER BY FechaHoraInicio, SesionID)` |

Reglas: una reserva es activa solo si `FechaCancelacion IS NULL`; las sesiones sin reservas aparecen con 0.

## 3. Mediciones (sql/Indices_Optimizacion.sql)

Cada medición se hizo con `SET STATISTICS IO, TIME ON`, caché fría y los mismos datos y filtros antes y después.

### Consulta (a) Ranking de clases

- **Problema observado antes:** (operador principal y tabla, p. ej. Clustered Index Scan sobre operacion.Sesion; completar)
- **Índice aplicado:** `IX_Sesion_Clase_Inicio ON operacion.Sesion (ClaseID, FechaHoraInicio) INCLUDE (CupoMaximo)`
- **Justificación:** (por qué ese índice ayuda a esta consulta)

| Métrica | Antes | Después |
|---|---|---|
| Lecturas lógicas operacion.Sesion | | |
| Lecturas lógicas operacion.Reserva | | |
| CPU (ms) | | |
| Tiempo transcurrido (ms) | | |
| Operador principal | | |

- **Conclusión:** (mejoró o no, y por qué)

### Consulta (b) Ingresos diarios

- **Problema observado antes:** (completar)
- **Índice aplicado:** `IX_Pago_FechaPago ON finanzas.Pago (FechaPago) INCLUDE (Monto)`
- **Justificación:** (completar)

| Métrica | Antes | Después |
|---|---|---|
| Lecturas lógicas finanzas.Pago | | |
| CPU (ms) | | |
| Tiempo transcurrido (ms) | | |
| Operador principal | | |

- **Conclusión:** (completar)

### Consulta (c) Ocupación por sesión

- **Problema observado antes:** (completar)
- **Índice aplicado:** el mismo `IX_Sesion_Clase_Inicio`; las reservas activas ya las cubre `UX_Reserva_Activa`, que no se modificó.
- **Justificación:** el índice entrega las sesiones ya ordenadas por clase y fecha, que es lo que necesita `LAG` con `PARTITION BY ClaseID ORDER BY FechaHoraInicio`.

| Métrica | Antes | Después |
|---|---|---|
| Lecturas lógicas operacion.Sesion | | |
| Lecturas lógicas operacion.Reserva | | |
| CPU (ms) | | |
| Tiempo transcurrido (ms) | | |
| Operador principal (¿desaparece el Sort?) | | |

- **Conclusión:** (completar)

## 4. Índices conservados y descartados

| Índice | Conservado | Motivo |
|---|---|---|
| UX_Reserva_Activa (ya existía) | Sí | Evita reservas activas duplicadas; no se modificó |
| IX_Sesion_Clase_Inicio | (sí/no) | (según la medición) |
| IX_Pago_FechaPago | (sí/no) | (según la medición) |

## 5. Validación de resultados

| Comprobación | Vista | Consulta directa |
|---|---|---|
| Reservas activas totales | | |
| Ingresos totales | | |
| Sesiones totales | | |

Las canceladas no se cuentan como activas. Las cifras del dashboard coinciden con estas consultas (captura en `evidencias/CompA/`).

## 6. Evidencias

Capturas en `evidencias/CompA/`: resultados de las tres consultas, estadísticas y plan antes y después de cada una, y el dashboard completo.
