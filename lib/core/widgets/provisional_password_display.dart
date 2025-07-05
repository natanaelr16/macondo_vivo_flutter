import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/utils/password_utils.dart';
import '../../shared/services/api_service.dart';
import 'package:share_plus/share_plus.dart';

class ProvisionalPasswordDisplay extends StatefulWidget {
  final String userId;
  final bool provisionalPasswordSet;

  const ProvisionalPasswordDisplay({
    super.key,
    required this.userId,
    required this.provisionalPasswordSet,
  });

  @override
  State<ProvisionalPasswordDisplay> createState() => _ProvisionalPasswordDisplayState();
}

class _ProvisionalPasswordDisplayState extends State<ProvisionalPasswordDisplay> {
  String? provisionalPassword;
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool hasCopied = false;

  @override
  void initState() {
    super.initState();
    if (widget.provisionalPasswordSet) {
      _loadProvisionalPassword();
    }
  }

  Future<void> _loadProvisionalPassword() async {
    if (!widget.provisionalPasswordSet) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      print('[ProvisionalPasswordDisplay] 🔄 Cargando contraseña para usuario: ${widget.userId}');
      
      // Primero intentar obtener la contraseña desde la API web
      String? password;
      try {
        password = await ApiService.getProvisionalPassword(widget.userId);
        print('[ProvisionalPasswordDisplay] ✅ Contraseña obtenida desde API: $password');
      } catch (e) {
        print('[ProvisionalPasswordDisplay] ⚠️ Error consultando API: $e');
        print('[ProvisionalPasswordDisplay] 🔄 Intentando con generación local...');
        
        // Fallback: generar localmente si la API falla
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          final email = userData?['email'] as String?;
          
          if (email != null) {
            password = generateDeterministicPassword(email);
            print('[ProvisionalPasswordDisplay] 🔧 Contraseña generada localmente: $password');
          }
        }
      }
      
      setState(() {
        provisionalPassword = password;
        isLoading = false;
      });
      
    } catch (e) {
      print('[ProvisionalPasswordDisplay] ❌ Error general: $e');
      setState(() {
        provisionalPassword = null;
        isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (provisionalPassword != null) {
      Clipboard.setData(ClipboardData(text: provisionalPassword!));
      setState(() {
        hasCopied = true;
      });
      // Resetear el estado después de 2 segundos
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            hasCopied = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.provisionalPasswordSet) {
      return const SizedBox.shrink();
    }

    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Usuario No Verificado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Contraseña Provisional',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Cargando...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta contraseña se eliminará automáticamente cuando el usuario cambie su contraseña por primera vez.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (provisionalPassword == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Usuario No Verificado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.15)),
              ),
              child: Text(
                'No hay contraseña provisional disponible.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 22),
              const SizedBox(width: 8),
              Text(
                'Usuario No Verificado',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Contraseña Provisional',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.only(left: 18, top: 8, bottom: 8, right: 0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          isPasswordVisible ? provisionalPassword! : '••••••••••••',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      tooltip: isPasswordVisible ? 'Ocultar' : 'Mostrar',
                      padding: const EdgeInsets.only(right: 0),
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      onPressed: _copyToClipboard,
                      icon: Icon(
                        hasCopied ? Icons.check : Icons.copy,
                        size: 18,
                        color: hasCopied ? Colors.green : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      tooltip: hasCopied ? 'Copiado' : 'Copiar',
                      padding: const EdgeInsets.only(right: 0),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta contraseña se eliminará automáticamente cuando el usuario cambie su contraseña por primera vez.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 