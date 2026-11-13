# Diccionario de datos — GimnasioDB

PK = clave primaria. FK = clave foránea. IDENTITY(1,1) = identificador generado por SQL Server, con inicio en 1 e incremento de 1.

## operacion.Socio

Registra a los socios del gimnasio.

| Columna | Tipo | Admite NULL | Descripción y reglas |
|---|---|---|---|
| SocioID | INT | No | PK, IDENTITY(1,1). Identifica al socio. |
| Nombres | NVARCHAR(100) | No | Nombres del socio. |
| Apellidos | NVARCHAR(100) | No | Apellidos del socio. |
| Correo | NVARCHAR(254) | No | Correo del socio. Debe ser único en esta tabla. |
| FechaRegistro | DATE | No | Fecha de alta. Por defecto toma la fecha del servidor. |
| Activo | BIT | No | 1 indica activo y 0 inactivo. Por defecto vale 1. |

## operacion.Entrenador

Registra a los entrenadores que pueden asignarse a las sesiones.

| Columna | Tipo | Admite NULL | Descripción y reglas |
|---|---|---|---|
| EntrenadorID | INT | No | PK, IDENTITY(1,1). Identifica al entrenador. |
| Nombres | NVARCHAR(100) | No | Nombres del entrenador. |
| Apellidos | NVARCHAR(100) | No | Apellidos del entrenador. |
| Correo | NVARCHAR(254) | No | Correo del entrenador. Debe ser único en esta tabla. |
| Activo | BIT | No | 1 indica activo y 0 inactivo. Por defecto vale 1. |

## operacion.Clase

Define los tipos de clase que ofrece el gimnasio, como Spinning, Yoga y Zumba.

| Columna | Tipo | Admite NULL | Descripción y reglas |
|---|---|---|---|
| ClaseID | INT | No | PK, IDENTITY(1,1). Identifica el tipo de clase. |
| Nombre | NVARCHAR(100) | No | Nombre de la clase. Debe ser único. |
| Descripcion | NVARCHAR(300) | Sí | Descripción opcional de la actividad. |
| Activa | BIT | No | 1 indica activa y 0 inactiva. Por defecto vale 1. |

## operacion.Sesion

Programa una clase para una fecha y hora, con un entrenador y un cupo máximo.

| Columna | Tipo | Admite NULL | Descripción y reglas |
|---|---|---|---|
| SesionID | INT | No | PK, IDENTITY(1,1). Identifica la sesión programada. |
| ClaseID | INT | No | FK a operacion.Clase(ClaseID). Indica qué clase se imparte. |
| EntrenadorID | INT | No | FK a operacion.Entrenador(EntrenadorID). Indica quién imparte la sesión. |
| FechaHoraInicio | DATETIME2(0) | No | Fecha y hora de inicio. |
| FechaHoraFin | DATETIME2(0) | No | Fecha y hora de finalización. Debe ser posterior al inicio. |
| CupoMaximo | INT | No | Cantidad máxima de reservas activas. Debe ser mayor que cero. |

## operacion.Reserva

Vincula a un socio con una sesión y conserva el historial de cancelaciones.

| Columna | Tipo | Admite NULL | Descripción y reglas |
|---|---|---|---|
| ReservaID | INT | No | PK, IDENTITY(1,1). Identifica la reserva. |
| SocioID | INT | No | FK a operacion.Socio(SocioID). Indica quién reservó. |
| SesionID | INT | No | FK a operacion.Sesion(SesionID). Indica qué sesión reservó. |
| FechaReserva | DATETIME2(0) | No | Momento del registro. Por defecto toma la fecha y hora del servidor. |
| FechaCancelacion | DATETIME2(0) | Sí | NULL indica que la reserva sigue activa. Si se cancela, la fecha debe ser igual o posterior a FechaReserva. |

El índice único filtrado UX_Reserva_Activa permite una sola reserva activa por socio y sesión. El procedimiento operacion.RegistrarReserva comprueba que el socio esté activo y que queden cupos antes de registrar la reserva.

## finanzas.Pago

Registra los pagos recibidos de cada socio.

| Columna | Tipo | Admite NULL | Descripción y reglas |
|---|---|---|---|
| PagoID | INT | No | PK, IDENTITY(1,1). Identifica el pago. |
| SocioID | INT | No | FK a operacion.Socio(SocioID). Identifica al socio que pagó. |
| Monto | DECIMAL(10,2) | No | Importe en dólares, con dos decimales. Debe ser mayor que cero. |
| FechaPago | DATETIME2(0) | No | Momento del pago. Por defecto toma la fecha y hora del servidor. |

## Tabla auxiliar de importación

dbo.SocioImportacion recibe las columnas Nombres, Apellidos y Correo del CSV. Se utiliza para revisar los datos antes de cargarlos en operacion.Socio.
