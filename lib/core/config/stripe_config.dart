class StripeConfig {
  StripeConfig._();

  // Publishable key is safe to ship to clients.
  static const publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue:
        'pk_live_51TB6lO30JQkRaV5j20ckQmEQH4w4XbKEjpcRjxptxCGogwnf1E8AZ7xWx4cBsPDupRBOjdmqLk0ZJQ0qdf9kfapm00pK2HYBeP',
  );

  // Used as fallback for Stripe Checkout redirect URLs (especially on mobile).
  static const appBaseUrl = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: '',
  );
}

