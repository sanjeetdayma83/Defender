import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/identity/current_user.dart';
import '../../providers/session_provider.dart';
import '../../services/warehouse/warehouse_service.dart';
import '../screen_ui.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  final WarehouseService _warehouseService = WarehouseService();

  List<WarehouseInfo> _warehouses = const <WarehouseInfo>[];
  WarehouseInfo? _selectedWarehouse;
  WarehouseStats? _stats;

  bool _loading = true;
  bool _loadingStats = false;
  bool _saving = false;
  String? _error;

  bool get _canManage {
    final role = context.read<SessionProvider>().user?.role;

    return role == 'PLATFORM_ADMIN' ||
        role == 'OWNER' ||
        role == 'ADMIN';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final warehouses = await _warehouseService.listWarehouses();

      if (!mounted) return;

      final sessionUser = context.read<SessionProvider>().user;
      final primaryId = sessionUser?.primaryWarehouse?.id;

      WarehouseInfo? selected;

      if (primaryId != null && primaryId.isNotEmpty) {
        for (final warehouse in warehouses) {
          if (warehouse.id == primaryId && warehouse.isActive) {
            selected = warehouse;
            break;
          }
        }
      }

      if (selected == null) {
        for (final warehouse in warehouses) {
          if (warehouse.isActive) {
            selected = warehouse;
            break;
          }
        }
      }

      setState(() {
        _warehouses = warehouses;
        _selectedWarehouse = selected;
        _stats = null;
        _loading = false;
      });

      if (selected != null) {
        await _loadStats(selected);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _cleanError(error);
      });
    }
  }

  Future<void> _loadStats(WarehouseInfo warehouse) async {
    if (!mounted) return;

    setState(() {
      _loadingStats = true;
      _stats = null;
    });

    try {
      final stats = await _warehouseService.getStats(warehouse.id);

      if (!mounted) return;

      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingStats = false;
        _error = _cleanError(error);
      });
    }
  }

  Future<void> _selectWarehouse(WarehouseInfo warehouse) async {
    if (!warehouse.isActive) {
      _showMessage('Inactive warehouses cannot be selected.');
      return;
    }

    setState(() {
      _selectedWarehouse = warehouse;
      _stats = null;
      _error = null;
    });

    await _loadStats(warehouse);
  }

  Future<void> _showCreateDialog() async {
    final result = await _showWarehouseDialog();

    if (result == null) return;

    setState(() => _saving = true);

    try {
      final warehouse = await _warehouseService.createWarehouse(
        name: result.name,
        code: result.code,
        country: result.country,
      );

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage('Warehouse created successfully.');

      await _load();

      if (!mounted) return;

      final created = _findWarehouse(warehouse.id);

      if (created != null) {
        await _selectWarehouse(created);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);
      _showMessage(_cleanError(error));
    }
  }

  Future<void> _showEditDialog() async {
    final warehouse = _selectedWarehouse;

    if (warehouse == null) return;

    final result = await _showWarehouseDialog(
      initialName: warehouse.name,
      initialCode: warehouse.code,
    );

    if (result == null) return;

    setState(() => _saving = true);

    try {
      await _warehouseService.updateWarehouse(
        warehouseId: warehouse.id,
        name: result.name,
        code: result.code,
      );

      if (!mounted) return;

      setState(() => _saving = false);

      _showMessage('Warehouse updated successfully.');

      await _load();
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);
      _showMessage(_cleanError(error));
    }
  }

  Future<void> _toggleStatus() async {
    final warehouse = _selectedWarehouse;

    if (warehouse == null) return;

    final newStatus = !warehouse.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            newStatus
                ? 'Activate warehouse?'
                : 'Deactivate warehouse?',
          ),
          content: Text(
            newStatus
                ? 'This warehouse will become available for operations.'
                : 'This warehouse will no longer be available for operations.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(newStatus ? 'Activate' : 'Deactivate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _saving = true);

    try {
      await _warehouseService.setWarehouseStatus(
        warehouseId: warehouse.id,
        isActive: newStatus,
      );

      if (!mounted) return;

      setState(() => _saving = false);

      _showMessage(
        newStatus
            ? 'Warehouse activated.'
            : 'Warehouse deactivated.',
      );

      await _load();
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);
      _showMessage(_cleanError(error));
    }
  }

  Future<void> _deleteWarehouse() async {
    final warehouse = _selectedWarehouse;

    if (warehouse == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete warehouse?'),
          content: Text(
            'Delete "${warehouse.name}" (${warehouse.code})? '
            'This action is allowed only when the warehouse has no orders '
            'or packing sessions.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _saving = true);

    try {
      await _warehouseService.deleteWarehouse(warehouse.id);

      if (!mounted) return;

      setState(() => _saving = false);

      _showMessage('Warehouse deleted.');

      await _load();
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);
      _showMessage(_cleanError(error));
    }
  }

  Future<_WarehouseFormResult?> _showWarehouseDialog({
    String? initialName,
    String? initialCode,
  }) async {
    final nameController = TextEditingController(text: initialName ?? '');
    final codeController = TextEditingController(text: initialCode ?? '');

    final result = await showDialog<_WarehouseFormResult>(
      context: context,
      builder: (context) {
        String? localError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                initialName == null
                    ? 'Add Warehouse'
                    : 'Edit Warehouse',
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Warehouse Name',
                        hintText: 'Main Warehouse',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Warehouse Code',
                        hintText: 'MAIN',
                      ),
                    ),
                    if (localError != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          localError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final code = codeController.text.trim().toUpperCase();

                    if (name.isEmpty || code.isEmpty) {
                      setDialogState(() {
                        localError =
                            'Warehouse name and code are required.';
                      });
                      return;
                    }

                    Navigator.of(context).pop(
                      _WarehouseFormResult(
                        name: name,
                        code: code,
                        country: 'India',
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    codeController.dispose();

    return result;
  }

  WarehouseInfo? _findWarehouse(String id) {
    for (final warehouse in _warehouses) {
      if (warehouse.id == id) {
        return warehouse;
      }
    }

    return null;
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return LDPage(
      title: 'Warehouse',
      subtitle: 'Operational configuration, warehouse status and health.',
      child: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null && _warehouses.isEmpty) {
      return _buildErrorState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToolbar(),
        const SizedBox(height: 20),
        if (_saving) const LinearProgressIndicator(),
        if (_saving) const SizedBox(height: 12),
        if (_error != null) _buildInlineError(),
        _buildStats(),
        const SizedBox(height: 20),
        _buildWarehouseProfile(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedWarehouse?.id,
            decoration: const InputDecoration(
              labelText: 'Warehouse',
              prefixIcon: Icon(Icons.warehouse_outlined),
              border: OutlineInputBorder(),
            ),
            items: _warehouses.map((warehouse) {
              return DropdownMenuItem<String>(
                value: warehouse.id,
                child: Text(
                  '${warehouse.name} (${warehouse.code})',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (id) {
              if (id == null) return;

              final warehouse = _findWarehouse(id);

              if (warehouse != null) {
                _selectWarehouse(warehouse);
              }
            },
          ),
        ),
        if (_canManage)
          FilledButton.icon(
            onPressed: _saving ? null : _showCreateDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Warehouse'),
          ),
        OutlinedButton.icon(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
    );
  }

  Widget _buildStats() {
    final stats = _stats;

    if (_selectedWarehouse == null) {
      return _buildEmptyState();
    }

    if (_loadingStats) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: LDStat(
            label: 'Active Orders',
            value: stats?.activeOrders.toString() ?? '—',
            icon: Icons.inventory_2_outlined,
            color: ldBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LDStat(
            label: 'Active Sessions',
            value: stats?.activeSessions.toString() ?? '—',
            icon: Icons.play_circle_outline,
            color: ldAmber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LDStat(
            label: 'Total Orders',
            value: stats?.totalOrders.toString() ?? '—',
            icon: Icons.receipt_long_outlined,
            color: ldGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildWarehouseProfile() {
    final warehouse = _selectedWarehouse;
    final stats = _stats;

    if (warehouse == null) {
      return _buildEmptyState();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LDCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LDSectionTitle(
                  title: warehouse.name,
                  subtitle: 'Warehouse profile',
                ),
                _row('Code', warehouse.code),
                _row(
                  'Status',
                  warehouse.isActive ? 'Active' : 'Inactive',
                  valueColor:
                      warehouse.isActive ? ldGreen : Colors.red,
                ),
                _row(
                  'Warehouse ID',
                  warehouse.id,
                ),
                _row(
                  'Total Sessions',
                  stats?.totalSessions.toString() ?? '—',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (_canManage)
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _showEditDialog,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                    if (_canManage)
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _toggleStatus,
                        icon: Icon(
                          warehouse.isActive
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                        ),
                        label: Text(
                          warehouse.isActive
                              ? 'Deactivate'
                              : 'Activate',
                        ),
                      ),
                    if (_canManage)
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _deleteWarehouse,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        label: const Text('Delete'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LDCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LDSectionTitle(
                  title: 'Warehouse Health',
                  subtitle: 'Live backend status',
                ),
                _healthRow(
                  'Warehouse',
                  warehouse.isActive ? 'Operational' : 'Inactive',
                  warehouse.isActive,
                ),
                _healthRow(
                  'Orders',
                  stats == null
                      ? 'Loading'
                      : '${stats.activeOrders} active',
                  stats != null,
                ),
                _healthRow(
                  'Packing Sessions',
                  stats == null
                      ? 'Loading'
                      : '${stats.activeSessions} active',
                  stats != null,
                ),
                _healthRow(
                  'Backend',
                  stats == null ? 'Unavailable' : 'Connected',
                  stats != null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load warehouses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineError() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(_error!)),
          IconButton(
            onPressed: () {
              setState(() => _error = null);
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return LDCard(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.warehouse_outlined,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'No active warehouse available',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create or activate a warehouse to start operations.',
                textAlign: TextAlign.center,
              ),
              if (_canManage) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Warehouse'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: ldMute),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? ldNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthRow(
    String name,
    String status,
    bool healthy,
  ) {
    final color = healthy ? ldGreen : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 9,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name)),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarehouseFormResult {
  final String name;
  final String code;
  final String country;

  const _WarehouseFormResult({
    required this.name,
    required this.code,
    required this.country,
  });
}

