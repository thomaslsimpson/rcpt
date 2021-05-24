//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {



  print("Starting DB Manager ...");
  var thisMonth;
  DBManager dbm;

  dbm = DBManager();

  print("DB Manager initial (non wait) complete.");
  thisMonth = MonthCounter().toString();
  print("This month: $thisMonth");

  dbm.whenReady((){
    print("DB Manager is ready now.");

    // this manually deletes the disk contents

    //Hive.box('MAIN_DB').deleteFromDisk();
    //Hive.box('INFO_DB').deleteFromDisk();


    // add a bunch of test items

/*
    // index, mills-epoch, from, amount, for
    var m0= MonthCounter(monthsAhead: -2).toString();
    for(var i=0; i < 10; i++){
      var dt= (DateTime.now().millisecondsSinceEpoch - (1000 * 60 * 60 * 24 * 60) ) - (i * 6000000);
      var am= (i+10)*7;
      dbm.addItem(m0, [0, dt, "From $i", "$am.00", "For month $m0 $dt"]);
    }
    m0= MonthCounter(monthsAhead: -1).toString();
    for(var i=0; i < 10; i++){
      var dt= (DateTime.now().millisecondsSinceEpoch - (1000 * 60 * 60 * 24 * 32) ) - (i * 6000000);
      var am= (i+10)*7;
      dbm.addItem(m0, [0, dt, "From $i", "$am.00", "For month $m0 $dt"]);
    }
    m0= MonthCounter().toString();
    for(var i=0; i < 10; i++){
      var dt= DateTime.now().millisecondsSinceEpoch - (i * 6000000);
      var am= (i+10)*7;
      dbm.addItem(m0, [0, dt, "From $i", "$am.00", "For month $m0 $dt"]);
    }
*/


    var currentItems = dbm.getItems(thisMonth);
    currentItems.forEach((item) {
      print("Item $item ${item.length}");
    });

    // we can start the application now.
    // Needs to be a material app to have a Navigator
    runApp(MaterialApp(
      title: "Where does this title go?",
      home: MyApp(),
    ));

  });
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  var thisMonth = MonthCounter().toString();
  var monthIndex= -1;
  var lastMonth = MonthCounter(monthsAhead:-1).toString();
  
  var dbm = DBManager();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Receipt Book',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('My Receipt Book'),
        ),
        body: ValueListenableBuilder(
          valueListenable: dbm.getListenable(),
          builder: (context, box, widget) {
            var thisMonthRCPTList = dbm.getItems(thisMonth);
            thisMonthRCPTList.forEach((item) {
              print("This month Item $item");
            });

            var rcptList = [];
            rcptList.addAll(thisMonthRCPTList);

            return ListView.builder(
              //reverse: true,
              itemCount: rcptList.length,
              itemBuilder: (context, index) {
                var rcptData = rcptList[index];
                return RCPTCardWidget(
                    id: rcptData[0],
                    date: DateTime.fromMillisecondsSinceEpoch(rcptData[1]),
                    from: rcptData[2],
                    amount: rcptData[3],
                    whatFor: rcptData[4]);
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddRCPTPage(
                        onValueChanged: (value) {
                          dbm.addItem(thisMonth, value);
                        },
                      )),
            );
          },
          child: Icon(Icons.add),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}

class AddRCPTPage extends StatefulWidget {
  final onValueChanged;

  AddRCPTPage({Key key, this.onValueChanged}) : super(key: key);

  @override
  _AddRCPTPageState createState() => _AddRCPTPageState();
}

class _AddRCPTPageState extends State<AddRCPTPage> {
  @override
  Widget build(BuildContext context) {
    var selectedDate = DateTime.now();

    var result = [-1, selectedDate.millisecondsSinceEpoch, "", "", ""];

    var tfFrom = TextField(
      onChanged: (value) {
        result[2] = value;
      },
    );
    var tfAmount = TextField(
      onChanged: (value) {
        result[3] = value;
      },
    );
    var tfFor = TextField(
      onChanged: (value) {
        result[4] = value;
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Add a New Receipt"),
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              RCPTFormField(
                  fieldName: "Date",
                  field: Text("${selectedDate.toString().split(' ')[0]}")),
              RCPTFormField(fieldName: "From", field: tfFrom),
              RCPTFormField(fieldName: "Amount", field: tfAmount),
              RCPTFormField(fieldName: "For", field: tfFor),
              Divider(),
              Row(
                children: [
                  Expanded(
                      child: TextButton(
                    child: Text("Cancel"),
                    onPressed: () => {Navigator.pop(context)},
                  )),
                  Expanded(
                    child: TextButton(
                      child: Text("Save"),
                      onPressed: () {
                        widget.onValueChanged(result);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//
// This is a form field widget used on the Add Receipt Page
//
class RCPTFormField extends StatelessWidget {
  final fieldName;
  final field;

  RCPTFormField({Key key, this.fieldName, this.field}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var textLabel = Container(
        alignment: Alignment.bottomRight,
        padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
        child: Text(fieldName,
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 14,
            )));

    var fieldWidget = Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 8, 16),
      color: Colors.lightBlue.shade50,
      child: field,
    );

    return Row(
      children: <Widget>[
        Expanded(flex: 1, child: textLabel),
        Expanded(flex: 3, child: fieldWidget),
      ],
    );
  }
}

class RCPTCardWidget extends StatelessWidget {
  final id;
  final DateTime date;
  final from;
  final amount;
  final whatFor;

  RCPTCardWidget(
      {Key key, this.id, this.date, this.from, this.amount, this.whatFor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String dateText = date.toString().split(' ')[0];

    return Card(
        margin: EdgeInsets.fromLTRB(4, 4, 4, 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(2, 4, 4, 12),
          child: Column(children: [
            Row(
              children: [
                Expanded(flex: 3, child: RCPTCardWidgetField("Date")),
                Expanded(flex: 9, child: RCPTCardWidgetValue(dateText)),
                Expanded(flex: 3, child: RCPTCardWidgetField("No.")),
                Expanded(
                    flex: 6,
                    child: Text("$id",
                        style: TextStyle(color: Colors.red, fontSize: 24))),
              ],
            ),
            Row(
              children: [
                Expanded(flex: 3, child: RCPTCardWidgetField("From")),
                Expanded(flex: 18, child: RCPTCardWidgetValue(from)),
              ],
            ),
            Row(
              children: [
                Expanded(flex: 13, child: RCPTCardWidgetField("Amount")),
                Expanded(
                  flex: 8,
                  child: RCPTCardWidgetValue(amount),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(flex: 3, child: RCPTCardWidgetField("For")),
                Expanded(flex: 18, child: RCPTCardWidgetValue(whatFor)),
              ],
            ),
          ]),
        ));
  }
}

class RCPTCardWidgetField extends StatelessWidget {
  final text;
  final TextAlign align;
  RCPTCardWidgetField(this.text, {Key key, this.align = TextAlign.right})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(8),
        child: Text(text,
            textAlign: align,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue,
            )));
  }
}

class RCPTCardWidgetValue extends StatelessWidget {
  final text;
  final TextAlign align;

  RCPTCardWidgetValue(this.text, {Key key, this.align = TextAlign.left})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.fromLTRB(0, 8, 4, 8),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(width: 1.0, color: Colors.blueGrey)),
        ),
        child: Text(text,
            textAlign: align,
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
            )));
  }
}

//
// This is a singleton wrapper over the Hive Box
// var dmb= DBManager(); <- returns a singleton
//
class DBManager {
  static const String DB_NAME = "MAIN_DB";
  static const String DB_INFO = "INFO_DB";
  var mainBox;
  var infoBox;
  Future readyToUse;
  bool ready= false;

  DBManager._internal() {
    print("DM Manager _internal, calling _init");
    
    readyToUse= this._init();
    readyToUse.then( (f) {
      print("DM Manager _internal, _init complete.");
      ready= true;
    });

    print("DB Manager _internal exiting function.");
  }
  // this creates the static class singleton
  static final DBManager _globalSingletoneDBManager = DBManager._internal();

  // factory constructor which returns the singleton
  factory DBManager() {
    print("DB Manager returning from factory constructor");
    return _globalSingletoneDBManager;
  }

  // the leading '_' makes the method private
  Future<void> _init() async {
    print("DB Manager init ...");
    await Hive.initFlutter();
    mainBox = await Hive.openBox(DB_NAME);
    infoBox = await Hive.openBox(DB_INFO);
    print("DB Manager init complete.");
    return;
  }

  void whenReady(callback){
    if(!ready){
      print("DB Manager not ready to use yet ...");
      readyToUse.then( (f) {
        print("DB Manager good to go.");
        callback();
      });
    } else {
      print("DB Manager already ready.");
      callback();
    }
  }

  List getItems(month) {
    var result = mainBox.get(month);
    if(result == null) return [];
    result.sort(sortItems);
    return result;
  }

  void addItem(month, item) {
    print("DB Manager addItem $month $item");
    var items = getItems(month);
    item[0]= getNextID();
    infoBox.put('total_items', item[0]+1);
    items.add(item);
    mainBox.put(month, items);
    print("DB Manager added Item $month $item");
  }



  int getNextID() {
    var result = infoBox.get('total_items');
    return (result == null ? 0 : result);
  }

  int getDBVersion(){
    var result = infoBox.get('db_version');
    return (result == null ? 0 : result);
  }
  int setDBVersion(int dbv){
    infoBox.put('db_version', dbv);
  }

  Listenable getListenable() {
    return Hive.box(DB_NAME).listenable();
  }

/*
  void checkVersion(){
    // upgrade db version is necessary
    //var CURRENT_DB_VERSION= 1;
    var dbVersion= getDBVersion();
    if(dbVersion == 0){
      print("DB Needs to be cleared");

    }
  }
*/


}

class MonthCounter {
  var monthsAhead;

  MonthCounter({this.monthsAhead = 0});

  MonthCounter operator +(int ma) {
    return MonthCounter(monthsAhead: this.monthsAhead + ma);
  }

  MonthCounter operator -(int ma) {
    return MonthCounter(monthsAhead: this.monthsAhead - ma);
  }

  String toString() {
    var now = new DateTime.now();
    var months = now.month;
    var year = now.year;
    months += monthsAhead;
    if (months < 1) {
      months += 12;
      year += 1;
    } else if (months > 12) {
      months -= 12;
      year -= 1;
    }
    return "$months-$year";
  }
}

int sortItems(a, b){
  return b[0] - a[0];
} 