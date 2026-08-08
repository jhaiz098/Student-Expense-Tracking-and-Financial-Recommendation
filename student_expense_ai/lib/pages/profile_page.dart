import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'main_page.dart';

class ProfilePage extends StatefulWidget {
  final bool isFirstSetup;

  const ProfilePage({super.key, this.isFirstSetup = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final fullNameController = TextEditingController();
  final addressController = TextEditingController();

  final schoolController = TextEditingController();
  final schoolAddressController = TextEditingController();

  final workplaceController = TextEditingController();
  final workplaceAddressController = TextEditingController();
  final positionController = TextEditingController();

  DateTime? selectedDateOfBirth;

  String? selectedStatus;

  final List<String> statuses = ["Student", "Working", "Working Student"];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final profile = await DatabaseHelper.instance.getUserProfile();

    if (profile == null) return;

    fullNameController.text = profile["fullName"] ?? "";
    addressController.text = profile["address"] ?? "";

    selectedStatus = profile["currentStatus"];

    if (profile["dateOfBirth"] != null) {
      selectedDateOfBirth = DateTime.tryParse(profile["dateOfBirth"]);
    }

    schoolController.text = profile["school"] ?? "";
    schoolAddressController.text = profile["schoolAddress"] ?? "";

    workplaceController.text = profile["workplace"] ?? "";
    workplaceAddressController.text = profile["workplaceAddress"] ?? "";

    positionController.text = profile["position"] ?? "";

    if (mounted) {
      setState(() {});
    }
  }

  bool get isStudent =>
      selectedStatus == "Student" || selectedStatus == "Working Student";

  bool get isWorking =>
      selectedStatus == "Working" || selectedStatus == "Working Student";

  Future<void> selectDateOfBirth() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> saveProfile() async {
    if (fullNameController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        selectedDateOfBirth == null ||
        selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete your basic information."),
        ),
      );

      return;
    }

    if (isStudent &&
        (schoolController.text.trim().isEmpty ||
            schoolAddressController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete your school information."),
        ),
      );

      return;
    }

    if (isWorking &&
        (workplaceController.text.trim().isEmpty ||
            workplaceAddressController.text.trim().isEmpty ||
            positionController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete your work information.")),
      );

      return;
    }

    final data = {
      "fullName": fullNameController.text.trim(),
      "dateOfBirth": selectedDateOfBirth!.toIso8601String(),
      "address": addressController.text.trim(),
      "currentStatus": selectedStatus,

      "school": isStudent ? schoolController.text.trim() : null,

      "schoolAddress": isStudent ? schoolAddressController.text.trim() : null,

      "workplace": isWorking ? workplaceController.text.trim() : null,

      "workplaceAddress": isWorking
          ? workplaceAddressController.text.trim()
          : null,

      "position": isWorking ? positionController.text.trim() : null,
    };

    final existingProfile = await DatabaseHelper.instance.getUserProfile();

    if (existingProfile == null) {
      await DatabaseHelper.instance.saveUserProfile(data);
    } else {
      await DatabaseHelper.instance.updateUserProfile(data);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile saved successfully.")),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isFirstSetup,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isFirstSetup ? "Set Up Your Profile" : "Profile"),
          automaticallyImplyLeading: !widget.isFirstSetup,
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              if (widget.isFirstSetup) ...[
                const Text(
                  "Welcome!",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(
                  "Tell us a little about yourself so "
                  "the app can provide more personalized "
                  "recommendations.",
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 25),
              ],

              buildTextField(
                controller: fullNameController,
                label: "Full Name",
                icon: Icons.person,
              ),

              const SizedBox(height: 20),

              InkWell(
                onTap: selectDateOfBirth,

                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Date of Birth",
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  child: Text(
                    selectedDateOfBirth == null
                        ? "Select date"
                        : "${selectedDateOfBirth!.month}/"
                              "${selectedDateOfBirth!.day}/"
                              "${selectedDateOfBirth!.year}",
                  ),
                ),
              ),

              const SizedBox(height: 20),

              buildTextField(
                controller: addressController,
                label: "Address",
                icon: Icons.location_on,
              ),

              const SizedBox(height: 25),

              const Text(
                "Current Status",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: selectedStatus,

                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.work_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                hint: const Text("Select your current status"),

                items: statuses.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });
                },
              ),

              const SizedBox(height: 25),

              // -------------------------
              // SCHOOL INFORMATION
              // -------------------------
              if (isStudent) ...[
                const Text(
                  "School Information",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 15),

                buildTextField(
                  controller: schoolController,
                  label: "School",
                  icon: Icons.school,
                ),

                const SizedBox(height: 15),

                buildTextField(
                  controller: schoolAddressController,
                  label: "School Address",
                  icon: Icons.location_on,
                ),

                const SizedBox(height: 25),
              ],

              // -------------------------
              // WORK INFORMATION
              // -------------------------
              if (isWorking) ...[
                const Text(
                  "Work Information",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 15),

                buildTextField(
                  controller: workplaceController,
                  label: "Workplace / Company",
                  icon: Icons.business,
                ),

                const SizedBox(height: 15),

                buildTextField(
                  controller: workplaceAddressController,
                  label: "Workplace Address",
                  icon: Icons.location_on,
                ),

                const SizedBox(height: 15),

                buildTextField(
                  controller: positionController,
                  label: "Position",
                  icon: Icons.badge,
                ),

                const SizedBox(height: 25),
              ],

              SizedBox(
                width: double.infinity,

                height: 52,

                child: ElevatedButton(
                  onPressed: saveProfile,

                  child: Text(
                    widget.isFirstSetup ? "Continue" : "Save Profile",
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    addressController.dispose();

    schoolController.dispose();
    schoolAddressController.dispose();

    workplaceController.dispose();
    workplaceAddressController.dispose();
    positionController.dispose();

    super.dispose();
  }
}
