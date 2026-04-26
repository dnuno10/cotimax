import 'package:cotimax/core/config/stripe_config.dart';
import 'package:cotimax/core/services/backend_providers.dart';
import 'package:cotimax/shared/models/domain_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StripeCheckoutResult {
  StripeCheckoutResult({required this.url, required this.mode});

  final String url;
  final String mode; // "checkout" | "portal"
}

class StripeCheckoutService {
  StripeCheckoutService(this._client);

  final SupabaseClient _client;

  Future<StripeCheckoutResult> createCheckout({
    required Plan plan,
    int? seats,
    String action = 'checkout', // checkout | portal | cancel
  }) async {
    final origin = _originOrEmpty();
    final appBaseUrl = StripeConfig.appBaseUrl.trim();
    final response = await _client.functions.invoke(
      'stripe-checkout',
      body: {
        'action': action,
        'plan_id': plan.id,
        if (seats != null) 'seats': seats,
        if (origin.isNotEmpty) 'origin': origin,
        if (appBaseUrl.isNotEmpty) 'app_base_url': appBaseUrl,
      },
    );

    if (response.status != 200) {
      throw response.data ?? 'Stripe checkout error';
    }

    final data = response.data;
    if (data is! Map) {
      throw 'Stripe checkout response inválida.';
    }

    final url = (data['url'] ?? '').toString();
    final mode = (data['mode'] ?? '').toString();
    if (url.trim().isEmpty) {
      throw 'Stripe no regresó un URL de checkout.';
    }
    return StripeCheckoutResult(url: url, mode: mode);
  }

  String _originOrEmpty() {
    if (!kIsWeb) return '';
    try {
      return Uri.base.origin;
    } catch (_) {
      return '';
    }
  }
}

final stripeCheckoutServiceProvider = Provider<StripeCheckoutService>((ref) {
  return StripeCheckoutService(ref.watch(supabaseClientProvider));
});
