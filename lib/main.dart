//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
/*
  DBManager dbm = DBManager();
  var thisMonth = MonthCounter().toString();
  print("This month: $thisMonth");
  var currentItems = dbm.getItems(thisMonth);
  currentItems.forEach((item) {
    print("Item $item");
  });
*/

  await Hive.initFlutter();
  await Hive.openBox('MAIN_DB');

  // Needs to be a material app to have a Navigator
  runApp(MaterialApp(
    title: "Where does this title go?",
    home: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  var thisMonth;
  var lastMonth;

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
          valueListenable: Hive.box('MAIN_DB').listenable(),
          builder: (context, box, widget) {
            // get the last two months from the box
            var now = new DateTime.now();
            thisMonth = "${now.month}-${now.year}";
            if (now.month == 1) {
              lastMonth = "12-${now.year - 1}";
            } else {
              lastMonth = "${now.month - 1}-${now.year}";
            }

            var thisMonthRCPTList = box.get(thisMonth);
            if (thisMonthRCPTList == null) {
              print("this month $thisMonth was null in listener: new or error");
              thisMonthRCPTList = [];
            }
            var lastMonthRCPTList = box.get(lastMonth);
            if (lastMonthRCPTList == null) {
              print("this month $lastMonth was null in listener: new or error");
              lastMonthRCPTList = [];
            }

            // todo: clear up the double use of RAM here
            var rcptList = [];
            rcptList.addAll(lastMonthRCPTList);
            rcptList.addAll(thisMonthRCPTList);

            return ListView.builder(
              //reverse: true,
              itemCount: rcptList.length,
              itemBuilder: (context, index) {
                var rcptData = rcptList[index];
                return RCPTCardWidget(
                    id: index,
                    date: DateTime.fromMillisecondsSinceEpoch(rcptData[0]),
                    from: rcptData[1],
                    amount: rcptData[2],
                    whatFor: rcptData[3]);
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
                          print("Result: $value");
                          var database = Hive.box('MAIN_DB');
                          var rcptListThisMonth = database.get(thisMonth);
                          if (rcptListThisMonth == null) {
                            rcptListThisMonth = [];
                          }
                          rcptListThisMonth.add(value);
                          database.put(thisMonth, rcptListThisMonth);
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

    var result = [selectedDate.millisecondsSinceEpoch, "", "", ""];

    var tfFrom = TextField(
      onChanged: (value) {
        result[1] = value;
      },
    );
    var tfAmount = TextField(
      onChanged: (value) {
        result[2] = value;
      },
    );
    var tfFor = TextField(
      onChanged: (value) {
        result[3] = value;
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

  DBManager._internal() {
    this._init();
  }
  // this creates the static class singleton
  static final DBManager _globalSingletoneDBManager = DBManager._internal();

  // factory constructor which returns the singleton
  factory DBManager() {
    return _globalSingletoneDBManager;
  }

  // the leading '_' makes the method private
  void _init() async {
    await Hive.initFlutter();
    mainBox = await Hive.openBox(DB_NAME);
    infoBox = await Hive.openBox(DB_INFO);
  }

  List getItems(month) {
    var result = mainBox.get(month);
    return (result == null ? [] : result);
  }

  void addItem(month, item) {
    var items = getItems(month);
    infoBox.put('total_items', getNextID());
    items.add(item);
    mainBox.put(month, items);
  }

  int getNextID() {
    var result = infoBox.get('total_items');
    return (result == null ? 0 : result);
  }

  Listenable getListenable() {
    return mainBox.listenable();
  }
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
