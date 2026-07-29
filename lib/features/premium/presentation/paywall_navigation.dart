import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Opens the paywall with an analytics-ready source tag.
void openPremiumPaywall(BuildContext context, {required String source}) {
  context.push('/premium?source=${Uri.encodeQueryComponent(source)}');
}
