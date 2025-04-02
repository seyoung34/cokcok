import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/Team.dart';
import '../model/Player.dart';
import '../model/Match.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  // ✅ 실시간 경기 정보 스트림
  Stream<List<Match>> watchAllMatches() {
    return _db
        .collectionGroup('경기') // 🔹 "남성/여성/혼성" 하위 모든 경기 컬렉션 포함
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Match.fromJson(data as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> deleteCollection(String category) async {
    final snapshot = await _db.collection(category).get();
    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

  }

  //참가자 불러오기
  Future<List<Player>> loadPlayer() async{
    List<Player> playerList = [];

    QuerySnapshot snapshot = await _db.collection("참가자").get();

    for (var doc in snapshot.docs) {
      Player player = Player.fromJson(doc.data() as Map<String, dynamic>);
      playerList.add(player);
    }

    return playerList;
  }


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
  //team에서 사용됨
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


  //최초 모든 경기 데이터 저장하기
  Future<void> saveMatches(Map<String, List<Match>> matchTable, String tournamentId) async {
    print("saveMatches 시작 : ${DateTime.now()}");
    final batch = _db.batch();

    for (var entry in matchTable.entries) {
      final keyParts = entry.key.split('_'); // ex) 남성_1, 남성_1_A

      final category = keyParts[0];      // 남성 / 여성 / 혼성
      final division = keyParts[1];      // 1
      final group = keyParts.length == 3 ? keyParts[2] : null; // A or B or null

      final docId = group == null ? division : "${division}_$group"; // ex) 1_A
      final docName = group == null ? "$category ${division}부" : "$category ${division}_${group}조";

      final divisionDoc = _db
          .collection('경기 기록')
          .doc(tournamentId)
          .collection(category)
          .doc(docId);

      batch.set(divisionDoc, {
        'name': docName,
        'createdAt': FieldValue.serverTimestamp(),
        'tournamentId': tournamentId,
      });

      for (var match in entry.value) {
        final matchDoc = divisionDoc.collection('경기').doc(match.id);
        batch.set(matchDoc, match.toJson());
      }
    }

    await batch.commit();
    print("saveMatches 종료 : ${DateTime.now()}");
  }


  //경기 데이터 불러오기
  // Future<Map<String, List<Match>>> loadMatches({String gender = " "}) async {
  //   print("loadMatches 시작 ${DateTime.now()}");
  //   Map<String, List<Match>> matchTable = {};
  //
  //   List<String> categories = ['남성', '여성', '혼성'];
  //
  //   if(gender != " "){
  //       categories = [gender];
  //   }
  //
  //   for (String category in categories) {
  //     var categorySnapshot = await _db
  //         .collection('경기 기록')
  //         .doc('콕콕 리그전')
  //         .collection(category)
  //         .get();
  //
  //
  //     for (var divisionDoc in categorySnapshot.docs) {
  //       if(divisionDoc == null) print("divisoinDoc is null!!");
  //       var matchesSnapshot = await divisionDoc.reference
  //           .collection('경기')
  //           .get();
  //
  //
  //       String key = '${category}_${divisionDoc.id}';
  //       matchTable[key] = matchesSnapshot.docs
  //           .map((doc) => Match.fromJson(doc.data()))
  //           .toList();
  //     }
  //   }
  //
  //   return matchTable;
  // }

  //경기 데이터 불러오기 (비동기 병렬 처리)
  Future<Map<String, List<Match>>> loadMatches({String gender = " "}) async {
    Map<String, List<Match>> matchTable = {};
    List<String> categories = ['남성', '여성', '혼성'];

    if (gender.trim().isNotEmpty) {
      categories = [gender];
    }

    for (String category in categories) {
      // 🔹 division 문서들 비동기로 가져오기
      var divisionSnapshot = await _db
          .collection('경기 기록')
          .doc('콕콕 리그전')
          .collection(category)
          .get();

      // 🔹 division마다의 경기 리스트를 동시에 요청 (병렬 처리 핵심)
      List<Future<void>> futures = divisionSnapshot.docs.map((divisionDoc) async {
        var matchesSnapshot = await divisionDoc.reference.collection('경기').get();

        String key = '${category}_${divisionDoc.id}';
        matchTable[key] = matchesSnapshot.docs
            .map((doc) => Match.fromJson(doc.data()))
            .toList();
      }).toList();

      // 🔹 모든 division의 경기 정보를 병렬로 기다림
      await Future.wait(futures);
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
    print(tournamentId + match.id.toString() + gender);
    await _db
        .collection('경기 기록')
        .doc(tournamentId)
        .collection(gender) //남성,여성,혼성
        .doc(match.division)
        .collection('경기')
        .doc(match.id)
        .update(match.toJson());
  }


  Future<void> updateMatchCourt(String matchId, int courtNumber, String gender, String division) async {
    await _db
        .collection("경기 기록")
        .doc("콕콕 리그전")
        .collection(gender)
        .doc(division)
        .collection("경기")
        .doc(matchId)
        .update({'courtNumber': courtNumber});
  }




}
