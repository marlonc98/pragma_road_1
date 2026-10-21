import 'package:flutter/material.dart';
import 'package:gestor_tareas_personales/presentation/widgets/button_widget.dart';

class NoResultsSmallWidget extends StatelessWidget {
  final Function()? onRetry;
  final String? message;
  final String? retryText;
  final String? title;
  final Widget? icon;

  const NoResultsSmallWidget({
    super.key,
    this.onRetry,
    this.message,
    this.retryText,
    this.title,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        minHeight: 0,
        maxHeight: double.infinity,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ?icon,
              const SizedBox(height: 6),
              Text(
                title ?? 'Sin resultados',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.grey, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  message!,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 8),
                ButtonWidget(
                  fitContent: true,
                  onTap: onRetry!,
                  text: retryText ?? 'Reintentar',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
