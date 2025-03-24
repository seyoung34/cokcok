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
    // print("~~~$category");
    // print(snapshot.docs.map((e) => e.data()));
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
  Future<List<Player>> loadPlayers(String category, String gender, {bool sortByRank = false}) async {
    Query query = _db
        .collection(category)
        .where("성별", isEqualTo: gender); // 🔹 성별 필터

    if (sortByRank) {
      query = query.orderBy("순위", descending: false); // 🔹 오름차순 정렬
    }

    QuerySnapshot snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      print("Firestore에서 데이터를 찾을 수 없음: $category");
      return [];
    }

    return snapshot.docs.map((doc) {
      print("*******************");
      print(doc.data().toString());
      return Player.fromJson(doc.data() as Map<String, dynamic>);
    }).toList();

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

  //부 저장
  Future<void> saveDivision(Map<String, int> divisionCount, String category) async {
    final batch = _db.batch();
    DocumentReference docRef = _db.collection(category).doc("부");

    // divisionCount 전체를 저장
    batch.set(docRef, divisionCount);

    await batch.commit();
    print("📌 $category 컬렉션의 부 정보 저장 완료: $divisionCount");
  }

  //부 정보 불러오기
  Future<Map<String, int>> loadDivision(String category) async {
    final doc = await _db.collection(category).doc("부").get();

    if (!doc.exists) return {};
    return Map<String, int>.from(doc.data() as Map<String, dynamic>);
  }





}
