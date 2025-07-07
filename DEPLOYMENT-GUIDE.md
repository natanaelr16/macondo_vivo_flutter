rr# Documentación Completa - Macondo VIVO

## 📋 **Índice General**
1. [Arquitectura y Configuración](#arquitectura-y-configuración)
2. [Sistema de Autenticación](#sistema-de-autenticación)
3. [Gestión de Usuarios](#gestión-de-usuarios)
4. [Gestión de Actividades](#gestión-de-actividades)
5. [Sistema de Sesiones](#sistema-de-sesiones)
6. [Configuraciones](#configuraciones)
7. [Reportes](#reportes)
8. [Base de Datos](#base-de-datos)
9. [API Endpoints](#api-endpoints)
10. [Flujos de Usuario](#flujos-de-usuario)

---

## 🏗️ **Arquitectura y Configuración**

### **Tecnologías Utilizadas**
- **Frontend**: Next.js 14 + TypeScript + Material-UI
- **Backend**: Next.js API Routes
- **Base de Datos**: Firebase Firestore
- **Autenticación**: Firebase Authentication
- **Hosting**: Vercel

### **Estructura del Proyecto**
```
src/
├── app/api/           # API Routes (Backend)
├── components/        # Componentes React
├── contexts/         # Contextos (AuthContext)
├── hooks/           # Custom Hooks
├── lib/             # Configuración Firebase
├── services/        # Servicios de datos
├── types/           # Tipos TypeScript
└── utils/           # Utilidades
```

### **Configuración Firebase**
```typescript
// Cliente (src/lib/firebase.ts)
const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID
};

// Servidor (src/lib/firebase-admin.ts)
const firebaseAdminConfig = {
  credential: cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  }),
};
```

### **Variables de Entorno**
```env
# Frontend
NEXT_PUBLIC_FIREBASE_API_KEY=your_api_key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
NEXT_PUBLIC_FIREBASE_APP_ID=your_app_id

# Backend
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_CLIENT_EMAIL=your_service_account_email
FIREBASE_PRIVATE_KEY=your_private_key
```

---

## 🔐 **Sistema de Autenticación**

### **Flujo de Autenticación**
1. **Login**: Usuario ingresa email/password
2. **Firebase Auth**: Valida credenciales
3. **ID Token**: Firebase genera token automáticamente
4. **Sesión**: Se crea cookie de sesión en servidor
5. **Validación**: Cada request valida la sesión

### **Contexto de Autenticación** (`src/contexts/AuthContext.tsx`)
```typescript
interface AuthContextType {
  user: AuthUser | null;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  getIdToken: () => Promise<string>;
}

interface AuthUser extends FirebaseUser {
  appRole: AppRole;
  userType: UserType;
  firstName: string;
  lastName: string;
  isActive: boolean;
  provisionalPasswordSet: boolean;
  documentType: DocumentType;
  documentNumber: string;
  phone?: string;
  createdAt: string;
  updatedAt: string;
  typeSpecificData?: TypeSpecificData;
}
```

### **Endpoints de Autenticación**

#### **POST `/api/auth/login`**
- **Propósito**: Iniciar sesión
- **Body**: `{ idToken: string }` (ID token de Firebase)
- **Respuesta**: Cookie de sesión configurada
- **Validaciones**:
  - Usuario debe existir en Firestore
  - Usuario debe estar activo (`isActive: true`)

#### **POST `/api/auth/session`**
- **Propósito**: Crear sesión desde ID token de Firebase
- **Body**: `{ idToken: string }`
- **Respuesta**: Cookie de sesión

#### **DELETE `/api/auth/session`**
- **Propósito**: Cerrar sesión
- **Respuesta**: Elimina cookie de sesión

#### **POST `/api/auth/logout`**
- **Propósito**: Cerrar sesión (alternativo)
- **Respuesta**: Elimina cookie de sesión

### **Implementación para Móvil**
```typescript
// Ejemplo de autenticación en app móvil
class MobileAuthService {
  async signIn(email: string, password: string): Promise<User> {
    // Usar Firebase Auth directamente
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    const idToken = await userCredential.user.getIdToken();
    
    // Crear sesión en el servidor
    await fetch('/api/auth/session', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ idToken })
    });
    
    return userCredential.user;
  }
  
  async signOut(): Promise<void> {
    await signOut(auth);
    await fetch('/api/auth/logout', { method: 'POST' });
  }
  
  async getIdToken(): Promise<string> {
    const user = auth.currentUser;
    if (!user) throw new Error('No autenticado');
    return await user.getIdToken();
  }
}
```

---

## 👥 **Gestión de Usuarios**

### **Tipos de Usuario**
```typescript
type UserType = 'DOCENTE' | 'ADMIN_STAFF' | 'ESTUDIANTE' | 'ACUDIENTE';
type AppRole = 'SuperUser' | 'ADMIN' | 'USER';
type DocumentType = 'CC' | 'CE' | 'TI' | 'PASSPORT';
type UserStatus = 'PENDING' | 'VERIFIED' | 'DISABLED';
```

### **Estructura de Usuario**
```typescript
interface User {
  uid: string;
  email: string;
  firstName: string;
  lastName: string;
  documentType: DocumentType;
  documentNumber: string;
  phone?: string;
  userType: UserType;
  appRole: AppRole;
  status?: UserStatus;
  isActive: boolean;
  provisionalPasswordSet: boolean;
  createdAt: string;
  updatedAt: string;
  typeSpecificData?: TypeSpecificData;
}
```

### **Datos Específicos por Tipo**
```typescript
interface TypeSpecificData {
  // Admin Staff
  profession?: string;
  
  // Docente
  areaOfStudy?: string;
  assignedToGradeLevel?: GradeLevel;
  educationLevel?: EducationLevel;
  educationLevelOther?: string;
  schoolPosition?: SchoolPosition;
  specialAssignment?: string;
  teacherLevel?: TeacherLevel;
  isPTA?: boolean;
  teacherRoles?: TeacherRole[];
  
  // Estudiante
  schoolGrade?: SchoolGrade;
  
  // Acudiente
  representedChildrenCount?: number;
  representedStudentUIDs?: string[];
}

type GradeLevel = 'PREESCOLAR' | 'PRIMARIA' | 'BACHILLERATO';
type EducationLevel = 'PROFESIONAL' | 'MAESTRIA' | 'OTRO';
type SchoolPosition = 'RECTOR' | 'COORD_ACADEMICO_PRIMARIA' | 'COORD_ACADEMICO_SECUNDARIA' | 'COORD_CONVIVENCIA' | 'ADMINISTRATIVO' | 'DOCENTE';
type SchoolGrade = 'PREESCOLAR' | 'PRIMARIA_GRADO_1' | 'PRIMARIA_GRADO_2' | 'PRIMARIA_GRADO_3' | 'PRIMARIA_GRADO_4' | 'PRIMARIA_GRADO_5' | 'BACHILLERATO_GRADO_6' | 'BACHILLERATO_GRADO_7' | 'BACHILLERATO_GRADO_8' | 'BACHILLERATO_GRADO_9' | 'BACHILLERATO_GRADO_10' | 'BACHILLERATO_GRADO_11';
type TeacherLevel = 'TRANSICION' | 'PRIMARIA' | 'BACHILLERATO';
type TeacherRole = 'REPRESENTANTE_CONSEJO_ACADEMICO' | 'REPRESENTANTE_COMITE_CONVIVENCIA' | 'REPRESENTANTE_CONSEJO_DIRECTIVO' | 'LIDER_PROYECTO' | 'LIDER_AREA' | 'DIRECTOR_GRUPO' | 'NINGUNO';
```

### **Proceso de Creación de Usuarios**

#### **1. Formulario de Creación** (`/dashboard/users/create`)
```typescript
// Campos requeridos según tipo de usuario
const requiredFields = {
  general: ['email', 'firstName', 'lastName', 'documentType', 'documentNumber', 'phone', 'userType', 'appRole'],
  DOCENTE: ['areaOfStudy', 'assignedToGradeLevel', 'educationLevel', 'schoolPosition'],
  ESTUDIANTE: ['schoolGrade'],
  ACUDIENTE: ['representedChildrenCount']
};
```

#### **2. Validaciones**
```typescript
// Validar documento único
const validateUniqueDocument = async (documentNumber: string): Promise<boolean> => {
  const snapshot = await db.collection('users').where('documentNumber', '==', documentNumber).get();
  return snapshot.empty;
};

// Validar email único (excepto estudiantes/acudientes)
const validateUniqueEmail = async (email: string, userType: string): Promise<boolean> => {
  if (userType === 'ESTUDIANTE' || userType === 'ACUDIENTE') {
    return true; // Permitir email duplicado
  }
  
  const snapshot = await db.collection('users')
    .where('email', '==', email)
    .where('userType', 'not-in', ['ESTUDIANTE', 'ACUDIENTE'])
    .get();
  return snapshot.empty;
};

// Validar límite de superusuarios
const validateSuperUserLimit = async (appRole: string): Promise<boolean> => {
  if (appRole !== 'SuperUser') return true;
  const snapshot = await db.collection('users').where('appRole', '==', 'SuperUser').get();
  return snapshot.size < 2;
};
```

#### **3. Generación de Contraseña Provisional**
```typescript
const generateProvisionalPassword = () => {
  const length = 12;
  const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
  let password = '';
  for (let i = 0; i < length; i++) {
    const randomIndex = Math.floor(Math.random() * charset.length);
    password += charset[randomIndex];
  }
  return password;
};
```

#### **4. Proceso de Creación**
```typescript
// 1. Validar datos
const validationError = validateRequiredFields(userData);
if (validationError) {
  return NextResponse.json({ success: false, message: validationError }, { status: 400 });
}

// 2. Validar unicidad
const isDocumentUnique = await validateUniqueDocument(userData.documentNumber);
const isEmailUnique = await validateUniqueEmail(userData.email, userData.userType);
const canCreateSuperUser = await validateSuperUserLimit(userData.appRole);

// 3. Generar contraseña provisional
const provisionalPassword = generateProvisionalPassword();

// 4. Crear usuario en Authentication
const userRecord = await adminAuth.createUser({
  email: userData.email,
  password: provisionalPassword,
  displayName: `${userData.firstName} ${userData.lastName}`,
});

// 5. Almacenar en Firestore
const newUser: User = {
  ...userData,
  uid: userRecord.uid,
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now(),
  isActive: true,
  provisionalPasswordSet: true
};

await db.collection('users').doc(userRecord.uid).set(newUser);

// 6. Enviar email de reset
await sendPasswordResetEmail(auth, userData.email);
```

### **Funciones de Usuario**

#### **Listar Usuarios** (`/api/users`)
```typescript
// Permisos: ADMIN/SuperUser ven información completa, USER solo básica
const isFullAccess = ['ADMIN', 'SuperUser'].includes(userData.appRole);

const users = usersSnapshot.docs.map(doc => {
  const data = doc.data();
  
  if (isFullAccess) {
    return { uid: doc.id, ...data }; // Información completa
  } else {
    return {
      uid: doc.id,
      firstName: data.firstName || '',
      lastName: data.lastName || '',
      appRole: data.appRole || 'USER',
      isActive: data.isActive ?? true,
    }; // Solo información básica
  }
});
```

#### **Editar Usuario** (`/api/users/update/[id]`)
```typescript
// Permisos: SuperUser puede editar todo, ADMIN limitado
const canEdit = userData?.appRole === 'SuperUser' || 
                (userData?.appRole === 'ADMIN' && 
                 !['SuperUser'].includes(existingUser.appRole));

// Validaciones específicas
if (userData?.appRole === 'ADMIN' && updateData.appRole === 'SuperUser') {
  return NextResponse.json({ error: 'No puedes asignar rol SuperUser' }, { status: 403 });
}
```

#### **Eliminar Usuario** (`/api/users/delete/[id]`)
```typescript
// Permisos: Solo SuperUser
if (userData?.appRole !== 'SuperUser') {
  return NextResponse.json({ error: 'No autorizado' }, { status: 403 });
}

// Proceso: Eliminar de Auth + Firestore
await adminAuth.deleteUser(userId);
await db.collection('users').doc(userId).delete();
```

#### **Resetear Contraseña** (`/api/users/reset-password/[id]`)
```typescript
// Permisos: SuperUser o propio usuario
const canReset = userData?.appRole === 'SuperUser' || decodedToken.uid === userId;

// Proceso: Generar nueva contraseña provisional + enviar email
const newPassword = generateProvisionalPassword();
await adminAuth.updateUser(userId, { password: newPassword });
await db.collection('users').doc(userId).update({
  provisionalPasswordSet: true,
  updatedAt: Timestamp.now()
});
await sendPasswordResetEmail(auth, userEmail);
```

### **Sistema de Permisos**
```typescript
class PermissionManager {
  static canAccessUsers(user: User | null): boolean {
    if (!user) return false;
    if (user.appRole === 'SuperUser') return true;
    if (user.appRole === 'ADMIN') {
      return !['ESTUDIANTE', 'ACUDIENTE'].includes(user.userType);
    }
    return false;
  }

  static canCreateUsers(user: User | null): boolean {
    if (!user) return false;
    return user.appRole === 'SuperUser';
  }

  static canEditUsers(user: User | null): boolean {
    if (!user) return false;
    return user.appRole === 'SuperUser';
  }

  static canDeleteUsers(user: User | null): boolean {
    if (!user) return false;
    return user.appRole === 'SuperUser';
  }

  static canChangeUserStatus(user: User | null): boolean {
    if (!user) return false;
    return user.appRole === 'SuperUser';
  }
}
```

---

## 📚 **Gestión de Actividades**

### **Estructura de Actividad**
```typescript
interface Activity {
  activityId: string;
  title: string;
  description: string; // HTML rich text
  numberOfSessions: number;
  sessionDates: SessionDate[];
  submissionLink?: string;
  category?: string;
  estimatedDuration?: number; // minutos
  materials?: string[];
  objectives?: string[];
  responsibleUsers: Participant[];
  participants: Participant[];
  status: 'ACTIVA' | 'INACTIVA' | 'COMPLETADA';
  adminCanEdit: boolean;
  createdBy_uid: string;
  createdAt: any;
  updatedAt: any;
  sessionCompletions?: SessionCompletion[];
  completionPercentage?: number;
}
```

### **Tipos de Datos Relacionados**
```typescript
interface SessionDate {
  sessionNumber: number;
  date: string; // ISO date
  startTime: string; // "HH:MM"
  endTime: string; // "HH:MM"
  location?: string;
  status?: 'pending' | 'active' | 'completed';
}

interface Participant {
  userId: string;
  status: 'PENDIENTE' | 'COMPLETADA';
  completedAt?: any;
}

interface SessionCompletion {
  sessionNumber: number;
  userId: string;
  completedAt: any;
  isResponsible: boolean;
  status: 'PENDING_APPROVAL' | 'APPROVED' | 'COMPLETED';
  approvedBy?: string;
  approvedAt?: any;
}
```

### **Formulario de Creación de Actividades**

#### **Campos del Formulario**
```typescript
interface CreateActivityData {
  title: string; // requerido
  description: string; // requerido, HTML
  numberOfSessions: number; // requerido
  sessionDates: SessionDate[]; // requerido
  submissionLink?: string;
  category?: string;
  estimatedDuration?: number;
  materials?: string[];
  objectives?: string[];
  responsibleUsers: Participant[]; // requerido
  participants: Participant[];
}
```

#### **Validaciones**
```typescript
// Validar datos requeridos
if (!activityData.title || !activityData.description || !activityData.numberOfSessions) {
  return NextResponse.json({ error: 'Faltan datos requeridos' }, { status: 400 });
}

// Validar al menos un responsable
if (!activityData.responsibleUsers || activityData.responsibleUsers.length === 0) {
  return NextResponse.json({ error: 'Debe asignar al menos un responsable' }, { status: 400 });
}

// Validar fechas de sesiones
const sortedDates = activityData.sessionDates.sort((a, b) => 
  new Date(a.date).getTime() - new Date(b.date).getTime()
);
```

### **Sistema de Completación de Sesiones**

#### **1. Flujo de Completación**
```typescript
// Usuario marca sesión como completada
POST /api/activities/[id]/complete
{
  sessionNumber: number,
  userId: string
}

// Responsable aprueba completación
POST /api/activities/[id]/approve
{
  participantUserId: string,
  sessionNumber: number
}
```

#### **2. Estados de Completación**
```typescript
type CompletionStatus = 'PENDING_APPROVAL' | 'APPROVED' | 'COMPLETED';

// PENDING_APPROVAL: Usuario completó, espera aprobación
// APPROVED: Responsable aprobó la completación
// COMPLETED: Sesión finalizada
```

#### **3. Cálculo de Progreso**
```typescript
const calculateActivityProgress = (activity: Activity, sessionCompletions: SessionCompletion[]) => {
  const totalRequired = activity.numberOfSessions * activity.participants.length;
  const completed = sessionCompletions.filter(sc => sc.status === 'COMPLETED').length;
  
  return {
    completionPercentage: (completed / totalRequired) * 100,
    isFullyCompleted: completed === totalRequired,
    totalRequiredCompletions: totalRequired,
    currentCompletions: completed
  };
};
```

### **Funciones de Actividades**

#### **Crear Actividad** (`/api/activities`)
```typescript
// Permisos: Solo ADMIN/SuperUser
if (!['ADMIN', 'SuperUser'].includes(userData.appRole)) {
  return NextResponse.json({ error: 'No tienes permisos para crear actividades' }, { status: 403 });
}

// Proceso: Validar datos → Crear en Firestore → Asignar participantes
const newActivity = {
  ...activityData,
  status: 'ACTIVA',
  adminCanEdit: true,
  createdBy_uid: decodedToken.uid,
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now(),
};

const docRef = await db.collection('activities').add(newActivity);
```

#### **Listar Actividades** (`/api/activities`)
```typescript
// Obtener todas las actividades ordenadas por fecha
const activitiesSnapshot = await db.collection('activities')
  .orderBy('createdAt', 'desc')
  .get();

const activities = activitiesSnapshot.docs.map(doc => ({
  activityId: doc.id,
  ...doc.data(),
  createdAt: doc.data().createdAt?.toDate()?.toISOString(),
  updatedAt: doc.data().updatedAt?.toDate()?.toISOString(),
}));
```

#### **Obtener Actividades de Usuario** (`/api/users/[id]/activities`)
```typescript
// Filtrar actividades donde el usuario es participante o responsable
const allActivitiesSnapshot = await db.collection('activities').get();

const userActivities = allActivitiesSnapshot.docs
  .filter(doc => {
    const activityData = doc.data();
    
    const isParticipant = activityData.participants?.some(
      (p: any) => p.userId === id
    );
    
    const isResponsible = activityData.responsibleUsers?.some(
      (r: any) => r.userId === id
    );
    
    return isParticipant || isResponsible;
  })
  .map(doc => {
    const data = doc.data();
    return {
      activityId: doc.id,
      ...data,
      createdAt: data.createdAt?.toDate?.() ? data.createdAt.toDate().toISOString() : data.createdAt,
      updatedAt: data.updatedAt?.toDate?.() ? data.updatedAt.toDate().toISOString() : data.updatedAt,
    };
  });
```

#### **Completar Actividad** (`/api/activities/[id]/complete`)
```typescript
// Verificar que el usuario está asignado a la actividad
const isParticipant = activity.participants?.some((p: any) => p.userId === userId);
const isResponsible = activity.responsibleUsers?.some((r: any) => r.userId === userId);

if (!isParticipant && !isResponsible) {
  return NextResponse.json({ 
    error: 'No tienes permisos para completar esta actividad' 
  }, { status: 403 });
}

// Crear completación de sesión
const sessionCompletion: SessionCompletion = {
  sessionNumber: sessionNumber,
  userId: userId,
  completedAt: Timestamp.now(),
  isResponsible: isResponsible,
  status: 'PENDING_APPROVAL'
};

// Actualizar actividad
await db.collection('activities').doc(activityId).update({
  sessionCompletions: admin.firestore.FieldValue.arrayUnion(sessionCompletion),
  updatedAt: Timestamp.now()
});
```

#### **Aprobar Completación** (`/api/activities/[id]/approve`)
```typescript
// Verificar que quien aprueba sea responsable de la actividad
const isResponsible = activity.responsibleUsers?.some((r: any) => r.userId === approvingUserId);

if (!isResponsible) {
  return NextResponse.json({ 
    error: 'Solo los responsables pueden aprobar completaciones' 
  }, { status: 403 });
}

// Actualizar estado de completación
const updatedCompletions = activity.sessionCompletions.map((completion: SessionCompletion) => {
  if (completion.sessionNumber === sessionNumber && 
      completion.userId === participantUserId) {
    return {
      ...completion,
      status: 'APPROVED',
      approvedBy: approvingUserId,
      approvedAt: Timestamp.now()
    };
  }
  return completion;
});

// Actualizar actividad
await db.collection('activities').doc(activityId).update({
  sessionCompletions: updatedCompletions,
  updatedAt: Timestamp.now()
});
```

---

## 🔄 **Sistema de Sesiones**

### **Gestión de Sesiones Múltiples**
```typescript
interface UserSession {
  sessionId: string;
  userId: string;
  deviceInfo: DeviceInfo;
  ipAddress: string;
  userAgent: string;
  createdAt: Timestamp;
  lastActivity: Timestamp;
  isActive: boolean;
  timeoutMinutes: number;
  nickname?: string;
}

interface DeviceInfo {
  deviceType: 'desktop' | 'mobile' | 'tablet';
  browser: string;
  os: string;
  screenResolution: string;
}
```

### **Servicios de Sesión**
```typescript
class SessionService {
  async createSession(userId: string): Promise<string> {
    const sessionId = generateSessionId();
    const deviceInfo = this.getDeviceInfo();
    const ipAddress = await this.getIPAddress();
    
    const session: UserSession = {
      sessionId,
      userId,
      deviceInfo,
      ipAddress,
      userAgent: navigator.userAgent,
      createdAt: Timestamp.now(),
      lastActivity: Timestamp.now(),
      isActive: true,
      timeoutMinutes: 30
    };
    
    await setDoc(doc(db, this.sessionsCollection, sessionId), session);
    return sessionId;
  }

  async validateSession(sessionId: string, userId: string): Promise<boolean> {
    const sessionDoc = await getDoc(doc(db, this.sessionsCollection, sessionId));
    
    if (!sessionDoc.exists()) return false;
    
    const session = sessionDoc.data() as UserSession;
    
    // Verificar que pertenece al usuario
    if (session.userId !== userId) return false;
    
    // Verificar que está activa
    if (!session.isActive) return false;
    
    // Verificar timeout
    const lastActivity = session.lastActivity.toDate();
    const now = new Date();
    const timeoutMs = session.timeoutMinutes * 60 * 1000;
    
    if (now.getTime() - lastActivity.getTime() > timeoutMs) {
      await this.terminateSession(sessionId);
      return false;
    }
    
    // Actualizar última actividad
    await updateDoc(doc(db, this.sessionsCollection, sessionId), {
      lastActivity: Timestamp.now()
    });
    
    return true;
  }

  async terminateSession(sessionId: string): Promise<void> {
    await updateDoc(doc(db, this.sessionsCollection, sessionId), {
      isActive: false,
      lastActivity: Timestamp.now()
    });
  }

  async getUserActiveSessions(userId: string): Promise<UserSession[]> {
    const q = query(
      collection(db, this.sessionsCollection),
      where('userId', '==', userId),
      where('isActive', '==', true)
    );
    
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => doc.data() as UserSession);
  }

  async cleanupDuplicateIPSessions(userId: string, currentSessionId: string): Promise<void> {
    const userSessions = await this.getUserActiveSessions(userId);
    const currentSession = userSessions.find(s => s.sessionId === currentSessionId);
    
    if (!currentSession) return;
    
    // Terminar sesiones con la misma IP (excepto la actual)
    const sessionsToTerminate = userSessions.filter(s => 
      s.sessionId !== currentSessionId && 
      s.ipAddress === currentSession.ipAddress
    );
    
    for (const session of sessionsToTerminate) {
      await this.terminateSession(session.sessionId);
    }
  }

  async logout(): Promise<void> {
    const sessionId = localStorage.getItem('sessionId');
    
    if (sessionId) {
      await this.terminateSession(sessionId);
      localStorage.removeItem('sessionId');
    }
  }
}
```

### **Hooks de Sesión**
```typescript
// useSessionManager
export function useSessionManager() {
  const { user, signOut } = useAuth();
  const router = useRouter();
  const [sessionStatus, setSessionStatus] = useState<SessionStatus>({
    isValidating: false,
    sessionValid: false,
    sessionInfo: null,
    error: null
  });

  const validateCurrentSession = useCallback(async (): Promise<boolean> => {
    if (!user) return false;

    const sessionId = localStorage.getItem('sessionId');
    if (!sessionId) return false;

    setSessionStatus(prev => ({ ...prev, isValidating: true, error: null }));

    try {
      await sessionService.cleanupDuplicateIPSessions(user.uid, sessionId);
      const isValid = await sessionService.validateSession(sessionId, user.uid);
      
      setSessionStatus(prev => ({
        ...prev,
        isValidating: false,
        sessionValid: isValid
      }));

      if (!isValid) {
        await handleSessionInvalid();
        return false;
      }

      return true;
    } catch (error) {
      console.error('Error validating session:', error);
      setSessionStatus(prev => ({
        ...prev,
        isValidating: false,
        sessionValid: false,
        error: 'Error al validar sesión'
      }));
      
      await handleSessionInvalid();
      return false;
    }
  }, [user]);

  const handleSessionInvalid = useCallback(async () => {
    toast.error('🔒 Has iniciado sesión en otro dispositivo. Por seguridad, tu sesión anterior ha sido cerrada.', {
      duration: 6000,
      icon: '🔒'
    });

    localStorage.removeItem('sessionId');
    await signOut();
    router.push('/login?reason=session_conflict');
  }, [signOut, router]);

  // Validación periódica cada 30 segundos
  useEffect(() => {
    if (!user) return;

    validateCurrentSession();

    const interval = setInterval(() => {
      validateCurrentSession();
    }, 30 * 1000);

    return () => clearInterval(interval);
  }, [user, validateCurrentSession]);

  return {
    sessionStatus,
    validateCurrentSession,
    createNewSession,
    terminateCurrentSession,
    getUserSessions,
    handleSessionInvalid
  };
}
```

---

## ⚙️ **Configuraciones**

### **Página de Configuraciones** (`/dashboard/settings`)

#### **Configuraciones Disponibles**
1. **Esquema de Colores**
   - Electric Blue
   - Sunset Orange
   - Vibrant Purple

2. **Configuraciones de Sesión**
   - Timeout de sesión
   - Múltiples sesiones permitidas
   - Notificaciones de sesión

3. **Configuraciones de Notificaciones**
   - Email de actividades
   - Notificaciones push
   - Recordatorios

#### **Implementación**
```typescript
// Guardar configuración en localStorage
const saveColorScheme = (colorScheme: ColorScheme) => {
  localStorage.setItem('colorScheme', colorScheme);
  setColorScheme(colorScheme);
};

// Cargar configuración al iniciar
useEffect(() => {
  const savedColorScheme = localStorage.getItem('colorScheme') as ColorScheme | null;
  if (savedColorScheme) {
    setColorScheme(savedColorScheme);
  }
}, []);
```

---

## 📊 **Reportes**

### **Página de Reportes** (`/dashboard/reports`)

#### **Tipos de Reportes**
1. **Reporte de Usuarios**
   - Total de usuarios por tipo
   - Usuarios activos/inactivos
   - Distribución por roles

2. **Reporte de Actividades**
   - Actividades por estado
   - Tasa de completación
   - Actividades por categoría

3. **Reporte de Participación**
   - Participación por usuario
   - Sesiones completadas
   - Progreso general

#### **Implementación**
```typescript
// Generar reporte de usuarios
const generateUserReport = async () => {
  const usersSnapshot = await db.collection('users').get();
  const users = usersSnapshot.docs.map(doc => doc.data() as User);

  const report = {
    totalUsers: users.length,
    activeUsers: users.filter(u => u.isActive).length,
    inactiveUsers: users.filter(u => !u.isActive).length,
    byUserType: {
      DOCENTE: users.filter(u => u.userType === 'DOCENTE').length,
      ESTUDIANTE: users.filter(u => u.userType === 'ESTUDIANTE').length,
      ACUDIENTE: users.filter(u => u.userType === 'ACUDIENTE').length,
      ADMIN_STAFF: users.filter(u => u.userType === 'ADMIN_STAFF').length,
    },
    byAppRole: {
      SuperUser: users.filter(u => u.appRole === 'SuperUser').length,
      ADMIN: users.filter(u => u.appRole === 'ADMIN').length,
      USER: users.filter(u => u.appRole === 'USER').length,
    }
  };

  return report;
};

// Generar reporte de actividades
const generateActivityReport = async () => {
  const activitiesSnapshot = await db.collection('activities').get();
  const activities = activitiesSnapshot.docs.map(doc => doc.data() as Activity);

  const report = {
    totalActivities: activities.length,
    activeActivities: activities.filter(a => a.status === 'ACTIVA').length,
    completedActivities: activities.filter(a => a.status === 'COMPLETADA').length,
    inactiveActivities: activities.filter(a => a.status === 'INACTIVA').length,
    averageCompletionRate: activities.reduce((sum, activity) => 
      sum + (activity.completionPercentage || 0), 0) / activities.length,
    byCategory: activities.reduce((acc, activity) => {
      const category = activity.category || 'Sin categoría';
      acc[category] = (acc[category] || 0) + 1;
      return acc;
    }, {} as Record<string, number>)
  };

  return report;
};
```

---

## 🗄️ **Base de Datos**

### **Colecciones de Firestore**

#### **`users`**
```typescript
{
  uid: string; // ID único de Firebase Auth
  email: string;
  firstName: string;
  lastName: string;
  documentType: DocumentType;
  documentNumber: string;
  phone?: string;
  userType: UserType;
  appRole: AppRole;
  status?: UserStatus;
  isActive: boolean;
  provisionalPasswordSet: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  typeSpecificData?: TypeSpecificData;
}
```

#### **`activities`**
```typescript
{
  activityId: string; // ID del documento
  title: string;
  description: string; // HTML
  numberOfSessions: number;
  sessionDates: SessionDate[];
  submissionLink?: string;
  category?: string;
  estimatedDuration?: number;
  materials?: string[];
  objectives?: string[];
  responsibleUsers: Participant[];
  participants: Participant[];
  status: 'ACTIVA' | 'INACTIVA' | 'COMPLETADA';
  adminCanEdit: boolean;
  createdBy_uid: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  sessionCompletions?: SessionCompletion[];
  completionPercentage?: number;
}
```

#### **`sessions`**
```typescript
{
  sessionId: string; // ID único de sesión
  userId: string;
  deviceInfo: DeviceInfo;
  ipAddress: string;
  userAgent: string;
  createdAt: Timestamp;
  lastActivity: Timestamp;
  isActive: boolean;
  timeoutMinutes: number;
  nickname?: string;
}
```

### **Reglas de Firestore**
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
    
    // Función para verificar si es superuser
    function isSuperUser() {
      return isAuthenticated() && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.appRole == 'SuperUser';
    }
    
    // Función para verificar si es el propio usuario
    function isSelf(userId) {
      return request.auth.uid == userId;
    }
    
    // Reglas para la colección users
    match /users/{userId} {
      // Lectura: permitida para el propio usuario y admin/superadmin
      allow read: if isAuthenticated() && (isAdminOrSuper() || isSelf(userId));
      
      // Creación: solo superadmin/admin pueden crear usuarios
      allow create: if isAuthenticated() && 
        isAdminOrSuper() && 
        hasRequiredUserFields(request.resource.data);
      
      // Actualización: 
      // - SuperUser puede actualizar cualquier campo
      // - Admin puede actualizar todo excepto appRole de otros admins/superusers  
      // - Usuario normal SOLO puede cambiar su contraseña
      allow update: if isAuthenticated() && (
        isSuperUser() || 
        (isAdminOrSuper() && 
         (!('appRole' in request.resource.data) || 
          get(/databases/$(database)/documents/users/$(userId)).data.appRole != 'SuperUser')) ||
        (isSelf(userId) && 
         request.resource.data.diff(resource.data).affectedKeys()
         .hasOnly(['provisionalPasswordSet', 'updatedAt']))
      );
      
      // Eliminación: solo superadmin puede eliminar usuarios
      allow delete: if isAuthenticated() && isSuperUser();
    }
    
    // Reglas para la colección activities
    match /activities/{activityId} {
      // Lectura: usuarios autenticados pueden leer actividades
      allow read: if isAuthenticated();
      
      // Creación: solo admin/superuser pueden crear actividades
      allow create: if isAuthenticated() && isAdminOrSuper();
      
      // Actualización: 
      // - SuperUser puede actualizar cualquier actividad
      // - Admin puede actualizar actividades que creó
      // - Usuarios pueden actualizar su progreso en actividades donde participan
      allow update: if isAuthenticated() && (
        isSuperUser() || 
        (isAdminOrSuper() && resource.data.createdBy_uid == request.auth.uid) ||
        (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['sessionCompletions', 'updatedAt']))
      );
      
      // Eliminación: solo superuser y creador (admin) pueden eliminar
      allow delete: if isAuthenticated() && (
        isSuperUser() || 
        (isAdminOrSuper() && resource.data.createdBy_uid == request.auth.uid)
      );
    }
    
    // Reglas para la colección sessions
    match /sessions/{sessionId} {
      // Usuarios solo pueden acceder a sus propias sesiones
      allow read, write: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## 🌐 **API Endpoints**

### **Autenticación**
| Método | Endpoint | Descripción | Permisos |
|--------|----------|-------------|----------|
| POST | `/api/auth/login` | Iniciar sesión | Público |
| POST | `/api/auth/session` | Crear sesión | Público |
| DELETE | `/api/auth/session` | Cerrar sesión | Autenticado |
| POST | `/api/auth/logout` | Cerrar sesión | Autenticado |

### **Usuarios**
| Método | Endpoint | Descripción | Permisos |
|--------|----------|-------------|----------|
| GET | `/api/users` | Listar usuarios | ADMIN/SuperUser |
| POST | `/api/users/create` | Crear usuario | SuperUser |
| GET | `/api/users/[id]` | Obtener usuario | Propio/ADMIN/SuperUser |
| PUT | `/api/users/update/[id]` | Actualizar usuario | SuperUser/Propio |
| DELETE | `/api/users/delete/[id]` | Eliminar usuario | SuperUser |
| POST | `/api/users/reset-password/[id]` | Resetear contraseña | SuperUser/Propio |
| GET | `/api/users/[id]/activities` | Actividades del usuario | Propio/ADMIN/SuperUser |

### **Actividades**
| Método | Endpoint | Descripción | Permisos |
|--------|----------|-------------|----------|
| GET | `/api/activities` | Listar actividades | Autenticado |
| POST | `/api/activities` | Crear actividad | ADMIN/SuperUser |
| GET | `/api/activities/[id]` | Obtener actividad | Autenticado |
| PUT | `/api/activities/[id]` | Actualizar actividad | Creador/ADMIN/SuperUser |
| DELETE | `/api/activities/[id]` | Eliminar actividad | Creador/ADMIN/SuperUser |
| POST | `/api/activities/[id]/complete` | Completar actividad | Participante/Responsable |
| POST | `/api/activities/[id]/approve` | Aprobar completación | Responsable |

### **Sesiones**
| Método | Endpoint | Descripción | Permisos |
|--------|----------|-------------|----------|
| POST | `/api/session/validate` | Validar sesión | Autenticado |
| GET | `/api/session/get-ip` | Obtener IP | Autenticado |

### **Reportes**
| Método | Endpoint | Descripción | Permisos |
|--------|----------|-------------|----------|
| GET | `/api/reports` | Obtener reportes | ADMIN/SuperUser |

---

## 🔄 **Flujos de Usuario**

### **Flujo de Registro/Login**
1. **Acceso**: Usuario accede a `/login`
2. **Autenticación**: Ingresa email/password
3. **Validación**: Firebase Auth valida credenciales
4. **Verificación**: Se verifica que el usuario existe en Firestore y está activo (`isActive: true`). Si no, se deniega el acceso.
5. **Sesión**: Se crea una cookie de sesión segura en el backend.
6. **Redirección**: El usuario es redirigido al dashboard principal.

#### **Flujo de Creación de Usuario**
1. **Acceso**: Solo SuperUser puede acceder a `/dashboard/users/create`.
2. **Formulario**: Se muestran campos dinámicos según el tipo de usuario.
3. **Validación**: Se valida unicidad de documento/email, y campos requeridos.
4. **Creación**: Se crea el usuario en Firebase Auth y Firestore.
5. **Clave provisional**: Se genera y se envía email de restablecimiento.
6. **Redirección**: El usuario aparece en la lista de usuarios.

#### **Flujo de Creación de Actividad**
1. **Acceso**: Solo ADMIN/SuperUser pueden crear actividades.
2. **Formulario**: Se ingresan datos básicos, sesiones, responsables y participantes.
3. **Validación**: Se valida que haya al menos un responsable y sesiones válidas.
4. **Creación**: Se almacena la actividad en Firestore.
5. **Notificación**: Los usuarios asignados pueden ver la actividad en su panel.

#### **Flujo de Completitud de Sesión**
1. **Participante**: Marca una sesión como completada.
2. **Estado**: La sesión queda en `PENDING_APPROVAL`.
3. **Responsable**: Aprueba la sesión, pasa a `APPROVED` o `COMPLETED`.
4. **Progreso**: Se actualiza el porcentaje de avance de la actividad.

#### **Flujo de Reportes**
1. **Acceso**: Solo ADMIN/SuperUser pueden ver reportes.
2. **Selección**: Se elige el tipo de reporte (usuarios, actividades, participación).
3. **Visualización**: Se muestran gráficos y tablas con los datos agregados.
4. **Exportación**: Opcionalmente, se pueden exportar los reportes a PDF/Excel.

#### **Flujo de Configuración**
1. **Acceso**: Todos los usuarios pueden acceder a `/dashboard/settings`.
2. **Preferencias**: Se pueden cambiar colores, notificaciones y timeout de sesión.
3. **Persistencia**: Las preferencias se guardan en localStorage y se aplican automáticamente.

---

## 📝 **Notas Finales para la App Móvil**

- **Todos los endpoints y lógica pueden ser consumidos desde la app móvil** usando el mismo flujo de autenticación (Firebase Auth + ID Token).
- **Los formularios y validaciones** deben replicar la lógica de campos requeridos y validaciones de unicidad.
- **La gestión de sesiones** puede implementarse usando el mismo modelo de cookies o tokens, según la plataforma móvil.
- **La estructura de datos y reglas de Firestore** aseguran la seguridad y consistencia de la información.
- **Los reportes y configuraciones** pueden ser adaptados a la interfaz móvil, consultando los mismos endpoints.

---

**¡Con esto tienes la documentación completa y lista para replicar toda la lógica y flujos en tu app móvil!**