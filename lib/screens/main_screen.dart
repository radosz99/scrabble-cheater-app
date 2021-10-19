import 'package:flutter/material.dart';
import 'package:scrabble_cheater/components/moves.dart';
import 'utils.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:scrabble_cheater/services/networking.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static final countMatrix = 15;
  List<List<String>> matrix = [];
  List<List<String>> realMatrix = [];
  List<Move> moves = [];
  final imagePicker = ImagePicker();
  bool status = true;
  bool isLoadingBoard = false;
  bool isLoadingMoves = false;
  final lettersController = TextEditingController();

  @override
  void initState() {
    super.initState();

    setEmptyFields();
  }

  List<List<String>> getEmptyMatrix(){
    return List.generate(
        countMatrix,
    (_) => List.generate(countMatrix, (_) => ' '));
  }

  void setEmptyFields() => setState(() {
    matrix = getEmptyMatrix();
    realMatrix = getEmptyMatrix();
  });

  Future getBoard(String path) async {
    List<List<String>> board = await getBoardFromImage(path);
    return board;
  }

  //TODO: add loading indicator
  Future getImageFromGallery() async {
    final image = await imagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      status = false;
      isLoadingBoard = true;
      moves = [];
    });
    List<List<String>> board = await getBoard(image.path);
    setState(() {
      matrix = getBoardCopy(board);
      realMatrix = getBoardCopy(board);
      isLoadingBoard = false;
      status = true;
    });
  }

  Future getImageFromCamera() async {
    final image = await imagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      status = false;
      isLoadingBoard = true;
      moves = [];
    });
    List<List<String>> board = await getBoard(image.path);
    setState(() {
      matrix = getBoardCopy(board);
      realMatrix = getBoardCopy(board);
      isLoadingBoard = false;
      status = true;
    });
  }

  Future updateMoves(String letters) async {
    setState(() {
      moves = [];
      isLoadingMoves = true;
    });
    String response = await getBestMove(realMatrix, letters);
    setState(() {
      moves = convertJSONtoMovesList(jsonDecode(response)['moves']);
      isLoadingMoves = false;
    });
  }

  void makeMove(int index){
    setState(() {
      matrix = getBoardCopy(realMatrix);
      matrix = makeIthMove(moves, matrix, index);
    });
  }

  List<List<String>> getBoardCopy(List<List<String>> board){
    List<List<String>> copy = List.generate(15, (i) => List.generate(15, (index) => ' '));
    for(int i=0; i<board.length; i++){
      for(int j=0; j<board[i].length;j++){
        copy[i][j] = board[i][j];
      }
    }
    return copy;
  }

  findMoves(){
    updateMoves(lettersController.text);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor:  Color.fromRGBO(224, 227, 245, 1.0),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 20.0,
            ),
            Expanded(
              flex: 10,
              child: buildBoard()
            ),
            SizedBox(
              height: 10.0,
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Theme(
                      data: ThemeData(
                        primaryColor: Color.fromRGBO(12, 53, 104, 1.0),
                          primaryColorDark: Color.fromRGBO(12, 53, 104, 1.0)
                      ),
                      child: TextField(
                      controller: lettersController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Letters',
                        helperText: 'Type letters from your rack'
                      ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 5.0,
                  ),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(primary: Color.fromRGBO(12, 53, 104, 1.0) ),
                      child: const Text("Calculate!"),
                      onPressed: status ? findMoves : null,
                    )
                  )
                ],
              ),
            ),
            Expanded(
              flex:7,
              child: buildMoves()
            ),

          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Color.fromRGBO(12, 53, 104, 1.0),
          child: Icon(Icons.camera_alt),
          onPressed: _showPicker,
        ),
      ),
  );

  Widget buildBoard(){
    if(isLoadingBoard){
      return  getLoadingIndicator('Detecting letters...');
    }
    else {
      return Column(
        children: Utils.modelBuilder(matrix, (x, value) => buildRow(x)),
      );
    }
  }

  Widget getLoadingIndicator(String text){
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Text(
          text,
          style: Theme.of(context).textTheme.headline6,
        ),
        CircularProgressIndicator(
          backgroundColor: Colors.grey,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget buildMoves(){
    if(isLoadingMoves){
      return  getLoadingIndicator('Calculating moves...');
    }
    else {
        return MovesComponent(moves: moves, callback: makeMove);
    }

  }
  void _showPicker() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              child: new Wrap(
                children: <Widget>[
                  new ListTile(
                      leading: new Icon(Icons.photo_library),
                      title: new Text('Gallery'),
                      onTap: () {
                        getImageFromGallery();
                        Navigator.of(context).pop();
                      }),
                  new ListTile(
                    leading: new Icon(Icons.photo_camera),
                    title: new Text('Camera'),
                    onTap: () {
                      getImageFromCamera();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget buildRow(int x) {
    final values = matrix[x];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: Utils.modelBuilder(
        values,
            (y, value) => buildField(x, y),
      ),
    );
  }

  double getCellDimension(){
    int width = MediaQuery.of(context).size.width.round();
    int diff = width % 15;
    return (width - diff) / 15 - 4;
  }

  Widget buildField(int x, int y) {
    final value = matrix[x][y];
    final color = getFieldColor(x, y);

    return Container(
          child: SizedBox(
            width: getCellDimension(),
            height: getCellDimension(),
            child: Center(
              child: Text(
                value.toUpperCase(),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
          ),
            ),
          ),
          decoration: BoxDecoration(border: Border.all(), color: color),
    );
  }

  bool checkIfLetterFromMove(int x, int y){
    if(realMatrix.isEmpty){
      return false;
    }
    if(realMatrix[x][y] == ' '){
      if(matrix[x][y] != ' '){
        return true;
      }
      else{
        return false;
      }
    }
    else{
      return false;
    }
  }

  Color getFieldColor(int x, int y) {
    Color colour = Colors.green;
    if(checkIfLetterFromMove(x, y)){
      return Colors.yellow;
    }
    if(matrix[x][y] != ' '){
      return Colors.white;
    }
    if((x==y) || (x+y==14)) {
      colour = Color.fromRGBO(255, 153, 255, 1.0);
    }
    if(((x==0 || x==14) && (y==0 || y==7 || y==14)) || (x==7 && (y==0 || y==14))) {
      colour = Colors.red;
    }
    if(((x==5 || x==9) && (y==1 || y==5 || y==9 || y==13)) || ((x==1 || x==13) && (y==5 || y==9))){
      colour = Color.fromRGBO(0, 101, 255, 1.0);
    }
    if(((x==0 || x==7 || x==14) && (y==3 || y==11)) || ((x==3 || x==11) && (y==0 || y==7 || y==14))
        ||((x==2 || x==6 || x==8 || x==12) && (y==6 || y==8)) ||((y==2 || y==6 || y==8 || y==12) && (x==6 || x==8))){
      colour = Color.fromRGBO(102, 204, 255, 1.0);
    }
    if(x==7 && y==7){
      colour = Color.fromRGBO(255, 153, 255, 1.0);
    }
    return colour;
  }
}