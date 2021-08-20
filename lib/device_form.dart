import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

class DeviceForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return DeviceFormState();
  }
}

class DeviceFormState extends State<DeviceForm> {
  // Create form key
  final formKey = GlobalKey<FormState>();
  String device = '';
  String desiredVal = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(20.0),
      child: Form(
        //Pass it to children widgets
        key: formKey,
        child: Column(
          children: [
            deviceField(),
            desiredValField(),
            Container(
              margin: EdgeInsets.only(top: 25.0),
            ),
            registerDevice(),
            submitButton(),
          ],
        ),
      ),
    );
  }

  Widget deviceField() {
    return TextFormField(
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: 'Device Name/Serial',
      ),
      onSaved: (String? value) {
        if (value != null) {
          device = value;
        }
      },
    );
  }

  Widget desiredValField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Enter Desired Value',
      ),
      onSaved: (String? value) {
        if (value != null) {
          desiredVal = value;
        }
      },
    );
  }

  Widget submitButton() {
    return ElevatedButton(
      child: Text('Submit Device Event'),
      onPressed: () async {
        //Access form key created by its parent widget
        if (formKey.currentState != null) {
          formKey.currentState?.save();

          // Take *both* device and desiredVal
          // add post them to some API
          print('This should send IoT Date to register and subscribe to');
          var url = Uri.parse(
              'https://0t52mixuj9.execute-api.us-east-1.amazonaws.com/prod/update');

          var data = {
            "serial": device,
            "payload": {
              "state": {
                "desired": {"heatTo": int.parse(desiredVal)}
              }
            }
          };

          var body = convert.jsonEncode(data);

          var headers = {'Content-Type': 'application/json'};

          var response = await http.put(url, headers: headers, body: body);
          print(body);
          print('Response Status: ${response.statusCode}');
          print('Response Body: ${response.body}');
        }
      },
    );
  }

  Widget registerDevice() {
    return ElevatedButton(
      child: Text('Register Device'),
      onPressed: () async {
        //Access form key created by its parent widget
        if (formKey.currentState != null) {
          formKey.currentState?.save();
          var token = await FirebaseMessaging.instance.getToken();
          var headers = {'Content-Type': 'application/json'};
          var url = Uri.parse(
              'https://0t52mixuj9.execute-api.us-east-1.amazonaws.com/prod/provision');

          var data = {'token': token, 'serial': device};
          var body = convert.jsonEncode(data);
          var response = await http.post(url, headers: headers, body: body);
          print('Registering $data');
          print('Response Status: ${response.statusCode}');
          print('Response Body: ${response.body}');
        }
      },
    );
  }
}
