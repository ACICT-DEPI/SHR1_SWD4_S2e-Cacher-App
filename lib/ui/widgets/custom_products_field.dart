import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

FormBuilderTextField buildTextFormed(
  TextEditingController controller,
  String name,
  bool isUpdating,
  String initialValue,
) {
  return FormBuilderTextField(
    keyboardType: name == 'اسم المنتج' ? TextInputType.text : TextInputType.number,
    controller: controller,
    name: name,
    decoration: InputDecoration(
      hintText: name,
      labelText: name,
      labelStyle: const TextStyle(fontSize: 20, color: Colors.black),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color.fromARGB(255, 25, 28, 235)),
      ),
    ),
    // Only the 'اسم المنتج', 'الكمية', and 'سعر البيع' fields are required
    validator: name == 'التكلفة'
        ? null
        : FormBuilderValidators.required(),
  );
}