import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'main_page.dart';

const Color _profilePurple = Color(0xFF5B45B5);
const Color _profileDarkPurple = Color(0xFFB9A8FF);
const Color _profileBackground = Color(0xFFF7F7FB);
const Color _profileDarkBackground = Color(0xFF15131E);
const Color _profileDarkCard = Color(0xFF211D2D);
const Color _profileBorder = Color(0xFFE7E4F0);
const Color _profileDarkBorder = Color(0xFF393246);
const Color _profileText = Color(0xFF29263A);
const Color _profileDarkText = Color(0xFFF5F2FF);
const Color _profileMuted = Color(0xFF6F6B82);
const Color _profileDarkMuted = Color(0xFFB7B2C8);
const Color _profileRed = Color(0xFFE05252);

class ProfilePage extends StatefulWidget {
  final bool isFirstSetup;

  const ProfilePage({super.key, this.isFirstSetup = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
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

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _background =>
      _isDark ? _profileDarkBackground : _profileBackground;

  Color get _card => _isDark ? _profileDarkCard : Colors.white;

  Color get _border => _isDark ? _profileDarkBorder : _profileBorder;

  Color get _text => _isDark ? _profileDarkText : _profileText;

  Color get _muted => _isDark ? _profileDarkMuted : _profileMuted;

  Color get _accent => _isDark ? _profileDarkPurple : _profilePurple;

  Color get _fieldBackground =>
      _isDark ? const Color(0xFF2A2538) : _profileBackground;

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
        firstNameController.text = profile['firstName'] ?? '';
        middleNameController.text = profile['middleName'] ?? '';
        lastNameController.text = profile['lastName'] ?? '';

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
      _showMessage('Unable to load your profile. Please try again.');
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
        final dark = Theme.of(context).brightness == Brightness.dark;
        final accent = dark ? _profileDarkPurple : _profilePurple;
        final background = dark ? _profileDarkCard : Colors.white;
        final textColor = dark ? _profileDarkText : _profileText;

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: accent,
              onPrimary: dark ? _profileDarkBackground : Colors.white,
              surface: background,
              onSurface: textColor,
            ),
            dialogTheme: DialogThemeData(backgroundColor: background),
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
      'firstName': firstNameController.text.trim(),
      'middleName': middleNameController.text.trim().isEmpty
          ? null
          : middleNameController.text.trim(),
      'lastName': lastNameController.text.trim(),
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
        SnackBar(
          backgroundColor: _isDark ? Colors.white : const Color(0xFF5B45B5),
          content: Text(
            'Profile saved successfully!',
            style: TextStyle(
              color: _isDark ? const Color(0xFF29263A) : Colors.white,
            ),
          ),
        ),
      );

      if (widget.isFirstSetup) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainPage(showTutorial: true)),
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => isSaving = false);
      _showMessage('Unable to save your profile. Please try again.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: _isDark ? _profileText : Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _isDark ? Colors.white : _profilePurple,
        ),
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
                color: _accent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _accent, size: 21),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool requiredField = true,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      style: TextStyle(color: _text, fontSize: 14),
      validator: requiredField
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter ${label.toLowerCase()}';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _muted),
        hintText: hint,
        hintStyle: TextStyle(color: _muted),
        prefixIcon: Icon(icon, color: _accent, size: 21),
        filled: true,
        fillColor: _fieldBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _profileRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _profileRed, width: 1.5),
        ),
      ),
    );
  }

  Widget _dateOfBirthField() {
    final date = selectedDateOfBirth;

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
            labelStyle: TextStyle(color: _muted),
            prefixIcon: Icon(Icons.calendar_month_rounded, color: _accent),
            suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: _muted),
            filled: true,
            fillColor: _fieldBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _accent, width: 1.5),
            ),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 14,
              color: date == null ? _muted : _text,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusSelector() {
    return DropdownButtonFormField<String>(
      initialValue: selectedStatus,
      isExpanded: true,
      dropdownColor: _card,
      style: TextStyle(color: _text, fontSize: 14),
      validator: (value) {
        if (value == null) {
          return 'Please select your current status';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Current Status',
        labelStyle: TextStyle(color: _muted),
        prefixIcon: Icon(Icons.work_outline_rounded, color: _accent),
        filled: true,
        fillColor: _fieldBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accent, width: 1.5),
        ),
      ),
      hint: Text('Select your current status', style: TextStyle(color: _muted)),
      items: statuses.map((status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(status, style: TextStyle(color: _text)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => selectedStatus = value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isFirstSetup,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: Text(
            widget.isFirstSetup ? 'Set Up Your Profile' : 'My Profile',
            style: TextStyle(color: _text, fontWeight: FontWeight.w800),
          ),
          centerTitle: true,
          automaticallyImplyLeading: !widget.isFirstSetup,
          backgroundColor: _background,
          foregroundColor: _text,
          elevation: 0,
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: _accent))
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 35),
                  children: [
                    _sectionTitle(
                      'Basic Information',
                      subtitle: 'Tell us about yourself.',
                      icon: Icons.person_outline_rounded,
                    ),
                    _textField(
                      controller: firstNameController,
                      label: 'First Name',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 15),
                    _textField(
                      controller: middleNameController,
                      label: 'Middle Name (Optional)',
                      icon: Icons.person_outline_rounded,
                      requiredField: false,
                    ),
                    const SizedBox(height: 15),
                    _textField(
                      controller: lastNameController,
                      label: 'Last Name',
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
                          backgroundColor: _accent,
                          foregroundColor: _isDark
                              ? _profileDarkBackground
                              : Colors.white,
                          disabledBackgroundColor: _accent.withValues(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: _muted,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Your information helps personalize your experience.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _muted, fontSize: 11),
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
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    addressController.dispose();
    schoolController.dispose();
    schoolAddressController.dispose();
    workplaceController.dispose();
    workplaceAddressController.dispose();
    positionController.dispose();
    super.dispose();
  }
}
