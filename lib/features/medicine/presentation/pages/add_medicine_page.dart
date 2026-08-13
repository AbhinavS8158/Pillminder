import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/models/medicine_model.dart';
import '../../../../core/models/dose_model.dart';
import '../bloc/medicine_cubit.dart';
import '../bloc/medicine_state.dart';

class AddMedicinePage extends StatefulWidget {
  final MedicineModel? medicineToEdit;

  const AddMedicinePage({super.key, this.medicineToEdit});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // Basic Info Form Fields
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _strengthController;
  String _selectedType = 'Tablet';

  // Dates Fields
  late DateTime _startDate;
  DateTime? _endDate;
  bool _isOngoing = true;

  // Doses list
  final List<DoseFormModel> _doses = [];

  final List<String> _medicineTypes = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Injection',
    'Cream',
    'Inhaler',
    'Drops',
    'Powder',
    'Other'
  ];

  final List<String> _foodInstructions = [
    'After Breakfast',
    'After Lunch',
    'After Dinner',
    'Before Breakfast',
    'Before Lunch',
    'Before Dinner',
    'After Food',
    'Before Food',
    'With Food',
    'Empty Stomach',
    'As Needed',
    'None'
  ];

  @override
  void initState() {
    super.initState();
    final editMed = widget.medicineToEdit;

    // Prepopulate if editing
    _nameController = TextEditingController(text: editMed?.name ?? '');
    _descController = TextEditingController(text: editMed?.description ?? '');
    _strengthController = TextEditingController(text: editMed?.strength ?? '');
    _selectedType = editMed?.type ?? 'Tablet';
    _startDate = editMed?.startDate ?? DateTime.now();
    _endDate = editMed?.endDate;
    _isOngoing = editMed == null ? true : (editMed.endDate == null);

    if (editMed != null && editMed.doses.isNotEmpty) {
      for (final dose in editMed.doses) {
        _doses.add(DoseFormModel(
          id: dose.id,
          time: TimeOfDay(
            hour: int.parse(dose.time.split(':')[0]),
            minute: int.parse(dose.time.split(':')[1]),
          ),
          quantity: dose.quantity,
          unit: dose.unit,
          foodInstruction: dose.foodInstruction,
        ));
      }
    } else {
      // Add one default dose block for new medicines
      _addDoseBlock();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _strengthController.dispose();
    super.dispose();
  }

  void _addDoseBlock() {
    setState(() {
      _doses.add(DoseFormModel(
        id: _uuid.v4(),
        time: const TimeOfDay(hour: 8, minute: 0),
        quantity: 1.0,
        unit: 'Tablet',
        foodInstruction: 'After Food',
      ));
    });
  }

  void _removeDoseBlock(int index) {
    if (_doses.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one dose is required.')),
      );
      return;
    }
    setState(() {
      _doses.removeAt(index);
    });
  }

  Future<void> _selectTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _doses[index].time,
    );
    if (picked != null) {
      setState(() {
        _doses[index].time = picked;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 7)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) return;
    if (_doses.isEmpty) return;

    final medId = widget.medicineToEdit?.id ?? _uuid.v4();

    // Map DoseFormModel back to DoseModel
    final List<DoseModel> listDoses = _doses.map((d) {
      final hourStr = d.time.hour.toString().padLeft(2, '0');
      final minStr = d.time.minute.toString().padLeft(2, '0');
      return DoseModel(
        id: d.id,
        time: '$hourStr:$minStr',
        quantity: d.quantity,
        unit: d.unit,
        foodInstruction: d.foodInstruction,
      );
    }).toList();

    final newMedicine = MedicineModel(
      id: medId,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      type: _selectedType,
      strength: _strengthController.text.trim(),
      startDate: _startDate,
      endDate: _isOngoing ? null : _endDate,
      doses: listDoses,
      isActive: true,
      createdAt: widget.medicineToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.medicineToEdit == null) {
      context.read<MedicineCubit>().addMedicine(newMedicine);
    } else {
      context.read<MedicineCubit>().editMedicine(newMedicine);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.medicineToEdit != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<MedicineCubit, MedicineState>(
      listener: (context, state) {
        if (state is MedicineSuccess) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              return _SuccessAnimationDialog(isEdit: isEdit);
            },
          ).then((_) {
            if (context.mounted) {
              Navigator.pop(context, true); // Return success to reload dashboard
            }
          });
        } else if (state is MedicineError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppTheme.missedRed),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(isEdit ? 'Edit Medicine' : 'Add Medicine'),
          ),
          body: SafeArea(
            child: state is MedicineLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Basic Info Section
                          _buildSectionTitle('Basic Information'),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Medicine Name *',
                              hintText: 'e.g. Paracetamol',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter medicine name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _strengthController,
                            decoration: const InputDecoration(
                              labelText: 'Strength (Optional)',
                              hintText: 'e.g. 500 mg, 10 ml',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedType,
                                  decoration: const InputDecoration(
                                    labelText: 'Medicine Type',
                                  ),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedType = val;
                                        // Update doses units to match
                                        for (final d in _doses) {
                                          d.unit = val;
                                        }
                                      });
                                    }
                                  },
                                  items: _medicineTypes
                                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descController,
                            decoration: const InputDecoration(
                              labelText: 'Description / Notes (Optional)',
                              hintText: 'e.g. For pain relief',
                            ),
                            maxLines: 2,
                          ),
                          
                          const SizedBox(height: 32),
                          // 2. Schedule Section
                          _buildSectionTitle('Treatment Duration'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkSlate : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: _selectStartDate,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Start Date *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('d MMM yyyy').format(_startDate),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Ongoing toggle
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Ongoing Treatment', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('No set end date (schedules indefinitely)'),
                            value: _isOngoing,
                            activeColor: AppTheme.primaryTeal,
                            onChanged: (val) {
                              setState(() {
                                _isOngoing = val;
                                if (!val && _endDate == null) {
                                  _endDate = _startDate.add(const Duration(days: 7));
                                }
                              });
                            },
                          ),
                          
                          if (!_isOngoing) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkSlate : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: _selectEndDate,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('End Date *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Text(
                                            _endDate != null
                                                ? DateFormat('d MMM yyyy').format(_endDate!)
                                                : 'Select End Date',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryTeal),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 32),
                          // 3. Dose configuration
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionTitle('Dose Times'),
                              TextButton.icon(
                                onPressed: _addDoseBlock,
                                icon: const Icon(Icons.add, color: AppTheme.primaryTeal),
                                label: const Text('Add Time', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _doses.length,
                            itemBuilder: (context, index) {
                              return _buildDoseBlock(index, isDark);
                            },
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Submit Button
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryTeal.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _saveForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                isEdit ? 'Save Changes' : 'Create Reminder',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildDoseBlock(int index, bool isDark) {
    final dose = _doses[index];
    final hrStr = dose.time.hourOfPeriod.toString().padLeft(2, '0');
    final minStr = dose.time.minute.toString().padLeft(2, '0');
    final period = dose.time.period == DayPeriod.am ? 'AM' : 'PM';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSlate : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Time Selector Button
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.access_time, color: AppTheme.primaryTeal, size: 20),
                        Text(
                          '$hrStr:$minStr $period',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Delete Button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.missedRed),
                onPressed: () => _removeDoseBlock(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Quantity Form
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: dose.quantity % 1 == 0 ? dose.quantity.toInt().toString() : dose.quantity.toString(),
                  decoration: const InputDecoration(labelText: 'Dose Qty'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || double.tryParse(val) == null || double.parse(val) <= 0) {
                      return 'Invalid Qty';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null) {
                      dose.quantity = parsed;
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Unit Selection Label
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: dose.unit,
                  decoration: const InputDecoration(labelText: 'Dose Unit'),
                  onChanged: (val) {
                    if (val.trim().isNotEmpty) {
                      dose.unit = val.trim();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Food Instruction Dropdown
          DropdownButtonFormField<String>(
            value: dose.foodInstruction,
            decoration: const InputDecoration(labelText: 'Food Instruction'),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  dose.foodInstruction = val;
                });
              }
            },
            items: _foodInstructions
                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// Temporary data class for Form inputs state management
class DoseFormModel {
  String id;
  TimeOfDay time;
  double quantity;
  String unit;
  String foodInstruction;

  DoseFormModel({
    required this.id,
    required this.time,
    required this.quantity,
    required this.unit,
    required this.foodInstruction,
  });
}

class _SuccessAnimationDialog extends StatefulWidget {
  final bool isEdit;
  const _SuccessAnimationDialog({required this.isEdit});

  @override
  State<_SuccessAnimationDialog> createState() => _SuccessAnimationDialogState();
}

class _SuccessAnimationDialogState extends State<_SuccessAnimationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();

    // Auto dismiss after 1.8 seconds
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSlate : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Checkmark Badge
              ScaleTransition(
                scale: _checkAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.successGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.isEdit ? 'Changes Saved!' : 'Medicine Added!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isEdit
                    ? 'Your updates have been registered.'
                    : 'Reminders have been scheduled.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
