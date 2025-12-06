// lib/features/gym/presentation/screens/gym_code_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../domain/models/gym_code.dart';
import '../../domain/services/gym_code_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Screen for gym admins to manage rotating gym codes
class GymCodeManagementScreen extends StatefulWidget {
  final String gymId;
  final String gymName;

  const GymCodeManagementScreen({
    Key? key,
    required this.gymId,
    required this.gymName,
  }) : super(key: key);

  @override
  State<GymCodeManagementScreen> createState() => _GymCodeManagementScreenState();
}

class _GymCodeManagementScreenState extends State<GymCodeManagementScreen> {
  final _gymCodeService = GymCodeService();
  GymCode? _activeCode;
  List<GymCode> _codeHistory = [];
  bool _isLoading = true;
  bool _isRotating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final activeCode = await _gymCodeService.getActiveCodeForGym(widget.gymId);
      final history = await _gymCodeService.getCodeHistory(widget.gymId, limit: 10);
      
      setState(() {
        _activeCode = activeCode;
        _codeHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
  }

  Future<void> _rotateCode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code rotieren?'),
        content: const Text(
          'Möchtest du einen neuen Code generieren? '
          'Der alte Code bleibt noch 24 Stunden gültig.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rotieren'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRotating = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final newCode = await _gymCodeService.rotateCode(
        gymId: widget.gymId,
        createdBy: userId,
      );

      await _loadData();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Neuer Code erstellt'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  newCode.code,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Gültig bis: ${DateFormat('dd.MM.yyyy').format(newCode.expiresAt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Rotieren: $e')),
        );
      }
    } finally {
      setState(() => _isRotating = false);
    }
  }

  void _copyCode() {
    if (_activeCode == null) return;
    Clipboard.setData(ClipboardData(text: _activeCode!.code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code kopiert!')),
    );
  }

  void _shareCode() {
    if (_activeCode == null) return;
    final expiresAt = DateFormat('dd.MM.yyyy').format(_activeCode!.expiresAt);
    Share.share(
      '${widget.gymName} Registrierungs-Code:\n\n'
      '${_activeCode!.code}\n\n'
      'Gültig bis: $expiresAt',
      subject: 'Gym Registrierungs-Code',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym-Code Verwaltung'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildActiveCodeCard(),
                    const SizedBox(height: 24),
                    _buildQRCodeCard(),
                    const SizedBox(height: 24),
                    _buildHistorySection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActiveCodeCard() {
    if (_activeCode == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.warning, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Kein aktiver Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Erstelle einen neuen Code für dein Gym.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isRotating ? null : _rotateCode,
                icon: const Icon(Icons.add),
                label: const Text('Code erstellen'),
              ),
            ],
          ),
        ),
      );
    }

    final daysLeft = _activeCode!.daysUntilExpiration;
    final isExpiringSoon = daysLeft <= 7 && daysLeft > 0;
    final isExpired = daysLeft < 0;

    return Card(
      color: isExpired
          ? Colors.red.shade50
          : isExpiringSoon
              ? Colors.orange.shade50
              : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Aktueller Code',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                if (isExpired)
                  const Chip(
                    label: Text('Abgelaufen'),
                    backgroundColor: Colors.red,
                    labelStyle: TextStyle(color: Colors.white),
                  )
                else if (isExpiringSoon)
                  Chip(
                    label: Text('$daysLeft Tage'),
                    backgroundColor: Colors.orange,
                    labelStyle: const TextStyle(color: Colors.white),
                  )
                else
                  Chip(
                    label: Text('$daysLeft Tage'),
                    backgroundColor: Colors.green,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Text(
                _activeCode!.code,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Gültig bis: ${DateFormat('dd.MM.yyyy HH:mm').format(_activeCode!.expiresAt)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _copyCode,
                  icon: const Icon(Icons.copy, size: 20),
                  label: const Text('Kopieren'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _shareCode,
                  icon: const Icon(Icons.share, size: 20),
                  label: const Text('Teilen'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isRotating ? null : _rotateCode,
                  icon: _isRotating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 20),
                  label: const Text('Rotieren'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeCard() {
    if (_activeCode == null || _activeCode!.isExpired) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'QR-Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: _activeCode!.code,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Zum Scannen für neue Mitglieder',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_codeHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Code-Historie',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _codeHistory.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final code = _codeHistory[index];
              return ListTile(
                leading: Icon(
                  code.isActive ? Icons.check_circle : Icons.cancel,
                  color: code.isActive ? Colors.green : Colors.grey,
                ),
                title: Text(
                  code.code,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                subtitle: Text(
                  'Erstellt: ${DateFormat('dd.MM.yyyy').format(code.createdAt)}\n'
                  'Läuft ab: ${DateFormat('dd.MM.yyyy').format(code.expiresAt)}',
                ),
                trailing: Chip(
                  label: Text(code.isActive ? 'Aktiv' : 'Inaktiv'),
                  backgroundColor: code.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
