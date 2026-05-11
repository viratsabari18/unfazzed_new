
import 'package:zeerah/core/common/app_exports.dart';

class AppSizes {
  static double width(BuildContext context) => MediaQuery.of(context).size.width;
  static double height(BuildContext context) => MediaQuery.of(context).size.height;
  static double w(BuildContext context, double value) => width(context) * (value / 375);
  static double h(BuildContext context, double value) => height(context) * (value / 812);
}
