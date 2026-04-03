enum ProductType { producto, servicio }

extension ProductTypeLabel on ProductType {
  String get label {
    switch (this) {
      case ProductType.producto:
        return 'Producto';
      case ProductType.servicio:
        return 'Servicio';
    }
  }
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

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.transferencia:
        return 'Transferencia';
      case PaymentMethod.efectivo:
        return 'Efectivo';
      case PaymentMethod.tarjeta:
        return 'Tarjeta';
      case PaymentMethod.deposito:
        return 'Depósito';
      case PaymentMethod.otro:
        return 'Otro';
    }
  }
}

extension RecurrenceFrequencyLabel on RecurrenceFrequency {
  String get label {
    switch (this) {
      case RecurrenceFrequency.ninguna:
        return 'Ninguna';
      case RecurrenceFrequency.cadaDia:
        return 'Cada dia';
      case RecurrenceFrequency.diasDeLaSemana:
        return 'Dias de la semana';
      case RecurrenceFrequency.finDeSemana:
        return 'Fin de semana';
      case RecurrenceFrequency.cadaSemana:
        return 'Cada semana';
      case RecurrenceFrequency.cadaDosSemanas:
        return 'Cada dos semanas';
      case RecurrenceFrequency.cadaCuatroSemanas:
        return 'Cada 4 semanas';
      case RecurrenceFrequency.cadaMes:
        return 'Cada mes';
      case RecurrenceFrequency.cadaDosMeses:
        return 'Cada 2 meses';
      case RecurrenceFrequency.cadaTresMeses:
        return 'Cada 3 meses';
      case RecurrenceFrequency.cadaCuatroMeses:
        return 'Cada 4 meses';
      case RecurrenceFrequency.cadaSeisMeses:
        return 'Cada 6 meses';
      case RecurrenceFrequency.cadaAnio:
        return 'Cada año';
    }
  }

  bool get supportsWeekdaySelection =>
      this == RecurrenceFrequency.diasDeLaSemana;
}
