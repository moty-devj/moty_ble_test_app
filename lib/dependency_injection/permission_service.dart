import 'dart:async';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<String?> checkBluetoothPermission() async {
    var bluetoothScanStatus = await Permission.bluetoothScan.status;
    var bluetoothConnectStatus = await Permission.bluetoothConnect.status;
    if (Platform.isAndroid && bluetoothScanStatus != PermissionStatus.granted) {
      return '블루투스 스캔 권한 없음 ';
    }
    if (Platform.isAndroid &&
        bluetoothConnectStatus != PermissionStatus.granted) {
      return '블루투스 연결 권한 없음';
    }
    return null;
  }

  Future<String?> requestBluetoothPermission() async {
    var statuses =
        await [Permission.bluetoothScan, Permission.bluetoothConnect].request();
    for (var status in statuses.entries) {
      if (Platform.isAndroid && status.key == Permission.bluetoothScan) {
        if (status.value.isGranted) {
        } else {
          return '블루투스 스캔 권한 없음 ';
        }
      } else if (Platform.isAndroid &&
          status.key == Permission.bluetoothConnect) {
        if (!status.value.isGranted) {
          return '블루투스 연결 권한 없음';
        }
      }
    }
    return null;
  }

  Future<String?> checkRunPermission() async {
    var alwaysPermission = await Permission.locationAlways.status;

    if (alwaysPermission.isGranted == false) {
      var whenInUsePermission = await Permission.locationWhenInUse.status;
      if (whenInUsePermission.isGranted == false) {
        return '위치 권한이 없습니다';
      }
    }

    if (alwaysPermission.isGranted == false) {
      return '위치 액세스 권한을 "항상 허용"이어야 시작이 가능합니다.';
    }

    return null;
  }

  Future<void> requestRunPermission() async {
    var alwaysPermission = await Permission.locationAlways.status;

    if (alwaysPermission.isGranted == false) {
      var whenInUsePermission = await Permission.locationWhenInUse.status;
      if (whenInUsePermission.isGranted == false) {
        whenInUsePermission = await Permission.locationWhenInUse.request();
        if (whenInUsePermission.isGranted == false) {
          throw '위치 권한이 없습니다.';
        }
      }
    }
  }
}
