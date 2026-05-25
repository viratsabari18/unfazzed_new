// Add these classes to your booking_model.dart or create separate files

class BookingStatusModel {
  final BookingState currentState;
  final ProfessionalMatch professional;
  final String appointmentDate;
  final String appointmentTime;

  BookingStatusModel({
    required this.currentState,
    required this.professional,
    required this.appointmentDate,
    required this.appointmentTime,
  });
}

enum BookingState {
  pending,
  assigned,
  onTheWay,
  arrived,
  inProgress,
  completed,
  cancelled;
}

class ProfessionalMatch {
  final String name;
  final double rating;
  final int jobsDone;
  final String avatarUrl;

  ProfessionalMatch({
    required this.name,
    required this.rating,
    required this.jobsDone,
    required this.avatarUrl,
  });
}