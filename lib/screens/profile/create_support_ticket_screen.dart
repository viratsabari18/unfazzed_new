import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/services/helpdesk_service.dart';

class CreateSupportTicketScreen extends StatefulWidget {
  const CreateSupportTicketScreen({super.key});

  @override
  State<CreateSupportTicketScreen> createState() => _CreateSupportTicketScreenState();
}

class _CreateSupportTicketScreenState extends State<CreateSupportTicketScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final HelpDeskService _helpDeskService = HelpDeskService();
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  Future<void> _submitTicket() async {
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();

    if (subject.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final employeeId = userProvider.backendUserId;

    if (employeeId == null || employeeId.isEmpty || employeeId == '1') {
       // If it is '1', it might be the default I set earlier, or it might be coming from provider incorrectly.
       // The user says it should be 166.
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Invalid User ID. Please try logging out and in again.')),
       );
       setState(() => _isLoading = false);
       return;
    }

    final success = await _helpDeskService.saveTicket(
      subject: subject,
      description: description,
      employeeId: employeeId,
      token: userProvider.apiToken,
      attachment: _selectedImage,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket submitted successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit ticket')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Help Desk',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Subject'),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _subjectController,
                  hint: 'e.g. Damaged furniture',
                  maxLines: 1,
                  maxLength: 120,
                  suffixIcon: Icons.article_outlined,
                ),
                const SizedBox(height: 25),
                _buildLabel('Description'),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _descriptionController,
                  hint: 'e.g. During the service, the furniture was accidentally damaged.',
                  maxLines: 5,
                  suffixIcon: Icons.auto_awesome_mosaic_outlined,
                ),
                const SizedBox(height: 25),
                _buildImagePicker(),
                const SizedBox(height: 15),
                Text(
                  'Note: You can upload image with \'jpg\', \'png\', \'jpeg\' extensions & you can select only one image',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 50),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
          ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    int? maxLength,
    required IconData suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
          counterText: maxLength != null ? null : '',
          suffixIcon: Icon(suffixIcon, color: Colors.grey[400], size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.primaryRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: _pickImage,
        child: _selectedImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.close, size: 18, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 40, color: AppColors.primaryRed.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  Text(
                    'Choose Image',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitTicket,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: Text(
          'Submit',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
