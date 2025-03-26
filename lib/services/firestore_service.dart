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
  // Future<void> saveMatches(List<Match> matches) async {
  //   final batch = _db.batch();
  //   CollectionReference matchesRef = _db.collection("경기 기록");
  //
  //   for (var match in matches) {
  //     batch.set(matchesRef.doc(match.id), match.toJson());
  //   }
  //
  //   await batch.commit();
  // }

  // Future<void> saveMatches(Map< String, List<Match>> matchTable) async {
  //   final batch = _db.batch();
  //   CollectionReference matchesRef = _db.collection("경기 기록");
  //
  //   for(var match in matchTable.entries){ //key : { 남성_1, 남성_2, 남성_3, 여성_1, 여성_2, 혼성_1}
  //     batch.set(matchesRef.doc(match.key), match.value);
  //   }
  //
  //   await batch.commit();
  // }

  // Future<void> saveMatches(Map<String, List<Match>> matchTable) async {
  //   final batch = _db.batch();
  //
  //   for (var entry in matchTable.entries) {
  //     String collectionName = entry.key; // 예: "남성_1"
  //     CollectionReference matchCollection = _db.collection("경기 기록").doc("리그전").collection(collectionName);
  //
  //     for (var match in entry.value) {
  //       DocumentReference matchDoc = matchCollection.doc(match.id);
  //       batch.set(matchDoc, match.toJson());
  //     }
  //   }
  //
  //   await batch.commit();
  //   print("📌 경기 기록 저장 완료 (컬렉션 분리 구조)");
  // }

  Future<void> saveMatches(Map<String, List<Match>> matchTable, String tournamentId) async {
    for (var entry in matchTable.entries) {
      String category = entry.key.split('_')[0]; //남성
      String division = entry.key.split('_')[1]; //1

      // 카테고리 문서 생성 시 기본 필드 추가
      await _db
          .collection('경기 기록')
          .doc(tournamentId)
          .collection(category)
          .doc(division)
          .set({
        'name': category + ' ' + division + ' 부',
        'createdAt': FieldValue.serverTimestamp(),
        'tournamentId': tournamentId
      });

      for (var match in entry.value) {
        await _db
            .collection('경기 기록')
            .doc(tournamentId)
            .collection(category)
            .doc(division)
            .collection('경기')
            .doc(match.id)
            .set(match.toJson());
      }
    }
    print("saveMatches 완료");
  }



  Future<Map<String, List<Match>>> loadMatches() async {
    Map<String, List<Match>> matchTable = {};

    List<String> categories = ['남성', '여성', '혼성'];

    for (String category in categories) {
      var categorySnapshot = await _db
          .collection('경기 기록')
          .doc('콕콕 리그전')
          .collection(category)
          .get();

      print("경기 기록 : ${await _db.collection('경기 기록').doc().get()}");
      print("콕콕 리그전_category_남성 : ${await _db.collection('경기 기록').doc('콕콕 리그전').collection(category).doc('남성').get()}");
      print("콕콕 리그전_category_남성 : ${await _db.collection('경기 기록').doc('콕콕 리그전').collection(category).doc('남성').collection('1').get()}");
      print("categorySnapshot : ${categorySnapshot.docs}");

      for (var divisionDoc in categorySnapshot.docs) {
        if(divisionDoc == null) print("divisoinDoc is null!!");
        var matchesSnapshot = await divisionDoc.reference
            .collection('경기')
            .get();

        print("matchesSnapshot : ${matchesSnapshot.docs}");

        String key = '${category}_${divisionDoc.id}';
        matchTable[key] = matchesSnapshot.docs
            .map((doc) => Match.fromJson(doc.data()))
            .toList();
      }
    }

    return matchTable;
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


  Future<void> updateMatch({ required String tournamentId, required Match match}) async {
    await _db
        .collection('경기 기록')
        .doc(tournamentId)
        .collection(match.team1.division == 1 ? '남성' : '여성')
        .doc(match.division.toString())
        .collection('경기')
        .doc(match.id)
        .update(match.toJson());
  }



}
