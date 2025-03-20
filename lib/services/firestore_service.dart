import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/Team.dart';
import '../model/Player.dart';
import '../model/Match.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 팀 저장
  Future<void> saveTeams(List<Team> teams, String category) async {
    final batch = _db.batch();
    CollectionReference teamsRef = _db.collection(category);

    for (var team in teams) {
      batch.set(teamsRef.doc(team.id), team.toJson());
    }

    await batch.commit();
  }

  // 🔹 팀 불러오기
  Future<List<Team>> loadTeams(String category) async {
    QuerySnapshot snapshot = await _db.collection(category).get();
    return snapshot.docs.map((doc) => Team.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  // 🔹 참가자 저장
  Future<void> savePlayers(List<Player> players, String category) async {
    final batch = _db.batch();
    CollectionReference playersRef = _db.collection(category);

    for (var player in players) {
      batch.set(playersRef.doc(player.name), player.toJson());
    }

    await batch.commit();
  }

  // 🔹 참가자 불러오기
  Future<List<Player>> loadPlayers(String category) async {
    QuerySnapshot snapshot = await _db.collection(category).get();
    return snapshot.docs.map((doc) => Player.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  // 🔹 경기 저장
  Future<void> saveMatches(List<Match> matches) async {
    final batch = _db.batch();
    CollectionReference matchesRef = _db.collection("경기 기록");

    for (var match in matches) {
      batch.set(matchesRef.doc(match.id), match.toJson());
    }

    await batch.commit();
  }

  // 🔹 경기 불러오기
  Future<List<Match>> loadMatches() async {
    QuerySnapshot snapshot = await _db.collection("경기 기록").get();
    return snapshot.docs.map((doc) => Match.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }
}
