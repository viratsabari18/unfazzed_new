

import 'package:flutter_html/flutter_html.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/models/policy_model.dart';
import 'package:zeerah/core/services/policy_service.dart';



class TermsAndCondtion extends StatefulWidget {
  const TermsAndCondtion({super.key});

  @override
  State<TermsAndCondtion> createState() => _TermsAndCondtionState();
}

class _TermsAndCondtionState extends State<TermsAndCondtion> {
  final PolicyService _service = PolicyService();

  PolicyModel? policyModel;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getTermsConditions();
  }

  Future<void> getTermsConditions() async {
    final response = await _service.getTermsConditions();

    if (response != null) {
      policyModel = response;
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.naturalWhite,
      appBar: AppBar(
                backgroundColor:AppColors.naturalWhite ,
        elevation: 0,
        surfaceTintColor: AppColors.naturalWhite,
        title: const Text('Terms & Conditions'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Html(
                data: policyModel?.data ?? '',
              ),
            ),
    );
  }
}