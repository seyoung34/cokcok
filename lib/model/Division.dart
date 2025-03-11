import 'Team_update.dart';

class Division {
  final int divisionNumber; // 1부, 2부, 3부
  List<Team> teams; // 해당 부의 팀 목록

  Division({
    required this.divisionNumber,
    required this.teams,
  });

  // JSON 변환 함수
  Map<String, dynamic> toJson() => {
    'divisionNumber': divisionNumber,
    'teams': teams.map((t) => t.toJson()).toList(),
  };

  static Division fromJson(Map<String, dynamic> json) => Division(
    divisionNumber: json['divisionNumber'],
    teams: (json['teams'] as List).map((t) => Team.fromJson(t)).toList(),
  );
}
