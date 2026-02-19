import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/asset_bloc.dart';
import '../bloc/asset_event_state.dart';
import '../data/asset_repository.dart';
import '../data/models/asset_models.dart';

class AssetFormScreen extends StatefulWidget {
  final Asset? existingAsset;

  const AssetFormScreen({super.key, this.existingAsset});

  @override
  State<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends State<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool get _isEditing => widget.existingAsset != null;

  // Controllers
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _serialNumberCtrl;
  late final TextEditingController _acquisitionValueCtrl;
  late final TextEditingController _currentValueCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _notesCtrl;

  String? _categoryId;
  String _condition = 'bom';
  String _acquisitionType = 'compra';
  DateTime? _acquisitionDate;

  // Categories for dropdown
  List<AssetCategory> _categories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    final a = widget.existingAsset;
    _descriptionCtrl = TextEditingController(text: a?.description ?? '');
    _brandCtrl = TextEditingController(text: a?.brand ?? '');
    _modelCtrl = TextEditingController(text: a?.model ?? '');
    _serialNumberCtrl = TextEditingController(text: a?.serialNumber ?? '');
    _acquisitionValueCtrl = TextEditingController(
      text: a?.acquisitionValue != null ? a!.acquisitionValue!.toStringAsFixed(2) : '',
    );
    _currentValueCtrl = TextEditingController(
      text: a?.currentValue != null ? a!.currentValue!.toStringAsFixed(2) : '',
    );
    _locationCtrl = TextEditingController(text: a?.location ?? '');
    _notesCtrl = TextEditingController(text: a?.notes ?? '');
    _categoryId = a?.categoryId;
    _condition = a?.condition ?? 'bom';
    _acquisitionType = a?.acquisitionType ?? 'compra';
    if (a?.acquisitionDate != null) {
      _acquisitionDate = DateTime.tryParse(a!.acquisitionDate!);
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _serialNumberCtrl.dispose();
    _acquisitionValueCtrl.dispose();
    _currentValueCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final repo = AssetRepository(apiClient: apiClient);
      final result = await repo.getCategories(perPage: 100);
      if (mounted) {
        setState(() {
          _categories = result.items;
          _loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingCategories = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _acquisitionDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _acquisitionDate = date);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria')),
      );
      return;
    }

    final data = <String, dynamic>{
      'category_id': _categoryId,
      'description': _descriptionCtrl.text.trim(),
      'condition': _condition,
    };

    if (_brandCtrl.text.isNotEmpty) data['brand'] = _brandCtrl.text.trim();
    if (_modelCtrl.text.isNotEmpty) data['model'] = _modelCtrl.text.trim();
    if (_serialNumberCtrl.text.isNotEmpty) {
      data['serial_number'] = _serialNumberCtrl.text.trim();
    }
    if (_acquisitionDate != null) {
      data['acquisition_date'] =
          '${_acquisitionDate!.year}-${_acquisitionDate!.month.toString().padLeft(2, '0')}-${_acquisitionDate!.day.toString().padLeft(2, '0')}';
    }
    if (_acquisitionValueCtrl.text.isNotEmpty) {
      data['acquisition_value'] =
          double.tryParse(_acquisitionValueCtrl.text) ?? 0;
    }
    data['acquisition_type'] = _acquisitionType;
    if (_currentValueCtrl.text.isNotEmpty) {
      data['current_value'] = double.tryParse(_currentValueCtrl.text) ?? 0;
    }
    if (_locationCtrl.text.isNotEmpty) {
      data['location'] = _locationCtrl.text.trim();
    }
    if (_notesCtrl.text.isNotEmpty) data['notes'] = _notesCtrl.text.trim();

    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final bloc = AssetBloc(repository: AssetRepository(apiClient: apiClient));

    if (_isEditing) {
      bloc.add(
          AssetUpdateRequested(assetId: widget.existingAsset!.id, data: data));
    } else {
      bloc.add(AssetCreateRequested(data: data));
    }

    bloc.stream.listen((state) {
      if (state is AssetSaved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
        context.go('/assets/items');
      } else if (state is AssetError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Bem' : 'Novo Bem'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Salvar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Basic Info
              Text('Informações Básicas',
                  style: AppTypography.headingSmall
                      .copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.md),
              _buildWrap(isWide, [
                _field(
                  child: TextFormField(
                    controller: _descriptionCtrl,
                    decoration: const InputDecoration(labelText: 'Descrição *'),
                    validator: (v) => v == null || v.trim().length < 2
                        ? 'Mínimo 2 caracteres'
                        : null,
                  ),
                ),
                _field(
                  child: _loadingCategories
                      ? const LinearProgressIndicator()
                      : DropdownButtonFormField<String>(
                          value: _categoryId,
                          decoration:
                              const InputDecoration(labelText: 'Categoria *'),
                          items: _categories
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _categoryId = v),
                        ),
                ),
              ]),
              const SizedBox(height: AppSpacing.md),
              _buildWrap(isWide, [
                _field(
                  child: TextFormField(
                    controller: _brandCtrl,
                    decoration: const InputDecoration(labelText: 'Marca'),
                  ),
                ),
                _field(
                  child: TextFormField(
                    controller: _modelCtrl,
                    decoration: const InputDecoration(labelText: 'Modelo'),
                  ),
                ),
              ]),
              const SizedBox(height: AppSpacing.md),
              _buildWrap(isWide, [
                _field(
                  child: TextFormField(
                    controller: _serialNumberCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Número de Série'),
                  ),
                ),
                _field(
                  child: DropdownButtonFormField<String>(
                    value: _condition,
                    decoration: const InputDecoration(labelText: 'Condição'),
                    items: const [
                      DropdownMenuItem(value: 'novo', child: Text('Novo')),
                      DropdownMenuItem(value: 'bom', child: Text('Bom')),
                      DropdownMenuItem(
                          value: 'regular', child: Text('Regular')),
                      DropdownMenuItem(value: 'ruim', child: Text('Ruim')),
                      DropdownMenuItem(
                          value: 'inservivel', child: Text('Inservível')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _condition = v);
                    },
                  ),
                ),
              ]),

              const SizedBox(height: AppSpacing.xl),
              // Section 2: Acquisition
              Text('Aquisição',
                  style: AppTypography.headingSmall
                      .copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.md),
              _buildWrap(isWide, [
                _field(
                  child: DropdownButtonFormField<String>(
                    value: _acquisitionType,
                    decoration:
                        const InputDecoration(labelText: 'Tipo de Aquisição'),
                    items: const [
                      DropdownMenuItem(
                          value: 'compra', child: Text('Compra')),
                      DropdownMenuItem(
                          value: 'doacao', child: Text('Doação')),
                      DropdownMenuItem(
                          value: 'construcao', child: Text('Construção')),
                      DropdownMenuItem(
                          value: 'outro', child: Text('Outro')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _acquisitionType = v);
                    },
                  ),
                ),
                _field(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data de Aquisição',
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        _acquisitionDate != null
                            ? '${_acquisitionDate!.day.toString().padLeft(2, '0')}/${_acquisitionDate!.month.toString().padLeft(2, '0')}/${_acquisitionDate!.year}'
                            : '',
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: AppSpacing.md),
              _buildWrap(isWide, [
                _field(
                  child: TextFormField(
                    controller: _acquisitionValueCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Valor de Aquisição (R\$)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                _field(
                  child: TextFormField(
                    controller: _currentValueCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Valor Atual (R\$)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ]),

              const SizedBox(height: AppSpacing.xl),
              // Section 3: Location
              Text('Localização',
                  style: AppTypography.headingSmall
                      .copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Localização',
                  hintText: 'Ex: Salão principal, Escritório, Almoxarifado',
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              // Section 4: Notes
              Text('Observações',
                  style: AppTypography.headingSmall
                      .copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({required Widget child}) {
    return Expanded(child: child);
  }

  Widget _buildWrap(bool isWide, List<Widget> children) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .expand((c) => [c, const SizedBox(width: AppSpacing.md)])
            .toList()
          ..removeLast(),
      );
    }
    return Column(
      children: children
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SizedBox(width: double.infinity, child: c),
              ))
          .toList(),
    );
  }
}
