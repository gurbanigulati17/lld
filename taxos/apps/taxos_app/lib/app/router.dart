import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/assistant/assistant_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/filing/filing_screen.dart';
import '../features/gst/gst_screen.dart';
import '../features/home/home_shell.dart';
import '../features/itr/computation_screen.dart';
import '../features/itr/itr_screen.dart';
import '../features/itr/sections/business_section.dart';
import '../features/itr/sections/capital_gains_section.dart';
import '../features/itr/sections/deductions_section.dart';
import '../features/itr/sections/house_property_section.dart';
import '../features/itr/sections/other_sources_section.dart';
import '../features/itr/sections/profile_section.dart';
import '../features/itr/sections/salary_section.dart';
import '../features/itr/sections/taxes_paid_section.dart';

/// Route names, so screens never hard-code paths.
abstract final class Routes {
  static const home = '/';
  static const itr = '/itr';
  static const gst = '/gst';
  static const assistant = '/assistant';
  static const computation = '/itr/computation';
  static const filing = '/itr/filing';
  static const profile = '/itr/profile';
  static const salary = '/itr/salary';
  static const houseProperty = '/itr/house-property';
  static const capitalGains = '/itr/capital-gains';
  static const business = '/itr/business';
  static const otherSources = '/itr/other-sources';
  static const deductions = '/itr/deductions';
  static const taxesPaid = '/itr/taxes-paid';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    routes: [
      ShellRoute(
        builder: (context, state, child) => HomeShell(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(path: Routes.home, builder: (_, __) => const DashboardScreen()),
          GoRoute(path: Routes.itr, builder: (_, __) => const ItrScreen()),
          GoRoute(path: Routes.gst, builder: (_, __) => const GstScreen()),
          GoRoute(
            path: Routes.assistant,
            builder: (_, __) => const AssistantScreen(),
          ),
        ],
      ),
      GoRoute(path: Routes.computation, builder: (_, __) => const ComputationScreen()),
      GoRoute(path: Routes.filing, builder: (_, __) => const FilingScreen()),
      GoRoute(path: Routes.profile, builder: (_, __) => const ProfileSection()),
      GoRoute(path: Routes.salary, builder: (_, __) => const SalarySection()),
      GoRoute(path: Routes.houseProperty, builder: (_, __) => const HousePropertySection()),
      GoRoute(path: Routes.capitalGains, builder: (_, __) => const CapitalGainsSection()),
      GoRoute(path: Routes.business, builder: (_, __) => const BusinessSection()),
      GoRoute(path: Routes.otherSources, builder: (_, __) => const OtherSourcesSection()),
      GoRoute(path: Routes.deductions, builder: (_, __) => const DeductionsSection()),
      GoRoute(path: Routes.taxesPaid, builder: (_, __) => const TaxesPaidSection()),
    ],
  );
});
