import 'package:flutter/material.dart';
import 'user_messages.dart';

class CategoryItem {
  final int id;        
  final String title;
  final String image;
  final String subtitle;
  final String price;
  final Color color;
  final String rating;
  final List<Map<String, String>> howItsDone;
  final List<String> whatsIncluded;
  final List<String> whatsNotIncluded;
  final List<Map<String, dynamic>> customerReviews;

  const CategoryItem({
    required this.id,
    required this.title,
    required this.image,
    this.subtitle = "Professional service at your doorstep",
    this.price = "0",
    this.color = const Color(0xFFF5F5F5),
    this.rating = "4.0",
    this.howItsDone = const [],
    this.whatsIncluded = const [],
    this.whatsNotIncluded = const [],
    this.customerReviews = const [],
  });
}

class CategoryData {
  static const List<Map<String, String>> categories = [
    {"title": "Cleaning", "image": UserMessages.cleaning},
    {"title": "Electrician", "image": UserMessages.electrician},
    {"title": "Pest\nControl", "image": UserMessages.pestControl},
    {"title": "Plumber", "image": UserMessages.plumber},
    {"title": "Appliance\nRepair", "image": UserMessages.applianceRepair},
  ];

  static const Map<String, List<CategoryItem>> categoryMap = {
    "Cleaning": [
      CategoryItem(
        title: "Home Cleaning",
        subtitle: "Home spotless quickly",
        price: "240",
        image: "lib/assets/images/cleaning1.png",
        color: Color(0xFFE3F2FD),
        rating: "4.9",
        howItsDone: [
          {"title": "Dusting & Scrubbing", "image": "lib/assets/images/cleaning_living_room.png"},
          {"title": "Floor Cleaning", "image": "lib/assets/images/cleaning_kitchan.png"},
          {"title": "Bathroom Sanitizing", "image": "lib/assets/images/cleaning_bathroom.png"},
          {"title": "Final Touch-up", "image": "lib/assets/images/cleaning_full_house.png"},
        ],
        whatsIncluded: [
          "Room floor scrubbing",
          "Cabinets & furniture exterior",
          "Ceiling & fan dusting",
          "Sofa & mattress",
          "Doors, windows & mirrors",
          "Switch board & fixture",
          "Kitchen sink area, tiles & slabs",
          "Stove & kitchen appliances",
          "Cabinet exterior & interior",
          "Bathroom floor scrubbing",
          "Toilet seat & fixtures",
          "Balcony",
        ],
        whatsNotIncluded: [
          "Glue/paint stains/sticker removal",
          "Sofa & furniture cleaning",
          "Wet wiping of walls & ceiling",
          "Cleaning of terrace & inaccesible areas",
        ],
        customerReviews: [
          {
            "name": "Elizabeth",
            "rating": 5,
            "comment": "Very good service, my home was neatly cleaned and arranged kudos to the team",
            "date": "2 days ago"
          },
          {
            "name": "James",
            "rating": 4,
            "comment": "Great work on the kitchen cabinets!",
            "date": "5 days ago"
          }
        ], id: 0,
      ),
      CategoryItem(
        id:0,
        title: "Bathroom Cleaning",
        subtitle: "Sparkling clean bathrooms",
        price: "120",
        image: "lib/assets/images/cleaning2.png",
        color: Color(0xFFF3E5F5),
        rating: "4.8",
        howItsDone: [
          {"title": "Toilet Disinfection", "image": "lib/assets/images/cleaning_bathroom.png"},
          {"title": "Tile Scrubbing", "image": "lib/assets/images/cleaning_bathroom.png"},
          {"title": "Sink & Tap Polish", "image": "lib/assets/images/cleaning_bathroom.png"},
          {"title": "Glass & Mirror", "image": "lib/assets/images/cleaning_bathroom.png"},
        ],
        whatsIncluded: [
          "Toilet seat & fixtures",
          "Bathroom floor scrubbing",
          "Wall tiles deep cleaning",
          "Mirror & glass polishing",
          "Washbasin & tap descale",
          "Grout & corner scrub",
        ],
        whatsNotIncluded: [
          "Ceiling repair",
          "Drain blockage removal",
          "Deep mold treatment",
        ],
        customerReviews: [
          {
            "name": "Sarah",
            "rating": 5,
            "comment": "Absolutely sparkling! The tiles haven't looked this good in years.",
            "date": "1 day ago"
          }
        ],
      ),
      CategoryItem(
        title: "Kitchen Cleaning",
        subtitle: "Degreasing and sanitizing",
        price: "150",
        image: "lib/assets/images/cleaning3.png",
        color: Color(0xFFFFF9C4),
        rating: "4.7",
        howItsDone: [
          {"title": "Stove & Hobs", "image": "lib/assets/images/cleaning_kitchan.png"},
          {"title": "Countertop Sanitizing", "image": "lib/assets/images/cleaning_kitchan.png"},
          {"title": "Cabinet Degreasing", "image": "lib/assets/images/cleaning_kitchan.png"},
          {"title": "Kitchen Sink Scrub", "image": "lib/assets/images/cleaning_kitchan.png"},
        ],
        whatsIncluded: [
          "Kitchen sink area",
          "Tiles & slabs",
          "Stove & kitchen appliances",
          "Cabinet exterior & interior",
          "Exhaust fan & chimney exterior",
          "Floor deep scrubbing",
        ],
        whatsNotIncluded: [
          "Refrigerator interior",
          "Cooking for customers",
          "Utensil washing",
        ],
        customerReviews: [
          {
            "name": "David",
            "rating": 4,
            "comment": "Very thorough with the cabinets. Recommended!",
            "date": "3 days ago"
          }
        ],id:0,
      ),
      CategoryItem(
        title: "Living Room Cleaning",
        subtitle: "Deep dust removal",
        price: "100",
        image: "lib/assets/images/cleaning4.png",
        color: Color(0xFFEEEEEE),
        rating: "4.6",
        howItsDone: [
          {"title": "Sofa Dusting", "image": "lib/assets/images/cleaning_living_room.png"},
          {"title": "Floor Polish", "image": "lib/assets/images/cleaning_living_room.png"},
          {"title": "Window & Sills", "image": "lib/assets/images/cleaning_living_room.png"},
          {"title": "TV Unit Wiping", "image": "lib/assets/images/cleaning_living_room.png"},
        ],
        whatsIncluded: [
          "Room floor scrubbing",
          "Sofa & upholstery dusting",
          "Ceiling & fan dusting",
          "Doors, windows & mirrors",
          "Switch board & fixture",
          "Furniture exterior wiping",
        ],
        whatsNotIncluded: [
          "Carpet shampooing",
          "Curtain dry cleaning",
          "Wall painting",
        ],
        customerReviews: [
          {
            "name": "Michael",
            "rating": 5,
            "comment": "Quick and very effective. House feels fresh.",
            "date": "4 days ago"
          }
        ],id:0,
      ),
    ],
    "Electrician": [
      CategoryItem(
        title: "Fan Installation",
        subtitle: "Safe and secure fitting",
        price: "80",
        image: "lib/assets/images/elec1.png",
        color: Color(0xFFE8F5E9),
        rating: "4.8",
        howItsDone: [
          {"title": "Safety Check", "image": "lib/assets/images/elec1.png"},
          {"title": "Blade Assembly", "image": "lib/assets/images/elec2.png"},
          {"title": "Installation", "image": "lib/assets/images/elec3.png"},
          {"title": "Speed Test", "image": "lib/assets/images/elec4.png"},
        ],
        whatsIncluded: [
          "Fan mounting",
          "Regulator connection",
          "Initial balancing",
          "Standard height setup",
        ],
        whatsNotIncluded: [
          "Fan purchase cost",
          "New wiring pull",
          "False ceiling repair",
        ],
        customerReviews: [
          {"name": "Robert", "rating": 5, "comment": "Quick installation and very safe.", "date": "1 day ago"}
        ],id:0,
      ),
      CategoryItem(
        title: "Switch & Socket",
        subtitle: "Repair or replacement",
        price: "60",
        image: "lib/assets/images/elec2.png",
        color: Color(0xFFE3F2FD),
        rating: "4.7",
        howItsDone: [
          {"title": "Terminal Check", "image": "lib/assets/images/elec5.png"},
          {"title": "Old Plate removal", "image": "lib/assets/images/elec6.png"},
          {"title": "New Installation", "image": "lib/assets/images/elec7.png"},
        ],
        whatsIncluded: [
          "Wiring verification",
          "New plate fitting",
          "Burn check",
        ],
        whatsNotIncluded: [
          "Internal wall wiring",
          "MCB replacement",
        ],
        customerReviews: [
          {"name": "Linda", "rating": 4, "comment": "Neat work on the living room sockets.", "date": "3 days ago"}
        ],id:0,
      ),
      CategoryItem(
        title: "Wiring Repair",
        subtitle: "Complete circuit check",
        price: "150",
        image: "lib/assets/images/elec3.png",
        color: Color(0xFFFFF3E0),
        rating: "4.9",
        howItsDone: [
          {"title": "Circuit Testing", "image": "lib/assets/images/elec1.png"},
          {"title": "Identify Fault", "image": "lib/assets/images/elec2.png"},
          {"title": "Wire Replacement", "image": "lib/assets/images/elec3.png"},
        ],
        whatsIncluded: [
          "Main panel check",
          "Joint tightening",
          "Isolation test",
          "Earth leakage check",
        ],
        whatsNotIncluded: [
          "Concealed wiring digging",
          "New conduit pipe",
          "Wall painting post-repair",
        ],
        customerReviews: [
          {"name": "Kevin", "rating": 5, "comment": "Expert handling of complex shorts.", "date": "1 week ago"}
        ],id:0,
      ),
      CategoryItem(
        title: "Inverter",
        subtitle: "Setup and maintenance",
        price: "200",
        image: "lib/assets/images/elec4.png",
        color: Color(0xFFF3E5F5),
        rating: "4.8",
        howItsDone: [
          {"title": "Terminal Check", "image": "lib/assets/images/elec5.png"},
          {"title": "Acid Leveling", "image": "lib/assets/images/elec6.png"},
          {"title": "Load Balancing", "image": "lib/assets/images/elec7.png"},
        ],
        whatsIncluded: [
          "Battery health check",
          "Backup duration test",
          "Wire insulation check",
          "Distilled water top-up",
        ],
        whatsNotIncluded: [
          "New battery cost",
          "PCB card repair",
          "Relocation of inverter",
        ],
        customerReviews: [
          {"name": "Suresh", "rating": 5, "comment": "Very professional setup. Backup is great.", "date": "3 days ago"}
        ],id:0,
      ),
      CategoryItem(
        title: "Light Fitting",
        subtitle: "Indoor and outdoor lighting",
        price: "70",
        image: "lib/assets/images/elec5.png",
        color: Color(0xFFFFF9C4),
        rating: "4.7",
        howItsDone: [
          {"title": "Holder Check", "image": "lib/assets/images/elec1.png"},
          {"title": "Fitting Mounting", "image": "lib/assets/images/elec2.png"},
          {"title": "Illumination Test", "image": "lib/assets/images/elec3.png"},
        ],
        whatsIncluded: [
          "Bracket mounting",
          "Connector safety clamping",
          "Height adjustment",
          "Beam centering",
        ],
        whatsNotIncluded: [
          "False ceiling cutting",
          "Decorative light cost",
          "External ladder hire",
        ],
        customerReviews: [
          {"name": "Anita", "rating": 5, "comment": "The dining lights look perfect now.", "date": "2 days ago"}
        ],id:0,
      ),
    ],
    "Pest\nControl": [
      CategoryItem(
        title: "Cockroach Control",
        subtitle: "Gel and spray treatment",
        price: "150",
        image: "lib/assets/images/pest1.png",
        color: Color(0xFFFFEBEE),
        rating: "4.9",
        howItsDone: [
          {"title": "Inspection", "image": "lib/assets/images/pest1.png"},
          {"title": "Gel Spotting", "image": "lib/assets/images/pest2.png"},
          {"title": "Spray Shield", "image": "lib/assets/images/pest3.png"},
        ],
        whatsIncluded: [
          "Kitchen gel treatment",
          "Drainage cleaning",
          "Main door shielding",
        ],
        whatsNotIncluded: [
          "Full house sanitization",
          "Rodent control",
        ],
        customerReviews: [
          {"name": "Mike", "rating": 5, "comment": "No more roaches after one visit!", "date": "1 week ago"}
        ],id:0,
      ),
      CategoryItem(
        title: "Termite Control",
        subtitle: "Advanced drilling treatment",
        price: "350",
        image: "lib/assets/images/pest2.png",
        color: Color(0xFFEFEBE9),
        rating: "4.9",
        howItsDone: [
          {"title": "Soil Drilling", "image": "lib/assets/images/pest1.png"},
          {"title": "Chemical Injection", "image": "lib/assets/images/pest2.png"},
          {"title": "Perimeter Shield", "image": "lib/assets/images/pest3.png"},
        ],
        whatsIncluded: [
          "Foundation drilling",
          "Advanced anti-termite fluid",
          "Wall hole plugging",
          "5-year certificate",
        ],
        whatsNotIncluded: [
          "Furniture restoration",
          "New wood installation",
          "Structural repair",
        ],
        customerReviews: [
          {"name": "Mark", "rating": 5, "comment": "The team was very thorough with the drilling.", "date": "1 week ago"}
        ],id:0,
      ),
      CategoryItem(
        title: "Bed Bugs Control",
        subtitle: "Multi-stage odor-free spray",
        price: "200",
        image: "lib/assets/images/pest3.png",
        color: Color(0xFFE1F5FE),
        rating: "4.8",
        howItsDone: [
          {"title": "Steam Treatment", "image": "lib/assets/images/pest1.png"},
          {"title": "Crevice Spraying", "image": "lib/assets/images/pest2.png"},
          {"title": "Mattress Vacuuming", "image": "lib/assets/images/pest3.png"},
        ],
        whatsIncluded: [
          "Mattress deep treatment",
          "Curtain disinfection",
          "Nook & corner spray",
          "Follow-up checkups",
        ],
        whatsNotIncluded: [
          "Laundry service",
          "Linen replacement",
          "Room fumigation",
        ],
        customerReviews: [
          {"name": "Jane", "rating": 5, "comment": "Finally a peaceful night's sleep. Thank you!", "date": "2 days ago"}
        ],id:0,
      ),
    ],
    "Plumber": [
      CategoryItem(
        title: "Tap Repair",
        subtitle: "Fixing leaks and breaks",
        price: "50",
        image: "lib/assets/images/pl1.png",
        color: Color(0xFFE0F2F1),
        rating: "4.6",
        howItsDone: [
          {"title": "Washer Check", "image": "lib/assets/images/pl1.png"},
          {"title": "O-ring Replace", "image": "lib/assets/images/pl2.png"},
          {"title": "Pressure Test", "image": "lib/assets/images/pl3.png"},
        ],
        whatsIncluded: [
          "Washer Replacement",
          "Spout cleaning",
          "Gland packing",
        ],
        whatsNotIncluded: [
          "New Tap cost",
          "Wall breakage",
        ],
        customerReviews: [
          {"name": "Chris", "rating": 4, "comment": "Fixed the drip finally.", "date": "2 days ago"}
        ],id:0,
      ),
      CategoryItem(
        title: "Pipe Leakage",
        subtitle: "High-pressure pipe repair",
        price: "120",
        image: "lib/assets/images/pl2.png",
        color: Color(0xFFE8EAF6),
        rating: "4.7",
        howItsDone: [
          {"title": "Leak Detection", "image": "lib/assets/images/pl1.png"},
          {"title": "Joint Inspection", "image": "lib/assets/images/pl2.png"},
          {"title": "Sealant Application", "image": "lib/assets/images/pl4.png"},
          {"title": "Pressure Test", "image": "lib/assets/images/pl5.png"},
        ],
        whatsIncluded: [
          "Leak spot identification",
          "Epoxy sealing",
          "Joint tightening",
          "Main line pressure check",
        ],
        whatsNotIncluded: [
          "New pipe purchase",
          "Wall tile repair",
          "External ladder charge",
        ],
        customerReviews: [
          {"name": "Robert", "rating": 5, "comment": "Saved my kitchen from a flood!", "date": "1 day ago"}
        ],id:0,
      ),
      CategoryItem(
        title: "Toilet Repair",
        subtitle: "Flush and block management",
        price: "180",
        image: "lib/assets/images/pl3.png",
        color: Color(0xFFF3E5F5),
        rating: "4.8",
        howItsDone: [
          {"title": "Flush Mechanism Check", "image": "lib/assets/images/pl1.png"},
          {"title": "Valve Adjustment", "image": "lib/assets/images/pl2.png"},
          {"title": "Leakproof Sealant", "image": "lib/assets/images/pl3.png"},
          {"title": "Full Flush Test", "image": "lib/assets/images/pl5.png"},
        ],
        whatsIncluded: [
          "Flush valve repair",
          "Ball-cock adjustment",
          "Leak-proof washer fitting",
          "Minor clog removal",
        ],
        whatsNotIncluded: [
          "New toilet seat",
          "Full commode replacement",
          "Drain pipe excavation",
        ],
        customerReviews: [
          {"name": "Lisa", "rating": 5, "comment": "Excellent work on the guest bathroom.", "date": "4 days ago"}
        ],id:0,
      ),
    ],
    "Appliance\nRepair": [
      CategoryItem(
        title: "AC Repair",
        subtitle: "Cooling and gas charging",
        price: "250",
        image: "lib/assets/images/wo1.png",
        color: Color(0xFFE0F7FA),
        rating: "4.8",
        howItsDone: [
          {"title": "Filter Jet Wash", "image": "lib/assets/images/wo1.png"},
          {"title": "Gas Pressure check", "image": "lib/assets/images/wo2.png"},
          {"title": "Drain Clean", "image": "lib/assets/images/wo3.png"},
        ],
        whatsIncluded: [
          "Indoor Jet wash",
          "Outdoor grill clean",
          "Amps Check",
        ],
        whatsNotIncluded: [
          "Gas refill cost",
          "PCB repair",
        ],
        customerReviews: [
          {"name": "Anna", "rating": 5, "comment": "AC is cooling like new!", "date": "1 day ago"}
        ],id:0,
      ),
      CategoryItem(
        title: "Fridge Repair",
        subtitle: "Compressor and gas fix",
        price: "220",
        image: "lib/assets/images/wo2.png",
        color: Color(0xFFFFFDE7),
        rating: "4.7",
        howItsDone: [
          {"title": "Compressor Diagnosis", "image": "lib/assets/images/wo1.png"},
          {"title": "Gas Pressure Check", "image": "lib/assets/images/wo2.png"},
          {"title": "Thermostat Testing", "image": "lib/assets/images/wo3.png"},
          {"title": "Door Seal Inspect", "image": "lib/assets/images/wo2.png"},
        ],
        whatsIncluded: [
          "Cooling coil cleaning",
          "Relay & capacitor test",
          "Drain pipe clearing",
          "Gas leakage detection",
        ],
        whatsNotIncluded: [
          "New compressor cost",
          "Main PCB board repair",
          "Body dent/paint work",
        ],
        customerReviews: [
          {"name": "Daniel", "rating": 5, "comment": "Fixed the cooling issue in 30 minutes.", "date": "3 days ago"}
        ],id:0,
      ),
      CategoryItem(
        title: "TV Installation",
        subtitle: "Wall mount and setup",
        price: "100",
        image: "lib/assets/images/wo3.png",
        color: Color(0xFFFCE4EC),
        rating: "4.9",
        howItsDone: [
          {"title": "Wall Strength Check", "image": "lib/assets/images/wo1.png"},
          {"title": "Bracket Mounting", "image": "lib/assets/images/wo2.png"},
          {"title": "Level Alignment", "image": "lib/assets/images/wo3.png"},
          {"title": "Channel Tuning", "image": "lib/assets/images/wo3.png"},
        ],
        whatsIncluded: [
          "Standard wall bracket install",
          "Connectivity & setup",
          "Cable management",
          "Feature demo",
        ],
        whatsNotIncluded: [
          "New TV wall mount cost",
          "Concealed wiring",
          "Wall painting/repair",
        ],
        customerReviews: [
          {"name": "Sarah", "rating": 5, "comment": "Perfectly leveled and neatly wired.", "date": "1 week ago"}
        ],id:0,
      ),
    ],
  };

  static List<CategoryItem> getItemsForCategory(String categoryName) {
    return categoryMap[categoryName] ?? 
           categoryMap.values.first; // Fallback to first if not found
  }
}
