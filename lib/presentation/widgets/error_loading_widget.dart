import 'package:flutter/material.dart';
import 'package:gestor_tareas_personales/presentation/widgets/button_widget.dart';

class ErrorLoadingWidget extends StatelessWidget {
  final Function()? onRetry;
  final String? error;

  const ErrorLoadingWidget({super.key, required this.onRetry, this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              error ?? 'Ocurrió un error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            if (onRetry != null)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: ButtonWidget(onTap: onRetry!, text: 'Reintentar'),
              ),
          ],
        ),
      ),
    );
  }
}
