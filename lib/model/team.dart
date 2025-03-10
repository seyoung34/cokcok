class Team {
  String id; // 팀 고유 ID
  List<Player> members;
  Team({required this.id, required this.members});
}

class Player {
  String id;
  String name;
  String gender;
  String rank;

  Player({required this.id, required this.name, required this.gender, required this.rank});
}
