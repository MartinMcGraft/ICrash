// ignore_for_file: slash_for_doc_comments
import 'dart:convert';

import 'package:http/http.dart' as http;

///
///https://pub.dev/documentation/http/latest/
class RequestHandler {
  // Client:
  final client = http.Client();

  /**
   * If the server is deployed, need to change the host to the server public
   * host and verify the port of the server.
   */
  // Server information:
  final String host = '192.168.174.19';
  final String port = '8000';
  late String urlStart;

  // Institution information:
  String instName = '';
  String instID = '';
  bool registeredInst = false;

  // CrashCart information:
  String ccartName = '';
  String ccartID = '';
  bool registeredCC = false;

  // Drawer information:
  String drawerName = '';
  String drawerID = '';

  // Slot information:
  String slotName = '';
  String slotID = '';

  ///
  RequestHandler() {
    urlStart = 'http://$host:$port/api';
  }

  void closeClient() {
    client.close();
  }

  Future<bool> createInstitution(String instName, String instDesc) async {
    if (registeredInst) return registeredInst;

    String url = '$urlStart/institution/create/';
    final data = {'name': instName, 'description': instDesc};

    final response = await client.post(Uri.parse(url), body: data);
    if (response.statusCode == 200) {
      this.instName = instName;
      registeredInst = true;
      return true;
    }
    return false;
  }

  Future<bool> getInstitutionID() async {
    String url = '$urlStart/institution/name/$instName/';

    final response = await client.get(Uri.parse(url));
    if (response.statusCode == 200) {
      instID = response.body;
      return true;
    }
    return false;
  }

  Future<bool> createCrashCarts(String numCC) async {
    if (registeredCC) return registeredCC;

    String url = '$urlStart/institution/$instID/crashcart/create/';
    final data = {'numCC': numCC, 'id_i': instID};

    final response = await client.post(Uri.parse(url), body: data);
    if (response.statusCode == 200) {
      registeredCC = true;
      return true;
    }
    return false;
  }

  Future<bool> getCrashCartID(String ccartName) async {
    this.ccartName = ccartName;

    String url = '$urlStart/institution/$instID/crashcart/name/$ccartName/';

    final response = await client.get(Uri.parse(url));
    if (response.statusCode == 200) {
      ccartID = response.body;
      return true;
    }
    return false;
  }

  Future<bool> createDrawers(String numD) async {
    String url =
        '$urlStart/institution/$instID/crashcart/$ccartID/drawer/create/';
    final data = {'numD': numD, 'id_i': instID, 'id_c': ccartID};

    final response = await client.post(Uri.parse(url), body: data);
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<String> getNumDrawers(String idI, String idC) async {
    instID = idI;
    ccartID = idC;

    String url =
        '$urlStart/institution/$instID/crashcart/$ccartID/drawers/count/';

    final response = await client.get(Uri.parse(url));
    return response.body;
  }

  Future<bool> getDrawerID(String drawerName) async {
    this.drawerName = drawerName;

    String url =
        '$urlStart/institution/$instID/crashcart/$ccartID/drawer/name/$drawerName/';

    final response = await client.get(Uri.parse(url));
    if (response.statusCode == 200) {
      drawerID = response.body;
      return true;
    }
    return false;
  }

  Future<List<String>> getDrawerShape(
      String idI, String idC, String idD) async {
    instID = idI;
    ccartID = idC;
    drawerID = idD;

    String url =
        '$urlStart/institution/$instID/crashcart/$ccartID/drawer/$drawerID/';

    final response = await client.get(Uri.parse(url));
    if (response.statusCode == 200) {
      Map<String, dynamic> json = jsonDecode(response.body);
      String nLins = json['n_lins'].toString();
      String nCols = json['n_cols'].toString();
      return [nLins, nCols];
    }

    return ['0', '0'];
  }

  Future<bool> updateDrawerShape(String nLins, String nCols) async {
    String url =
        '$urlStart/institution/$instID/crashcart/$ccartID/drawer/$drawerID/update/';
    final data = {'n_lins': nLins, 'n_cols': nCols};

    final response = await client.put(Uri.parse(url), body: data);
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<bool> createSlot(String sAdjHor, String sAdjVer, String nameProd,
      String volWeight, String applic, String maxQuant) async {
    String url =
        '$urlStart/institution/$instID/crashcart/$ccartID/drawer/$drawerID/slot/create/';
    final data = {
      's_adj_hor': sAdjHor,
      's_adj_ver': sAdjVer,
      'name_prod': nameProd,
      'vol_weight': volWeight,
      'max_quant': maxQuant
    };

    if (applic.isNotEmpty) {
      data['application'] = applic;
    }

    final response = await client.post(Uri.parse(url), body: data);
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> getSlots(
      String idI, String idC, String idD) async {
    instID = idI;
    ccartID = idC;
    drawerID = idD;

    String url =
        '$urlStart/institution/$instID/crashcart/$ccartID/drawer/$drawerID/slots/info/';

    final response = await client.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);

      final List<Map<String, dynamic>> slotsList =
          jsonData.cast<Map<String, dynamic>>();

      for (var slot in slotsList) {
        print("Slot Information:");
        print("Name: ${slot['name']}");
        print("s_adj_hor: ${slot['s_adj_hor']}");
        print("s_adj_ver: ${slot['s_adj_ver']}");
        print("Name Product: ${slot['name_prod']}");
        print("Application: ${slot['application']}");
        print("Volume Weight: ${slot['vol_weight']}");
        print("Max Quantity: ${slot['max_quant']}");
      }

      return slotsList;
    }

    throw Exception('Failed to load slots');
  }

  Future<List<String>> updateSlotQuantity(
      String idI, String idC, String idD, String idS) async {
    instID = idI;
    ccartID = idC;
    drawerID = idD;
    slotID = idS;

    String url =
        '$urlStart/institution/$instID/crashcart/$ccartID/drawer/$drawerID/slot/$slotID/';

    final response = await client.get(Uri.parse(url));
    if (response.statusCode == 200) {
      Map<String, dynamic> json = jsonDecode(response.body);
      String nameProd = json['name_prod'].toString();
      String maxQuant = json['max_quant'].toString();
      return [nameProd, maxQuant];
    }

    throw Exception('Failed to get name and quantity');
  }
}
