
import 'Player.dart';

class Team {
  final String id; // 팀 ID
  final List<Player> players; // 선수 리스트
  final int division; // 팀이 속한 부 (1부, 2부, 3부)

  Team({
    required this.id,
    required this.players, // 리스트 형태로 저장
    required this.division,
  });

  // JSON 변환 함수
  Map<String, dynamic> toJson() => {
    'id': id,
    'players': players.map((player) => player.toJson()).toList(), // JSON 변환
    'division': division,
  };

  static Team fromJson(Map<String, dynamic> json) => Team(
    id: json['id'],
    players:
    List<Player>.from(json['players'].map((p) => Player.fromJson(p))), // JSON 변환
    division: json['division'],
  );

  // 선수 리스트 반환
  List<Player> toListPlayer() => players;
}
