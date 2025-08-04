# 📚 Documentación Técnica - Macondo VIVO Flutter

## 📋 Índice
1. [Arquitectura del Sistema](#arquitectura-del-sistema)
2. [Configuración de Firebase](#configuración-de-firebase)
3. [Guía de Desarrollo](#guía-de-desarrollo)
4. [Guía de Despliegue](#guía-de-despliegue)
5. [Seguridad](#seguridad)

---

## 🏗️ Arquitectura del Sistema

### **Estructura del Proyecto**
```
macondo_vivo_flutter/
├── lib/                          # Código fuente principal
│   ├── core/                     # Núcleo de la aplicación
│   │   ├── router/              # Configuración de rutas
│   │   ├── theme/               # Temas y estilos
│   │   └── widgets/             # Widgets reutilizables
│   ├── features/                # Características principales
│   │   ├── activities/          # Gestión de actividades
│   │   ├── dashboard/           # Panel principal
│   │   ├── reports/             # Sistema de reportes
│   │   ├── settings/            # Configuraciones
│   │   └── users/               # Gestión de usuarios
│   ├── shared/                  # Recursos compartidos
│   │   ├── models/              # Modelos de datos
│   │   ├── providers/           # Gestión de estado
│   │   ├── services/            # Servicios de datos
│   │   └── utils/               # Utilidades
│   └── main.dart               # Punto de entrada
├── assets/                      # Recursos estáticos
│   ├── icons/                  # Iconos de la aplicación
│   └── logos/                  # Logos de tecnologías
├── android/                     # Configuración Android
├── ios/                        # Configuración iOS
├── web/                        # Configuración Web
├── test/                       # Tests de la aplicación
└── functions/                  # Firebase Functions
```

### **Patrones de Diseño Implementados**

#### **1. Clean Architecture**
- **Separación de capas**: Presentación, Dominio, Datos
- **Independencia de frameworks**: Lógica de negocio aislada
- **Testabilidad**: Fácil testing de componentes

#### **2. Provider Pattern**
- **Gestión de estado**: Estado global de la aplicación
- **Reactividad**: Actualización automática de UI
- **Simplicidad**: Fácil de entender y mantener

#### **3. Repository Pattern**
- **Abstracción de datos**: Interfaz única para acceso a datos
- **Flexibilidad**: Fácil cambio de fuente de datos
- **Testabilidad**: Mocking simplificado

---

## 🔥 Configuración de Firebase

### **Servicios Utilizados**

#### **1. Firebase Authentication**
```dart
// Configuración en main.dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

#### **2. Cloud Firestore**
```dart
// Estructura de colecciones
users/           # Usuarios del sistema
activities/      # Actividades educativas
sessions/        # Sesiones de usuario
```

#### **3. Firebase Functions**
```typescript
// functions/src/index.ts
export const createUser = functions.https.onCall(async (data, context) => {
  // Lógica de creación de usuarios
});
```

### **Reglas de Seguridad**

#### **Firestore Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Función para verificar autenticación
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Función para verificar si es admin o superuser
    function isAdminOrSuper() {
      return isAuthenticated() && 
        (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.appRole == 'ADMIN' ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.appRole == 'SuperUser');
    }
    
    // Reglas para usuarios
    match /users/{userId} {
      allow read: if isAuthenticated() && (isAdminOrSuper() || request.auth.uid == userId);
      allow create: if isAuthenticated() && isAdminOrSuper();
      allow update: if isAuthenticated() && (isSuperUser() || isAdminOrSuper());
      allow delete: if isAuthenticated() && isSuperUser();
    }
    
    // Reglas para actividades
    match /activities/{activityId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && isAdminOrSuper();
      allow update: if isAuthenticated() && (isSuperUser() || isAdminOrSuper());
      allow delete: if isAuthenticated() && (isSuperUser() || isAdminOrSuper());
    }
  }
}
```

---

## 🚀 Guía de Desarrollo

### **Configuración del Entorno**

#### **1. Requisitos Previos**
```bash
# Instalar Flutter
flutter --version

# Instalar Firebase CLI
npm install -g firebase-tools

# Verificar instalación
firebase --version
```

#### **2. Configuración del Proyecto**
```bash
# Clonar repositorio
git clone https://github.com/tu-usuario/macondo_vivo_flutter.git
cd macondo_vivo_flutter

# Instalar dependencias
flutter pub get

# Configurar Firebase
firebase login
firebase init
```

#### **3. Variables de Entorno**
Crear archivo `.env`:
```env
FIREBASE_API_KEY=tu_api_key
FIREBASE_AUTH_DOMAIN=tu_proyecto.firebaseapp.com
FIREBASE_PROJECT_ID=tu_proyecto_id
FIREBASE_STORAGE_BUCKET=tu_proyecto.appspot.com
FIREBASE_MESSAGING_SENDER_ID=tu_sender_id
FIREBASE_APP_ID=tu_app_id
```

### **Estructura de Modelos**

#### **UserModel**
```dart
class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final UserType userType;
  final AppRole appRole;
  final bool isActive;
  final bool provisionalPasswordSet;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TypeSpecificData? typeSpecificData;
}
```

#### **ActivityModel**
```dart
class ActivityModel {
  final String activityId;
  final String title;
  final String description;
  final int numberOfSessions;
  final List<SessionDate> sessionDates;
  final List<Participant> responsibleUsers;
  final List<Participant> participants;
  final ActivityStatus status;
  final String createdBy_uid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SessionCompletion> sessionCompletions;
}
```

### **Servicios Principales**

#### **AuthService**
```dart
class AuthService {
  Future<bool> signIn(String email, String password);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<void> updatePassword(String newPassword);
}
```

#### **FirestoreService**
```dart
class FirestoreService {
  Future<UserCreationResult> createUser(UserModel user, String password);
  Future<List<UserModel>> getUsers();
  Future<ActivityCreationResult> createActivity(ActivityModel activity);
  Future<List<ActivityModel>> getActivities();
}
```

---

## 📦 Guía de Despliegue

### **Despliegue de Firebase**

#### **1. Configurar Proyecto**
```bash
# Inicializar Firebase
firebase init

# Seleccionar servicios:
# - Firestore
# - Functions
# - Hosting (opcional)
```

#### **2. Desplegar Reglas**
```bash
# Desplegar reglas de Firestore
firebase deploy --only firestore:rules

# Desplegar índices
firebase deploy --only firestore:indexes
```

#### **3. Desplegar Functions**
```bash
# Instalar dependencias
cd functions
npm install

# Desplegar functions
firebase deploy --only functions
```

### **Build de la Aplicación**

#### **Android**
```bash
# Generar APK
flutter build apk --release

# Generar AAB (Google Play Store)
flutter build appbundle --release
```

#### **iOS**
```bash
# Generar para iOS
flutter build ios --release
```

#### **Web**
```bash
# Generar para web
flutter build web --release

# Desplegar en Firebase Hosting
firebase deploy --only hosting
```

---

## 🔐 Seguridad

### **Autenticación**

#### **Flujo de Autenticación**
1. Usuario ingresa credenciales
2. Firebase Auth valida credenciales
3. Se genera ID token
4. Se valida usuario en Firestore
5. Se crea sesión local

#### **Gestión de Tokens**
```dart
// Obtener token de autenticación
String? token = await FirebaseAuth.instance.currentUser?.getIdToken();

// Validar token en cada request
if (token != null) {
  // Realizar request con token
}
```

### **Autorización**

#### **Sistema de Roles**
- **SuperUser**: Acceso completo al sistema
- **Admin**: Gestión limitada de usuarios y actividades
- **User**: Acceso a actividades asignadas

#### **Validación de Permisos**
```dart
class PermissionManager {
  static bool canCreateUsers(UserModel? user) {
    return user?.appRole == AppRole.SuperUser;
  }
  
  static bool canManageActivities(UserModel? user) {
    return ['SuperUser', 'ADMIN'].contains(user?.appRole?.name);
  }
}
```

### **Validación de Datos**

#### **Validaciones Frontend**
```dart
// Validación de email
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

// Validación de documento único
Future<bool> isDocumentUnique(String documentNumber) async {
  // Verificar en Firestore
}
```

#### **Validaciones Backend**
```typescript
// Firebase Functions
export const validateUserData = functions.https.onCall(async (data, context) => {
  // Validar datos del usuario
  if (!data.email || !data.firstName || !data.lastName) {
    throw new functions.https.HttpsError('invalid-argument', 'Datos requeridos faltantes');
  }
});
```

---

## 🧪 Testing

### **Tipos de Tests**

#### **Unit Tests**
```dart
// test/unit/auth_service_test.dart
void main() {
  group('AuthService', () {
    test('should sign in user with valid credentials', () async {
      // Test implementation
    });
  });
}
```

#### **Widget Tests**
```dart
// test/widget/login_screen_test.dart
void main() {
  testWidgets('should show login form', (WidgetTester tester) async {
    // Test implementation
  });
}
```

#### **Integration Tests**
```dart
// test/integration/app_test.dart
void main() {
  testWidgets('complete user flow', (WidgetTester tester) async {
    // Test implementation
  });
}
```

### **Cobertura de Código**
```bash
# Ejecutar tests con cobertura
flutter test --coverage

# Generar reporte HTML
genhtml coverage/lcov.info -o coverage/html
```

---

## 📊 Monitoreo y Analytics

### **Firebase Analytics**
```dart
// Configurar analytics
await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

// Eventos personalizados
await FirebaseAnalytics.instance.logEvent(
  name: 'activity_created',
  parameters: {
    'activity_id': activityId,
    'user_type': userType,
  },
);
```

### **Crashlytics**
```dart
// Reportar errores
FirebaseCrashlytics.instance.recordError(
  error,
  stackTrace,
  reason: 'Error en creación de actividad',
);
```

---

## 🔄 CI/CD

### **GitHub Actions**
```yaml
# .github/workflows/flutter.yml
name: Flutter CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: flutter test
    - run: flutter build apk
```

---

## 📞 Soporte

### **Recursos Útiles**
- [Documentación Flutter](https://docs.flutter.dev)
- [Documentación Firebase](https://firebase.google.com/docs)
- [Material Design](https://material.io/design)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

### **Contacto**
- **Email**: natanaelr16@hotmail.com
- **WhatsApp**: +57 300 1476654
- **Web App**: [Macondo VIVO Web](https://macondo-vivo-logasi3oq-macondovivo.vercel.app)

---

*Documentación actualizada: Enero 2025*
*Versión: 1.0.0* 