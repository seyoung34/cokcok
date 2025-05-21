// 혼성 및 남성 토너먼트 통합 페이지 (flutter_tournament_bracket 기반)

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tournament_bracket/flutter_tournament_bracket.dart';
import '../../model/Match.dart';
import '../../model/Team.dart';
import '../../services/firestore_service.dart';

abstract class TournamentUnifiedPage extends StatefulWidget {
  final String title;
  final bool isAdmin;

  const TournamentUnifiedPage(
      {super.key, required this.title, this.isAdmin = false});

  @override
  TournamentUnifiedPageState createState();
}

abstract class TournamentUnifiedPageState<T extends TournamentUnifiedPage>
    extends State<T> {
  final FirestoreService firestoreService = FirestoreService();
  final ScrollController verticalController = ScrollController();
  final ScrollController horizontalController = ScrollController();

  List<String> categories = ["혼성 토너먼트", "남성 1부", "남성 2부"];
  String selectedCategory = "혼성 토너먼트";

  @override
  void initState() {
    super.initState();
  }

  Stream<List<Tournament>> getTournamentStream() {
    if (selectedCategory == "혼성 토너먼트") {
      return firestoreService.watchMixedTournament().map((matches) {
        debugPrint("📦 혼성 토너먼트 match 수: ${matches.length}");
        for (final m in matches) {
          debugPrint(
              "🟢 ${m.id} | ${m.team1.id} (${m.team1Score}) vs ${m.team2.id} (${m.team2Score})");
        }
        return _convertToTournamentRounds(matches);
      });
    } else if (selectedCategory.startsWith("남성")) {
      final division =
          int.tryParse(selectedCategory.split(" ")[1].replaceAll("부", "")) ?? 1;
      return firestoreService.watchFinalMatches("남성", division).map((matches) {
        debugPrint("📦 남성 ${division}부 토너먼트 match 수: ${matches.length}");
        for (final m in matches) {
          debugPrint(
              "🟦 ${m.id} | ${m.team1.id} (${m.team1Score}) vs ${m.team2.id} (${m.team2Score})");
        }
        return _convertToTournamentRounds(matches);
      });
    } else {
      return Stream.value([]);
    }
  }

  /*List<Tournament> _convertToTournamentRounds(List<Match> matches) {
    final grouped = <String, List<TournamentMatch>>{};

    for (var match in matches) {
      final group = match.group ?? "기타";
      grouped
          .putIfAbsent(group, () => [])
          .add(_convertMatchToTournamentMatch(match));
    }

    final roundOrder = ["4강", "결승"];
    return roundOrder
        .where((r) => grouped.containsKey(r))
        .map((r) => Tournament(matches: grouped[r]!))
        .toList();
  }*/
  List<Tournament> _convertToTournamentRounds(List<Match> matches) {
    final grouped = <String, List<TournamentMatch>>{};

    for (var match in matches) {
      final group = match.group ?? "기타";
      final tm = _convertMatchToTournamentMatch(match);
      debugPrint(
          "📦 Match group: $group | ${tm.teamA} (${tm.scoreTeamA}) vs ${tm.teamB} (${tm.scoreTeamB})");
      grouped.putIfAbsent(group, () => []).add(tm);
    }

    final roundOrder = ["round_1", "round_2", "round_3", "round_4"];

    for (final round in roundOrder) {
      if (grouped.containsKey(round)) {
        debugPrint("✅ 라운드 '$round'에 포함된 경기 수: ${grouped[round]!.length}");
      } else {
        debugPrint("⚠️ 라운드 '$round'는 없음");
      }
    }

    return roundOrder.where((r) => grouped.containsKey(r)).map((r) {
      final matches = grouped[r]!;
      debugPrint("🔽 Tournament 생성: $r - ${matches.length}개 경기");
      return Tournament(matches: matches);
    }).toList();
  }

  TournamentMatch _convertMatchToTournamentMatch(Match match) {
    return TournamentMatch(
      id: match.id,
      teamA: match.team1.id,
      teamB: match.team2.id,
      scoreTeamA: match.team1Score?.toString(),
      scoreTeamB: match.team2Score?.toString(),
    );
  }

  Widget buildMatchCard(TournamentMatch match) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(match.teamA ?? "-",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(match.teamB ?? "-"),
          const SizedBox(height: 8),
          Text(
              "Score: ${match.scoreTeamA ?? "-"} - ${match.scoreTeamB ?? "-"}"),
        ],
      ),
    );
  }

  /*Future<void> generateMixedTournament() async {
    final List<Team> teams = await firestoreService.loadMixedLeagueTeams();
    teams.shuffle(); // 무작위 셔플

    print("혼성 팀 (${teams.length}개): ${teams.map((e) => e.id).toList()}");

    final List<Match> allMatches = [];
    final emptyTeam = Team.empty();
    final List<Team> currentTeams = [];

    int matchIdCounter = 0;

    // 🔹 8강 라운드 생성
    List<Team> nextRoundTeams = [];
    for (int i = 0; i < teams.length; i += 2) {
      final team1 = teams[i];
      final team2 = (i + 1 < teams.length) ? teams[i + 1] : emptyTeam;

      final isBye = team2.id == "빈 팀";
      final match = Match(
        id: "${team1.id.split("_").last} VS ${team2.id.split("_").last}",
        team1: team1,
        team2: team2,
        team1Score: isBye ? 1 : 0,
        team2Score: isBye ? 0 : 0,
        isCompleted: isBye,
        winnerTeamId: isBye ? team1.id : null,
        division: 1,
        group: "8강",
      );

      allMatches.add(match);

      if (match.isCompleted) {
        allMatches.removeLast();
        nextRoundTeams.add(team1); // 부전승일 경우
      }
    }

    // 🔹 준준결승 라운드 생성 (빈 경기로 채워넣기)
    matchIdCounter = 0;
    List<Team> semiFinalTeams = _fillWithPlaceholder(nextRoundTeams, 6);
    List<Team> finalCandidates = [];
    for (int i = 0; i < semiFinalTeams.length; i += 2) {
      final match = Match(
        id: "2_${matchIdCounter++}",
        team1: semiFinalTeams[i],
        team2: semiFinalTeams[i + 1],
        division: 1,
        group: "4강",
      );
      allMatches.add(match);
      // 추후 승자 업데이트용 후보 저장
      finalCandidates.add(emptyTeam); // 추후 winnerTeamId 기반으로 업데이트됨
    }

    // 🔹 준결승 경기 미리 생성
    final finalMatch = Match(
      id: "3_0",
      team1: emptyTeam,
      team2: emptyTeam,
      division: 1,
      group: "결승",
    );
    allMatches.add(finalMatch);

    // 🔹 Firestore 저장
    await firestoreService.saveMixedTournamentMatches(allMatches);
  }*/

  Future<void> generateMixedTournament() async {
    final List<Team> teams = await firestoreService.loadMixedLeagueTeams();
    teams.shuffle();

    final int totalTeams = 16;
    final int neededPlaceholders = totalTeams - teams.length;

    final List<Team> filledTeams = [
      ...teams,
      ...List.generate(neededPlaceholders, (_) => Team.empty()),
    ];

    final List<Match> allMatches = [];
    List<Team> currentRoundTeams = filledTeams;
    final emptyTeam = Team.empty();

    int roundNumber = 1;

    while (currentRoundTeams.length > 1) {
      List<Team> nextRoundTeams = [];
      for (int i = 0; i < currentRoundTeams.length; i += 2) {
        final team1 = currentRoundTeams[i];
        final team2 = currentRoundTeams[i + 1];

        final isBye = team1.id == "빈 팀" || team2.id == "빈 팀";
        final winner = (team1.id == "빈 팀") ? team2 : team1;

        final match = Match(
          id: "round${roundNumber}_${i ~/ 2}",
          team1: team1,
          team2: team2,
          team1Score: isBye ? (team1.id == "빈 팀" ? 0 : 1) : 0,
          team2Score: isBye ? (team2.id == "빈 팀" ? 0 : 1) : 0,
          isCompleted: isBye,
          winnerTeamId: isBye ? winner.id : null,
          division: 1,
          group: "round_$roundNumber",
        );

        allMatches.add(match);
        if (isBye) nextRoundTeams.add(winner);
      }

      // 실제 승자 선택이 완료된 경우만 승자 리스트 구성
      currentRoundTeams = nextRoundTeams.length == currentRoundTeams.length ~/ 2
          ? nextRoundTeams
          : List.generate(currentRoundTeams.length ~/ 2, (_) => Team.empty());

      roundNumber++;
    }

    await firestoreService.saveMixedTournamentMatches(allMatches);
  }



  ///본선경기 생성
  /*Future<void> generateMaleFinalTournament(int division) async {
    final groupA = await firestoreService.loadMatchesByGroup("남성_${division}_A");
    final groupB = await firestoreService.loadMatchesByGroup("남성_${division}_B");

    if (!groupA.every((m) => m.isCompleted) || !groupB.every((m) => m.isCompleted)) {
      throw Exception("예선 경기가 모두 완료되어야 합니다.");
    }

    final aTeams = firestoreService.getUniqueTeams(groupA);
    final bTeams = firestoreService.getUniqueTeams(groupB);
    final aStats = firestoreService.calculateStats(groupA, aTeams);
    final bStats = firestoreService.calculateStats(groupB, bTeams);

    final aSorted = [...aTeams]..sort((a, b) => aStats[a.id]!['rank'].compareTo(aStats[b.id]!['rank']));
    final bSorted = [...bTeams]..sort((a, b) => bStats[a.id]!['rank'].compareTo(bStats[b.id]!['rank']));

    final semi1 = Match(
      id: "준결승1",
      team1: aSorted[0],
      team2: bSorted[1],
      division: division,
      group: "4강",
    );
    final semi2 = Match(
      id: "준결승2",
      team1: bSorted[0],
      team2: aSorted[1],
      division: division,
      group: "4강",
    );

    final matches = [semi1, semi2];

    final colRef = _db.collection("경기 기록").doc("콕콕 리그전").collection("남성").doc("본선_$division").collection("경기");
    final batch = _db.batch();
    for (final match in matches) {
      batch.set(colRef.doc(match.id), match.toJson());
    }
    await batch.commit();
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: horizontalController,
            child: Row(
              children: categories
                  .map((cat) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: selectedCategory == cat,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => selectedCategory = cat);
                            }
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<Tournament>>(
              stream: getTournamentStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final rounds = snapshot.data!;

                // ✅ 디버깅 출력
                debugPrint("📦 stream으로 받은 토너먼트 라운드 수: ${rounds.length}");
                for (int i = 0; i < rounds.length; i++) {
                  final round = rounds[i];
                  debugPrint("🔹 Round $i: ${round.matches.length} 경기");
                  for (final m in round.matches) {
                    debugPrint(
                        "  - ${m.teamA} vs ${m.teamB} (${m.scoreTeamA} : ${m.scoreTeamB})");
                  }
                }

                if (rounds.isEmpty) {
                  return const Center(child: Text("아직 생성되지 않음"));
                }
                /*return
                  Scrollbar(
                  thumbVisibility: true,
                  controller: verticalController,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    controller: verticalController,
                    child: Scrollbar(
                      thumbVisibility: true,
                      controller: horizontalController,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: horizontalController,
                        child: Container(
                          width: 1300,
                            height: 1000,
                            color: Colors.green.shade100,
                            padding: const EdgeInsets.all(16),
                            child: TournamentBracket(
                              list: rounds,
                              card: buildMatchCard,
                              cardWidth: 220,
                              cardHeight: 100,
                              itemsMarginVertical: 20,
                              lineWidth: 80,
                              lineThickness: 4,
                              lineColor: Colors.green,
                            ),
                          ),
                        ),
                      ),
                    ),
                );*/
                return Scrollbar(
                  thumbVisibility: true,
                  controller: verticalController,
                  child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      controller: verticalController,
                      child: Container(
                        width: 1300,
                        height: 1000,
                        color: Colors.green.shade100,
                        padding: const EdgeInsets.all(16),
                        child: TournamentBracket(
                          list: rounds,
                          card: buildMatchCard,
                          cardWidth: 220,
                          cardHeight: 100,
                          itemsMarginVertical: 20,
                          lineWidth: 80,
                          lineThickness: 4,
                          lineColor: Colors.green,
                        ),
                      )),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await generateMixedTournament();
              } catch (e) {
                print("에러: $e");
              }
            },
            child: Text("혼성 토너먼트 생성"),
          ),
        ],
      ),
    );
  }
}
