import 'package:zeerah/core/common/app_exports.dart';

class ServiceCetagorices extends StatelessWidget {
  final String title;

  const ServiceCetagorices({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    List<String> titles = [];
    List<String> images = [];

    /// DATA SETUP
    if (title.toLowerCase() == "cleaning") {
      titles = [
        "Full Home Cleaning",
        "Bathroom Cleaning",
        "Kitchen Cleaning",
        "Living Room Cleaning",
      ];

      images = [
        "lib/assets/images/cleaning_full_house.png",
        "lib/assets/images/cleaning_bathroom.png",
        "lib/assets/images/cleaning_kitchan.png",
        "lib/assets/images/cleaning_living_room.png",
      ];
    } else if (title.toLowerCase() == "electrician") {
      titles = [
        "Fan Installation",
        "Switch & Socket",
        "Wiring Repair",
        "Inverter Installation",
        "Light",
        "Doorbell & Security",
        "Appliances",
        "Book Consulting",
      ];

      images = [
        "lib/assets/images/electrical_fan.png",
        "lib/assets/images/electrical_swicth.png",
        "lib/assets/images/electrical_wireing.png",
        "lib/assets/images/electrical_inverter.png",
        "lib/assets/images/electrical_light.png",
        "lib/assets/images/electrical_doorbell.png",
        "lib/assets/images/electrical_appliences.png",
        "lib/assets/images/electrical_book_consulting.png",
      ];
    } else if (title.toLowerCase() == "pest control") {
      titles = ["Cockroach Control", "Termite Control", "Bed Bugs Control"];
      images = [
            "lib/assets/images/cockroach_control.png"
            "lib/assets/images/beg_bugs_control.png"
            "lib/assets/images/termite_control.png",
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GridView.builder(
                  itemCount: titles.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    return _buildCard(
                      title: titles[index],
                      image: images[index],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ FIXED CARD UI (MATCHES IMAGE DESIGN)
  Widget _buildCard({required String title, required String image}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFD580), // full yellow card
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// IMAGE
          SizedBox(height: 65, child: Image.asset(image, fit: BoxFit.cover)),

          /// TEXT
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyles.bodyMedium.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
