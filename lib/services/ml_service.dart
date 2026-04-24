import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MalnutritionModelService {
  List<Map<String, dynamic>> _parsedTrees = [];
  double _baseScore = 0.5;
  bool get isLoaded => _parsedTrees.isNotEmpty;

  Future<void> initModel() async {
    try {
      String jsonString = await rootBundle.loadString('assets/json/xgboost.json');
      Map<String, dynamic> rawModel = jsonDecode(jsonString);
      _parsedTrees = List<Map<String, dynamic>>.from(rawModel['trees']);
      _baseScore = (rawModel['base_score'] as num).toDouble();
      print("ML Model Ready: Loaded ${_parsedTrees.length} trees.");
    } catch (e) {
      print("Failed to load ML model: $e");
    }
  }

  double predict(Map<String, double> inputs) {
    if (_parsedTrees.isEmpty) return 0.0;
    
    double totalScore = _baseScore; // Base score
    for (var tree in _parsedTrees) {
      totalScore += _walkTree(tree, inputs);
    }
    
    // Sigmoid function to convert log-odds to 0.0 - 1.0 probability
    return 1.0 / (1.0 + exp(-totalScore));
  }

  double _walkTree(Map<String, dynamic> node, Map<String, double> inputs) {
    if (node.containsKey('leaf')) {
      return (node['leaf'] as num).toDouble();
    }
    
    String splitFeature = node['split'] as String;
    double threshold = (node['split_condition'] as num).toDouble();
    
    // Fallback to 0 if feature is missing, though all 51 should be provided
    double featureVal = inputs[splitFeature] ?? 0.0;
    
    if (featureVal < threshold) {
      return _walkTree(node['children'][0], inputs);
    } else {
      return _walkTree(node['children'][1], inputs);
    }
  }
}

final malnutritionModelServiceProvider = Provider<MalnutritionModelService>((ref) {
  throw UnimplementedError('malnutritionModelServiceProvider not initialized');
});

