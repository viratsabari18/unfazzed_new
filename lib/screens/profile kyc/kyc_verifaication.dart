import 'package:flutter/material.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/routes/app_routes.dart';

class KycVerifaication extends StatefulWidget {
  const KycVerifaication({super.key});

  @override
  State<KycVerifaication> createState() => _KycVerifaicationState();
}

class _KycVerifaicationState extends State<KycVerifaication> {
  String? selectedDoc;

  final List<String> kycDocs = [
    UserMessages.aadhaarCard,
    UserMessages.panCard,
    UserMessages.drivingLicense,
    UserMessages.voterId,
    UserMessages.passport,
    UserMessages.rationCard,
  ];

  final TextEditingController idController = TextEditingController();

  Widget uploadBox(String text, String image) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: AppSizes.h(context, 18)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Insets.xs),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: AppSizes.h(context, 40)),
          SizedBox(width: Insets.xs),
          Text(text, style: TextStyle(fontSize: AppSizes.w(context, 12))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.reviewBgColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Insets.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios),
                  ),
                  SizedBox(width: Insets.xs),
                  Expanded(
                    child: Text(
                      UserMessages.kycVerification,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: AppSizes.w(context, 16),
                      ),
                    ),
                  ),
                  SizedBox(width: Insets.lg),
                ],
              ),
              SizedBox(height: AppSizes.h(context, 20)),
              Center(
                child: Text(
                  UserMessages.verifyYourIdentity,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: AppSizes.h(context, 8)),
              Center(
                child: Text(
                  UserMessages.kycDescription,
                  style: TextStyle(
                    fontSize: AppSizes.w(context, 12),
                    color: AppColors.naturalBlack54,
                  ),
                ),
              ),
              SizedBox(height: AppSizes.h(context, 20)),
              Text(
                UserMessages.selectDocumentType,
                style: TextStyle(fontSize: AppSizes.w(context, 13)),
              ),
              SizedBox(height: AppSizes.h(context, 6)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: Insets.xsm),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Insets.xs),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedDoc,
                    hint: Text(UserMessages.selectDocument),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: kycDocs.map((e) {
                      return DropdownMenuItem(value: e, child: Text(e));
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedDoc = val;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: AppSizes.h(context, 16)),
              TextField(
                controller: idController,
                decoration: InputDecoration(
                  hintText: UserMessages.enterIdNumber,
                  contentPadding: EdgeInsets.symmetric(horizontal: Insets.xsm),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Insets.xs),
                  ),
                ),
              ),
              SizedBox(height: AppSizes.h(context, 16)),
              uploadBox(
                UserMessages.uploadFrontId,
                UserMessages.kycFrontImage,
              ),
              SizedBox(height: AppSizes.h(context, 12)),
              uploadBox(
                UserMessages.uploadBackId,
                UserMessages.kycBackImage,
              ),
              SizedBox(height: AppSizes.h(context, 50)),
              Container(
                height: AppSizes.h(context, 50),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.submitButtonColor,
                  borderRadius: BorderRadius.circular(Insets.xs),
                ),
                child: Center(
                  child: Text(
                    UserMessages.submitForVerification,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(height: AppSizes.h(context, 10)),
              Center(
                child: Text(
                  UserMessages.kycSecureMessage,
                  style: TextStyle(
                    fontSize: AppSizes.w(context, 10),
                    color: AppColors.naturalBlack54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
