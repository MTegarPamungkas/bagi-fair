import 'package:flutter/widgets.dart';

/// One set of controllers for one receipt item row.
class ItemControllers {
  final name = TextEditingController();
  final quantity = TextEditingController();
  final price = TextEditingController();

  void dispose() {
    name.dispose();
    quantity.dispose();
    price.dispose();
  }
}

/// Owns every text controller used by the expense form.
///
/// Keeping them in one small object lets the form sections live in their own
/// widget files while the page stays about state orchestration.
class ExpenseFormControllers {
  final title = TextEditingController();
  final amount = TextEditingController();
  final note = TextEditingController();
  final fx = TextEditingController();
  final tax = TextEditingController();
  final service = TextEditingController();
  final discount = TextEditingController();
  final Map<String, TextEditingController> percent = {};
  final Map<String, TextEditingController> exact = {};
  final Map<String, ItemControllers> items = {};

  void dispose() {
    title.dispose();
    amount.dispose();
    note.dispose();
    fx.dispose();
    tax.dispose();
    service.dispose();
    discount.dispose();
    for (final controller in percent.values) {
      controller.dispose();
    }
    for (final controller in exact.values) {
      controller.dispose();
    }
    for (final controller in items.values) {
      controller.dispose();
    }
  }
}
