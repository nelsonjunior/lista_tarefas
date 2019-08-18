import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

void main() {
  runApp(MaterialApp(
    home: Home(),
    theme: ThemeData(
      primaryColor: Colors.deepOrange,
      cursorColor: Colors.deepOrange,
      accentColor: Colors.deepOrange,
      hintColor: Colors.deepOrange,
      highlightColor: Colors.deepOrange,
    ),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List _toDoList = [];

  Map<String, dynamic> _lastRemoveToDo;
  int _lastPositionRemoveToDo;

  final _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      if (_formKey.currentState.validate()) {
        Map<String, dynamic> novaTarefa = Map();
        novaTarefa["title"] = _inputController.text;
        novaTarefa["ok"] = false;

        _inputController.text = "";

        _toDoList.add(novaTarefa);

        _formKey = GlobalKey<FormState>();

        _saveData();
      }
    });
  }

  void _changeToDo(int index, bool value) {
    setState(() {
      _toDoList[index]["ok"] = value;
      _saveData();
    });
  }

  void _removeToDo(BuildContext context, int index) {
    setState(() {
      _lastRemoveToDo = Map.from(_toDoList[index]);
      _lastPositionRemoveToDo = index;
      _toDoList.removeAt(index);
      _saveData();

      final snack = SnackBar(
        content: Text("Tarefa \"${_lastRemoveToDo["title"]}\" removida!"),
        action: SnackBarAction(label: "Desfazer", onPressed: _undoRemoveToDo),
        duration: Duration(seconds: 2),
      );

      Scaffold.of(context).removeCurrentSnackBar();
      Scaffold.of(context).showSnackBar(snack);
    });
  }

  void _undoRemoveToDo() {
    setState(() {
      _toDoList.insert(_lastPositionRemoveToDo, _lastRemoveToDo);
      _saveData();
      _lastRemoveToDo = null;
      _lastPositionRemoveToDo = null;
    });
  }

  Future<Null> _refreshToDo() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(20.0, 2.0, 8.0, 2.0),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _inputController,
                          validator: (value) {
                            if (value.isEmpty) {
                              return "Insira o nome da tarefa!";
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                              labelText: "Nova Tarefa",
                              labelStyle: TextStyle(color: Colors.deepOrange)),
                        ))),
                RaisedButton(
                  color: Colors.deepOrange,
                  textColor: Colors.white,
                  child: Text("Add"),
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                child: ListView.builder(
                    padding: EdgeInsets.only(top: 10.0),
                    itemCount: _toDoList.length,
                    itemBuilder: buildItem),
                onRefresh: _refreshToDo),
          )
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Container(
          padding: EdgeInsets.only(left: 10.0),
          color: Colors.red,
          child: Row(
            children: <Widget>[
              Icon(
                Icons.delete,
                color: Colors.white,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Text(
                    "Remover Tarefa!",
                    textAlign: TextAlign.start,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        onChanged: (bool newValue) {
          _changeToDo(index, newValue);
        },
        secondary: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
      ),
      onDismissed: (direction) {
        _removeToDo(context, index);
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();

    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return await file.readAsString();
    } on Exception catch (e) {
      return null;
    }
  }
}
