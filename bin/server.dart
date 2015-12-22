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
  int ID;

  static List<String> part1 = ["Vierkante", "Ronde", "Driehoekige"];
  static List<String> part2 = ["Rode", "Blauwe", "Zwarte", "Groene"];
  static List<String> part3 = ["Deuren", "Ramen", "Bureaubladen"];

  static int lastID = 0;

  Conference(this.name) {
    this.ID = lastID + 1;

    lastID++;
  }

  factory Conference.random() {
    String name = "";

    name += part1[r.nextInt(part1.length)] + " ";
    name += part2[r.nextInt(part2.length)] + " ";
    name += part3[r.nextInt(part3.length)] + " ";
    name += "Conference";

    return new Conference(name);
  }
}

class Attendee {
  String firstname, lastname, company, email, phone, sex, subevent;
  int ID, secret;

  static int lastID = 0;



  Attendee(this.firstname, this.lastname, this.company, this.email, this.phone, this.sex, this.subevent, this.secret) {
    this.ID = lastID + 1;
    lastID++;
  }
}


List<Conference> conferences = [];

void main(List<String> args) {
  for(int i = 0; i < 10; i++) {
    conferences.add(new Conference.random());
  }

  var parser = new ArgParser()
    ..addOption('port', abbr: 'p', defaultsTo: '8080');

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
      if(token != null && tokenForUsername.containsKey(token)) {
        tokenForUsername.remove(token);

        return new shelf.Response.ok(JSON.encode({"login": false}), headers: headers);
      }

      return new shelf.Response.notFound(JSON.encode({"login": false}), headers: headers);
    case "boyevents":
      if(token == null || !tokenForUsername.containsKey(token))
        return new shelf.Response.forbidden(JSON.encode({"login": false}), headers: headers);

      List events = [];

      for(Conference conference in conferences) {
        events.add({
          "id": conference.ID,
          "date_start": "2016-01-01",
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
      if(token == null || !tokenForUsername.containsKey(token))
        return new shelf.Response.forbidden(JSON.encode({"login": false}), headers: headers);

      return new shelf.Response.ok(JSON.encode({
        "responses": {
          "registrations":[
            {
              "id": 123,
              "firstname": "Wilma",
              "lastname": "Bakker",
              "arrived": 1,
              "email": "koekjes@bakker.nl",
              "phone": "0612345678",
              "reg_id": 123,
              "company": "De Koekjes Bakker",
              "sex": "ms",
              "secret": 1234567890,
              "subevent": "Vierkante Ramen Conference"
            }
          ]
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
  return (username.toLowerCase() == "boy" && password == "zelen");
}

String generateToken(String username) {
  if(username == null) return null;

  crypto.MD5 digest = new crypto.MD5();

  digest.add(username.codeUnits);

  return crypto.CryptoUtils.bytesToHex(digest.close());
}