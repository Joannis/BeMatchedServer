// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;

import 'package:args/args.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;


Map<String, String> tokenForUsername = {};


class Conference {
  static Random r = new Random();

  String name;
  DateTime startDate;
  int ID;
  List<Attendee> attendees = [];

  static List<String> part1 = ["Vierkante", "Ronde", "Driehoekige"];
  static List<String> part2 = ["Rode", "Blauwe", "Zwarte", "Groene"];
  static List<String> part3 = ["Deuren", "Ramen", "Bureaubladen"];

  static int lastID = 0;

  Conference(this.name, this.startDate) {
    this.ID = lastID + 1;

    lastID++;
  }

  factory Conference.random() {
    String name = "";

    name += part1[r.nextInt(part1.length)] + " ";
    name += part2[r.nextInt(part2.length)] + " ";
    name += part3[r.nextInt(part3.length)] + " ";
    name += "Conference";

    return new Conference(name, new DateTime.now());
  }
}

class Attendee {
  String firstname, lastname, company, email, phone, sex, subevent, fakepass, linkedin;
  int ID, secret;
  bool arrived;

  static int lastID = 0;

  Attendee(this.firstname, this.lastname, this.company, this.email, this.phone, this.sex, this.subevent, this.secret, this.fakepass, this.linkedin, this.arrived) {
    this.ID = lastID + 1;
    lastID++;
  }
}


List<Conference> conferences = [];

void main(List<String> args) {
  /*for(int i = 0; i < 10; i++) {
    conferences.add(new Conference.random());
  }*/
  conferences.add(new Conference("IOT Event", new DateTime(2016, 6, 7, 9)));
  conferences.add(new Conference("Medical Expo", new DateTime(2016, 1, 27, 9)));
  conferences.add(new Conference("3D Dental Printing Conference", new DateTime(2016, 1, 27, 9)));
  conferences.add(new Conference("3D Printing Materials Conference", new DateTime(2016, 1, 27, 9)));
  conferences.add(new Conference("3D Bioprinting Conference", new DateTime(2016, 1, 27, 9)));

  Attendee joannis = new Attendee("Joannis", "Orlandos", "Jakajima", "j.orlandos@jakajima.eu", "0612345678", "mr", "Jakajima Staff", 1245209518, "J@ANN15", "joannis-orlandos-2a668a93", false);
  Attendee boy = new Attendee("Boy", "Zelen", "Jakajima", "b.zelen@jakajima.eu", "0612345678", "mr", "Jakajima Staff", 1245209519, "boodschap!", "boyzelen", false);
  Attendee roopali = new Attendee("Roopali", "Gupta", "Jakajima", "r.gupta@jakajima.eu", "0612345678", "mr", "Jakajima Staff", 1245209520, "test123", "roopali-gupta-66517b2", false);

  conferences.where((Conference c) {
    return c.name == "IOT Event";
  }).forEach((Conference c) {
    c.attendees.add(roopali);
  });

  for(Conference c in conferences) {
    c.attendees.add(joannis);
    c.attendees.add(boy);
  }

  var parser = new ArgParser()
    ..addOption('port', abbr: 'p', defaultsTo: '1337');

  var result = parser.parse(args);

  var port = int.parse(result['port'], onError: (val) {
    stdout.writeln('Could not parse port value "$val" into a number.');
    exit(1);
  });

  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(_echoRequest);

  io.serve(handler, InternetAddress.ANY_IP_V4, port).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });
}

Future<shelf.Response> _echoRequest(shelf.Request request) async {
  Map headers = {
    "Access-Control-Allow-Origin": "*"
  };

  String dataString = await request.readAsString();

  Map data = JSON.decode(dataString);

  String token = data["token"];

  switch(data["request"]) {
    case "login":
      if(login(data["email"], data["password"])) {
        String token = generateToken(data["email"]);

        tokenForUsername[token] = data["email"];

        print(token);

        return new shelf.Response.ok(JSON.encode({
          "responses": {
            "login": true
          },
          "token": token
        }), headers: headers);
      }

      return new shelf.Response.forbidden(JSON.encode({"login": false}), headers: headers);
    case "logout":
      if((token != null && tokenForUsername.containsKey(token)) && false) {
        tokenForUsername.remove(token);

        return new shelf.Response.ok(JSON.encode({"login": false}), headers: headers);
      }

      return new shelf.Response.notFound(JSON.encode({"login": false}), headers: headers);
    case "boyevents":
      if((token == null || !tokenForUsername.containsKey(token)) && false)
        return new shelf.Response.forbidden(JSON.encode({"login": false}), headers: headers);

      List events = [];

      for(Conference conference in conferences) {
        events.add({
          "id": conference.ID,
          "date_start": "${conference.startDate.year}-${conference.startDate.month}-${conference.startDate.day}",
          "event_name": conference.name
        });
      }

      return new shelf.Response.ok(JSON.encode({
        "responses": {
          "events":events
        },
        "errors": [],
        "token": token
      }), headers: headers);
    case "registrations":
      if((token == null || !tokenForUsername.containsKey(token)) && false)
        return new shelf.Response.forbidden(JSON.encode({"login": false}), headers: headers);

      if(data["id"] is String) {
        data["id"] = int.parse(data["id"]);
      }

      for(Conference conference in conferences) {
        if(conference.ID == data["id"]) {
          print("test");
          List<Map> registrationList = [];

          for(Attendee attendee in conference.attendees) {
            registrationList.add({
              "id": attendee.ID,
              "firstname": attendee.firstname,
              "lastname": attendee.lastname,
              "arrived": attendee.arrived ? 1 : 0,
              "email": attendee.email,
              "phone": attendee.phone,
              "reg_id": attendee.ID,
              "company": attendee.company,
              "sex": attendee.sex,
              "secret": attendee.secret,
              "subevent": attendee.subevent
            });
          }

          return new shelf.Response.ok(JSON.encode({
            "responses": {
              "registrations": registrationList
            },
            "errors": [],
            "token": token
          }), headers: headers);
        }
      }

      return new shelf.Response.ok(JSON.encode({
        "responses": {
          "registrations":[]
        },
        "errors": [],
        "token": token
      }), headers: headers);
    case "ping":
      return new shelf.Response.notFound("No such API thingy", headers: headers);

    default:
      return new shelf.Response.notFound("No such API thingy", headers: headers);
  }
}

bool login(String username, String password) {
  return (username.toLowerCase() == "b.zelen@jakajima.eu" && password == "zelen");
}

String generateToken(String username) {
  if(username == null) return null;

  crypto.MD5 digest = new crypto.MD5();

  digest.add(username.codeUnits);

  return crypto.CryptoUtils.bytesToHex(digest.close());
}