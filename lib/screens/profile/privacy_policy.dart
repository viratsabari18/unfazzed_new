// privacy_policy.dart

import 'package:flutter_html/flutter_html.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/models/policy_model.dart';
import 'package:zeerah/core/services/policy_service.dart';



class PrivacyPolicy extends StatefulWidget {
  const PrivacyPolicy({super.key});

  @override
  State<PrivacyPolicy> createState() => _PrivacyPolicyState();
}

class _PrivacyPolicyState extends State<PrivacyPolicy> {
  final PolicyService _service = PolicyService();

  PolicyModel? policyModel;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getPrivacyPolicy();
  }

  Future<void> getPrivacyPolicy() async {
    final response = await _service.getPrivacyPolicy();

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
        title: const Text('Privacy Policy'),
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