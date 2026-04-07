import 'package:cotimax/core/localization/app_localization.dart';

enum ProductType { producto, servicio }

String enumKey(Object value) => value.toString().split('.').last;

extension ProductTypeLabel on ProductType {
  String get label {
    switch (this) {
      case ProductType.producto:
        return tr('Producto', 'Product');
      case ProductType.servicio:
        return tr('Servicio', 'Service');
    }
  }

  String get key => enumKey(this);
}

enum QuoteStatus { borrador, enviada, aprobada, rechazada }

enum PaymentMethod { transferencia, efectivo, tarjeta, deposito, otro }

enum RecurrenceFrequency {
  ninguna,
  cadaDia,
  diasDeLaSemana,
  finDeSemana,
  cadaSemana,
  cadaDosSemanas,
  cadaCuatroSemanas,
  cadaMes,
  cadaDosMeses,
  cadaTresMeses,
  cadaCuatroMeses,
  cadaSeisMeses,
  cadaAnio,
}

enum UserRole { admin, usuario }

extension QuoteStatusValue on QuoteStatus {
  String get key => enumKey(this);
}

extension PaymentMethodValue on PaymentMethod {
  String get key => enumKey(this);
}

extension RecurrenceFrequencyValue on RecurrenceFrequency {
  String get key => enumKey(this);
}

extension UserRoleValue on UserRole {
  String get key => enumKey(this);
}

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.transferencia:
        return tr('Transferencia', 'Transfer');
      case PaymentMethod.efectivo:
        return tr('Efectivo', 'Cash');
      case PaymentMethod.tarjeta:
        return tr('Tarjeta', 'Card');
      case PaymentMethod.deposito:
        return tr('Depósito', 'Deposit');
      case PaymentMethod.otro:
        return tr('Otro', 'Other');
    }
  }
}

extension RecurrenceFrequencyLabel on RecurrenceFrequency {
  String get label {
    switch (this) {
      case RecurrenceFrequency.ninguna:
        return tr('Ninguna', 'None');
      case RecurrenceFrequency.cadaDia:
        return tr('Cada dia', 'Every day');
      case RecurrenceFrequency.diasDeLaSemana:
        return tr('Dias de la semana', 'Weekdays');
      case RecurrenceFrequency.finDeSemana:
        return tr('Fin de semana', 'Weekend');
      case RecurrenceFrequency.cadaSemana:
        return tr('Cada semana', 'Every week');
      case RecurrenceFrequency.cadaDosSemanas:
        return tr('Cada dos semanas', 'Every two weeks');
      case RecurrenceFrequency.cadaCuatroSemanas:
        return tr('Cada 4 semanas', 'Every 4 weeks');
      case RecurrenceFrequency.cadaMes:
        return tr('Cada mes', 'Every month');
      case RecurrenceFrequency.cadaDosMeses:
        return tr('Cada 2 meses', 'Every 2 months');
      case RecurrenceFrequency.cadaTresMeses:
        return tr('Cada 3 meses', 'Every 3 months');
      case RecurrenceFrequency.cadaCuatroMeses:
        return tr('Cada 4 meses', 'Every 4 months');
      case RecurrenceFrequency.cadaSeisMeses:
        return tr('Cada 6 meses', 'Every 6 months');
      case RecurrenceFrequency.cadaAnio:
        return tr('Cada año', 'Every year');
    }
  }

  bool get supportsWeekdaySelection =>
      this == RecurrenceFrequency.diasDeLaSemana;
}
