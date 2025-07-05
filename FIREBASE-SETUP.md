# Configuración de Firebase para Macondo Vivo Flutter

## Pasos para configurar Firebase correctamente:

### 1. Instalar Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. Iniciar sesión en Firebase
```bash
firebase login
```

### 3. Inicializar Firebase en el proyecto
```bash
firebase init
```

### 4. Seleccionar servicios:
- Firestore
- Hosting (opcional)

### 5. Configurar Firestore:
- Seleccionar el proyecto: `macondo-vs`
- Usar las reglas existentes: `firestore.rules`
- Usar los índices existentes: `firestore.indexes.json`

### 6. Desplegar las reglas de Firestore
```bash
firebase deploy --only firestore:rules
```

### 7. Desplegar los índices de Firestore
```bash
firebase deploy --only firestore:indexes
```

## Reglas de Seguridad Actuales

Las reglas actuales permiten:
- Lectura y escritura para usuarios autenticados en todas las colecciones
- Acceso completo a las colecciones `users` y `activities`

## Solución de Problemas

### Error de Permisos
Si recibes el error `permission-denied`:
1. Verifica que las reglas estén desplegadas: `firebase deploy --only firestore:rules`
2. Verifica que el usuario esté autenticado
3. Verifica que el proyecto de Firebase esté correctamente configurado

### Error de Conexión
Si hay problemas de conexión:
1. Verifica la conexión a internet
2. Verifica que el proyecto de Firebase esté activo
3. Verifica que las credenciales de Firebase estén correctas

## Comandos Útiles

```bash
# Ver estado del proyecto
firebase projects:list

# Ver configuración actual
firebase use

# Desplegar todo
firebase deploy

# Desplegar solo reglas
firebase deploy --only firestore:rules

# Desplegar solo índices
firebase deploy --only firestore:indexes

# Ver logs
firebase functions:log
``` 