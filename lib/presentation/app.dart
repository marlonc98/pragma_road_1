import 'package:flutter/material.dart';
import 'package:gestor_tareas_personales/presentation/router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Gestor de Tareas Personales",
      routerConfig: router,
    );
  }
}
