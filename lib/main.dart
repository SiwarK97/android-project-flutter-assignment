import 'package:english_words/english_words.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home:App()));
}


class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
            body: Center(
                child: Text(snapshot.error.toString(),
                    textDirection: TextDirection.ltr)));
      }
      if (snapshot.connectionState == ConnectionState.done) {
        return MyApp();
      }
      return Center(child: const CircularProgressIndicator());
        },
    );
  }
}

class LogInPage extends StatefulWidget {
  final _saved;
  bool isLoggedIn;
  LogInPage(this.isLoggedIn, this._saved);

  @override
  _LogInPageState createState() => _LogInPageState();
}
class _LogInPageState extends State<LogInPage> {

  _LogInPageState();
  var checkIfPassIdentecal = true;
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController _confirm = TextEditingController();
  Future<void> _handleLogin(context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text, password: passController.text);
      onLogIn();
    } catch (e) {
      // print(e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('There was an error logging into the app'),
        ),
      );
    }
  }

  void onLogIn() async {
    var set = Set<WordPair>();
    await FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser?.uid.toString()).collection("favorites").get().then((res) {
      res.docs.forEach((element) {
        var first = element.data().entries.first.value.toString();
        var second = element.data().entries.last.value.toString();
        set.add(WordPair(first, second));
      });
      widget._saved.addAll(set);
      widget.isLoggedIn = true;
      Navigator.pop(context, widget.isLoggedIn);

    });

    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Center(child: Text("Login")),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SizedBox(height: 20),
            Text(
                'Welcome to Startup Names Generator, please log in below',
                style: TextStyle(fontSize: 16)),
            Padding(
              padding: EdgeInsets.only(left: 15.0, right: 15.0, top: 60.0),
              child: Center(
                child: TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                  ),
                ),
              ),),
            Padding(
              padding: EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              child: TextField(
                controller: passController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                ),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              height: 35,
              width: 350,
              decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(30)),

              child: ElevatedButton(
                onPressed: () => _handleLogin(context),
                child: const Text('Log in', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(350, 35),
                  shape: const StadiumBorder(),
                  primary: Colors.deepPurple,
                  onPrimary: Colors.white,
                ),
              ),

            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ElevatedButton(
                onPressed: () async {
                  showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return Container(
                          height: 200,
                          child: Container(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const Text(
                                  "Please confirm your password below:",
                                  style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 18),
                                ),
                                const SizedBox(height: 25),
                                TextField(
                                  controller: _confirm,
                                  obscureText: true,
                                  decoration:  InputDecoration(
                                    labelText: 'Password',
                                    errorText: checkIfPassIdentecal
                                        ? null
                                        : 'Passwords must match',
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (passController.text == _confirm.text) {
                                      FirebaseAuth.instance.createUserWithEmailAndPassword(email: emailController.text, password: passController.text);
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    } else {
                                      checkIfPassIdentecal = false;
                                       const SnackBar(
                                        content:
                                        Text("Passwords must match", style: TextStyle(fontWeight: FontWeight.bold)),
                                        backgroundColor: Colors.red,
                                      );
                                      setState(() {
                                        FocusScope.of(context).requestFocus(FocusNode());
                                      });
                                    }
                                  },
                                  child: const Text('Confirm',
                                      style: TextStyle(fontSize: 16)),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(100, 30),
                                    primary: Colors.lightBlue,
                                    onPrimary: Colors.white,
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      });
                },
                child: const Text('New user? Click to sign up',style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  primary: Colors.lightBlue,
                  onPrimary: Colors.white,
                  minimumSize: const Size(350, 35),
                  shape: const StadiumBorder(),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}


class _RandomWordsState extends State<RandomWords> {
  bool _isLogged = false;
  Future<bool> showMyDialog(WordPair pair) async {

    return await showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Suggestion'),
          content: SingleChildScrollView(
            child: Column(
              children:  <Widget>[
                Text('Are you sure you want to delete ${pair} from your saved suggestions?'),
              ],
            ),
          ),
          actions:[
            TextButton(
              child: Text('Yes'),
              style: ButtonStyle(foregroundColor : MaterialStateProperty.all(Colors.white),
                  backgroundColor: MaterialStateProperty.all(Colors.deepPurple)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            TextButton(
              child: Text('No'),
              style: ButtonStyle(foregroundColor : MaterialStateProperty.all(Colors.white),
        backgroundColor: MaterialStateProperty.all(Colors.deepPurple)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        );
      },
    );
  }
  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final tiles = _saved.map(
                (pair) {
              return Dismissible(
                key: ValueKey<WordPair>(pair),
                child: ListTile(
                    title: Text(
                      pair.asPascalCase,
                      style: _biggerFont,
                    )),
                onDismissed: (direction) async {
                  _saved.remove(pair);
                  Navigator.of(context).build(context);

                },confirmDismiss: (dir) async {

                  return await showMyDialog(pair);
              },

                background: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  color: Colors.deepPurple,
                  child: Row(children: [
                    Icon(Icons.delete, color: Colors.white),
                    const Text('Delete Suggestion', style: TextStyle(color: Colors.white ,fontSize: 16))
                  ]),
                ),
              );
            },
          ).toList();

          final divided = tiles.isNotEmpty
              ? ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList()
              : <Widget>[];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Suggestions'),
            ),
            body: ListView(children: divided,
            ),
          );
        },
      ), // ...to here.
    ).then((value) {
      setState(() {
      });
    });
  }

  void _logout() async {

    await FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser?.uid.toString()).collection("favorites")
        .get().then((snapshot) {
      for (DocumentSnapshot ds in snapshot.docs){
        ds.reference.delete();
      }
    });

    _saved.forEach ((e)
    async { await FirebaseFirestore.instance.collection("users").doc(FirebaseAuth.instance.currentUser?.uid.toString()).collection("favorites").
    doc(e.toString()).set({"first" : e.first, "second" : e.second});});
    await FirebaseAuth.instance.signOut();
    setState(() {
      _saved.clear();
      _isLogged = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully logged out'),
        ),
      );
    });

  }
  var email,user ,userID;
  var drag = true;
  SnappingSheetController sheetController = SnappingSheetController();
  final _suggestions = <WordPair>[];
  final _saved = <WordPair>{};
  final _biggerFont = const TextStyle(fontSize: 18);
  @override
  Widget build(BuildContext context) {
    user=FirebaseAuth.instance.currentUser;
    userID=FirebaseAuth.instance.currentUser?.uid;
    email = FirebaseAuth.instance.currentUser?.email.toString();
    String _imageURL;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Startup Name Generator'),
        // Add from here ...
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: _pushSaved,
            tooltip: 'Saved Suggestions',
          ),
          IconButton(icon: Icon(_isLogged? Icons.exit_to_app : Icons.login), onPressed: _isLogged?_logout : _pushLogin),
        ],
      ),
    //  body: _buildSuggestions(),
      body: GestureDetector(
          child: SnappingSheet(
            controller: sheetController,
            snappingPositions: const [
              SnappingPosition.pixels(
                  positionPixels: 200,
                  snappingCurve: Curves.bounceOut,
                  snappingDuration: Duration(milliseconds: 200)),
              SnappingPosition.factor(
                  positionFactor: 1,
                  snappingCurve: Curves.easeInBack,
                  snappingDuration: Duration(milliseconds: 1)),
            ],
            lockOverflowDrag: true,
            child: _buildSuggestions(),
            sheetBelow: user!=null
                ? SnappingSheetContent(
              draggable: drag,
              child: Container(
                color: Colors.white,
                height: 80,
                child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      Column(children: [
                        Row(children: <Widget>[
                          Expanded(
                            child: Container(
                              color: Colors.grey,
                              height: 40,
                              child: Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Flexible(
                                      flex: 3,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                            "  Welcome back, " + email
                                            ,textAlign: TextAlign.left,
                                            style: const TextStyle(
                                                fontSize: 16.0)),
                                      )),
                                   IconButton(icon: Icon(drag? Icons.keyboard_arrow_up_outlined : Icons.keyboard_arrow_down_outlined), onPressed: null,
                                   ),
                                ],
                              ),
                            ),
                          ),
                        ]),
                        Row(children: <Widget>[
                          FutureBuilder(
                              future: FirebaseStorage.instance.ref()
                                  .child('$userID/profilePic').getDownloadURL(),
                              builder: (context, AsyncSnapshot<String> snapshot) {
                                _imageURL = snapshot.data ??
                                    'https://cdn-icons-png.flaticon.com/512/847/847969.png';

                                return CircleAvatar(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.purple,
                                    backgroundImage: NetworkImage(_imageURL),radius: 40);

                              }),
                          Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(email,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20))),
                        ]),
                        Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              MaterialButton(
                                onPressed: () async {
                                  FilePickerResult? result =
                                  await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: [
                                      'png', 'jpg', 'gif','jpeg','bmp', 'webp'
                                    ],
                                  );
                                  File file;
                                  if (result != null) {
                                    file = File(result.files.single.path
                                        .toString());
                                    await FirebaseStorage.instance.ref('$userID/profilePic').putFile(file);
                                  } else {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(content: Text('No image selected')));
                                    return;
                                  }
                                },
                                textColor: Colors.white,
                                padding: const EdgeInsets.only(
                                    left: 1.0,
                                    top: 1.0,
                                    bottom: 100.0,
                                    right: 100.0),
                                  child: Container(
                                       color: Colors.lightBlue,
                                         padding: const EdgeInsets.only(
                                             left: 10.0,
                                             top: 8.0,
                                             bottom: 8.0,
                                             right: 10.0),
                                         child: const Text('Change Avatar',
                                             style: TextStyle(color: Colors.white, fontSize: 16)),
                                       ),

                              ),
                            ]),
                      ]),
                    ]),
              ),
              //heightBehavior: SnappingSheetHeight.fit(),
            )
                : null,
          ),
          onTap: () => {
            setState(() {
              if (drag == false) {
                drag = true;
                sheetController
                    .snapToPosition(const SnappingPosition.factor(
                  positionFactor: 0.05,
                ));
              } else {
                drag = false;
                sheetController.snapToPosition(
                    const SnappingPosition.factor(
                        positionFactor: 0.25,
                        snappingDuration: Duration(milliseconds: 200)));
              }
            })
          }),
    );
  }
  void _pushLogin()  async {
    _isLogged = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return LogInPage(_isLogged, _saved);
        },
      ),
    );
    setState(() {
    }
    );
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(     // NEW from here...
        alreadySaved ? Icons.star : Icons.star_border,
        color: alreadySaved ? Colors.deepPurple : null,
        semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
      ),
      onTap: () {      // NEW lines from here...
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
          } else {
            _saved.add(pair);
          }
        });
      },               // ... to here.
    );
  }
  Widget _buildSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, i) {
        if (i.isOdd) {
          return const Divider();
        }
        final index = i ~/ 2;
        if (index >= _suggestions.length) {
          _suggestions.addAll(generateWordPairs().take(10));
        }
        return _buildRow(_suggestions[index]);
      },

    );
  }
}






















class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);

  @override
  State<RandomWords> createState() => _RandomWordsState();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(          // Remove the const from here
      title: 'Startup Name Generator',

      theme: ThemeData(          // Add the 5 lines from here...
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),                         // ... to here.
      home: const RandomWords(), // And add the const back here.
    );
  }
}

