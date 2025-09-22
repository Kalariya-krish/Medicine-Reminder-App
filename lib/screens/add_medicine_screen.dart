// In a file named: lib/screens/add_medicine_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add 'intl' package to pubspec.yaml for date formatting

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

  String? _dosageValue = '1 tablet';
  String? _frequencyValue = 'Once a day';

  // State for the toggle buttons
  final List<bool> _timeSlotSelection = [
    true,
    false,
    false
  ]; // Morning, Afternoon, Night

  @override
  void dispose() {
    _medicineNameController.dispose();
    _notesController.dispose();
    _startDateController.dispose();
    super.dispose();
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
                setState(() => _frequencyValue = val);
              }),
              const SizedBox(height: 20),
              _buildLabel('Time Slot'),
              _buildTimeSlotSelector(),
              const SizedBox(height: 20),
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
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // TODO: Add logic to save medicine reminder
                      Navigator.pop(context);
                    }
                  },
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

  // --- Helper Widgets for Form Fields ---

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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  Widget _buildDropdown(
      List<String> items, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
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
      constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
      children: const [
        Text('Morning'),
        Text('Afternoon'),
        Text('Night'),
      ],
    );
  }
}
