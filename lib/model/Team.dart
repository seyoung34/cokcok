import 'Player.dart';

class Team {
  final String id; // 고유 ID
  final Player player1; // 첫 번째 선수
  final Player player2; // 두 번째 선수
  final int division; // 팀이 속한 부 (1부, 2부, 3부)
  final bool isManual; // 운영자가 직접 변경한 팀인지 여부

  Team({
    required this.id,
    required this.player1,
    required this.player2,
    required this.division,
    this.isManual = false, // 기본적으로 자동 배정, 운영자가 수정하면 true
  });

  // JSON 변환 함수
  Map<String, dynamic> toJson() => {
    'id': id,
    'player1': player1.toJson(),
    'player2': player2.toJson(),
    'division': division,
    'isManual': isManual,
  };

  static Team fromJson(Map<String, dynamic> json) => Team(
    id: json['id'],
    player1: Player.fromJson(json['player1']),
    player2: Player.fromJson(json['player2']),
    division: json['division'],
    isManual: json['isManual'],
  );

  List<Player> toListPlayer() {
    return [player1, player2];
  }

}
