import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/address_provider.dart';
import 'package:zeerah/core/providers/dashboard_provider.dart';
import 'package:zeerah/screens/home/expolore_categories.dart';
import 'package:zeerah/screens/home/expolre_categories_stack.dart';
import 'package:zeerah/screens/home/home_offer_section.dart';
import 'package:zeerah/screens/home/home_top_banner.dart';
import 'package:zeerah/screens/home/refer_section.dart';
import 'package:zeerah/screens/home/reliable_and_trustworthy_section.dart';
import 'package:zeerah/screens/home/seracbox.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.naturalWhite,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primaryRed,

          onRefresh: () async {
            await context.read<DashboardProvider>().fetchCategories();

            await context
                .read<AddressProvider>()
                .setCurrentLocationAutomatically();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const HomeTopBanner(),
                    Transform.translate(
                      offset: const Offset(0, -30),

                      // child: const HomeOfferSection(),
                      child: SearchBox(),
                    ),
                  ],
                ),
              ),
              // const SliverToBoxAdapter(child: SearchBox()),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              const SliverToBoxAdapter(child: ExpoloreCategories()),
              const SliverToBoxAdapter(child: ExpolreCategoriesStack()),
              SliverToBoxAdapter(child: ReliableAndTrustworthySection()),
              SliverToBoxAdapter(child: ReferSection()),
            ],
          ),
        ),
      ),
    );
  }
}
