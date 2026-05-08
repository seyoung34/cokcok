import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/Team.dart';
import '../model/Player.dart';
import '../model/Match.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 본선 경기 단발성 불러오기 (ex: 남성 1부)
  Future<List<Match>> loadTournamentMatches({
    required String tournamentId,
    required String gender,
    required int division,
  }) async {
    final snapshot = await _db
        .collection("본선 경기")
        .doc(tournamentId)
        .collection(gender)
        .doc(division.toString())
        .collection("경기")
        .get();

    return snapshot.docs.map((doc) => Match.fromJson(doc.data())).toList();
  }

  ///혼성 리그전 팀 불러오기
  Future<List<Team>> loadMixedLeagueTeams() async {
    final snapshot = await _db.collection("혼성 복식 팀").get();
    return snapshot.docs.map((doc) => Team.fromJson(doc.data())).toList();
  }


  ///본선 경기 불러오기(특정 division)
  Future<List<Match>> loadMatchesForTournament(String gender, int division) async {
    final snapshot = await _db
        .collection("본선 경기")
        .doc("콕콕 리그전")
        .collection(gender)
        .doc(division.toString())
        .collection("경기")
        .get();

    return snapshot.docs.map((doc) => Match.fromJson(doc.data())).toList();
  }


  ///혼성 경기 기록 불러오기
  //todo stream으로 변경해야할 듯
  Future<List<Match>> loadMixedMatches() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("경기 기록")
        .doc("콕콕 리그전")
        .collection("혼성")
        .doc("1")
        .collection("경기")
        .get();

    return snapshot.docs
        .map((doc) => Match.fromJson(doc.data()))
        .toList();
  }

  /// 혼성 토너먼트 경기 실시간 구독
  Stream<List<Match>> watchMixedTournament() {
    return _db
        .collection("경기 기록")
        .doc("콕콕 리그전")
        .collection("혼성 토너먼트")
        .doc("1")
        .collection("경기")
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Match.fromJson(doc.data()))
        .toList());
  }

  /// 남성 본선 토너먼트 경기 실시간 구독
  Stream<List<Match>> watchFinalMatches(String gender, int division) {
    return _db
        .collection("경기 기록")
        .doc("콕콕 리그전")
        .collection(gender)
        .doc("본선_$division")
        .collection("경기")
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Match.fromJson(doc.data()))
        .toList());
  }

  Future<void> saveMixedTournamentMatches(List<Match> matches) async {
    final batch = _db.batch();
    final colRef = _db
        .collection("경기 기록")
        .doc("콕콕 리그전")
        .collection("혼성 토너먼트")
        .doc("1")
        .collection("경기");

    for (final match in matches) {
      batch.set(colRef.doc(match.id), match.toJson());
    }

    await batch.commit();
  }



/// 본선 경기 실시간 수신 (ex: "남성_1")
  Stream<List<Match>> watchTournamentMatchesByDivision(String divisionKey) {
    final parts = divisionKey.split('_');
    final gender = parts[0];  ///남성, 여성, 혼성
    final division = int.tryParse(parts[1]) ?? 1; /// 1, 2....

    return _db
        .collection("본선 경기")
        .doc("콕콕 리그전")
        .collection(gender)
        .doc(division.toString())
        .collection("경기")
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Match.fromJson(doc.data())).toList());
  }


  Future<void> updateDivisionCompletion(String gender, String groupKey) async {
    final matchesSnapshot = await _db
        .collection("경기 기록")
        .doc("콕콕 리그전")
        .collection(gender)
        .doc(groupKey)
        .collection("경기")
        .get();

    final allCompleted = matchesSnapshot.docs.every((doc) => doc.data()["isCompleted"] == true);

    if (allCompleted) {
      await _db
          .collection("경기 기록")
          .doc("콕콕 리그전")
          .collection(gender)
          .doc(groupKey)
          .update({"isCompleted": true});
    }
  }


  Future<bool> hasFinalMatches(String tournamentId, String gender, int division) async {
    final snapshot = await _db
        .collection('본선 경기')
        .doc(tournamentId)
        .collection(gender)
        .doc(division.toString())
        .collection('경기')
        .get();

    return snapshot.docs.isNotEmpty;
  }


  Future<void> updateTournamentMatch(Match match, String category, int roundIndex) async {
    print("category : ${category} , roundIndex : ${roundIndex}");
    await FirebaseFirestore.instance
        .collection('경기 기록')
        .doc("콕콕 리그전")
        .collection(category)
        .doc(category == "혼성 토너먼트" ? "1" : "본선_$roundIndex")
        .collection("경기")
        .doc(match.id)
        .set(match.toJson());
  }

  Future<List<Match>> loadAllCurrentTournamentMatches(String selectedCategory) async {
    if (selectedCategory == "혼성 토너먼트") {
      // 혼성 토너먼트
      final snapshot = await _db
          .collection("경기 기록")
          .doc("콕콕 리그전")
          .collection("혼성 토너먼트")
          .doc("1")
          .collection("경기")
          .get();

      return snapshot.docs.map((doc) => Match.fromJson(doc.data())).toList();
    }

    if (selectedCategory.startsWith("남성")) {
      // 남성 본선
      final division = int.tryParse(selectedCategory.split(" ")[1].replaceAll("부", "")) ?? 1;

      final snapshot = await _db
          .collection("경기 기록")
          .doc("콕콕 리그전")
          .collection("남성")
          .doc("본선_$division")
          .collection("경기")
          .get();

      return snapshot.docs.map((doc) => Match.fromJson(doc.data())).toList();
    }

    // 지원되지 않는 카테고리
    return [];
  }





  Future<void> updateTournamentScore(Match match) async {
    await _db
        .collection("경기 기록")
        .doc("콕콕 리그전")
        .collection("혼성 토너먼트")
        .doc("1")
        .collection("경기")
        .doc(match.id)
        .set(match.toJson());
  }

  Future<void> updateMaleTournamentScore(Match match, int division) async {
    await _db
        .collection("경기 기록")
        .doc("콕콕 리그전")
        .collection("남성")
        .doc("본선_$division")
        .collection("경기")
        .doc(match.id)  //match id가 다름
        .set(match.toJson());
  }



  /// 특정 그룹(성별, division, group)의 경기 완료 여부 갱신
  Future<void> updateGroupCompletionStatus({
    required String tournamentId,
    required String gender, // 남성, 여성, 혼성
    required int division,
    String? group,          // A, B, 또는 null
  }) async {
    final groupKey = group != null ? "_$group" : "";
    final groupDoc = _db
        .collection('경기 기록')
        .doc(tournamentId)
        .collection(gender)
        .doc('$division$groupKey');

    final matchSnapshot = await groupDoc.collection('경기').get();

    final allCompleted = matchSnapshot.docs.every((doc) {
      final data = doc.data();
      return data['isCompleted'] == true;
    });

    await groupDoc.set({'isCompleted': allCompleted}, SetOptions(merge: true));
    print("일단 실행..");
  }

  Future<bool> isDivisionCompleted(int division, String group) async {
    final doc = await FirebaseFirestore.instance
        .collection('경기 기록')
        .doc('콕콕 리그전')
        .collection('남성')
        .doc('${division}_$group')
        .get();

    return doc.data()?['isCompleted'] == true;
  }

  Future<List<Match>> getDivisionMatches(int division, String group) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('경기 기록')
        .doc('콕콕 리그전')
        .collection('남성')
        .doc('${division}_$group')
        .collection('경기')
        .get();

    return snapshot.docs
        .map((doc) => Match.fromJson(doc.data()))
        .toList();
  }

  Future<void> saveMatchToFinalTournament(int division, Match match) async {
    final ref = FirebaseFirestore.instance
        .collection('경기 기록')
        .doc('콕콕 리그전')
        .collection('남성')
        .doc('본선_$division')
        .collection('경기')
        .doc(match.id);

    await ref.set(match.toJson());
  }



  /// 본선 경기 저장 (준결승, 결승, 3·4위전 포함)
  Future<void> saveFinalMatches({
    required String tournamentId,
    required String gender,
    required int division,
    required List<Match> matches,
  }) async {
    final batch = _db.batch();

    final basePath = _db
        .collection("본선 경기")
        .doc(tournamentId)
        .collection(gender)
        .doc(division.toString())
        .collection("경기");

    for (var match in matches) {
      final doc = basePath.doc(match.id);
      batch.set(doc, match.toJson());
    }

    await batch.commit();
  }


/// 본선 경기 저장
  Future<void> saveTournamentMatches({
    required String tournamentId,
    required String gender,
    required int division,
    required List<Match> matches,
  }) async {
    final batch = _db.batch();
    final divisionDoc = _db
        .collection('본선 경기')
        .doc(tournamentId)
        .collection(gender)
        .doc(division.toString());

    // division 메타정보
    batch.set(divisionDoc, {
      'name': "$gender $division 부 본선",
      'createdAt': FieldValue.serverTimestamp(),
      'tournamentId': tournamentId,
    });

    for (var match in matches) {
      final matchDoc = divisionDoc.collection('경기').doc(match.id);
      batch.set(matchDoc, match.toJson());
    }

    await batch.commit();
  }

  /// 본선 경기 실시간 조회
  Stream<List<Match>> watchTournamentMatches(
      String tournamentId, String gender, int division) {
    return _db
        .collection('본선 경기')
        .doc(tournamentId)
        .collection(gender)
        .doc(division.toString())
        .collection('경기')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Match.fromJson(data as Map<String, dynamic>);
      }).toList();
    });
  }



  // 본선 division 목록 가져오기
  Future<List<String>> getFinalDivisions(String gender) async {
    final snapshot = await _db.collection("경기 기록").doc("콕콕 리그전").collection(gender).get();
    return snapshot.docs
        .map((doc) => doc.id)
        .where((id) => id.startsWith("본선_"))
        .map((id) => id.replaceAll("본선_", "")) // "1", "2" ...
        .toList();
  }

  /// 이미 본선 경기가 존재하는지 확인
  Future<bool> finalMatchesExist({
    required String tournamentId,
    required String gender,
    required int division,
  }) async {
    final snapshot = await _db
        .collection("본선 경기")
        .doc(tournamentId)
        .collection(gender)
        .doc(division.toString())
        .collection("경기")
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Stream<List<Match>> watchLeagueMatches() {
    return _db
        .collectionGroup('경기')
        .snapshots()
        .map((snapshot) {
      final matches = snapshot.docs.map((doc) {
        final data = doc.data();
        final match = Match.fromJson(data as Map<String, dynamic>);

        // 본선 제외
        if (match.group?.startsWith("round") == true ||
            match.division.toString().startsWith("round")) {
          return null;
        }
        if(match.team1.id == "빈 팀" || match.team2.id == "빈 팀"){
          return null;
        }

        return match;
      }).whereType<Match>().toList(); // null 제거

      // ✅ 혼성을 먼저 정렬
      matches.sort((a, b) {
        final aGender = _getMatchGenderSortKey(a);
        final bGender = _getMatchGenderSortKey(b);
        return aGender.compareTo(bGender); // 낮은 순서대로 정렬
      });

      return matches;
    });
  }



  ///예선 정보 받아오기
  Stream<List<Match>> watchAllMatches() {
    return _db
        .collectionGroup('경기')
        .snapshots()
        .map((snapshot) {
      final matches = snapshot.docs.map((doc) {
        final data = doc.data();
        final match = Match.fromJson(data as Map<String, dynamic>);
        if(match.team1.id == "빈 팀" || match.team2.id == "빈 팀"){
          return null;
        }

        return match;
      }).whereType<Match>().toList(); // null 제거

      // ✅ 혼성을 먼저 정렬
      matches.sort((a, b) {
        final aGender = _getMatchGenderSortKey(a);
        final bGender = _getMatchGenderSortKey(b);
        return aGender.compareTo(bGender); // 낮은 순서대로 정렬
      });

      return matches;
    });
  }

// ⬇️ 혼성 → 남성 → 여성 순서로 정렬되도록 숫자 부여
  int _getMatchGenderSortKey(Match m) {
    final g1 = m.team1.players[0].gender;
    final g2 = m.team1.players[1].gender;
    if (g1 != g2) return 0;       // 혼성 먼저
    if (g1 == "남성") return 1;   // 남성 그다음
    if (g1 == "여성") return 1;   // 여성 마지막
    return 3;                     // 그 외 (예외처리용)
  }


  Future<void> deleteAllTournamentMatches() async {
    final firestore = FirebaseFirestore.instance;
    final tournamentRef = firestore.collection("본선 경기").doc("콕콕 리그전");

    final genderList = ['남성', '여성', '혼성'];

    for (final gender in genderList) {
      final genderCollection = tournamentRef.collection(gender);
      final genderSnapshot = await genderCollection.get();

      for (final divisionDoc in genderSnapshot.docs) {
        final matchesRef = divisionDoc.reference.collection("경기");
        final matchesSnapshot = await matchesRef.get();

        // 🔸 경기 삭제
        for (final matchDoc in matchesSnapshot.docs) {
          await matchDoc.reference.delete();
        }

        // 🔸 부 문서 삭제
        await divisionDoc.reference.delete();
      }
    }
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
    final teamsRef = _db.collection(category);

    // 1. 기존 문서 전체 가져오기
    final existingDocs = await teamsRef.get();

    // 2. 기존 문서 삭제
    for (var doc in existingDocs.docs) {
      batch.delete(doc.reference);
    }

    // 3. 새 팀 정보 저장
    for (var team in teams) {
      batch.set(teamsRef.doc(team.id), team.toJson());
    }

    // 4. 커밋
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
  Future<List<Player>> loadPlayers(String category, String gender, {bool sortByRank = true}) async {
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
      return Player.fromJson(doc.data() as Map<String, dynamic>);
    }).toList();

  }

  //경기 기록 삭제하기
  Future<void> deletePreliminaryMatches(String tournamentId) async {
    final root = _db.collection('경기 기록').doc(tournamentId);
    final categories = ["남성", "여성", "혼성"];

    for (final category in categories) {
      final categoryRef = root.collection(category);
      final divisionDocs = await categoryRef.get();

      for (final divisionDoc in divisionDocs.docs) {
        final divisionId = divisionDoc.id;

        final matchRef = categoryRef.doc(divisionId).collection("경기");
        final matchDocs = await matchRef.get();

        for (final match in matchDocs.docs) {
          await match.reference.delete();
        }

        // ⚠️ division 문서도 삭제 (필요하다면)
        await divisionDoc.reference.delete();
      }
    }
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
        'isCompleted' : false
      });

      for (var match in entry.value) {
        final matchDoc = divisionDoc.collection('경기').doc(match.id);
        batch.set(matchDoc, match.toJson());
      }
    }

    await batch.commit();
    print("saveMatches 종료 : ${DateTime.now()}");
  }


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

    print("matchTable Key : ${matchTable.keys.toString()}");
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
    String group = match.group != null ? "_${match.group}" : "";
    await _db
        .collection('경기 기록')
        .doc(tournamentId)
        .collection(gender) //남성,여성,혼성
        .doc(match.division.toString()+group) //1_A
        .collection('경기')
        .doc(match.id)
        .update(match.toJson());
  }


  Future<void> updateMatchCourt(String matchId, int? courtNumber, String gender, String division) async {
    print("matchId : $matchId, courtNumber : $courtNumber, gender : $gender, division : $division");

    // 🔹 혼성 토너먼트는 division 고정
    if (gender == "혼성 토너먼트") {
      division = "1";
    }

    // 🔸 남성 본선일 경우 division이 "숫자_roundX" 형태일 수 있음
    else if (gender == "남성" && RegExp(r'^\d+_round\d+$').hasMatch(division)) {
      final divNum = division.split("_").first;
      division = "본선_$divNum";
    }

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
