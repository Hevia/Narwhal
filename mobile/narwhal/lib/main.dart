import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/rendering.dart';
import 'package:dio/dio.dart';

class Destination {
  const Destination(this.index, this.title, this.icon, this.color);
  final int index;
  final String title;
  final IconData icon;
  final MaterialColor color;
}

const List<Destination> allDestinations = <Destination>[
  Destination(0, 'Search', Icons.search, Colors.teal),
  Destination(1, 'Home', Icons.home, Colors.cyan),
  Destination(2, 'Camera', Icons.photo_camera, Colors.orange),
];

class DetailPage extends StatelessWidget {

  final User user;

  DetailPage(this.user);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(user.name),
        )
    );
  }
}

class User {
  final String name;
  final String email;

  User(this.name, this.email);

}

class DestinationView extends StatefulWidget {
  final CameraDescription camera;

  const DestinationView({ Key key, this.destination, Key cameraKey, this.camera}) : super(key: key);

  final Destination destination;

  @override
  _DestinationViewState createState() => _DestinationViewState();
}

class _DestinationViewState extends State<DestinationView> {
  TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: 'sample text: ${widget.destination.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.destination.title == 'Camera') {
      return TakePictureScreen(camera: widget.camera);
    }
    else if (widget.destination.title == 'Search') {
      return new SearchPage();
    }
    else {
      return Scaffold(
        backgroundColor: widget.destination.color[100],
        body: Container(
          padding: const EdgeInsets.all(32.0),
          alignment: Alignment.center,
          child: TextField(controller: _textController),
          // child: Text('Dope'),
        ),
      );
    }
    
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {  
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    if (widget.camera == null)
      print('widget.camera is null');
    else
      print('widget.camera is NOT null');

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:  () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Construct the path where the image should be saved using the
            // pattern package.
            final path = join(
              // Store the picture in the temp directory.
              // Find the temp directory using the `path_provider` plugin.
              (await getTemporaryDirectory()).path,
              '${DateTime.now()}.png',
            );

            // Attempt to take a picture and log where it's been saved.
            await _controller.takePicture(path);

            // If the picture was taken, display it on a new screen.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(imagePath: path),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
        child: Icon(Icons.photo_camera),
        backgroundColor: Colors.blue,  
        elevation: 0.0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,    
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  Future<List<User>> _getUsers() async {

    var data = await http.get("https://jsonplaceholder.typicode.com/users");

    var jsonData = json.decode(data.body);

    List<User> users = [];

    for(var u in jsonData){

      User user = User(u["name"], u["email"]);

      users.add(user);

    }

    print(users.length);

    return users;
  }

  @override
  Widget build(BuildContext context) {
    print('Image file path is: $imagePath');
    
    File imageFile = File(imagePath);
    List<int> imageBytes = imageFile.readAsBytesSync();
    String base64Image = base64.encode(imageBytes);
    print('Base64 string is: $base64Image');

    final Set<String> _saved = Set<String>();  

    // Widget titleSection = new Text("This is a title section");
    Widget titleSection = new Container(
      child: FutureBuilder(
        future: _getUsers(),
        builder: (BuildContext context, AsyncSnapshot snapshot){
          print(snapshot.data);
          if(snapshot.data == null){
            return Container(
              child: Center(
                child: Text("Loading...")
              )
            );
          } else {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(snapshot.data[index].name),
                  subtitle: Text(snapshot.data[index].email),
                  trailing: Icon(
                    _saved.contains(snapshot.data[index].name) ? Icons.favorite : Icons.favorite_border,
                    color: _saved.contains(snapshot.data[index].name) ? Colors.red : null,
                  ),
                  onTap: () {
                    // TODO: ADD CHECKING FOR FAVORITE FACTS
                    if (_saved.contains(snapshot.data[index].name)) {
                      // _saved.remove(snapshot.data[index].name);
                    }
                    else {
                      // print('I got here');
                      // print('adding $snapshot.data[index]');
                      // _saved.add(snapshot.data[index].name);
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
    
    return new MaterialApp(
      title: "",
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Narwhal'),
        ),
        body: new Scrollbar(
          child: ListView(
            children: <Widget>[
              new Image.memory(base64.decode(base64Image), fit: BoxFit.cover),
              titleSection
            ],
          )
        )
      )
    );
  }
}

class HomePage extends StatefulWidget {
  final CameraDescription camera;

  const HomePage({
    Key key,
    this.camera,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin<HomePage> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        centerTitle: true,
        title: new Text('Narwhal'),
      ),
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _currentIndex,
          children: allDestinations.map<Widget>((Destination destination) {
            return DestinationView(destination: destination, camera: widget.camera);
          }).toList(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: allDestinations.map((Destination destination) {
          return BottomNavigationBarItem(
            icon: Icon(destination.icon),
            backgroundColor: destination.color,
            title: Text(destination.title)
          );
        }).toList(),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  // ExamplePage({ Key key }) : super(key: key);
  @override
  _SearchPageState createState() => new _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
 // final formKey = new GlobalKey<FormState>();
 // final key = new GlobalKey<ScaffoldState>();
  final TextEditingController _filter = new TextEditingController();
  final dio = new Dio();
  String _searchText = "";
  List names = new List();
  List filteredNames = new List();
  Icon _searchIcon = new Icon(Icons.search);
  Widget _appBarTitle = new Text('Search');

  _SearchPageState() {
    _filter.addListener(() {
      if (_filter.text.isEmpty) {
        setState(() {
          _searchText = "";
          filteredNames = names;
        });
      } else {
        setState(() {
          _searchText = _filter.text;
        });
      }
    });
  }

  @override
  void initState() {
    this._getNames();
    super.initState();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildBar(context),
      body: Container(
        child: _buildList(),
      ),
      resizeToAvoidBottomPadding: false,
    );
  }

  Widget _buildBar(BuildContext context) {
    return new AppBar(
      centerTitle: true,
      title: _appBarTitle,
      leading: new IconButton(
        icon: _searchIcon,
        onPressed: _searchPressed,
      ),
    );
  }

  Widget _buildList() {
    if (_searchText.isNotEmpty) {
      List tempList = new List();
      for (int i = 0; i < filteredNames.length; i++) {
        if (filteredNames[i]['name'].toLowerCase().contains(_searchText.toLowerCase())) {
          tempList.add(filteredNames[i]);
        }
      }
      filteredNames = tempList;
    }
    return ListView.builder(
      itemCount: names == null ? 0 : filteredNames.length,
      itemBuilder: (BuildContext context, int index) {
        return new ListTile(
          title: Text(filteredNames[index]['name']),
          onTap: () => print(filteredNames[index]['name']),
        );
      },
    );
  }

  void _searchPressed() {
    setState(() {
      if (this._searchIcon.icon == Icons.search) {
        this._searchIcon = new Icon(Icons.close);
        this._appBarTitle = new TextField(
          controller: _filter,
          decoration: new InputDecoration(
            prefixIcon: new Icon(Icons.search),
            hintText: 'Search...'
          ),
        );
      } else {
        this._searchIcon = new Icon(Icons.search);
        this._appBarTitle = new Text('Search');
        filteredNames = names;
        _filter.clear();
      }
    });
  }

  void _getNames() async {
    final response = await dio.get('https://swapi.co/api/people');
    List tempList = new List();
    for (int i = 0; i < response.data['results'].length; i++) {
      tempList.add(response.data['results'][i]);
    }
    setState(() {
      names = tempList;
      names.shuffle();
      filteredNames = names;
    });
  }


}

Future<void> main() async {
  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      /*
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
      */
      home: HomePage(camera: firstCamera),
      // home: new ExamplePage(),
    ),
  );
}