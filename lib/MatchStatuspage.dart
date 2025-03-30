import 'package:cokcok/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'model/Match.dart';
import 'model/Match.dart';
import 'model/Team.dart';

class MatchStatusPage extends StatefulWidget {
  @override
  _MatchStatusPageState createState() => _MatchStatusPageState();
}

class _MatchStatusPageState extends State<MatchStatusPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Match> allMatches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    Map<String, List<Match>> matchMap = await _firestoreService.loadMatches();
    allMatches = matchMap.values.expand((matchList) => matchList).toList();
    setState(() {
      isLoading = false;
    });
  }


  Future<void> _assignMatchToCourt(Match match, int courtNumber) async {
    match.courtNumber = courtNumber;
    await _firestoreService.updateMatchCourt(match.id, courtNumber);
    _loadMatches();
  }

  //note build
  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator());

    // 진행 중인 경기
    List<Match> ongoingMatches = allMatches
        .where((m) => m.courtNumber != null && !m.isCompleted)
        .toList();

    //진행 중인 경기
    List<String> activeTeamIds = allMatches
        .where((m) => m.courtNumber != null && !m.isCompleted)
        .expand((m) => [m.team1.id, m.team2.id])
        .toSet()
        .toList();

    //대기 중인 경기
    List<Match> waitingMatches = [];
    Set<String> waitingTeamIds = Set<String>();

    for (var match in allMatches) {
      if (match.courtNumber == null && !match.isCompleted) {
        // 중복 체크
        if (activeTeamIds.contains(match.team1.id) ||
            activeTeamIds.contains(match.team2.id) ||
            waitingTeamIds.contains(match.team1.id) ||
            waitingTeamIds.contains(match.team2.id)) {
          continue; // 현재 진행 중이거나 이미 대기 리스트에 포함된 팀이면 skip
        }

        waitingMatches.add(match);
        waitingTeamIds.add(match.team1.id);
        waitingTeamIds.add(match.team2.id);

        if (waitingMatches.length >= 3) break;
      }
    }



    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCourtsGrid(ongoingMatches),
          SizedBox(height: 20),
          Text("대기 팀", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ...waitingMatches.map(_buildWaitingCard).toList(),
        ],
      ),
    );
  }

  Widget _buildCourtsGrid(List<Match> matches) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      physics: NeverScrollableScrollPhysics(),
      children: List.generate(12, (index) {
        int courtNum = index + 1;
        final match = matches.firstWhere(
              (m) => m.courtNumber == courtNum,
          orElse: () => Match(
            id: "",
            team1: Team.empty(),
            team2: Team.empty(),
            division: 0,
            courtNumber: courtNum,
          ),
        );

        return Container(
          margin: EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            color: match.id == "" ? Colors.grey[200] : Colors.lightGreen[200],
          ),
          child: Center(
            child: match.id == ""
                ? Text("코트 $courtNum\n(비어 있음)", textAlign: TextAlign.center)
                : Text("${match.team1.id}\nvs\n${match.team2.id}", textAlign: TextAlign.center),
          ),
        );
      }),
    );
  }

  Widget _buildWaitingCard(Match match) {
    String divisionLabel = "${match.team1.players[0].gender} ${match.division}부";
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(divisionLabel, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text("${match.team1.players[0].name}, ${match.team1.players[1].name}"),
            Text("VS"),
            Text("${match.team2.players[0].name}, ${match.team2.players[1].name}"),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  // 비어 있는 코트 찾기
                  Set<int> usedCourts = allMatches
                      .where((m) => m.courtNumber != null && !m.isCompleted)
                      .map((m) => m.courtNumber!)
                      .toSet();

                  int? availableCourt;
                  for (int i = 1; i <= 12; i++) {
                    if (!usedCourts.contains(i)) {
                      availableCourt = i;
                      break;
                    }
                  }

                  if (availableCourt != null) {
                    _assignMatchToCourt(match, availableCourt);
                    //todo 컬렉션 넣는 게 잘못 됨 매개변수 변경필요
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("모든 코트가 사용 중입니다.")),
                    );
                  }
                },
                child: Text("입장"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
