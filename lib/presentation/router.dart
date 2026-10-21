import 'package:go_router/go_router.dart';
import 'package:gestor_tareas_personales/presentation/pages/placeholder/placeholder_page.dart';
import 'package:gestor_tareas_personales/presentation/pages/splash/splash_page.dart';

final router = GoRouter(
  initialLocation: SplashPage.route,
  routes: [
    GoRoute(
      path: SplashPage.route,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: PlaceholderPage.route,
      builder: (context, state) => const PlaceholderPage(),
    ),
  ],
);
