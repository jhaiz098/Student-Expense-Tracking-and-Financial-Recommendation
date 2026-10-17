import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'main_page.dart';

const Color _profilePurple = Color(0xFF5B45B5);
const Color _profileBackground = Color(0xFFF7F7FB);
const Color _profileBorder = Color(0xFFE7E4F0);
const Color _profileText = Color(0xFF29263A);
const Color _profileMuted = Color(0xFF6F6B82);

class ProfilePage extends StatefulWidget {
  final bool isFirstSetup;

  const ProfilePage({super.key, this.isFirstSetup = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final addressController = TextEditingController();
  final schoolController = TextEditingController();
  final schoolAddressController = TextEditingController();
  final workplaceController = TextEditingController();
  final workplaceAddressController = TextEditingController();
  final positionController = TextEditingController();

  DateTime? selectedDateOfBirth;
  String? selectedStatus;

  bool isLoading = true;
  bool isSaving = false;

  final List<String> statuses = ['Student', 'Working Student'];

  bool get isStudent =>
      selectedStatus == 'Student' || selectedStatus == 'Working Student';

  bool get isWorking => selectedStatus == 'Working Student';

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final profile = await DatabaseHelper.instance.getUserProfile();

      if (!mounted) return;

      if (profile != null) {
        fullNameController.text = profile['fullName'] ?? '';
        addressController.text = profile['address'] ?? '';
        selectedStatus = profile['currentStatus'];

        final dob = profile['dateOfBirth'];
        if (dob != null) {
          selectedDateOfBirth = DateTime.tryParse(dob.toString());
        }

        schoolController.text = profile['school'] ?? '';
        schoolAddressController.text = profile['schoolAddress'] ?? '';
        workplaceController.text = profile['workplace'] ?? '';
        workplaceAddressController.text = profile['workplaceAddress'] ?? '';
        positionController.text = profile['position'] ?? '';
      }

      setState(() => isLoading = false);
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load your profile. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> selectDateOfBirth() async {
    final now = DateTime.now();
    final initialDate =
        selectedDateOfBirth ?? DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now)
          ? now
          : initialDate.isBefore(DateTime(1900))
          ? DateTime(1900)
          : initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: _profilePurple),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || picked == null) return;

    setState(() => selectedDateOfBirth = picked);
  }

  Future<void> saveProfile() async {
    if (isSaving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (selectedDateOfBirth == null) {
      _showMessage('Please select your date of birth.');
      return;
    }

    if (selectedStatus == null) {
      _showMessage('Please select your current status.');
      return;
    }

    setState(() => isSaving = true);

    final data = {
      'fullName': fullNameController.text.trim(),
      'dateOfBirth': selectedDateOfBirth!.toIso8601String(),
      'address': addressController.text.trim(),
      'currentStatus': selectedStatus,
      'school': isStudent ? schoolController.text.trim() : null,
      'schoolAddress': isStudent ? schoolAddressController.text.trim() : null,
      'workplace': isWorking ? workplaceController.text.trim() : null,
      'workplaceAddress': isWorking
          ? workplaceAddressController.text.trim()
          : null,
      'position': isWorking ? positionController.text.trim() : null,
    };

    try {
      final existingProfile = await DatabaseHelper.instance.getUserProfile();

      if (existingProfile == null) {
        await DatabaseHelper.instance.saveUserProfile(data);
      } else {
        await DatabaseHelper.instance.updateUserProfile(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage(showTutorial: true)),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => isSaving = false);
      _showMessage('Unable to save your profile. Please try again.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: _profilePurple.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _profilePurple, size: 21),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _profileText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _profileMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white12 : _profileBorder),
      ),
      child: child,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter ${label.toLowerCase()}';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _profilePurple, size: 21),
        filled: true,
        fillColor: isDark
            ? Theme.of(context).colorScheme.surface
            : _profileBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _profileBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _profileBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _profilePurple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE04444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE04444), width: 1.5),
        ),
      ),
    );
  }

  Widget _dateOfBirthField() {
    final date = selectedDateOfBirth;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dateText = date == null
        ? 'Select your date of birth'
        : '${date.month.toString().padLeft(2, '0')}/'
              '${date.day.toString().padLeft(2, '0')}/'
              '${date.year}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selectDateOfBirth,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            prefixIcon: const Icon(
              Icons.calendar_month_rounded,
              color: _profilePurple,
            ),
            suffixIcon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _profileMuted,
            ),
            filled: true,
            fillColor: isDark
                ? Theme.of(context).colorScheme.surface
                : _profileBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _profileBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _profileBorder),
            ),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 14,
              color: date == null
                  ? _profileMuted
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      value: selectedStatus,
      isExpanded: true,
      validator: (value) {
        if (value == null) {
          return 'Please select your current status';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Current Status',
        prefixIcon: const Icon(
          Icons.work_outline_rounded,
          color: _profilePurple,
        ),
        filled: true,
        fillColor: isDark
            ? Theme.of(context).colorScheme.surface
            : _profileBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _profileBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _profileBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _profilePurple, width: 1.5),
        ),
      ),
      hint: const Text('Select your current status'),
      items: statuses.map((status) {
        return DropdownMenuItem<String>(value: status, child: Text(status));
      }).toList(),
      onChanged: (value) {
        setState(() => selectedStatus = value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !widget.isFirstSetup,
      child: Scaffold(
        backgroundColor: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : _profileBackground,
        appBar: AppBar(
          title: Text(
            widget.isFirstSetup ? 'Set Up Your Profile' : 'My Profile',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          centerTitle: true,
          automaticallyImplyLeading: !widget.isFirstSetup,
          backgroundColor: isDark
              ? Theme.of(context).scaffoldBackgroundColor
              : _profileBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _profilePurple),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 35),

                  children: [
                    const SizedBox(height: 12),

                    // Basic Information — no outer card
                    _sectionTitle(
                      'Basic Information',
                      subtitle: 'Tell us about yourself.',
                      icon: Icons.person_outline_rounded,
                    ),
                    _textField(
                      controller: fullNameController,
                      label: 'Full Name',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 15),
                    _dateOfBirthField(),
                    const SizedBox(height: 15),
                    _textField(
                      controller: addressController,
                      label: 'Address',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 15),
                    _statusSelector(),

                    if (isStudent) ...[
                      const SizedBox(height: 30),
                      _sectionTitle(
                        'School Information',
                        subtitle: 'Where you study.',
                        icon: Icons.school_outlined,
                      ),
                      _textField(
                        controller: schoolController,
                        label: 'School',
                        icon: Icons.account_balance_outlined,
                      ),
                      const SizedBox(height: 15),
                      _textField(
                        controller: schoolAddressController,
                        label: 'School Address',
                        icon: Icons.location_on_outlined,
                      ),
                    ],

                    if (isWorking) ...[
                      const SizedBox(height: 30),
                      _sectionTitle(
                        'Work Information',
                        subtitle: 'Tell us about your current job.',
                        icon: Icons.business_center_outlined,
                      ),
                      _textField(
                        controller: workplaceController,
                        label: 'Workplace / Company',
                        icon: Icons.business_outlined,
                      ),
                      const SizedBox(height: 15),
                      _textField(
                        controller: workplaceAddressController,
                        label: 'Workplace Address',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 15),
                      _textField(
                        controller: positionController,
                        label: 'Position',
                        icon: Icons.badge_outlined,
                      ),
                    ],

                    const SizedBox(height: 28),

                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _profilePurple,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _profilePurple.withValues(
                            alpha: 0.55,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.isFirstSetup
                                        ? Icons.arrow_forward_rounded
                                        : Icons.check_circle_outline_rounded,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 9),
                                  Text(
                                    widget.isFirstSetup
                                        ? 'Continue'
                                        : 'Save Profile',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    if (widget.isFirstSetup) ...[
                      const SizedBox(height: 13),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: _profileMuted,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Your information helps personalize your experience.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _profileMuted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
