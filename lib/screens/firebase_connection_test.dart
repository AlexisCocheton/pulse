import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseConnectionTest extends StatefulWidget {
  const FirebaseConnectionTest({super.key});

  @override
  State<FirebaseConnectionTest> createState() => _FirebaseConnectionTestState();
}

class _FirebaseConnectionTestState extends State<FirebaseConnectionTest> {
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _appName = '';
  String _projectId = '';

  @override
  void initState() {
    super.initState();
    _checkFirebaseConnection();
  }

  Future<void> _checkFirebaseConnection() async {
    try {
      // Récupérer l'instance Firebase
      final app = Firebase.app();
      
      setState(() {
        _isInitialized = true;
        _hasError = false;
        _appName = app.name;
        _projectId = app.options.projectId;
      });
    } catch (e) {
      setState(() {
        _isInitialized = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Test Connexion Firebase'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône de statut
              Icon(
                _hasError
                    ? Icons.error_outline
                    : (_isInitialized ? Icons.check_circle : Icons.pending),
                size: 100,
                color: _hasError
                    ? Colors.red
                    : (_isInitialized ? Colors.green : Colors.orange),
              ),
              const SizedBox(height: 24),

              // Message de statut
              Text(
                _hasError
                    ? 'Erreur de connexion'
                    : (_isInitialized
                        ? 'Firebase connecté !'
                        : 'Vérification...'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _hasError ? Colors.red : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Détails de la connexion
              if (_isInitialized && !_hasError) ...[
                _InfoCard(
                  icon: Icons.app_settings_alt,
                  title: 'Nom de l\'app',
                  value: _appName,
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  icon: Icons.cloud,
                  title: 'Project ID',
                  value: _projectId,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Firebase est correctement configuré et prêt à être utilisé !',
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Message d'erreur
              if (_hasError) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Text(
                            'Erreur détectée',
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _checkFirebaseConnection,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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
