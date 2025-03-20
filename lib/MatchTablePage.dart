import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../model/Match.dart';

class MatchTablePage extends StatefulWidget {
  @override
  _MatchTablePageState createState() => _MatchTablePageState();
}

class _MatchTablePageState extends State<MatchTablePage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Match> matches = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    matches = await _firestoreService.loadMatches();
    setState(() {});
  }

  Future<void> _saveMatches() async {
    await _firestoreService.saveMatches(matches);
  }

  void _updateMatchScore(int index, int team1Score, int team2Score) {
    setState(() {
      matches[index].team1Score = team1Score;
      matches[index].team2Score = team2Score;
      matches[index].isCompleted = true;
    });
    _saveMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("경기 진행")),
      body: ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("${matches[index].team1.id} vs ${matches[index].team2.id}"),
            subtitle: Text("점수: ${matches[index].team1Score} - ${matches[index].team2Score}"),
            onTap: () => _showScoreDialog(index),
          );
        },
      ),
    );
  }

  void _showScoreDialog(int index) {
    TextEditingController team1Controller = TextEditingController();
    TextEditingController team2Controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("점수 입력"),
          content: Column(
            children: [
              TextField(controller: team1Controller, decoration: InputDecoration(labelText: "팀1 점수")),
              TextField(controller: team2Controller, decoration: InputDecoration(labelText: "팀2 점수")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("취소")),
            TextButton(
              onPressed: () {
                _updateMatchScore(index, int.parse(team1Controller.text), int.parse(team2Controller.text));
                Navigator.pop(context);
              },
              child: Text("저장"),
            ),
          ],
        );
      },
    );
  }
}
