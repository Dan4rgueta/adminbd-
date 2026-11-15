# Dashboard real en Power BI Desktop (entregable `.pbix`)

## 1. Acceso SQL de solo lectura

En SSMS, abrir `powerbi/Crear_Login_Lectura.sql`, **cambiar la contraseña del texto de muestra**, ejecutar y no subir la copia con credenciales. El login `lector_powerbi` pertenece al rol `rol_analista`, que solo tiene `SELECT` al esquema `reportes`.

## 2. Importar las vistas

1. Power BI Desktop → Inicio → Obtener datos → SQL Server.
2. **Servidor:** `localhost,14333` (o el puerto real de `.env`); **Base de datos:** `GimnasioDB`.
3. Seleccionar **Importar** (más sencillo para la defensa); usar autenticación **Base de datos**, usuario `lector_powerbi` y contraseña definida en SSMS. Ajustar confianza de certificado solo para el entorno de laboratorio si Power BI lo solicita.
4. En el Navegador seleccionar `reportes.vw_RankingClases`, `reportes.vw_IngresosDiarios`, `reportes.vw_OcupacionSesiones` y `reportes.vw_Indicadores`. **Cargar**.
5. Renombrar las tablas de Power BI: `RankingClases`, `IngresosDiarios`, `OcupacionSesiones`, `Indicadores` (sin `vw_`).
6. Revisar tipos de datos: fechas como Fecha/FechaHora; Monto y ocupación como número decimal; reservaciones como número entero.

## 3. Medidas y tres vistas útiles

Crear las medidas de `MEDIDAS_DAX.txt` **una por una** (Modelado → Nueva medida). Usar formato moneda USD para ingresos; porcentaje para ocupación ponderada.

**Página 1 · Resumen**
- Tarjetas: ingresos totales, reservas activas, socios activos, ocupación ponderada %.
- Gráfico de columnas: eje `RankingClases[Clase]`, valor `[Reservas activas]` (mostrar top clases).
- Segmentadores: `RankingClases[Anio]`, `RankingClases[Mes]` (estos afectan únicamente visuales provenientes de ranking; para las tarjetas globales manejar filtros de forma explícita).

**Página 2 · Finanzas**
- Gráfico de líneas: eje `IngresosDiarios[Fecha]`, valor `IngresosDiarios[IngresosAcumulados]`.
- Gráfico de columnas: eje `IngresosDiarios[Fecha]`, valor `IngresosDiarios[Ingresos]`.
- Tarjetas: ingresos totales, número de pagos, ticket promedio.
- Segmentador de fecha, conectado a `IngresosDiarios[Fecha]`.

**Página 3 · Ocupación**
- Barras: eje `OcupacionSesiones[Clase]`, valor `[Ocupación ponderada %]` (formato porcentaje).
- Tabla: `Clase`, `FechaHoraInicio`, `ReservasActivas`, `CupoMaximo`, `OcupacionPct`, `VariacionPuntos`.
- Tarjeta: sesiones programadas; segmentador `OcupacionSesiones[Clase]`.

**Importante:** la columna `OcupacionPct` es 0-100, mientras que la medida `[Ocupación ponderada %]` es 0-1. Dar formato porcentaje **solo a la medida**. No sumes `IngresosAcumulados` entre días. Las vistas no comparten una tabla calendario relacionada en esta versión, por tanto los filtros de una página no cruzan automáticamente todas las tablas.

## 4. Presentación y entrega

1. Ver → Temas → Examinar temas: importar `powerbi/tema_gimnasio.json`.
2. Titular las páginas, agregar filtros, mostrar unidades ($ y %) y agregar una caja de texto explicando si se trata de datos ficticios. Agregar tarjeta de fecha de actualización.
3. Guardar como **`powerbi/GimnasioDB_Dashboard.pbix`**.
4. Tomar evidencia del panel y del Navegador SQL con las cuatro vistas; guardar las capturas en `evidencias/nuevas/`.
5. Probar **Actualizar**, cerrar y volver a abrir el `.pbix`, confirmar que los datos corresponden a las consultas de `sql/12_Pruebas.sql` bajo los mismos filtros.

## 5. Qué se entrega con el informe

El PDF solicita archivo `.pbix` y al menos tres visualizaciones significativas. La maqueta adjunta **no** es un `.pbix`, y las medidas DAX no lo reemplazan. Deben crear el archivo real en Power BI Desktop y tomar su propia captura; no afirmar en defensa que ya está construido hasta ese momento.
