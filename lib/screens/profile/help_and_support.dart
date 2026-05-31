import 'package:flutter_html/flutter_html.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/models/hep_and_support._model.dart';
import 'package:zeerah/core/services/policy_service.dart';  
  
  
  
  class HelpAndSupport extends StatefulWidget {
    const HelpAndSupport({super.key});
  
    @override
    State<HelpAndSupport> createState() => _HelpAndSupportState();
  }
  
  class _HelpAndSupportState extends State<HelpAndSupport> {
      final PolicyService _service = PolicyService();

  HelpAndSupportModel? helpAndSupportModel;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getHelpSupport();
  }

  Future<void> getHelpSupport() async {
    final response = await _service.getHelpSupport();

    if (response != null) {
      helpAndSupportModel = response;
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
        title: const Text('Help & Support'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Html(
                data: helpAndSupportModel?.data ?? '',
              ),
            ),
    );
    }
  }