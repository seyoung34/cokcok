import 'Team.dart';

class Match {
  final String id;
  final Team team1;
  final Team team2;
  final int division;
  String? group;
  int team1Score;
  int team2Score;
  bool isCompleted;
  int? courtNumber;
  String? winnerTeamId;

  Match({
    required this.id,
    required this.team1,
    required this.team2,
    required this.division,
    this.group,
    this.team1Score = 0,
    this.team2Score = 0,
    this.isCompleted = false,
    this.courtNumber,
    this.winnerTeamId,
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
    'group':group,
    'winnerTeamId': winnerTeamId
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
    group: json['group'],
    winnerTeamId: json['winnerTeamId'],
  );

  factory Match.empty() {
    return Match(
      id: "",
      team1: Team.empty(),
      team2: Team.empty(),
      division: 0,
      group: "",
    );
  }

  Match copyWith({
    String? id,
    Team? team1,
    Team? team2,
    int? team1Score,
    int? team2Score,
    String? group,
    int? division,
    bool? isCompleted,
    String? winnerTeamId,
    int? courtNumber,
  }) {
    return Match(
      id: id ?? this.id,
      team1: team1 ?? this.team1,
      team2: team2 ?? this.team2,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      group: group ?? this.group,
      division: division ?? this.division,
      isCompleted: isCompleted ?? this.isCompleted,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
      courtNumber: courtNumber ?? this.courtNumber,
    );
  }

}


