import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image/image.dart' as Im;
import 'package:flutter/services.dart';
import 'package:device_info/device_info.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';

final FirebaseApp app = FirebaseApp(
);

void main() async{

  runApp(new MaterialApp(
    home: PreviousActivity(),
  ));
}


DropdownButton ciudadesDrop, localidadesDrop;
List<Ciudad> ciudades=new List();
List<Poblacion> poblaciones= new List();
List<String> ciudadesTemp= new List();
List<String> poblacionesTemp = new List();
List<String> ciudadesCode= new List();
List<String> poblacionesCode = new List();
List<CameraDescription> cameras;

class PreviousActivity extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Primer Activity"),
        backgroundColor: new Color(0x673AB7),
      ),
      body: Center(
        child: RaisedButton(
          child: Text('Launch screen'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyApp ()),
            );
          },
        ),
      ),
    );
  }

}



class MyApp extends StatefulWidget{
  _MyAppState createState() => _MyAppState();
}


class _MyAppState extends State<MyApp>{
  var _scaffoldKey= new GlobalKey<ScaffoldState>();
  var isFirstTime=true;
  String _value="*Ciudad", _valueLocalidad="Localidad", URL1, URL2;
  Color nombreLine=Colors.transparent, _ciudadesDrop=Colors.transparent;
  TextField nombre, descripcion, cantidad, fechaCreacion;
  File image;
  File image2;
  Image camera1= new Image.asset('assets/pics/camera.png'), camera2= new Image.asset('assets/pics/camera.png');
  final myControllerName = TextEditingController(),
      myControllerDescripcion = TextEditingController(),
      myControllerCantidad = TextEditingController(),
      myControllerFecha = TextEditingController();
  
  ///Listener for the upload button that check all the required fields.
  void onPressedButton() {
    var valido = true;
    if (nombre.controller.value.text.length == 0) {
      valido = false;
      nombreLine = Colors.red;
      setState(() {});
    } else {
      nombreLine = Colors.transparent;
      setState(() {});
    }
    if(image==null && image2==null){
      valido=false;
      camera1=new Image.asset('assets/pics/camera_red.png'); //Red camera icon
      setState(() {});
    }
    Text ciudad=ciudadesDrop.hint;
    if(ciudad.data.compareTo("Ciudad")==0){
      valido=false;
    }


    if (!valido) {
      Fluttertoast.showToast(
        msg: "Debe de introducir los datos obligatorios",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIos: 1,
        bgcolor: "#e74c3c",
        textcolor: '#ffffff'
      );
    }else{
      uploadFiles();
    }
  }

  ///Method that upload the images to Firebase Storage, then take the links of
  ///the image and create a new Product with all the info provided by the user
  Future<Null> uploadFiles() async{

    AlertDialog dialog;
    showDialog(context: context,
        builder: (BuildContext context) {
          return dialog=new AlertDialog(
              title: new Text("Subiendo información..."),
              content: new LinearProgressIndicator()

          );
        });

    DeviceInfoPlugin deviceInfo= new DeviceInfoPlugin();
    AndroidDeviceInfo androidDeviceInfo= await deviceInfo.androidInfo;
    if(image!=null){
      ImageProperties properties = await FlutterNativeImage.getImageProperties(image.path);
      File compressedFile = await FlutterNativeImage.compressImage(image.path, quality: 15);


      final String fileName= androidDeviceInfo.manufacturer+androidDeviceInfo.model+DateTime.now().toIso8601String()+".jpg";
      final StorageReference reference = FirebaseStorage.instance.ref().child("productos_imagen").child(fileName);
      final StorageUploadTask task = reference.putFile(compressedFile);
      final Uri downloadUrl= (await task.future).downloadUrl;
      URL1=downloadUrl.toString();
      reference.putFile(compressedFile);
      print(URL1);
    }
    if(image2!=null){
      File compressedFile2 = await FlutterNativeImage.compressImage(image2.path, quality: 15);
      final String fileName= androidDeviceInfo.manufacturer+androidDeviceInfo.model+DateTime.now().toIso8601String()+".jpg";
      final StorageReference reference = FirebaseStorage.instance.ref().child("productos_imagen").child(fileName);
      final StorageUploadTask task = reference.putFile(compressedFile2);
      final Uri downloadUrl= (await task.future).downloadUrl;
      URL2=downloadUrl.toString();
      reference.putFile(compressedFile2);
      print(URL1);
    }
    List<String>urls= new List();
    if(URL1!=null) urls.add(URL1);
    if(URL2!=null) urls.add(URL2);
    //Subimos producto a Database =)

    print(descripcion.controller.value.text);


    var myProduct;
    Text ciudad= ciudadesDrop.hint;
    Text localidad=localidadesDrop.hint;
    String localidadCode;
    localidad.data.compareTo("Localidad")==0 ? localidadCode=null : localidadCode= getLocalidadCode(localidad.data);
    int cantidadNumber;
    try{
      cantidadNumber=int.parse(cantidad.controller.value.text);
    }catch(Exception){
      cantidadNumber=0;
    }

    if(urls.length==1){
          myProduct = <String, dynamic>{
        'name': nombre.controller.value.text,
        'des': descripcion.controller.value.text,
            'cant': cantidadNumber,
        'date': fechaCreacion.controller.value.text,
        'code_city': getCiudadCode(ciudad.data),
        'code_province': localidadCode,
        'photoUrl1': urls.elementAt(0),
        'photoUrl2': null
      };
    }else {
          myProduct = <String, dynamic>{
        'name': nombre.controller.value.text,
        'des': descripcion.controller.value.text,
            'cant': cantidadNumber,
        'date': fechaCreacion.controller.value.text,
            'code_city': getCiudadCode(ciudad.data),
            'code_province': localidadCode,
        'photoUrl1': urls.elementAt(0),
        'photoUrl2': urls.elementAt(1)
      };
    }
    DatabaseReference reference = FirebaseDatabase.instance.reference()
        .child("productos")
        .push();
    reference.set(myProduct);

    Navigator.pop(context); //Make dialog to close
  }


  @override
  void dispose() {
    // Clean up the controller when the Widget is disposed
    myControllerName.dispose();
    myControllerCantidad.dispose();
    myControllerDescripcion.dispose();
    myControllerFecha.dispose();
    super.dispose();
  }

  ///Method that allows to open the galley and select pictures
  galeria() async {
    File img = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      if (image != null && image2==null) {
        image2 = img;
        setState(() {});
      } else {
        image = img;
        setState(() {});
      }
    }
  }


  ///Method that allows to open the camera and take pictures
  camara() async {
    File img = await ImagePicker.pickImage(source: ImageSource.camera,);
    if (img != null) {
      if (image != null && image2==null) {
        image2 = img;
        setState(() {});
      } else {
        image = img;
        setState(() {});
      }
    }
  }
  ///Method that shows a Dialog in order of deleting a picture.
  void _showDeletePhotoDialog(int number){
    if(number==1 && image==null) return null;
    if(number==2 && image2==null) return null;
    showDialog(context: context,
    builder: (BuildContext context){
      return AlertDialog(
        title: new Text("Eliminar"),
        content: new Text("Desea eliminar la foto?"),
        actions: <Widget>[
          new FlatButton(
              onPressed: (){
                Navigator.pop(context);
              },
              child: new Text("Cancelar")),
          new FlatButton(
              onPressed: (){
                switch(number){
                  case 1:
                    image=null;
                    break;
                  case 2:
                    image2=null;
                    break;
                }
                setState(() {});
                Navigator.pop(context);
              },
              child: new Text("Eliminar"))
        ],
      );
    });
  }

  ///Method that shows a Dialog for picking camera or gallery
  void _showDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Imágenes"),
          content: new Text(
              "Añada imágenes sobre su producto, ya sean desde la galería, o con su cámara."),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Cámara"),
              onPressed: () {
                Navigator.of(context).pop();
                camara();
              },
            ),
            new FlatButton(
              child: new Text("Galería"),
              onPressed: () {
                Navigator.of(context).pop();
                galeria();
              },
            ),
          ],
        );
      },
    );
  }

  ///Method that create a widget from a file with custom
  ///height and width;
  Widget displaySelectedFile(File file) {
    return new SizedBox(
      height: 150.0,
      width: 150.0,
      child: file == null
          ? new Text('Sorry, nothing selected!')
          : new Image.file(file),
    );
  }

  void changeProvinces(String currentCity){
    String codeCurrent=getCityCode(currentCity);
    poblacionesTemp.clear();
    if(currentCity.compareTo("*Ciudad")==0)poblacionesTemp.add("");
    else{
      for(int i=0; i<poblaciones.length;i++){
        if(poblaciones.elementAt(i).code_city.compareTo(codeCurrent)==0) poblacionesTemp.add(poblaciones.elementAt(i).name);
      }
      if(poblacionesTemp.length==0) poblacionesTemp.add("");
    }



  }

  String getLocalidadCode(String localidad){
    for(int i=0; i<poblaciones.length; i++){
      if(poblaciones.elementAt(i).name.compareTo(localidad)==0) return poblaciones.elementAt(i).code;
    }
  }

  String getCiudadCode(String ciudad){
    for(int i=0; i<ciudades.length; i++){
      if(ciudades.elementAt(i).name.compareTo(ciudad)==0) return ciudades.elementAt(i).code;
    }
  }

  String getCityCode(String currentCity){
    for(int i=0; i<ciudades.length;i++){
      if(ciudades.elementAt(i).name.compareTo(currentCity)==0) return ciudades.elementAt(i).code;
    }
    return null;
  }



  ///Build method that creates the main layout.
  @override
  Widget build(BuildContext context){
    DocumentSnapshot ds;
    //getData();
    return new MaterialApp(
      title: "Productos",
      home: new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(title: new Text("Tu producto"),leading: ButtonBar(children: <Widget>[
          GestureDetector(
            child: new Icon(Icons.arrow_back),
            onTap:() {Navigator.pop(context);},
          ),

        ],
        ),

        ),
        body:
        new Center(
          child: new Column(
            children: <Widget>[
              new Padding(padding: new EdgeInsets.all(15.0)),
              new Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  GestureDetector(
                    onTap: (){_showDialog();},
                    onLongPress: (){_showDeletePhotoDialog(1);},
                    child: image==null ? camera1 : displaySelectedFile(image),
                  ),
                  new Padding(padding: new EdgeInsets.all(12.0)),
                  GestureDetector(
                    onTap: (){_showDialog();},
                    onLongPress: (){_showDeletePhotoDialog(2);},
                    child: image2==null ? camera2 : displaySelectedFile(image2),
                  ),
                ],
              ),
              new Padding(padding: new EdgeInsets.all(10.0)),
              nombre= new TextField(

                controller: myControllerName,
                keyboardType: TextInputType.text,
                maxLength: 30,

                decoration: new InputDecoration(
                    contentPadding: new EdgeInsets.fromLTRB(10.0, 10.0, 0.0, 5.0),
                    hintText: "Nombre del producto",
                    filled: true,
                    fillColor: nombreLine,
                    labelText: "Nombre"

                ),
              ),
              descripcion=new TextField(
                controller: myControllerDescripcion,
                keyboardType: TextInputType.text,
                maxLength: 50,
                decoration: InputDecoration(
                    contentPadding: new EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),

                    hintText: "Breve descripcion",
                    labelText: "Descripción"
                ),
              ),
              cantidad=new TextField(
                controller: myControllerCantidad,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    contentPadding: new EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                    hintText: "Numero de productos",
                    labelText: "Cantidad"
                ),
              ),
              fechaCreacion= new TextField(
                controller: myControllerFecha,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                    contentPadding: new EdgeInsets.fromLTRB(10.0, 10.0, 0.0, 5.0),
                    hintText: "Fecha de creacion",
                    labelText: "Fecha de creacion"
                ),
              ),
              new Padding(padding: new EdgeInsets.all(10.0)),
              new StreamBuilder(
                  stream: Firestore.instance.collection('Ciudades').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Text('Cargando...');
                    ciudades.clear();
                    ciudadesTemp.clear();
                    for (int i = 0; i < snapshot.data.documents.length; i++) {
                      ds = snapshot.data.documents[i];
                      ciudades.add(Ciudad(ds['name'],ds['code']));
                      ciudadesTemp.add(ds['name']);
                    }
                    //_value=ciudades.elementAt(0);
                    return ciudadesDrop=new DropdownButton<String>(
                        hint: new Text(_value),
                        items: ciudadesTemp.map((String value){
                          return new DropdownMenuItem(
                              value: value,
                              child: new Text('${value}'));
                        }).toList(),
                        //items: getDropDownMenuItemsCiudad(),
                        onChanged:(String value){
                          _value=value;
                          _valueLocalidad="Localidad";
                          changeProvinces(value);
                          setState(() {});
                        });
                  }),
              new Padding(padding: new EdgeInsets.all(1.0)),
              new StreamBuilder(
                  stream: Firestore.instance.collection('poblaciones').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Text('Cargando...');
                    poblaciones.clear();
                    poblacionesTemp.clear();

                    for (int i = 0; i < snapshot.data.documents.length; i++) {
                      ds = snapshot.data.documents[i];
                      poblaciones.add(Poblacion(ds['name'], ds['code'], ds['code_ciudad']));
                    }
                    if(ciudadesDrop !=null && !isFirstTime){
                      Text temp =ciudadesDrop.hint;
                      this.changeProvinces(temp.data);
                    }else{
                      poblacionesTemp.add("");
                      isFirstTime=false;
                    }
                    return localidadesDrop= new DropdownButton<String>(
                        hint: new Text(_valueLocalidad),
                        items:poblacionesTemp.map((String value){
                          return new DropdownMenuItem(
                              value: value,
                              child: new Text('${value}'));
                        }).toList(),
                        onChanged: (String value){
                          _valueLocalidad=value;
                          setState(() {});
                        });
                  }),
              new Padding(padding: new EdgeInsets.all(3.0)),
              new FlatButton(
                  onPressed: (){onPressedButton();},
                  child: new Text("Subir Producto",style: new TextStyle(color: Colors.blueAccent),))
            ],
          ),
        ),
      ),

    );

  }


}

class Ciudad{
  String name, code;
  Ciudad(this.name, this.code);

}

class Poblacion{
  String name, code, code_city;
  Poblacion(this.name, this.code, this.code_city);
}



