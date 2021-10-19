import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scrabble_cheater/services/networking.dart';

class MovesComponent extends StatelessWidget {
  MovesComponent({@required this.moves, @required this.callback});

  final List <Move> moves;
  final void Function(int) callback;
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Color.fromRGBO(224, 227, 245, 1.0),
        padding: EdgeInsets.all(20.0),
        child: Row(
            children: [
              Expanded(
                  child: MovesDataComponent(moves: moves, callback: callback),
              )
            ]
        )
    );
  }
}

class MovesDataComponent extends StatelessWidget{
  MovesDataComponent({@required this.moves, @required this.callback});
  final List <Move> moves;
  final void Function(int) callback;

  @override
  Widget build(BuildContext context){
    return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              showCheckboxColumn: false,
                showBottomBorder: true,
              columns: [
                DataColumn(label: Text('Word')),
                DataColumn(label: Text('Points')),
                DataColumn(label: Text('Coordinates')),
              ],
              rows: moves.map((move) =>
                  DataRow(
                      onSelectChanged: (bool selected) {
                        if(selected){
                          callback(move.index);
                        }
                      },
                      cells: [
                        DataCell(Text(move.word)),
                        DataCell(Text(move.points.toString())),
                        DataCell(Text(move.getCoordinatesString()))
                      ]
                  )).toList(),
            )
    );
  }
}
