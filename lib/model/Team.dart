
import 'Player.dart';

class Team {
  final String id;
  final List<Player> players;
  final int division;

  Team({
    required this.id,
    required this.players,
    required this.division,
  });

  factory Team.empty() {
    return Team(id: "빈 팀", players: [], division: 0);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'players': players.map((p) => p.toJson()).toList(),
    'division': division,
  };

  static Team fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] ?? '',
      players: (json['players'] as List<dynamic>?)
          ?.map((p) => Player.fromJson(p))
          .toList() ?? [],
      division: json['division'] ?? 0,
    );
  }


  // 선수 리스트 반환
  List<Player> toListPlayer() => players;
}
