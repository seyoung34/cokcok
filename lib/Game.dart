import 'package:flutter/material.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';

class Game extends StatefulWidget {
  const Game({super.key});

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> {
  List<DragAndDropList> lists = [];

  @override
  void initState() {
    super.initState();
    _initializeLists();
  }

  void _initializeLists() {
    lists = [ //DragAndDropLists
      DragAndDropList(
        header: Center(child: Text("리스트 1", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        children: [
          DragAndDropItem(child: ListTile(title: Text("아이템 1"))),
          DragAndDropItem(child: ListTile(title: Text("아이템 2"))),
          DragAndDropItem(child: ListTile(title: Text("아이템 3"))),
        ],
      ),
      DragAndDropList(
        header: Center(child: Text("리스트 2", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        children: [
          DragAndDropItem(child: ListTile(title: Text("아이템 A"))),
          DragAndDropItem(child: ListTile(title: Text("아이템 B"))),
          DragAndDropItem(child: ListTile(title: Text("아이템 C"))),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("리스트 간 Drag & Drop")),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // 가로 스크롤 가능하게 설정
        child: Row(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width, // 전체 화면 너비 사용
              child: DragAndDropLists(
                children: lists,
                onItemReorder: (oldItemIndex, oldListIndex, newItemIndex, newListIndex) {
                  setState(() {
                    var movedItem = lists[oldListIndex].children.removeAt(oldItemIndex);
                    lists[newListIndex].children.insert(newItemIndex, movedItem);
                  });
                },
                onListReorder: (oldListIndex, newListIndex) {
                  setState(() {
                    var movedList = lists.removeAt(oldListIndex);
                    lists.insert(newListIndex, movedList);
                  });
                },
                axis: Axis.horizontal, // 가로 정렬
                listWidth: 300, // 리스트 하나의 너비 조정
                listPadding: EdgeInsets.all(16), // 리스트 간격 추가
              ),
            ),
          ],
        ),
      ),
    );
  }
}
