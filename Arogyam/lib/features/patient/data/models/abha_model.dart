class AbhaModel {
  final String abhaId;
  final bool isLinked;

  AbhaModel({
    required this.abhaId,
    this.isLinked = false,
  });

  factory AbhaModel.fromJson(Map<String, dynamic> json) {
    return AbhaModel(
      abhaId: json['abhaId'] ?? '',
      isLinked: json['isLinked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'abhaId': abhaId,
      'isLinked': isLinked,
    };
  }
}
