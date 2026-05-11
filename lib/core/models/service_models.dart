enum BookingState { searching, assigned, onTheWay, arrived, started, completed }

class ProfessionalMatch {
  final String name;
  final double rating;
  final int jobsDone;
  final String avatarUrl;

  const ProfessionalMatch({
    required this.name,
    required this.rating,
    required this.jobsDone,
    required this.avatarUrl,
  });

  factory ProfessionalMatch.fromJson(Map<String, dynamic> json) {
    return ProfessionalMatch(
      name: json['name'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      jobsDone: json['jobsDone'] ?? 0,
      avatarUrl: json['avatarUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "rating": rating,
      "jobsDone": jobsDone,
      "avatarUrl": avatarUrl,
    };
  }

  factory ProfessionalMatch.dummy() {
    return const ProfessionalMatch(
      name: "Rohit Sharma",
      rating: 4.8,
      jobsDone: 120,
      avatarUrl: "lib/assets/images/rider_image.png",
    );
  }
}

class ProgressStepModel {
  final String title;
  final String subtitle;
  final BookingState state;

  const ProgressStepModel({
    required this.title,
    required this.subtitle,
    required this.state,
  });
}

class BookingStatusModel {
  final BookingState currentState;
  final ProfessionalMatch? professional;
  final String arrivalTime;
  final String appointmentTime;
  final String appointmentDate;
  final List<ProgressStepModel>? steps;

  const BookingStatusModel({
    required this.currentState,
    this.professional,
    this.arrivalTime = "12 mins",
    this.appointmentTime = "11:00 AM",
    this.appointmentDate = "26 March, 2026",
    this.steps,
  });
}
