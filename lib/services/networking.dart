import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

String DETECT_SERVER_ADDRESS = 'http://20.114.76.169:7088/detect_letters';
String CHEAT_SERVER_ADDRESS = 'http://20.114.76.169:8000/best-move/GB';


Future <String> detectBoard (String filename) async {
    var request = http.MultipartRequest('POST', Uri.parse(DETECT_SERVER_ADDRESS));
    request.files.add(
        http.MultipartFile('image', File(filename).readAsBytes().asStream(), File(filename).lengthSync(), filename: filename.split("/").last)
    );

    final res = await request.send();
    final respString = res.stream.bytesToString();
    if (res.statusCode == 200) {
      return respString;
    } else {
      return res.reasonPhrase;
    }
  }

  Future <String> getBestMove (List<dynamic> board, String letters) async {
    var res = await http.post(Uri.parse(CHEAT_SERVER_ADDRESS), headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    }, body: jsonEncode(<String, dynamic>{
      'board': board,
      'letters': letters
    }));
    if (res.statusCode == 200) {
      return res.body;
    } else {
      return res.reasonPhrase;
    }
  }


Coordinates getMoveDetailsBasedOnScrabbleCoordinates(String coordinates){
  var coords = coordinates.split('_');
  var coordX = 0;
  var coordY = 0;
  var orientation = 1;
  try {
    coordX = int.parse(coords[0]);
    coordY = coords[1].codeUnitAt(0) - 65;
  } on Exception {
    coordY = coords[0].codeUnitAt(0) - 65;
    coordX = int.parse(coords[1]);
    orientation = 0;
  }
  return Coordinates(coordX: coordX, coordY: coordY, orientation: Orientation.values[orientation]);
}

List<List<String>> putWordOnBoard(Move move, List<List<String>> board){
  String word = move.word;
  if(move.getCoordinates().orientation==Orientation.HORIZONTAL){
    for(int i=0; i<word.length; i++) {
      board[move.getCoordinates().coordX][move.getCoordinates().coordY + i] = word[i];
    }
  }
  else if(move.getCoordinates().orientation==Orientation.VERTICAL){
    for(int i=0; i<word.length; i++) {
      board[move.getCoordinates().coordX + i][move.getCoordinates().coordY] = word[i];
    }
  }
  return board;
}

enum Orientation {
  VERTICAL,
  HORIZONTAL
}

class Coordinates{
  int coordX;
  int coordY;
  Orientation orientation;
  Coordinates({this.coordX, this.coordY, this.orientation});
}

class Move{
  int index;
  int points;
  String coordinates;
  String word;

  String getCoordinatesString(){
    return coordinates.replaceAll('_', '');
  }

  Move({this.coordinates, this.word, this.points});

  Move.fromJson(Map<String, dynamic> json, int index)
      : points = json['points'],
        coordinates = json['coordinates'],
        word = json['word'],
        index = index;

  Coordinates getCoordinates(){
    return getMoveDetailsBasedOnScrabbleCoordinates(coordinates);
  }
}

Future<List<Move>> getPossibleMoves(List<List<String>> board, String letters) async{
  String response = await getBestMove(board, letters);
  return convertJSONtoMovesList(jsonDecode(response)['moves']);
}

List<Move> convertJSONtoMovesList(dynamic moves){
  List<Move> movesList = [];
  for(int i=0; i<moves.length; i++){
    movesList.add(Move.fromJson(moves[i], i));
  }
  return movesList;
}

Move getIthBestMove(List<Move> moves, int i){
  return moves[i];
}

Future<List<List<String>>> getBoardFromImage(String boardPath) async {
  String response = await detectBoard(boardPath);
  var board = jsonDecode(response)['board'];
  List<List<String>> boardList = [];
  board.forEach((element) {boardList.add(element.cast<String>());});
  return boardList;
}

List<List<String>> makeIthMove(List<Move> moves, List<List<String>> board, int i){
  Move move = getIthBestMove(moves, i);
  return putWordOnBoard(move, [...board]);
}

void main() async {
  List<List<String>> board = await getBoardFromImage('images/board_with_words.jpg');
  List<Move> moves = await getPossibleMoves(board, "misofvnjoadc");
  board = makeIthMove(moves, board, 0);

  board.forEach((element) {print(element);});
}