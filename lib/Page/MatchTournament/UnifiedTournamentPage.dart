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
    }
    else if (selectedCategory.startsWith("남성")) {
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
    }
    else {
      return Stream.value([]);
    }
  }

  List<Tournament> _convertToTournamentRounds(List<Match> matches) {
    final grouped = <String, List<TournamentMatch>>{};

    for (var match in matches) {
      final group = match.group ?? "기타";
      final tm = _convertMatchToTournamentMatch(match);
      debugPrint(
          "📦 Match group: $group | ${tm.teamA} (${tm.scoreTeamA}) vs ${tm.teamB} (${tm.scoreTeamB})");
      grouped.putIfAbsent(group, () => []).add(tm);
    }

    final roundOrder = ["round1", "round2", "round3", "round4"];

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

  Future<void> generateMixedTournament() async {
    final List<Team> teams = await firestoreService.loadMixedLeagueTeams();
    teams.shuffle();

    final int totalTeams = 16;
    final int neededPlaceholders = totalTeams - teams.length;

    final List<Team> filledTeams = [
      ...teams,
      ...List.generate(neededPlaceholders, (_) => Team.empty()),
    ];
    filledTeams.shuffle();

    final List<Match> allMatches = [];
    List<Team> currentRoundTeams = filledTeams;
    // final emptyTeam = Team.empty();

    int roundNumber = 1;

    while (currentRoundTeams.length > 1) {
      List<Team> nextRoundTeams = [];
      for (int i = 0; i < currentRoundTeams.length; i += 2) {
        final team1 = currentRoundTeams[i];
        final team2 = currentRoundTeams[i + 1];

        final bool isBye = team1.id == "빈 팀" || team2.id == "빈 팀";
        final winner = (team1.id == "빈 팀") ? team2 : team1;

        final match = Match(
          id: "round${roundNumber}_${i ~/ 2}",  //todo id 바꾸기
          team1: team1,
          team2: team2,
          team1Score: isBye ? (team1.id == "빈 팀" ? 0 : 1) : 0,
          team2Score: isBye ? (team2.id == "빈 팀" ? 0 : 1) : 0,
          isCompleted: false,
          winnerTeamId: isBye ? winner.id : null,
          division: 1,
          group: "round$roundNumber",
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

  Future<void> generateMaleFinalTournament(int division, List<Team> qualifiedTeams) async {
    if (qualifiedTeams.length != 4) {
      throw Exception("4개의 팀이 필요합니다.");
    }

    final teamA1 = qualifiedTeams[0];
    final teamB2 = qualifiedTeams[1];
    final teamA2 = qualifiedTeams[2];
    final teamB1 = qualifiedTeams[3];

    final matches = [
      Match(
        id: "round1_0",
        team1: teamA1,
        team2: teamB2,
        group: "round1",
        isCompleted: false,
        division: division,
      ),
      Match(
        id: "round1_1",
        team1: teamA2,
        team2: teamB1,
        group: "round1",
        isCompleted: false,
        division: division,
      ),
      Match(
        id: "round2_0", // 결승
        team1: Team.empty(),
        team2: Team.empty(),
        group: "round2",
        isCompleted: false,
        division: division,
      ),
      /*Match(
        id: "round2_1", // 3·4위전
        team1: Team.empty(),
        team2: Team.empty(),
        group: "round2",
        isCompleted: false,
        division: division,
      ),*/
    ];

    for (final match in matches) {
      await firestoreService.saveMatchToFinalTournament(division, match);
    }
  }



  Future<void> generateMaleDivisionFinalsIfReady(int division) async {
    final isACompleted = await firestoreService.isDivisionCompleted(division, "A");
    final isBCompleted = await firestoreService.isDivisionCompleted(division, "B");

    if (!(isACompleted && isBCompleted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("예선 완료되지 않음"),duration: Duration(seconds: 1),),
      );
      debugPrint("❌ 예선 완료되지 않음: ${division}_A, ${division}_B");
      return;
    }

    final aMatches = await firestoreService.getDivisionMatches(division, "A");
    final bMatches = await firestoreService.getDivisionMatches(division, "B");

    final aStats = calculateTeamRanks(aMatches);
    final bStats = calculateTeamRanks(bMatches);

    final aSorted = aStats.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final bSorted = bStats.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final a1 = aSorted[0].key;
    final a2 = aSorted[1].key;
    final b1 = bSorted[0].key;
    final b2 = bSorted[1].key;

    await generateMaleFinalTournament(division, [a1, b2, a2, b1]);


    debugPrint("✅ 남성 ${division}부 본선 생성 완료");
  }

  Map<Team, int> calculateTeamRanks(List<Match> matches) {
    final winCount = <String, int>{};
    final pointDiff = <String, int>{};
    final teamMap = <String, Team>{}; // id → Team 객체

    for (final match in matches) {
      if (!match.isCompleted) continue;

      final t1 = match.team1;
      final t2 = match.team2;
      final s1 = match.team1Score ?? 0;
      final s2 = match.team2Score ?? 0;

      teamMap[t1.id] = t1;
      teamMap[t2.id] = t2;

      winCount[t1.id] = (winCount[t1.id] ?? 0);
      winCount[t2.id] = (winCount[t2.id] ?? 0);
      pointDiff[t1.id] = (pointDiff[t1.id] ?? 0) + (s1 - s2);
      pointDiff[t2.id] = (pointDiff[t2.id] ?? 0) + (s2 - s1);

      if (s1 > s2) {
        winCount[t1.id] = winCount[t1.id]! + 1;
      } else if (s2 > s1) {
        winCount[t2.id] = winCount[t2.id]! + 1;
      }
    }

    // 팀 ID 기준 정렬 후 랭크 부여
    final sorted = winCount.keys.toList()
      ..sort((a, b) {
        final winCompare = winCount[b]!.compareTo(winCount[a]!);
        return winCompare != 0
            ? winCompare
            : pointDiff[b]!.compareTo(pointDiff[a]!);
      });

    final Map<Team, int> rankMap = {};
    for (int i = 0; i < sorted.length; i++) {
      final team = teamMap[sorted[i]]!;
      rankMap[team] = i + 1;
    }

    return rankMap;
  }




  //note build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                key: ValueKey(selectedCategory),
                stream: getTournamentStream(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final rounds = snapshot.data!;


                  if (rounds.isEmpty) {
                    return const Center(child: Text("아직 생성되지 않음"));
                  }

                  return Scrollbar(
                    controller: horizontalController,
                    thumbVisibility: false,
                    child: SingleChildScrollView(
                      controller: horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Scrollbar(
                        thumbVisibility: false,
                        controller: verticalController,
                        child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            controller: verticalController,
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height*0.9,
                              color: Colors.green.shade100,
                              padding: const EdgeInsets.all(16),
                              child: TournamentBracket(
                                key: ValueKey(selectedCategory),
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
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: widget.isAdmin == true
            ? FloatingActionButton.extended(
                onPressed: () async {
                  try {
                    if(selectedCategory == "혼성 토너먼트"){
                      await generateMixedTournament();
                    }
                    else if(selectedCategory == "남성 1부"){
                      generateMaleDivisionFinalsIfReady(1);
                    }
                    else if(selectedCategory == "남성 2부"){
                      generateMaleDivisionFinalsIfReady(2);
                    }
                    else{
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("유효하지 않음"),duration: Duration(seconds: 1),),
                      );
                    }
                    
                  } catch (e) {
                    print("에러: $e");
                  }
                },
                label: Text("생성"),
              )
            : null);
  }
}
