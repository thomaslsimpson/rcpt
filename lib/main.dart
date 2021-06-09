//import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

//import 'package:share_plus/share_plus.dart';
//import 'package:flutter_sms/flutter_sms.dart';

void main() async {

  print("Starting DB Manager ...");
  DBManager dbm;

  dbm = DBManager();

  print("DB Manager initial (non wait) complete.");

  dbm.whenReady((){
    print("DB Manager is ready now.");

    // -----------------------------
    // this manually deletes the disk contents
    //Hive.box('MAIN_DB').deleteFromDisk();
    //Hive.box('INFO_DB').deleteFromDisk();

    // -----------------------------
    // makes fake entries for testing
    // index, mills-epoch, from, amount, for
    /*
    var monthsToAdd= 16;
    var m0;
    for(var j=monthsToAdd; j > -1; j--){
      m0= MonthCounter(monthsAhead: (0 - j)).toString();
      DateTime d0= DateTime.now().subtract(Duration(days:(30 * j)));
      for(var i=0; i < 10; i++){
        var dt= d0.millisecondsSinceEpoch;
        var am= (i+10)*7;
        print("Adding test item $i, $am, $m0, $dt");
        dbm.addItem(m0, [0, dt, "From $i", "$am.00", "For month $m0 $dt"]);
        d0= d0.add(Duration(hours: 8));
      }
    }
    */

    dbm.getMonths().forEach( (m) => print("Month: $m") );

    var currentItems = dbm.getItems(MonthCounter().toString());
    currentItems.forEach((item) {
      print("Item $item ${item.length}");
    });

    // we can start the application now.
    // Needs to be a material app to have a Navigator
    runApp(MaterialApp(
      title: "Where does this title go?",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(),
    ));

  });
}


class MainPage extends StatefulWidget {
  @override
  MainPageStateWidget createState() => MainPageStateWidget();
}

class MainPageStateWidget extends State<MainPage> {
  // This widget is the root of your application.
  var currentMonth= MonthCounter().toString();

  var dbm = DBManager();

  @override
  void dispose(){
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var monthList= <Widget>[];
    dbm.getMonths().forEach( (month) {
      monthList.add(ListTile(
        title: Text(month)
      ));
    });

    return Scaffold(
      backgroundColor: Colors.amber,
      appBar: AppBar(
        title: Text('My Receipts'), // app bar title
      ),
      drawer: Drawer(child: ListView.builder(
        itemCount: dbm.getMonths().length + 1,
        itemBuilder: (BuildContext cntx, int index){
          if(index == 0){
            return DrawerHeader(
              decoration: BoxDecoration(color: Colors.lightBlue),
              child: Text("My Receipts v0.1"),
            ); // DrawerHeader
          } else {
            var month= dbm.getMonths()[index -1];
            return ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text("Display Month: $month"),
              onTap: () {
                //Navigator.pop(context);
                setState(() { currentMonth = month; });
                Navigator.of(context, rootNavigator: true).pop();
              },
            );
          } // else
        },
      ),),
      body: ValueListenableBuilder(
        valueListenable: dbm.getListenable(),
        builder: (context, box, widget) {
          var thisMonthRCPTList = dbm.getItems(currentMonth);
          thisMonthRCPTList.forEach((item) {
            print("This month Item $item");
          });

          var rcptList = [];
          rcptList.addAll(thisMonthRCPTList);

          return ListView.builder(
            //reverse: true,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 128),
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
                        dbm.addItem(currentMonth, value);
                      },
                    )),
          );
        },
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
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

    var tc= TextEditingController();
    var tfDate = TextField(
      enabled: false,
      controller: tc,
      decoration: InputDecoration( border: OutlineInputBorder()),
    );
    tc.text= "${selectedDate.toString().split(' ')[0]}";

    var tfFrom = TextField(
      onChanged: (value) { result[2] = value; },
      decoration: InputDecoration( border: OutlineInputBorder(), labelText: 'From'),
    );
    var tfAmount = TextField(
      onChanged: (value) {
        result[3] = value;
      },
      decoration: InputDecoration( border: OutlineInputBorder(), labelText: 'Amount'),
    );
    var tfFor = TextField(
      onChanged: (value) {
        result[4] = value;
      },
      decoration: InputDecoration( border: OutlineInputBorder(), labelText: 'For'),
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
              RCPTFormField(icon: Icons.calendar_today, fieldName: "Date", field: tfDate), 
              RCPTFormField(icon: Icons.person, fieldName: "From", field: tfFrom),
              RCPTFormField(icon: Icons.paid, fieldName: "Amount", field: tfAmount),
              RCPTFormField(icon: Icons.help_outline, fieldName: "For", field: tfFor),
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
                ]
              ),
/*              Divider(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      child: Text("Save and Text"),
                      onPressed: () {
                        sendTextRCPT();
                        widget.onValueChanged(result);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              */
            ],
          ),
        ),
      ),
    );
  }
  
  void sendTextRCPT() async {
    //String result = await sendSMS(message: "text", recipients: ["6013410440"]);
    //print("Text result: $result");
  }

}


//
// This is a form field widget used on the Add Receipt Page
//
class RCPTFormField extends StatelessWidget {
  final fieldName;
  final field;
  var icon= null;

  RCPTFormField({Key key, this.fieldName, this.field, this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var textLabel = Container(
        alignment: Alignment.bottomRight,
        padding: const EdgeInsets.fromLTRB(2, 4, 4, 0),
        child: Text(fieldName,
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 14,
            )));

    var fieldWidget = Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 8, 16),
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
      color: Colors.lightBlue.shade50,
      child: field,
    );

    // Icon

    return Row(
      children: <Widget>[
        Expanded(flex: 1, child: Icon(icon)),
        Expanded(flex: 5, child: fieldWidget),
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
        margin: EdgeInsets.fromLTRB(6, 8, 6, 8),
        elevation: 6,
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
                    child: Text("$id", textAlign: TextAlign.right,
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
                  child: RCPTCardWidgetValue(amount, align: TextAlign.right,),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(flex: 3, child: RCPTCardWidgetField("For")),
                Expanded(flex: 15, child: RCPTCardWidgetValue(whatFor)),
                // Share.share('check out my website https://example.com');
                Expanded(flex: 3, child: IconButton(
                  icon: Icon(Icons.ios_share_outlined),
                  onPressed: () async {
                    print("Pre print");

      final doc = pw.Document();

      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (pw.Context context) {
          return pw.Container(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Reciept Number: $id', textScaleFactor: 1.5),
                pw.Text('Date: $dateText', textScaleFactor: 1.5),
                pw.Text('From: $from', textScaleFactor: 1.5),
                pw.Text('Amount: $amount', textScaleFactor: 1.5),
                pw.Text('For: $whatFor', textScaleFactor: 1.5),
              ]
            ),
          ); // Center
        })); // Page
      await Printing.sharePdf(bytes: await doc.save(), filename: 'rcpt-$id.pdf');

                    /*
                    await Printing.layoutPdf(
                        onLayout: (PdfPageFormat format) async => await Printing.convertHtml(
                              format: format,
                              html: '<html><body><p>Hello!</p></body></html>',
                            ));
                    print("post await");
                    */

                    //Share.share(
                    //  "This is my RCPT."
                    //);
                  },
                )),
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
        padding: EdgeInsets.all(6),
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
        padding: EdgeInsets.fromLTRB(0, 8, 4, 2),
        margin: EdgeInsets.fromLTRB(0, 0, 4, 6),
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

  int sortMonths(a, b){
    var s1= a.toString().split('-');
    var s2= b.toString().split('-');
    a= "${s1[1]}-${s1[0].padLeft(2,'0')}";
    b= "${s2[1]}-${s2[0].padLeft(2,'0')}";
    return b.compareTo(a) as int;
  }

  List getMonths(){
    var result = mainBox.keys.toList();
    print("getMonths $result");
    if(result == null) return [];
    result.sort(sortMonths);
    return result;
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
      year -= 1;
    } else if (months > 12) {
      months -= 12;
      year += 1;
    }
    return "$months-$year";
  }
}

int sortItems(a, b){
  return b[0] - a[0];
} 

