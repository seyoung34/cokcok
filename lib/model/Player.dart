class Player {
  // final String id; // 고유 ID
  final String name; // 참가자 이름
  final String gender; // 성별 (예: "M", "F")
  final int rank; // 등수 (남녀 구분 없이 전체 등수)
  int division; // 1부, 2부, 3부 (운영자가 조정 가능)

  Player({
    // required this.id,
    required this.name,
    required this.gender,
    required this.rank,
    this.division =0,
  });

  // JSON 변환 함수 (Firebase 저장 고려)
  Map<String, dynamic> toJson() => {
    // 'id': id,
    'name': name,
    'gender': gender,
    'rank': rank,
    'division': division,
  };

  static Player fromJson(Map<String, dynamic> json) => Player(
    // id: json['id'],
    name: json['name'],
    gender: json['gender'],
    rank: json['rank'],
    division: json['division'],
  );
}
