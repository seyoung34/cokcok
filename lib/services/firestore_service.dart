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

  // Future<void> saveMatches(Map<String, List<Match>> matchTable, String tournamentId) async {
  //   for (var entry in matchTable.entries) {
  //     String category = entry.key.split('_')[0]; //남성
  //     String division = entry.key.split('_')[1]; //1
  //
  //     print("$category-$division 1차 : ${DateTime.now()}");
  //     // 카테고리 문서 생성 시 기본 필드 추가
  //     await _db
  //         .collection('경기 기록')
  //         .doc(tournamentId)
  //         .collection(category)
  //         .doc(division)
  //         .set({
  //       'name': category + ' ' + division + ' 부',
  //       'createdAt': FieldValue.serverTimestamp(),
  //       'tournamentId': tournamentId
  //     });
  //
  //     print("$category-$division 2차 : ${DateTime.now()}");
  //
  //     for (var match in entry.value) {
  //       await _db
  //           .collection('경기 기록')
  //           .doc(tournamentId)
  //           .collection(category)
  //           .doc(division)
  //           .collection('경기')
  //           .doc(match.id)
  //           .set(match.toJson());
  //     }
  //   }
  //   print("saveMatches 완료");
  // }


  //최초 모든 데이터 받아오기
  Future<void> saveMatches(Map<String, List<Match>> matchTable, String tournamentId) async {
    print("saveMatches 시작 : ${DateTime.now()}");
    final batch = _db.batch();
    for (var entry in matchTable.entries) {
      String category = entry.key.split('_')[0];  //남성,여성,혼성
      String division = entry.key.split('_')[1];  //1,2,3.....

      // division 문서에 메타 정보 작성
      final divisionDoc = _db
          .collection('경기 기록')
          .doc(tournamentId)  //콕콕 리그전
          .collection(category) //남성, 여성, 혼성
          .doc(division); //1,2.3...

      batch.set(divisionDoc, {
        'name': "$category $division 부",
        'createdAt': FieldValue.serverTimestamp(),
        'tournamentId': tournamentId,
      });

      for (var match in entry.value) {
        final matchDoc = divisionDoc.collection('경기').doc(match.id);
        batch.set(matchDoc, match.toJson());
      }
      print("---$category 끝 : ${DateTime.now()}");
    }
    print("반복문 종료 : ${DateTime.now()}");

    // ✅ 한 번에 커밋
    await batch.commit();
    print("saveMatches 종료 : ${DateTime.now()}");
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


      for (var divisionDoc in categorySnapshot.docs) {
        if(divisionDoc == null) print("divisoinDoc is null!!");
        var matchesSnapshot = await divisionDoc.reference
            .collection('경기')
            .get();


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


  Future<void> updateMatch({ required String tournamentId, required Match match, required String gender}) async {
    await _db
        .collection('경기 기록')
        .doc(tournamentId)
        .collection(gender) //남성,여성,혼성
        .doc(match.division.toString())
        .collection('경기')
        .doc(match.id)
        .update(match.toJson());
  }



}
