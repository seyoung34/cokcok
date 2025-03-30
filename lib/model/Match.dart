import 'Team.dart';

class Match {
  final String id;
  final Team team1;
  final Team team2;
  final int division;
  int team1Score;
  int team2Score;
  bool isCompleted;
  int? courtNumber; // 새로 추가됨

  Match({
    required this.id,
    required this.team1,
    required this.team2,
    required this.division,
    this.team1Score = 0,
    this.team2Score = 0,
    this.isCompleted = false,
    this.courtNumber,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'team1': team1.toJson(),
    'team2': team2.toJson(),
    'division': division,
    'team1Score': team1Score,
    'team2Score': team2Score,
    'isCompleted': isCompleted,
    'courtNumber': courtNumber,
  };

  static Match fromJson(Map<String, dynamic> json) => Match(
    id: json['id'] ?? '',
    team1: Team.fromJson(json['team1'] ?? {}),
    team2: Team.fromJson(json['team2'] ?? {}),
    division: json['division'] ?? 0,
    team1Score: json['team1Score'] ?? 0,
    team2Score: json['team2Score'] ?? 0,
    isCompleted: json['isCompleted'] ?? false,
    courtNumber: json['courtNumber'], // null 가능
  );
}


