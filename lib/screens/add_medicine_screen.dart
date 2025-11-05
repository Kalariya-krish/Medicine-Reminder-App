// In a file named: lib/screens/add_medicine_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // NEW: Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // NEW: Firestore
import '../models/medicine.dart'; // Import the Medicine model

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  // Form state
  final _formKey = GlobalKey<FormState>();
  final _medicineNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController(); // NEW CONTROLLER

  String? _dosageValue = '1 tablet';
  String? _frequencyValue = 'Once a day';

  // State for the toggle buttons (Morning, Afternoon, Night)
  final List<bool> _timeSlotSelection = [true, false, false];

  // List of controllers for specific alarm times (dynamic size)
  List<TextEditingController> _timeControllers = [TextEditingController()];

  @override
  void initState() {
    super.initState();
    // Set default start date to today
    _startDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _endDateController.text =
        DateFormat('dd/MM/yyyy').format(DateTime.now().add(Duration(days: 7)));
    _updateTimeControllers();
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    _notesController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    for (var controller in _timeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- Helper Methods (retained) ---

  int _getDoseCount(String frequency) {
    if (frequency.contains('Once')) return 1;
    if (frequency.contains('Twice')) return 2;
    if (frequency.contains('3 times')) return 3;
    return 1;
  }

  void _updateTimeControllers() {
    final newCount = _getDoseCount(_frequencyValue!);

    // Dispose and remove excess controllers
    while (_timeControllers.length > newCount) {
      _timeControllers.removeLast().dispose();
    }

    // Add new controllers with default times
    while (_timeControllers.length < newCount) {
      String defaultTime = '09:00';
      if (newCount == 2) {
        defaultTime = _timeControllers.length == 0 ? '09:00' : '17:00';
      } else if (newCount == 3) {
        defaultTime = _timeControllers.length == 0
            ? '08:00'
            : (_timeControllers.length == 1 ? '14:00' : '20:00');
      }

      _timeControllers.add(TextEditingController(text: defaultTime));
    }
    // Re-trigger rebuild to show/hide time inputs
    setState(() {});
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _startDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // NEW: Date Picker for End Date
  Future<void> _selectEndDate() async {
    // Parse the start date to set it as the minimum selectable date
    DateTime initialDate = DateTime.now().add(const Duration(days: 7));
    DateTime firstDate = DateTime.now();

    try {
      // Ensure start date exists and is parsable before setting firstDate
      final startDate =
          DateFormat('dd/MM/yyyy').parse(_startDateController.text);
      firstDate = startDate;
      initialDate = startDate.add(const Duration(days: 7));
    } catch (e) {
      // If start date is invalid, use today as minimum
      firstDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate, // End date cannot be before start date
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _endDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    TimeOfDay initialTime;
    try {
      final parts = controller.text.split(':');
      initialTime =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      initialTime = TimeOfDay.now();
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final String formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      setState(() {
        controller.text = formattedTime;
      });
    }
  }

  // --- Core Logic: Save Medicine (FIREBASE IMPLEMENTATION) ---
  void _saveMedicine() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Add validation to ensure end date is set if start date is set
    if (_startDateController.text.isNotEmpty &&
        _endDateController.text.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please select an End Date for the treatment duration.')),
        );
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error: You must be logged in to add medicine.')),
        );
      }
      return;
    }

    final List<String> timeSlots = ['Morning', 'Afternoon', 'Night'];
    final int selectedIndex = _timeSlotSelection.indexOf(true);
    final String primaryTimeSlot = timeSlots[selectedIndex];
    final String alarmTimesString =
        _timeControllers.map((c) => c.text.trim()).join(',');

    final newMedicine = Medicine(
      id: '', // Firestore will generate the ID
      name: _medicineNameController.text.trim(),
      dosage: _dosageValue!,
      frequency: _frequencyValue!,
      timeSlot: primaryTimeSlot,
      alarmTimes: alarmTimesString,
      startDate: _startDateController.text,
      endDate: _endDateController.text, // SAVE NEW FIELD
      notes: _notesController.text.trim(),
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medicines')
          .add(newMedicine.toMap());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine added successfully!')),
        );
        Navigator.pop(context, true); // Signal success
      }
    } catch (e) {
      debugPrint('Firebase insertion error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add medicine: $e')),
        );
        Navigator.pop(context, false);
      }
    }
  }
  // --- END OF FIREBASE FIX ---

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFEF6A6A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medicine'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Medicine Name'),
              TextFormField(
                controller: _medicineNameController,
                decoration: _buildInputDecoration('Enter medicine name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 20),
              _buildLabel('Dosage'),
              _buildDropdown(
                  ['1 tablet', '2 tablets', '3 tablets', '1 pill', '2 pills'],
                  _dosageValue, (val) {
                setState(() => _dosageValue = val);
              }),
              const SizedBox(height: 20),
              _buildLabel('Frequency'),
              _buildDropdown(['Once a day', 'Twice a day', '3 times a day'],
                  _frequencyValue, (val) {
                setState(() {
                  _frequencyValue = val;
                  _updateTimeControllers(); // Update controllers when frequency changes
                });
              }),
              const SizedBox(height: 20),

              // Dynamic Time Inputs
              _buildLabel('Specific Alarm Times'),
              ..._timeControllers.asMap().entries.map((entry) {
                int index = entry.key;
                TextEditingController controller = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextFormField(
                    controller: controller,
                    readOnly: true,
                    onTap: () => _selectTime(controller),
                    decoration:
                        _buildInputDecoration('Time for Dose ${index + 1}')
                            .copyWith(
                      hintText: 'Select time for dose ${index + 1}',
                      suffixIcon: const Icon(Icons.access_time),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Select a time' : null,
                  ),
                );
              }).toList(),

              const SizedBox(height: 20),

              _buildLabel('Primary Time Slot (For Visual Grouping)'),
              _buildTimeSlotSelector(),

              const SizedBox(height: 20),

              // Start Date Input
              _buildLabel('Start Date'),
              TextFormField(
                controller: _startDateController,
                decoration: _buildInputDecoration('Select date').copyWith(
                    suffixIcon: const Icon(Icons.calendar_today_outlined)),
                readOnly: true,
                onTap: _selectStartDate,
                validator: (value) =>
                    value!.isEmpty ? 'Please select a date' : null,
              ),

              // NEW: End Date Input
              const SizedBox(height: 20),
              _buildLabel('End Date (Optional)'),
              TextFormField(
                controller: _endDateController,
                decoration: _buildInputDecoration('Select end date').copyWith(
                    suffixIcon: const Icon(Icons.calendar_today_outlined)),
                readOnly: true,
                onTap: _selectEndDate,
              ),

              const SizedBox(height: 20),
              _buildLabel('Notes'),
              TextFormField(
                controller: _notesController,
                decoration: _buildInputDecoration('e.g. Take after food'),
                maxLines: 3,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _saveMedicine, // Calls the Firebase saving function
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets (unchanged) ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF6A6A), width: 2),
      ),
    );
  }

  Widget _buildDropdown(
      List<String> items, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      decoration: _buildInputDecoration(''),
    );
  }

  Widget _buildTimeSlotSelector() {
    return ToggleButtons(
      isSelected: _timeSlotSelection,
      onPressed: (int index) {
        setState(() {
          for (int i = 0; i < _timeSlotSelection.length; i++) {
            _timeSlotSelection[i] = i == index;
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      selectedColor: Colors.white,
      fillColor: const Color(0xFFEF6A6A),
      color: Colors.grey[600],
      constraints: const BoxConstraints(minHeight: 45, minWidth: 100),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: Text('Morning'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: Text('Afternoon'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: Text('Night'),
        ),
      ],
    );
  }
}
