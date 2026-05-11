import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/dashboard_provider.dart';
import 'package:provider/provider.dart';

class SearchBox extends StatefulWidget {
  const SearchBox({super.key});

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Insets.sm, vertical: Insets.xs),
      padding: EdgeInsets.symmetric(horizontal: Insets.xsm),
      height: AppSizes.h(context, 50),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: Colors.grey,
            size: 24,
          ),
          SizedBox(width: Insets.xs),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: (value) {
                Provider.of<DashboardProvider>(context, listen: false).searchCategory(value);
              },
              decoration: InputDecoration(
                hintText: UserMessages.searchForService,
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              ),
              onChanged: (value) {
                setState(() {}); // Update to show/hide clear icon
              },
            ),
          ),
        ],
      ),
    );
  }
}
