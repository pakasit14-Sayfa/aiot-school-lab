class RubricCriterionModel {
  final String id;
  final String name;
  final String? description;
  final num maxScore;
  final List<dynamic>? levels;
  final int sortOrder;

  RubricCriterionModel({
    required this.id,
    required this.name,
    this.description,
    required this.maxScore,
    this.levels,
    required this.sortOrder,
  });

  factory RubricCriterionModel.fromJson(Map<String, dynamic> json) {
    return RubricCriterionModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      maxScore: (json['max_score'] as num?) ?? 10,
      levels: json['levels'] as List<dynamic>?,
      sortOrder: (json['sort_order'] as int?) ?? 0,
    );
  }
}

class RubricModel {
  final String id;
  final String title;
  final String? description;
  final String? createdBy;
  final int criteriaCount;
  final int usedCount;
  final List<RubricCriterionModel> criteria;

  RubricModel({
    required this.id,
    required this.title,
    this.description,
    this.createdBy,
    this.criteriaCount = 0,
    this.usedCount = 0,
    this.criteria = const [],
  });

  factory RubricModel.fromListRow(Map<String, dynamic> row) {
    return RubricModel(
      id: row['rubric_id'] as String? ?? row['id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      description: row['description'] as String?,
      createdBy: row['created_by'] as String?,
      criteriaCount: (row['criteria_count'] as num?)?.toInt() ?? 0,
      usedCount: (row['used_count'] as num?)?.toInt() ?? 0,
    );
  }

  factory RubricModel.fromDetailRow(Map<String, dynamic> row) {
    final criteriaJson = row['criteria'] as List<dynamic>? ?? [];
    return RubricModel(
      id: row['rubric_id'] as String? ?? row['id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      description: row['description'] as String?,
      criteria: criteriaJson
          .map((c) => RubricCriterionModel.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
