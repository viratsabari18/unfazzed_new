import 'package:zeerah/screens/auth/complete_profile_screen.dart';
import 'package:zeerah/screens/auth/otp_verification.dart';
import 'package:zeerah/screens/auth/sign_in_screen.dart';
import 'package:zeerah/screens/auth/splash_screen.dart';
import 'package:zeerah/screens/cetagories/service_cetagorices.dart';
import 'package:zeerah/screens/chat/chat_room_screen.dart';
import 'package:zeerah/screens/handyman%20services/bookings/booking_history.dart';
import 'package:zeerah/screens/home/home_page.dart';
import 'package:zeerah/screens/booking/booking_config_screen.dart';
import 'package:zeerah/screens/cetagories/category_details_screen.dart';
import 'package:zeerah/screens/cetagories/service_details_screen.dart';
import 'package:zeerah/screens/booking_flow/booking_confirmed_screen.dart';
import 'package:zeerah/screens/booking_flow/booking_status_screen.dart';
import 'package:zeerah/screens/booking_flow/professional_assigned_screen.dart';
import 'package:zeerah/screens/booking_flow/service_verification_screen.dart';
import 'package:zeerah/screens/handyman%20services/bookings/booking_home_page.dart';
import 'package:zeerah/screens/handyman%20services/bookings/bookig_sevice_progress_home.dart';
import 'package:zeerah/screens/landing/landing_screen.dart';
import 'package:zeerah/screens/profile/privacy_policy.dart';
import 'package:zeerah/screens/profile/profile_screen.dart';
import 'package:zeerah/screens/profile/terms_and_condtion.dart';
import 'package:zeerah/screens/profile/wallet_history_screen.dart';
import 'package:zeerah/screens/profile/help_desk_screen.dart';
import 'package:zeerah/screens/profile/create_support_ticket_screen.dart';
import 'package:zeerah/screens/profile/support_ticket_detail_screen.dart';
import 'package:zeerah/screens/profile/referral_screen.dart';
import 'package:zeerah/screens/message/message_screen.dart';
import 'package:zeerah/screens/location/select_location_screen.dart';
import 'package:zeerah/screens/location/confirm_location_screen.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/screens/notifications/notification_history.dart';
import 'package:zeerah/screens/profile%20kyc/kyc_verifaication.dart';
import 'package:zeerah/screens/profile/favorie_service_history.dart';
import 'package:zeerah/screens/home/expolre_categories_stack.dart';
import 'package:zeerah/screens/handyman%20services/payments/payments_home_page.dart';
import 'package:zeerah/screens/handyman%20services/reviews/ratings_and_review_screen.dart';
import 'package:zeerah/core/models/service_list_model.dart';
import 'package:zeerah/core/models/user_model.dart';
import 'package:zeerah/screens/profile/services_payment_history_screen.dart';
import 'package:zeerah/screens/profile/withdraw_request_screen.dart';
import 'package:zeerah/screens/profile/add_bank_screen.dart';
import 'package:zeerah/screens/handyman services/bookings/booking_detail_screen.dart';
import 'package:zeerah/screens/profile/my_reviews_screen.dart';

class AppPages {
  static Map<String, WidgetBuilder> routes = {
    AppRoutes.splash: (context) => SplashScreen(),
    AppRoutes.signIn: (context) => SignInScreen(),
    AppRoutes.landingPage: (context) => LandingScreen(),
    AppRoutes.otpVerifly: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return OtpVerification(
        verificationId: args['verificationId'],
        phoneNumber: args['phoneNumber'],
      );
    },
    AppRoutes.completeProfile: (context) => const CompleteProfileScreen(),
    AppRoutes.homePage: (context) => LandingScreen(),
    AppRoutes.serviceCategories: (context) {
      final title = ModalRoute.of(context)!.settings.arguments as String;
      return ServiceCetagorices(title: title);
    },
    // In your router configuration
    AppRoutes.cleaningServices: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

      return CategoryDetailsScreen(
        subcategoryName: args['subcategoryName'],
        subcategoryId: args['subcategoryId'],
        parentCategoryName: args['parentCategoryName'],
      );
    },
    AppRoutes.serviceDetails: (context) {
      final service =
          ModalRoute.of(context)!.settings.arguments as ServiceData;
      return ServiceDetailsScreen(service: service);
    },
    AppRoutes.bookingConfig: (context) {
      final service =
          ModalRoute.of(context)!.settings.arguments as ServiceData;
      return BookingConfigScreen(service: service);
    },
    AppRoutes.bookingConfirmed: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Map<String, dynamic>) {
        return BookingConfirmedScreen(
          service: args['service'],
          bookingId: args['booking_id'],
          date: args['date'] ?? "26 March, 2026",
          time: args['time'] ?? "10:30 AM",
          price: args['price'] ?? "0",
        );
      }
      return BookingConfirmedScreen(service: args);
    },
    AppRoutes.bookingStatus: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Map<String, dynamic>) {
        return BookingStatusScreen(
          service: args['service'],
          bookingId: args['booking_id'],
          date: args['date'],
          time: args['time'],
          price: args['price'],
        );
      }
      return BookingStatusScreen(service: args as dynamic);
    },
    AppRoutes.professionalAssigned: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Map<String, dynamic>) {
        return ProfessionalAssignedScreen(
          service: args['service'],
          bookingStatus: args['status'] as BookingStatusModel,
          bookingData: args['booking_data'],
          initialUserLocation: args['initial_user_location'],
          initialRiderLocation: args['initial_rider_location'],
          price: args['price'],
        );
      }
      return ProfessionalAssignedScreen(
        service: args as dynamic,
        bookingStatus: const BookingStatusModel(
          currentState: BookingState.assigned,
        ),
      );
    },
    AppRoutes.serviceVerification: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Map<String, dynamic>) {
        return ServiceVerificationScreen(
          service: args['service'],
          bookingStatus: args['status'] as BookingStatusModel,
          bookingData: args['booking_data'],
          price: args['price'],
        );
      }
      return ServiceVerificationScreen(
        service: args as dynamic,
        bookingStatus: const BookingStatusModel(
          currentState: BookingState.arrived,
        ),
      );
    },
    AppRoutes.bookingHomePage: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Map<String, dynamic>) {
        return BookingHomePage(
          service: args['service'],
          totalAmount: args['total_amount'] ?? 0.0,
          selectedOption: args['selected_option'],
          selectedAddOns: args['selected_add_ons'] ?? const [],
        );
      }
      return BookingHomePage(service: args);
    },
    AppRoutes.serviceInProgress: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Map<String, dynamic>) {
        return BookingServiceProgressHome(
          serviceDurationInSeconds: args['duration'] ?? 0,
          bookingData: args['booking_data'],
          startTime: args['start_time'],
          completionTime: args['completion_time'],
          price: args['price'],
        );
      }
      return const BookingServiceProgressHome(serviceDurationInSeconds: 0);
    },
    AppRoutes.notificationHistory: (context) => const NotificationHistory(),
    AppRoutes.kycVerfication: (context) => const KycVerifaication(),
    AppRoutes.bookingHistory: (context) => BookingHistory(),
    AppRoutes.favoitesHistory: (context) => FavorieServiceHistory(),

    AppRoutes.chatHomeScreen: (context) => ChatRoomScreen(),
    AppRoutes.profile: (context) {
      final user =
          ModalRoute.of(context)!.settings.arguments as UserModel? ??
          UserModel.mock();
      return ProfileScreen(user: user);
    },
    AppRoutes.walletHistory: (context) {
      final user =
          ModalRoute.of(context)!.settings.arguments as UserModel? ??
          UserModel.mock();
      return WalletHistoryScreen(user: user);
    },
    AppRoutes.helpDesk: (context) => const HelpDeskScreen(),
    AppRoutes.createSupportTicket: (context) => const CreateSupportTicketScreen(),
    AppRoutes.supportTicketDetail: (context) {
      final ticketId = ModalRoute.of(context)!.settings.arguments as String;
      return SupportTicketDetailScreen(ticketId: ticketId);
    },
    AppRoutes.messages: (context) => const MessageScreen(),
    AppRoutes.selectLocation: (context) => const SelectLocationScreen(),
    AppRoutes.confirmLocation: (context) => const ConfirmLocationScreen(),
    AppRoutes.referral: (context) {
      final user =
          ModalRoute.of(context)!.settings.arguments as UserModel? ??
          UserModel.mock();
      return ReferralScreen(user: user);
    },
    AppRoutes.paymentsHome: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      // PaymentsHomePage reads its own args internally via ModalRoute,
      // so we just instantiate it — no constructor args needed.
      return const PaymentsHomePage();
    },
    AppRoutes.ratingsAndReview: (context) => const RatingsAndReviewScreen(),
    AppRoutes.servicesPaymentHistory: (context) => const ServicesPaymentHistoryScreen(),
    AppRoutes.withdrawRequest: (context) {
      final balance = ModalRoute.of(context)!.settings.arguments as double? ?? 0.0;
      return WithdrawRequestScreen(currentBalance: balance);
    },
    AppRoutes.addBank: (context) => const AddBankScreen(),
    AppRoutes.bookingDetail: (context) {
      final bookingId = ModalRoute.of(context)!.settings.arguments as String;
      return BookingDetailScreen(bookingId: bookingId);
    },
    AppRoutes.myReviews: (context) => const MyReviewsScreen(),
    AppRoutes.termsAndCondtions:(context)=>const TermsAndCondtion(),
    AppRoutes.privacyPolicy:(context)=>const PrivacyPolicy()
  };
}
