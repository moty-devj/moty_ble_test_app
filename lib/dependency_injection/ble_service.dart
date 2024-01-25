import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// BLE에 사용되는 상수값
const kServiceRN4870UUID = '49535343-fe7d-4ae5-8fa9-9fafd205e455';
const kChracteristicRN4870RwUUID = '49535343-1e4d-4bd9-ba61-23c647249616';

class BleService {
  late void Function(BluetoothDevice? device) _onChangeDeviceState;

  BluetoothDevice? _device;
  StreamSubscription? _deviceStateChanegSubscription;
  BluetoothCharacteristic? _writeCaharacteristic;
  StreamSubscription? _stateChanegSubscription;
  StreamSubscription? _valueChangedSubscription;

  // BLE 초기화
  Future<void> initialize(
    void Function(BluetoothAdapterState state) onChangeState,
    void Function(BluetoothDevice? device) onChangeDeviceState,
  ) async {
    if (await FlutterBluePlus.isSupported == false) {
      print("블루투스가 지원 안됩니다.");
      return;
    }

    _stateChanegSubscription = FlutterBluePlus.adapterState.listen((s) {
      onChangeState(s);
    });
    _onChangeDeviceState = onChangeDeviceState;

    if (Platform.isAndroid) {
      final isOn = await FlutterBluePlus.isOn;
      if (!isOn) {
        await FlutterBluePlus.turnOn();
      }
    }
  }

  Future<void> finalize() async {
    await disconnectDevice(true);
    await _stateChanegSubscription?.cancel();
    _stateChanegSubscription = null;

    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOff();
    }
  }

  Future<void> connectDevice(BluetoothDevice device) async {
    if (_device != null) {
      await disconnectDevice(false);
    }

    try {
      await FlutterBluePlus.stopScan();

      final currentDeviceState = await device.state.first;

      _device = device;
      _deviceStateChanegSubscription = device.state.listen((s) {
        _onChangeDeviceState(_device);
      });

      if (currentDeviceState == BluetoothConnectionState.disconnected) {
        try {
          await device.connect(
              timeout: const Duration(seconds: 10), autoConnect: true);
        } catch (e) {
          disconnectDevice(false);
        }
      }

      FlutterBluePlus.events.onCharacteristicReceived.listen((event) {
        print("onCharacteristicReceived");
      });

      if (Platform.isAndroid) {
        await device.requestMtu(512); // 안드로이드만 설정을 해줘야 합니다.
      }
    } catch (err) {
      print(err);
      await disconnectDevice(false);
      rethrow;
    }
  }

  Future<void> disconnectDevice(bool isFinalize) async {
    await _device?.disconnect();
    _device = null;

    await _deviceStateChanegSubscription?.cancel();
    _deviceStateChanegSubscription = null;

    await _valueChangedSubscription?.cancel();
    _valueChangedSubscription = null;

    if (!isFinalize) {
      _onChangeDeviceState(null);
    }
  }

  Future<BluetoothCharacteristic> _findWriteCharacteristics(
    BluetoothDevice device,
  ) async {
    final services = await device.discoverServices();

    for (var service in services) {
      if (service.uuid.toString() == kServiceRN4870UUID) {
        for (var character in service.characteristics) {
          if (character.uuid.toString() == kChracteristicRN4870RwUUID) {
            return character;
          }
        }
      }
    }
    throw '잘못된 디바이스 입니다.';
  }

  BluetoothDevice? getDevice() {
    return _device;
  }
}
