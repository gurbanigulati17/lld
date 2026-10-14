import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth.dart';
import '../features/auth/name_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/verify_screen.dart';
import '../features/auth/welcome_screen.dart';

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
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const verify = '/welcome/verify';
  static const name = '/welcome/name';
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
  // Re-run the redirect whenever the session changes, without rebuilding
  // the router (which would reset navigation).
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final inAuth = loc.startsWith(Routes.welcome);
      if (auth.isLoading && !auth.hasValue) {
        return loc == Routes.splash ? null : Routes.splash;
      }
      final session = auth.valueOrNull;
      if (session == null) {
        return loc == Routes.welcome || loc == Routes.verify ? null : Routes.welcome;
      }
      if (session.name.isEmpty) return loc == Routes.name ? null : Routes.name;
      if (inAuth || loc == Routes.splash) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: Routes.welcome,
        builder: (_, __) => const WelcomeScreen(),
        routes: [
          GoRoute(path: 'verify', builder: (_, __) => const VerifyScreen()),
          GoRoute(path: 'name', builder: (_, __) => const NameScreen()),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
              path: Routes.home, builder: (_, __) => const DashboardScreen()),
          GoRoute(path: Routes.itr, builder: (_, __) => const ItrScreen()),
          GoRoute(path: Routes.gst, builder: (_, __) => const GstScreen()),
          GoRoute(
            path: Routes.assistant,
            builder: (_, __) => const AssistantScreen(),
          ),
        ],
      ),
      GoRoute(
          path: Routes.computation,
          builder: (_, __) => const ComputationScreen()),
      GoRoute(path: Routes.filing, builder: (_, __) => const FilingScreen()),
      GoRoute(path: Routes.profile, builder: (_, __) => const ProfileSection()),
      GoRoute(path: Routes.salary, builder: (_, __) => const SalarySection()),
      GoRoute(
          path: Routes.houseProperty,
          builder: (_, __) => const HousePropertySection()),
      GoRoute(
          path: Routes.capitalGains,
          builder: (_, __) => const CapitalGainsSection()),
      GoRoute(
          path: Routes.business, builder: (_, __) => const BusinessSection()),
      GoRoute(
          path: Routes.otherSources,
          builder: (_, __) => const OtherSourcesSection()),
      GoRoute(
          path: Routes.deductions,
          builder: (_, __) => const DeductionsSection()),
      GoRoute(
          path: Routes.taxesPaid, builder: (_, __) => const TaxesPaidSection()),
    ],
  );
});
