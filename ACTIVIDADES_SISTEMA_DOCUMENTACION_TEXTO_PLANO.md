# Sistema de Actividades Educativas - Macondo Vivo
## Documentación Detallada en Texto Plano

---

## INTRODUCCIÓN

El sistema de actividades educativas de Macondo Vivo es una plataforma completa que permite crear, gestionar y participar en actividades educativas con múltiples sesiones. El sistema funciona como un ecosistema donde diferentes tipos de usuarios tienen roles específicos y permisos diferenciados.

---

## PÁGINA PRINCIPAL DE ACTIVIDADES

### Cómo se ve la página al entrar

Cuando un usuario accede a la página de actividades, ve una interfaz limpia y organizada. En la parte superior hay un título grande que dice "Actividades Educativas" y, dependiendo del rol del usuario, puede aparecer un botón azul con un ícono de "+" que dice "Nueva Actividad". Este botón solo aparece para usuarios ADMIN y SuperUser.

Debajo del título hay una barra de búsqueda que permite buscar actividades por título o descripción. A la derecha de la búsqueda hay dos botones: uno que dice "Filtros" y otro que dice "Calendario". El botón de calendario abre una vista de calendario donde se pueden ver todas las actividades organizadas por fecha.

### Sistema de pestañas

La página tiene cinco pestañas principales:

1. **"Todas"** - Muestra todas las actividades que el usuario puede ver según sus permisos
2. **"Mis Actividades"** - Muestra solo las actividades donde el usuario está asignado como participante o responsable
3. **"Activas"** - Muestra solo las actividades que están en estado activo
4. **"Completadas"** - Muestra las actividades que han sido completadas al 100%
5. **"Inactivas"** - Muestra las actividades que han sido canceladas

En la pestaña "Mis Actividades" aparece un número entre paréntesis que indica cuántas actividades tiene asignadas el usuario.

### Mensajes informativos

Dependiendo del rol del usuario y la pestaña seleccionada, aparecen mensajes informativos:

- Si el usuario es de tipo USER y está en la pestaña "Todas", aparece un mensaje azul que dice: "💡 Información de privacidad: Solo puedes ver los detalles de actividades donde estés asignado como participante o responsable."

- Si el usuario está en la pestaña "Mis Actividades", aparece un mensaje verde que dice: "👤 Mis Actividades: Mostrando X como participante y Y como responsable."

### Tarjetas de actividades

Las actividades se muestran en tarjetas rectangulares organizadas en una cuadrícula. En pantallas grandes aparecen 3 tarjetas por fila, en tablets 2, y en móviles 1.

Cada tarjeta tiene:

**Parte superior:**
- Un chip de color que indica el estado de la actividad (naranja para activa, verde para completada, gris para inactiva)
- Un chip adicional que muestra la categoría de la actividad (si tiene una)
- Un botón de tres puntos verticales para acceder a más opciones

**Parte central:**
- El título de la actividad en letras grandes y negritas
- La descripción de la actividad (limitada a 3 líneas)
- Si hay una próxima sesión programada, aparece la fecha y hora
- Una sección que muestra los responsables de la actividad con chips azules
- Información sobre participantes y sesiones completadas
- Duración estimada de la actividad

**Parte inferior:**
- Una barra de progreso que muestra el porcentaje de completación
- El porcentaje escrito en números
- Botones de acción según el estado y permisos del usuario

### Estados visuales de las tarjetas

Las tarjetas tienen diferentes colores en el borde izquierdo según el estado:
- **Naranja** para actividades activas
- **Verde** para actividades completadas  
- **Gris** para actividades inactivas

Cuando el usuario pasa el mouse sobre una tarjeta, esta se eleva ligeramente y se agranda un poco, creando un efecto de profundidad.

---

## CREACIÓN DE ACTIVIDADES

### Quién puede crear actividades

Solo los usuarios con rol ADMIN o SuperUser pueden crear actividades. Los usuarios normales (USER) no ven el botón "Nueva Actividad".

### Proceso de creación

Al hacer clic en "Nueva Actividad" se abre un formulario modal grande que cubre la pantalla. El formulario tiene varias secciones:

**Información básica:**
- Campo de título (obligatorio)
- Campo de descripción (obligatorio, soporta formato HTML)
- Selector de categoría (opcional)
- Campo de duración estimada en minutos
- Campo de enlace para entregas (opcional)

**Sesiones:**
- Selector de número de sesiones (mínimo 1)
- Para cada sesión se puede configurar:
  - Fecha de la sesión
  - Hora de inicio
  - Hora de fin
  - Ubicación (opcional)

**Materiales y objetivos:**
- Lista de materiales necesarios (se pueden agregar y quitar)
- Lista de objetivos de aprendizaje (se pueden agregar y quitar)

**Asignación de usuarios:**
- Sección para seleccionar responsables (usuarios que pueden aprobar)
- Sección para seleccionar participantes (usuarios que deben completar las sesiones)

### Validaciones del formulario

El sistema valida que:
- El título no esté vacío
- La descripción no esté vacía
- El número de sesiones sea al menos 1
- Cada sesión tenga fecha, hora de inicio y hora de fin
- Al menos un usuario esté asignado como responsable o participante

Si hay errores, aparecen mensajes en rojo debajo de los campos correspondientes.

### Qué sucede al crear una actividad

Cuando se envía el formulario:
1. Se validan todos los campos
2. Se crea un documento en la base de datos Firestore
3. Se asigna automáticamente el estado "ACTIVA"
4. Se registra el usuario creador
5. Se cierra el modal
6. Aparece un mensaje verde de confirmación
7. La lista de actividades se actualiza automáticamente

---

## SISTEMA DE PARTICIPACIÓN Y COMPLETACIÓN

### Cómo funciona el sistema de sesiones

Cada actividad puede tener múltiples sesiones. Los participantes deben completar cada sesión en orden secuencial. No pueden saltar sesiones ni completar la sesión 3 sin haber completado la 1 y 2.

### Estados de completación

Hay tres estados posibles para una completación de sesión:

1. **PENDING_APPROVAL** - El participante envió su completación pero espera que un responsable la apruebe
2. **APPROVED** - Un responsable aprobó la completación del participante
3. **COMPLETED** - La sesión fue completada directamente (solo para responsables)

### Proceso para participantes

Cuando un participante ve una actividad asignada:

1. **Ve el botón "Enviar Sesión X/Y"** - Donde X es el número de la próxima sesión a completar e Y es el total de sesiones
2. **Hace clic en el botón** - Se abre un diálogo de confirmación
3. **Confirma la acción** - Se envía la completación con estado PENDING_APPROVAL
4. **Aparece un mensaje** - "Sesión enviada para revisión"
5. **El botón cambia** - Ahora dice "🔒 Sesión no disponible aún" o desaparece

### Proceso para responsables

Los responsables tienen dos funciones:

**Aprobar sesiones de participantes:**
1. Ven las completaciones pendientes en el diálogo de detalles
2. Hacen clic en "Aprobar" junto a cada completación
3. La completación cambia a estado APPROVED
4. Se actualiza el progreso de la actividad

**Completar sus propias sesiones:**
1. Ven el botón "Completar Sesión X/Y"
2. Solo pueden completar si todos los participantes han enviado y sido aprobados
3. Al completar, su sesión va directamente a estado COMPLETED

### Validaciones del sistema

El sistema impide que:

- Un participante complete una sesión sin haber completado las anteriores
- Un participante complete una sesión que ya completó
- Un participante complete una sesión después de la fecha límite
- Un responsable complete su sesión sin que todos los participantes hayan enviado la suya
- Un responsable complete su sesión sin haber aprobado todas las completaciones pendientes

### Mensajes de error comunes

- "Ya has completado esta sesión"
- "Debes completar las sesiones anteriores primero"
- "La fecha límite para completar esta sesión ha pasado"
- "Tienes sesiones pendientes de aprobación. Espera a que un responsable las revise."
- "No puedes completar esta sesión hasta que todos los participantes hayan enviado su parte"
- "Debes aprobar todas las completaciones de los participantes antes de completar tu sesión"

---

## SISTEMA DE APROBACIÓN

### Cómo funciona la aprobación

Los responsables son usuarios especiales que pueden aprobar las completaciones de los participantes. Solo los usuarios asignados como "responsables" en una actividad pueden aprobar.

### Proceso de aprobación

1. **El responsable abre los detalles de la actividad**
2. **Ve una sección llamada "Completaciones Pendientes"**
3. **Para cada completación pendiente ve:**
   - Nombre del participante
   - Número de sesión
   - Fecha y hora de envío
   - Botón "Aprobar"
4. **Hace clic en "Aprobar"**
5. **Aparece un mensaje de confirmación**
6. **La completación cambia a estado APPROVED**
7. **Se actualiza el progreso total de la actividad**

### Validaciones de aprobación

El sistema verifica que:
- Quien aprueba sea realmente un responsable de la actividad
- La completación esté en estado PENDING_APPROVAL
- El participante esté asignado a la actividad

### Qué sucede después de aprobar

Cuando se aprueba una completación:
1. Se actualiza el estado a APPROVED
2. Se registra quién aprobó y cuándo
3. Se recalcula el progreso total de la actividad
4. Si todas las sesiones están completadas, la actividad cambia a estado COMPLETADA
5. Se muestra un mensaje de éxito

---

## CÁLCULO DE PROGRESO

### Cómo se calcula el progreso

El progreso se calcula SOLO considerando a los PARTICIPANTES, no a los responsables. Los responsables aprueban, no necesitan completar sus propias sesiones.

**Fórmula:**
```
Progreso = (Sesiones completadas por participantes / Total de sesiones requeridas) × 100
```

**Ejemplo:**
- Actividad con 3 sesiones
- 2 participantes
- Total requerido: 2 participantes × 3 sesiones = 6 completaciones
- Si hay 4 completaciones aprobadas: (4/6) × 100 = 66.67%

### Estados de progreso

- **0-99%** - Actividad en progreso
- **100%** - Actividad completada (cambia automáticamente a estado COMPLETADA)

### Visualización del progreso

En cada tarjeta de actividad aparece:
- Una barra de progreso horizontal
- El porcentaje escrito en números
- Información detallada: "X usuarios • Y sesiones • Z/W completadas"

---

## GESTIÓN DE ACTIVIDADES

### Menú de acciones

Cada tarjeta de actividad tiene un botón de tres puntos verticales que abre un menú con opciones según los permisos del usuario:

**Para SuperUser:**
- Editar
- Cancelar Actividad (si está activa)
- Reactivar Actividad (si está inactiva)
- Eliminar

**Para ADMIN (solo en actividades que creó):**
- Editar
- Cancelar Actividad (si está activa)
- Reactivar Actividad (si está inactiva)
- Eliminar

**Para USER:**
- No aparece menú de acciones

### Cambio de estados

**Cancelar actividad:**
- Solo ADMIN y SuperUser pueden cancelar
- Cambia el estado de ACTIVA a INACTIVA
- Los usuarios normales ya no pueden ver actividades inactivas
- Aparece mensaje de confirmación

**Reactivar actividad:**
- Solo ADMIN y SuperUser pueden reactivar
- Cambia el estado de INACTIVA a ACTIVA
- Los usuarios pueden volver a ver la actividad
- Aparece mensaje de confirmación

**Eliminar actividad:**
- Solo SuperUser y ADMIN (en actividades propias) pueden eliminar
- Se elimina permanentemente de la base de datos
- Aparece diálogo de confirmación
- No se puede deshacer

### Edición de actividades

Al editar una actividad:
1. Se abre el mismo formulario que para crear
2. Los campos vienen pre-llenados con los datos actuales
3. Se pueden modificar todos los campos
4. Al guardar se actualiza la actividad
5. Aparece mensaje de confirmación

---

## DIÁLOGO DE DETALLES

### Cómo acceder

Al hacer clic en una tarjeta de actividad se abre un diálogo grande que muestra todos los detalles de la actividad.

### Información mostrada

**Encabezado:**
- Título de la actividad
- Estado con chip de color
- Categoría (si tiene)
- Botón de cerrar

**Información general:**
- Descripción completa
- Duración estimada
- Enlace para entregas (si tiene)
- Materiales necesarios
- Objetivos de aprendizaje

**Sesiones:**
- Lista de todas las sesiones con:
  - Número de sesión
  - Fecha
  - Hora de inicio y fin
  - Ubicación
  - Estado (pendiente, activa, completada)

**Participantes:**
- Lista de participantes con:
  - Nombre completo
  - Progreso individual
  - Estado de cada sesión

**Responsables:**
- Lista de responsables con:
  - Nombre completo
  - Funciones disponibles

**Completaciones pendientes (solo para responsables):**
- Lista de completaciones que requieren aprobación
- Botón de aprobar para cada una

### Acciones disponibles

Según el rol del usuario y su asignación a la actividad:

**Para participantes:**
- Botón para completar próxima sesión
- Ver progreso personal

**Para responsables:**
- Botones para aprobar completaciones pendientes
- Botón para completar su propia sesión
- Ver progreso de todos los participantes

**Para SuperUser:**
- Botones de edición y gestión
- Acceso completo a toda la información

---

## SISTEMA DE NOTIFICACIONES

### Tipos de mensajes

**Mensajes de éxito (verde):**
- "Actividad creada exitosamente"
- "Actividad actualizada exitosamente"
- "Sesión completada exitosamente"
- "Sesión aprobada exitosamente"

**Mensajes de error (rojo):**
- "Error al crear la actividad"
- "No tienes permisos para completar esta actividad"
- "Ya has completado esta sesión"
- "La fecha límite ha pasado"

**Mensajes informativos (azul):**
- "Información de privacidad: Solo puedes ver actividades asignadas"
- "Mis Actividades: Mostrando X como participante y Y como responsable"

**Mensajes de advertencia (naranja):**
- "Tienes sesiones pendientes de aprobación"
- "Debes completar las sesiones anteriores primero"

### Dónde aparecen los mensajes

Los mensajes aparecen en la parte superior de la pantalla como "toasts" que se desvanecen automáticamente después de 6 segundos. El usuario puede cerrarlos manualmente haciendo clic en la X.

---

## BÚSQUEDA Y FILTRADO

### Búsqueda por texto

El campo de búsqueda permite buscar actividades por:
- Título de la actividad
- Descripción de la actividad
- Categoría de la actividad

La búsqueda es en tiempo real y filtra las actividades mientras el usuario escribe.

### Filtros por pestañas

Cada pestaña actúa como un filtro:
- **Todas**: Muestra todas las actividades visibles
- **Mis Actividades**: Solo actividades donde el usuario está asignado
- **Activas**: Solo actividades con estado ACTIVA
- **Completadas**: Solo actividades con estado COMPLETADA
- **Inactivas**: Solo actividades con estado INACTIVA

### Vista de calendario

El botón "Calendario" abre una vista de calendario donde:
- Las actividades se muestran en sus fechas correspondientes
- Se puede hacer clic en una actividad para ver sus detalles
- Se puede navegar entre meses
- Las actividades se muestran con colores según su estado

---

## PERMISOS Y RESTRICCIONES

### Por rol de usuario

**SuperUser:**
- Puede crear, editar, eliminar cualquier actividad
- Puede ver todas las actividades
- Puede cambiar estados de cualquier actividad
- Acceso completo a todas las funciones

**ADMIN:**
- Puede crear actividades
- Puede editar solo las actividades que creó
- Puede eliminar solo las actividades que creó
- Puede ver todas las actividades activas y completadas
- Puede ver actividades inactivas solo si las creó

**USER:**
- No puede crear actividades
- Solo puede ver actividades donde está asignado
- Puede completar sesiones de actividades asignadas
- Puede aprobar si es responsable

### Por estado de actividad

**Actividades ACTIVAS:**
- Todos los usuarios pueden ver si están asignados
- Los participantes pueden completar sesiones
- Los responsables pueden aprobar

**Actividades COMPLETADAS:**
- Todos los usuarios pueden ver si están asignados
- No se pueden completar más sesiones
- Solo se puede ver el historial

**Actividades INACTIVAS:**
- Solo SuperUser y ADMIN (creador) pueden ver
- No se pueden completar sesiones
- No se pueden aprobar completaciones

---

## FLUJOS COMPLETOS DE USUARIO

### Flujo 1: ADMIN crea una actividad

1. ADMIN hace clic en "Nueva Actividad"
2. Llena el formulario con título, descripción, sesiones
3. Asigna participantes y responsables
4. Guarda la actividad
5. Aparece mensaje "Actividad creada exitosamente"
6. La actividad aparece en la lista con estado ACTIVA
7. Los participantes y responsables reciben la actividad asignada

### Flujo 2: Participante completa una sesión

1. Participante ve la actividad en "Mis Actividades"
2. Ve el botón "Enviar Sesión 1/3" (ejemplo)
3. Hace clic en el botón
4. Aparece diálogo de confirmación
5. Confirma la acción
6. Aparece mensaje "Sesión enviada para revisión"
7. El botón cambia a "🔒 Sesión no disponible aún"
8. La completación aparece como PENDING_APPROVAL para los responsables

### Flujo 3: Responsable aprueba una sesión

1. Responsable abre los detalles de la actividad
2. Ve la sección "Completaciones Pendientes"
3. Ve la completación del participante
4. Hace clic en "Aprobar"
5. Aparece mensaje "Sesión aprobada exitosamente"
6. La completación cambia a estado APPROVED
7. El progreso de la actividad se actualiza
8. Si todas las sesiones están completadas, la actividad cambia a COMPLETADA

### Flujo 4: Responsable completa su sesión

1. Responsable ve que todos los participantes han enviado y sido aprobados
2. Ve el botón "Completar Sesión 1/3"
3. Hace clic en el botón
4. Confirma la acción
5. Su sesión va directamente a estado COMPLETED
6. El progreso se actualiza
7. Si es la última sesión, la actividad se marca como COMPLETADA

### Flujo 5: ADMIN gestiona una actividad

1. ADMIN ve sus actividades creadas
2. Abre el menú de acciones (tres puntos)
3. Selecciona "Editar"
4. Modifica los campos necesarios
5. Guarda los cambios
6. Aparece mensaje "Actividad actualizada exitosamente"
7. Los cambios se reflejan inmediatamente

---

## CASOS ESPECIALES Y EXCEPCIONES

### Actividades sin participantes

Si una actividad solo tiene responsables y no participantes:
- El progreso se considera 100% desde el inicio
- Los responsables pueden completar sus sesiones directamente
- La actividad se marca como COMPLETADA cuando todos los responsables completan

### Actividades con una sola sesión

Las actividades de una sola sesión funcionan igual que las de múltiples sesiones:
- Los participantes deben enviar su completación
- Los responsables deben aprobar
- Los responsables completan su sesión
- La actividad se marca como COMPLETADA

### Usuarios con múltiples roles

Si un usuario es tanto participante como responsable:
- Puede enviar sus completaciones como participante
- Puede aprobar otras completaciones como responsable
- Puede completar su sesión como responsable
- Ve ambas funcionalidades en la interfaz

### Fechas límite

Cada sesión tiene una fecha límite:
- Los usuarios no pueden completar sesiones después de la fecha límite
- Aparece mensaje de error si intentan completar tarde
- Las fechas límite se muestran en la interfaz
- El sistema valida automáticamente las fechas

### Actividades canceladas

Cuando una actividad se cancela:
- Cambia a estado INACTIVA
- Los usuarios normales ya no pueden verla
- No se pueden completar más sesiones
- Solo SuperUser y el ADMIN creador pueden verla
- Se puede reactivar si es necesario

---

## INTERFAZ RESPONSIVA

### En pantallas grandes (desktop)

- 3 tarjetas de actividades por fila
- Formularios en modales grandes
- Menús desplegables completos
- Todas las opciones visibles

### En tablets

- 2 tarjetas de actividades por fila
- Formularios adaptados al tamaño
- Menús simplificados
- Botones más grandes para toque

### En móviles

- 1 tarjeta de actividad por fila
- Formularios en pantalla completa
- Menús de hamburguesa
- Botones optimizados para toque
- Navegación por gestos

---

## INTEGRACIÓN CON FIREBASE

### Base de datos Firestore

Las actividades se almacenan en la colección "activities" con la siguiente estructura:
- Cada documento representa una actividad
- El ID del documento es el activityId
- Los campos incluyen toda la información de la actividad
- Las completaciones se almacenan como arrays dentro del documento

### Autenticación

El sistema usa Firebase Auth para:
- Verificar la identidad del usuario
- Obtener el rol y permisos
- Validar tokens en las API
- Mantener sesiones seguras

### Reglas de seguridad

Firestore tiene reglas que:
- Permiten lectura a usuarios autenticados
- Restringen creación solo a ADMIN y SuperUser
- Restringen edición según el rol y propiedad
- Protegen contra acceso no autorizado

---

## RENDIMIENTO Y OPTIMIZACIÓN

### Carga de datos

- Las actividades se cargan una vez al entrar a la página
- Se cachean en el estado de React
- Se actualizan solo cuando es necesario
- La búsqueda y filtrado es instantáneo

### Actualizaciones en tiempo real

- Los cambios se reflejan inmediatamente en la interfaz
- No es necesario recargar la página
- Los mensajes de confirmación aparecen rápidamente
- Las validaciones son instantáneas

### Optimizaciones de UI

- Las tarjetas se renderizan con animaciones suaves
- Los botones tienen estados de hover y active
- Las transiciones son fluidas
- La interfaz responde rápidamente a las acciones del usuario

---

## CONCLUSIÓN

El sistema de actividades educativas de Macondo Vivo es una plataforma completa y robusta que maneja múltiples roles de usuario, estados de actividad, y procesos de aprobación. La interfaz es intuitiva y responsive, adaptándose a diferentes tamaños de pantalla. El sistema mantiene la integridad de los datos a través de validaciones estrictas y un sistema de permisos granular.

Para replicar este sistema en una aplicación móvil, es fundamental mantener toda la lógica de negocio, los permisos, y las validaciones. La interfaz deberá adaptarse a las convenciones móviles, pero la funcionalidad debe ser idéntica para garantizar una experiencia consistente entre plataformas. 