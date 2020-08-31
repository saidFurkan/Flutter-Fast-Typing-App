import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:random_words/random_words.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyAppHome(),
      // theme: ThemeData(
      //   fontFamily: '',
      // ),
    );
  }
}

class MyAppHome extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyAppHomeState();
  }
}

class _MyAppHomeState extends State<MyAppHome> {
  String userName = "";
  int step = 0, score = 0, countWrong = 0, timer = 60;
  int highScore = 0;
  List<String> highScoresList = <String>[]; // 0:userName, 1:score, 2:countWrong
  String listName = "highScoresList", highScoreName = "highScore";

  static const String textGreyOrg = "                                      ";
  String textGrey, textBlue;

  var jumpTimer, timer1s;

  double jumpPixel = 0.0, blockPixelSize = 0.0;
  bool firstTouch = true;

  ScrollController _scrollController;
  TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _scrollController = ScrollController();
  }

  /// Will get the startupnumber from shared_preferences
  /// will return 0 if null
  Future<List<String>> _getStringListFromSharedPref() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(listName);
    if (list == null) {
      return <String>[];
    }
    return list;
  }

  Future<void> _setHighScoreList(int trueScore, int wrongScore) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = await _getStringListFromSharedPref();

    if (list.length < 5) {
      list.add("$userName,$trueScore,$wrongScore");
      highScore = score;
      for (int i = list.length; i < 5; i++) {
        list.add("-,0,0");
      }
      setState(() {
        highScoresList = list;
        prefs.setStringList(listName, list);
      });
      return;
    }

    for (int i = 0; i < list.length; i++) {
      int s = int.parse(list[i].split(',')[1]);
      if (s < score) {
        list.insert(i, "$userName,$trueScore,$wrongScore");
        prefs.setStringList(listName, list);
        break;
      }
    }
    while (list.length > 5) {
      list.removeLast();
      prefs.setStringList(listName, list);
    }
    setState(() {
      highScore = int.parse(list[0].split(',')[1]);
      highScoresList = list;
    });
  }

  void onUserNameType(String value) {
    setState(() {
      this.userName = value;
    });
  }

  void onType(String value) async {
    if (firstTouch) {
      startGame();
    }

    setState(() {
      if (value[value.length - 1] != textBlue[0]) {
        countWrong++;
      } else {
        score++;
      }
      textGrey += textBlue[0];
      textBlue = textBlue.substring(1);
    });
  }

  void startGame() {
    blockPixelSize = 1;
    firstTouch = false;

    jumpTimer = Timer.periodic(new Duration(milliseconds: 16), (timer) async {
      jumpPixel += blockPixelSize;
      setState(() {
        _scrollController.jumpTo(jumpPixel);
      });
    });

    timer1s = Timer.periodic(new Duration(seconds: 1), (t) async {
      setState(() {
        if (step == 1 && timer <= 0) {
          // GAME OVER
          endGame();
        }
        timer--;
      });
    });
  }

  Future<void> endGame() async {
    //_setNewHighScore(highScoreName);
    await _setHighScoreList(score, countWrong);
    _scrollController.jumpTo(0);
    _textEditingController.clear();
    jumpTimer.cancel();
    timer1s.cancel();
    setState(() {
      step++;
    });
  }

  void setGame() {
    setState(() {
      score = 0;
      countWrong = 0;
      step = 1;
      textGrey = textGreyOrg;
      textBlue = generateNoun().take(100).join(' ');
      jumpPixel = 0.0;
      firstTouch = true;
      blockPixelSize = 0.0;
      timer = 60;
    });
  }

  Future<void> restartGame() async {
    _textEditingController.clear();
    await endGame();
    setGame();
  }

  void goHomeScreen() {
    setState(() {
      step = 0;
    });
  }

  List<Widget> homePage() {
    return <Widget>[
      Text(
        'Oyuna Hoşgeldin\nYakalamaya Hazır mısın ?\n',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w400,
          fontSize: 28,
        ),
      ),
      Container(
        padding: EdgeInsets.all(20),
        child: TextField(
          onChanged: onUserNameType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: BorderSide(color: Colors.blue),
            ),
            hintText: 'İsminizi giriniz',
            labelText: 'İsim',
            prefixIcon: const Icon(
              Icons.person,
              color: Colors.blue,
            ),
          ),
        ),
      ),
      IconButton(
        icon: Icon(
          Icons.label_important,
          color: Colors.blue,
          size: 52.0,
        ),
        onPressed: userName.length == 0 ? null : setGame,
      ),
    ];
  }

  List<Widget> gamePage() {
    return <Widget>[
      Container(
        margin: EdgeInsets.only(bottom: 40.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  "Doğru : $score",
                  style: TextStyle(fontSize: 22, color: Colors.green[700]),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.timer,
                      color: Colors.black,
                      size: 36.0,
                    ),
                    SizedBox(height: 5),
                    Text(
                      "$timer",
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  "Yanlış : $countWrong",
                  style: TextStyle(fontSize: 22, color: Colors.red[700]),
                ),
              ),
            )
          ],
        ),
      ),
      SingleChildScrollView(
        controller: _scrollController,
        physics: NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            Container(
              child: Text(
                textGrey,
                style: TextStyle(color: Colors.grey[400], fontSize: 26),
              ),
            ),
            Container(
              child: Text(
                textBlue,
                style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 26,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 16),
        child: TextField(
          autofocus: true,
          controller: _textEditingController,
          onChanged: onType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.0),
                borderSide: BorderSide(color: Colors.black)),
            labelText: 'Yaz Bakalım',
          ),
        ),
      ),
      SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              Icons.replay,
              color: Colors.blue,
              size: 36.0,
            ),
            onPressed: restartGame,
          ),
          SizedBox(width: 30),
          RotatedBox(
            quarterTurns: 1,
            child: IconButton(
              icon: Icon(
                Icons.navigation,
                color: Colors.blue,
                size: 36.0,
              ),
              onPressed: endGame,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> resultPage() {
    return <Widget>[
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'En Yüksek Skor : $highScore',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 25),
            Text(
              'Puan : $score',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.green,
                fontSize: 22,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Yanlış : $countWrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
                fontSize: 22,
              ),
            ),
            SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.replay,
                    color: Colors.blue,
                    size: 36.0,
                  ),
                  onPressed: setGame,
                ),
                SizedBox(width: 30),
                IconButton(
                  icon: Icon(
                    Icons.home,
                    color: Colors.blue,
                    size: 36.0,
                  ),
                  onPressed: () {
                    setState(() {
                      step = 0;
                      userName = '';
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 30),
            Text(
              "En Yüksek 5 Puan",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      DataTable(
        columns: const <DataColumn>[
          DataColumn(
            label: Text(
              'İsim',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          DataColumn(
            label: Text(
              'Puan',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          DataColumn(
            label: Text(
              'Yanlış',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ],
        rows: createDataRows(),
      ),
    ];
  }

  List<DataRow> createDataRows() {
    List<DataRow> dataList = <DataRow>[];
    for (int i = 0; i < 5; i++) {
      dataList.add(
        DataRow(
          cells: <DataCell>[
            DataCell(Text(highScoresList[i].split(',')[0])),
            DataCell(Text(highScoresList[i].split(',')[1])),
            DataCell(Text(highScoresList[i].split(',')[2])),
          ],
        ),
      );
    }
    return dataList;
  }

  @override
  Widget build(BuildContext context) {
    var shownWidget;

    if (step == 0)
      shownWidget = homePage();
    else if (step == 1)
      shownWidget = gamePage();
    else
      shownWidget = resultPage();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Sıkıysa Yakala',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        child: Align(
          alignment: Alignment.center,
          child: new SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: shownWidget,
            ),
          ),
        ),
      ),
    );
  }
}

// build : flutter build apk --target-platform android-arm,android-arm64
