import 'package:flutter/services.dart';
import 'dart:convert';

Future<Map<String, dynamic>?> preprocessData(
    Map<String, dynamic> medicine) async {
  // Load known values from assets
  final knownDrugNamesString =
      await rootBundle.loadString('assets/known_drug_names.json');
  final knownMedicationTypesString =
      await rootBundle.loadString('assets/known_medication_types.json');
  final unitLabelString = await rootBundle.loadString('assets/unit_label.json');

  // Decode JSON
  if (knownDrugNamesString.isEmpty ||
      knownMedicationTypesString.isEmpty ||
      unitLabelString.isEmpty) {
    throw Exception("One or more assets are empty");
  }

  List<String> knownDrugNamesList =
      List<String>.from(jsonDecode(knownDrugNamesString));
  List<String> knownMedicationTypesList =
      List<String>.from(jsonDecode(knownMedicationTypesString));
  Map<String, dynamic> unitLabelMap = jsonDecode(unitLabelString);

  // Preprocess dosage
  double dosage = double.tryParse(medicine['dosage'].toString()) ?? 0.0;
  int dosageFreq = int.tryParse(medicine['dosagePerDay'].toString()) ?? 0;
  String dosageUnit = medicine['dosageUnit'].toString();

  // One-hot encode drug name
  String drugName = medicine['activeIngredient'];
  if (!knownDrugNamesList.contains(drugName)) {
    return {'error': 'Medication not registered in the model'};
  }
  List<int> drugNameFeatures =
      knownDrugNamesList.map((name) => name == drugName ? 1 : 0).toList();

  // One-hot encode medication type
  String medicationType = medicine['medicationType'];
  List<int> medicationTypeFeatures = knownMedicationTypesList
      .map((type) => type == medicationType ? 1 : 0)
      .toList();

  // Create feature vector
  Map<String, dynamic> featuresDict = {
    'Dosage': dosage,
    'DosageFreq': dosageFreq,
    'Dosage_Unit': dosageUnit,
    ...{
      for (var name in knownDrugNamesList)
        'Drug_Name_$name': drugNameFeatures[knownDrugNamesList.indexOf(name)]
    },
    ...{
      for (var type in knownMedicationTypesList)
        'Formulation_$type':
            medicationTypeFeatures[knownMedicationTypesList.indexOf(type)]
    },
  };

  return featuresDict;
}
