
import 'Player.dart';

class Team {
  final String id; // 팀 ID
  final List<Player> players; // 선수 리스트
  final int division; // 팀이 속한 부 (1부, 2부, 3부)
  final bool isManual; // 운영자가 직접 변경한 팀인지 여부

  Team({
    required this.id,
    required this.players, // 리스트 형태로 저장
    required this.division,
    this.isManual = false, // 기본적으로 자동 배정, 운영자가 수정하면 true
  });

  // JSON 변환 함수
  Map<String, dynamic> toJson() => {
    'id': id,
    'players': players.map((player) => player.toJson()).toList(), // JSON 변환
    'division': division,
    'isManual': isManual,
  };

  static Team fromJson(Map<String, dynamic> json) => Team(
    id: json['id'],
    players:
    List<Player>.from(json['players'].map((p) => Player.fromJson(p))), // JSON 변환
    division: json['division'],
    isManual: json['isManual'],
  );

  // 선수 리스트 반환
  List<Player> toListPlayer() => players;
}
