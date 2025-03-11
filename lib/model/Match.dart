import 'Team_update.dart';

class Match {
  final String id; // 고유 ID
  final Team team1; // 첫 번째 팀
  final Team team2; // 두 번째 팀
  final int division; // 경기 부 (1부, 2부, 3부)
  int team1Score; // 팀1 점수
  int team2Score; // 팀2 점수
  bool isCompleted; // 경기 완료 여부

  Match({
    required this.id,
    required this.team1,
    required this.team2,
    required this.division,
    this.team1Score = 0,
    this.team2Score = 0,
    this.isCompleted = false,
  });

  // JSON 변환 함수
  Map<String, dynamic> toJson() => {
    'id': id,
    'team1': team1.toJson(),
    'team2': team2.toJson(),
    'division': division,
    'team1Score': team1Score,
    'team2Score': team2Score,
    'isCompleted': isCompleted,
  };

  static Match fromJson(Map<String, dynamic> json) => Match(
    id: json['id'],
    team1: Team.fromJson(json['team1']),
    team2: Team.fromJson(json['team2']),
    division: json['division'],
    team1Score: json['team1Score'],
    team2Score: json['team2Score'],
    isCompleted: json['isCompleted'],
  );
}
