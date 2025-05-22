import 'package:flutter/material.dart';
import '../../model/Match.dart';
import '../../model/Team.dart';
import '../../services/firestore_service.dart';


abstract class MatchStatusBase extends StatefulWidget {
  final bool isAdmin;
  const MatchStatusBase({super.key, required this.isAdmin});

  @override
  MatchStatusBaseState createState();
}

abstract class MatchStatusBaseState<T extends MatchStatusBase> extends State<T> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Match> allMatches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  //매치에 코트 넘버 부여
  Future<void> _assignMatchToCourt(Match match, int courtNumber, String gender, String division) async {
    match.courtNumber = courtNumber;
    await _firestoreService.updateMatchCourt(match.id, courtNumber, gender, division);
    // _loadMatches();
  }


  //note build
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Match>>(
      stream: _firestoreService.watchAllMatches(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        allMatches = snapshot.data!;

        // 진행 중인 경기에서 출전 중인 선수 이름 추출
        final ongoingMatches = allMatches
            .where((m) => m.courtNumber != null && !m.isCompleted)
            .toList();

        final activePlayerNames = ongoingMatches
            .expand((m) => [...m.team1.players, ...m.team2.players])
            .map((p) => p.name)
            .toSet();

        final waitingMatches = <Match>[];
        final waitingPlayerNames = <String>{};

        for (var match in allMatches) {
          if (match.courtNumber == null && !match.isCompleted) {
            final teamPlayers = [...match.team1.players, ...match.team2.players];
            final names = teamPlayers.map((p) => p.name);

            // 진행 중이거나 대기 중인 선수와 겹치면 제외
            if (names.any((name) =>
            activePlayerNames.contains(name) ||
                waitingPlayerNames.contains(name))) continue;

            waitingMatches.add(match);
            waitingPlayerNames.addAll(names);

            if (waitingMatches.length >= 6) break;
          }
        }


        return SingleChildScrollView(
          child: Center(
            child: Container(
              margin: EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              width: (double.infinity >= 600) ? 600 : double.infinity,
              child: Column(
                children: [
                  _buildCourtsGrid(ongoingMatches),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("대기 팀", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        InkWell(
                          onTap: (){
                            _showImageDialog(context,"assets/images/yewon2.png");
                          },
                          child: Image.asset("assets/images/shuttlecock.png",width: 30,)
                        )
                      ],
                    ),
                  ),
                  ...waitingMatches.map(_buildWaitingCard).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  ///코트 상황 판
    Widget _buildCourtsGrid(List<Match> matches) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 20, 8, 0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        children: List.generate(6, (index) {
          int courtNum = index + 1;

          if (index == 1) {
            return Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
                image: const DecorationImage(
                  image: AssetImage("assets/images/cokcok_image.png"),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.white60, // 어두운 오버레이로 글자 가독성 향상
                    BlendMode.darken,
                  ),
                ),
              ),
              // child: const Center(
              //   child: Text("막혀있음\n(사용 불가)", textAlign: TextAlign.center),
              // ),
            );
          }

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

          final isEmpty = match.id == "";
          final isMixed = match.team1.players.length == 2 &&
              match.team1.players[0].gender != match.team1.players[1].gender;

          final gender = isMixed
              ? "혼성"
              : match.team1.players.isNotEmpty
              ? match.team1.players[0].gender
              : "기타";

          final backgroundColor = isEmpty
              ? Colors.grey[200]
              : gender == "남성"
              ? const Color(0xFFD0E8FF)
              : gender == "여성"
              ? const Color(0xFFFFD0E8)
              : const Color(0xFFD0FFD6);

          final divisionLabel = match.group != null
              ? "${match.division}부 ${match.group}조"
              : "${match.division}부";

          return LayoutBuilder(
            builder: (context, constraints) {
              double width = constraints.maxWidth;
              double fontSize = width * 0.08; // 예: 100px일 때 약 9px
              double labelSize = width * 0.09;
              double gap = width * 0.02
              ;

              return Container(
                margin: EdgeInsets.all(8),
                padding: EdgeInsets.symmetric(horizontal: gap, vertical: gap),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
                child: isEmpty
                ? Center(
                  child: Text(
                    "코트 $courtNum",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: labelSize),
                  ),
                )
                :Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          gender =="혼성" ? "혼성 복식" : "$gender $divisionLabel",
                          style: TextStyle(fontSize: labelSize, fontWeight: FontWeight.normal),
                        ),
                        if (widget.isAdmin)
                          IconButton(
                            icon: Icon(Icons.logout_outlined, size: fontSize),
                            tooltip: "퇴장",
                            onPressed: () async {
                              await _firestoreService.updateMatchCourt(
                                match.id,
                                null,
                                gender == "혼성" ? "혼성 토너먼트" : gender,
                                match.group != null
                                    ? "${match.division}_${match.group}"
                                    : match.division.toString(),
                              );
                            },
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),
                    Expanded(
                      child: Row(
                        children: [
                          // 팀1
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  match.team1.players.length > 0 ? match.team1.players[0].name : "빈자리",
                                  style: TextStyle(fontSize: fontSize),
                                ),
                                Text(
                                  match.team1.players.length > 1 ? match.team1.players[1].name : "빈자리",
                                  style: TextStyle(fontSize: fontSize),
                                ),

                              ],
                            ),
                          ),
                          // 구분선
                          Container(width: 1, height: double.infinity, color: Colors.black),
                          // 팀2
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(match.team2.players[0].name, style: TextStyle(fontSize: fontSize)),
                                Text(match.team2.players[1].name, style: TextStyle(fontSize: fontSize)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );


        }),
      ),
    );
  }


  ///대기팀
  Widget _buildWaitingCard(Match match) {
    final gender = match.team1.players[0].gender == match.team1.players[1].gender ? match.team1.players[0].gender : "혼성 토너먼트";
    final division = match.group != null ? "${match.division}_${match.group}" : match.division.toString();

    String label;
    if(gender == "혼성 토너먼트"){
      label = "혼성 복식";
    }
    else{
      label = "$gender ${division}부";
    }


    return Card(
      color:gender == "남성" ? Colors.blue.shade100 : gender == "여성"? Colors.pink.shade100 : Colors.green.shade100,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text("${match.team1.players[0].name}, ${match.team1.players[1].name}"),
              const Text("  VS  "),
              Text("${match.team2.players[0].name}, ${match.team2.players[1].name}"),
              const Spacer(),

              // ✅ 운영자일 때만 입장 버튼 표시
              if (widget.isAdmin)
                ElevatedButton(
                  onPressed: () {
                    Set<int> usedCourts = allMatches  ///사용중인 코트
                        .where((m) => m.courtNumber != null && !m.isCompleted)  /// 널아님,완료
                        .map((m) => m.courtNumber!)
                        .toSet(); ///사용중인 코트

                    int? availableCourt;
                    for (int i = 1; i <= 6; i++) {
                      print("i : $i");
                      if (!usedCourts.contains(i) && i != 2) {
                        availableCourt = i; ///비어있으면 브레이크로 탈출
                        print("availableCourt : $availableCourt");
                        break;
                      }
                    }

                    if (availableCourt != null) { ///비어있는 코트가 있으면
                      _assignMatchToCourt(match, availableCourt, gender, division); //코트 할당
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("모든 코트가 사용 중입니다.")),
                      );
                    }
                  },
                  child: const Text("입장"),
                ),
            ],
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          ],
        ),
      ),
    );
  }



}
