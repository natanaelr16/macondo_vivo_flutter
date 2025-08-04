# 🎓 Macondo VIVO - Sistema de Gestión Educativa Móvil

[![Flutter](https://img.shields.io/badge/Flutter-3.5.4+-blue.svg?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-9.0+-orange.svg?logo=firebase)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-En%20Desarrollo-yellow.svg)](https://github.com/tu-usuario/macondo_vivo_flutter)

> **🚀 Aplicación móvil nativa** para la gestión integral de actividades educativas, desarrollada con Flutter y Firebase. Versión móvil del sistema web de Macondo VIVO.

## 📱 Características Principales

### 🔐 **Sistema de Autenticación Robusto**
- 🔥 Autenticación con Firebase Auth
- 👥 Gestión de roles y permisos granulares
- 🔑 Contraseñas provisionales con reset automático
- ⏰ Validación de sesiones múltiples

### 👥 **Gestión Completa de Usuarios**
- **👨‍🏫 Tipos de Usuario**: Docentes, Administrativos, Estudiantes, Acudientes
- **🎭 Roles de Aplicación**: SuperUser, Admin, User
- **📋 Datos Específicos**: Información detallada según el tipo de usuario
- **✅ Validaciones**: Emails únicos, documentos únicos, límites de sistema

### 📚 **Gestión de Actividades Educativas**
- **➕ Creación y Edición**: Formularios dinámicos con validación
- **📅 Sesiones Múltiples**: Programación de fechas y horarios
- **👥 Participantes**: Asignación de responsables y participantes
- **📊 Seguimiento**: Progreso en tiempo real con porcentajes de completitud
- **✅ Aprobaciones**: Sistema de aprobación de sesiones por responsables

### 📊 **Dashboard Inteligente**
- **📈 Estadísticas en Tiempo Real**: Actividades, usuarios, progreso
- **🔍 Filtros Avanzados**: Por estado, categoría, fecha, participante
- **👁️ Vistas Múltiples**: Lista y calendario
- **🔎 Búsqueda Inteligente**: Por título, descripción, participantes

### 🎨 **Interfaz Moderna**
- **🎨 Material Design 3**: Diseño consistente y accesible
- **🌓 Temas Dinámicos**: Claro, oscuro y automático
- **📱 Responsive**: Adaptable a diferentes tamaños de pantalla
- **✨ Animaciones Fluidas**: Transiciones suaves y profesionales

## 🏗️ Arquitectura del Proyecto

### **Estructura de Directorios**
```
lib/
├── core/                    # 🎯 Núcleo de la aplicación
│   ├── router/             # 🛣️ Configuración de rutas
│   ├── theme/              # 🎨 Temas y estilos
│   └── widgets/            # 🧩 Widgets reutilizables
├── features/               # ⭐ Características principales
│   ├── activities/         # 📚 Gestión de actividades
│   ├── dashboard/          # 📊 Panel principal
│   ├── reports/            # 📈 Sistema de reportes
│   ├── settings/           # ⚙️ Configuraciones
│   └── users/              # 👥 Gestión de usuarios
├── shared/                 # 🔄 Recursos compartidos
│   ├── models/             # 📋 Modelos de datos
│   ├── providers/          # 🎛️ Gestión de estado
│   ├── services/           # 🔧 Servicios de datos
│   └── utils/              # 🛠️ Utilidades
└── main.dart              # 🚀 Punto de entrada
```

### **Patrones de Diseño**
- **🏗️ Clean Architecture**: Separación clara de responsabilidades
- **🔄 Provider Pattern**: Gestión de estado reactiva
- **📦 Repository Pattern**: Abstracción de datos
- **🔧 Service Layer**: Lógica de negocio centralizada

## 🚀 Stack Tecnológico

### **Frontend & UI**
<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Material_Design-757575?style=for-the-badge&logo=material-design&logoColor=white" alt="Material Design">
</div>

### **Backend & Servicios**
<div align="center">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Cloud_Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firestore">
  <img src="https://img.shields.io/badge/Firebase_Authentication-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase Auth">
</div>

### **Herramientas de Desarrollo**
<div align="center">
  <img src="https://img.shields.io/badge/VS_Code-007ACC?style=for-the-badge&logo=visual-studio-code&logoColor=white" alt="VS Code">
  <img src="https://img.shields.io/badge/Android_Studio-3DDC84?style=for-the-badge&logo=android-studio&logoColor=white" alt="Android Studio">
  <img src="https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white" alt="Git">
</div>

## 📋 Requisitos del Sistema

### **Desarrollo**
- 🎯 Flutter SDK 3.5.4 o superior
- 🎯 Dart SDK 3.0 o superior
- 🎯 Android Studio / VS Code
- 🎯 Git

### **Dispositivos Soportados**
- **🤖 Android**: API 21+ (Android 5.0+)
- **🍎 iOS**: iOS 11.0+
- **🌐 Web**: Navegadores modernos
- **💻 Desktop**: Windows, macOS, Linux

## ⚙️ Configuración e Instalación

### **1. Clonar el Repositorio**
```bash
git clone https://github.com/tu-usuario/macondo_vivo_flutter.git
cd macondo_vivo_flutter
```

### **2. Instalar Dependencias**
```bash
flutter pub get
```

### **3. Configurar Firebase**
```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Iniciar sesión
firebase login

# Inicializar proyecto
firebase init

# Desplegar reglas de seguridad
firebase deploy --only firestore:rules
```

### **4. Configurar Variables de Entorno**
Crear archivo `.env` en la raíz del proyecto:
```env
FIREBASE_API_KEY=tu_api_key
FIREBASE_AUTH_DOMAIN=tu_proyecto.firebaseapp.com
FIREBASE_PROJECT_ID=tu_proyecto_id
FIREBASE_STORAGE_BUCKET=tu_proyecto.appspot.com
FIREBASE_MESSAGING_SENDER_ID=tu_sender_id
FIREBASE_APP_ID=tu_app_id
```

### **5. Ejecutar la Aplicación**
```bash
# Modo desarrollo
flutter run

# Build para producción
flutter build apk --release
```

## 🔧 Configuración de Firebase

### **Reglas de Firestore**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Reglas de seguridad implementadas
    // - Autenticación requerida
    // - Permisos basados en roles
    // - Validación de datos
  }
}
```

### **Índices de Firestore**
```json
{
  "indexes": [
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userType", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" }
      ]
    }
  ]
}
```

## 📱 Funcionalidades Detalladas

### **Sistema de Usuarios**
- **➕ Creación**: Formularios dinámicos según tipo de usuario
- **✏️ Edición**: Actualización de datos con validaciones
- **🔄 Gestión de Estado**: Activación/desactivación de usuarios
- **🔑 Reset de Contraseñas**: Generación automática de contraseñas provisionales

### **Gestión de Actividades**
- **➕ Creación**: Formularios con validación en tiempo real
- **📅 Sesiones**: Programación de múltiples sesiones
- **👥 Participantes**: Asignación de responsables y participantes
- **📊 Seguimiento**: Progreso detallado con estadísticas
- **✅ Aprobaciones**: Sistema de aprobación de completitudes

### **Dashboard y Reportes**
- **📈 Estadísticas**: Métricas en tiempo real
- **🔍 Filtros**: Búsqueda avanzada y filtrado
- **👁️ Vistas**: Lista y calendario
- **📤 Exportación**: Generación de reportes

## 🔐 Seguridad

### **Autenticación**
- 🔥 Firebase Authentication con email/password
- 🎫 Tokens JWT para sesiones
- 🔒 Validación de permisos por rol
- ⏰ Timeout de sesiones automático

### **Autorización**
- **👑 SuperUser**: Acceso completo al sistema
- **👨‍💼 Admin**: Gestión limitada de usuarios y actividades
- **👤 User**: Acceso a actividades asignadas

### **Validación de Datos**
- ✅ Validación en frontend y backend
- 🧹 Sanitización de inputs
- 🔍 Verificación de unicidad
- 📊 Límites de sistema

## 🧪 Testing

### **Tipos de Tests**
```bash
# Unit tests
flutter test test/unit/

# Widget tests
flutter test test/widget/

# Integration tests
flutter test test/integration/
```

### **Cobertura de Código**
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📦 Despliegue

### **Android**
```bash
# Generar APK
flutter build apk --release

# Generar AAB (Google Play Store)
flutter build appbundle --release
```

### **iOS**
```bash
# Generar para iOS
flutter build ios --release
```

### **Web**
```bash
# Generar para web
flutter build web --release

# Desplegar en Firebase Hosting
firebase deploy --only hosting
```

## 🤝 Contribución

### **Proceso de Contribución**
1. 🍴 Fork del repositorio
2. 🌿 Crear rama feature (`git checkout -b feature/nueva-funcionalidad`)
3. 💾 Commit cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. 📤 Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. 🔄 Crear Pull Request

### **Estándares de Código**
- 📝 Seguir las convenciones de Dart/Flutter
- 📚 Documentar funciones públicas
- 🧪 Escribir tests para nuevas funcionalidades
- 📊 Mantener cobertura de código >80%

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

## 📞 Soporte

### **Recursos**
- 📖 [Documentación Flutter](https://docs.flutter.dev)
- 🔥 [Documentación Firebase](https://firebase.google.com/docs)
- 🎨 [Material Design](https://material.io/design)

### **Contacto**
- 📧 **Email**: natanaelr16@hotmail.com
- 📱 **WhatsApp**: +57 300 1476654
- 🌐 **Web App**: [Macondo VIVO Web](https://macondo-vivo-logasi3oq-macondovivo.vercel.app)

## 🙏 Agradecimientos

- **Flutter Team**: Por el increíble framework
- **Firebase Team**: Por las herramientas de backend
- **Material Design**: Por el sistema de diseño
- **Comunidad Flutter**: Por el soporte continuo

---

**¡Desarrollado con ❤️ para la comunidad educativa!** 🎓✨

*Versión: 1.0.0 | Última actualización: Enero 2025*
