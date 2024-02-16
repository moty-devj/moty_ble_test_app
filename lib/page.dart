import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:moty_test_app/dependency_injection/ble_service.dart';

import 'package:moty_test_app/dependency_injection/permission_service.dart';

const kServiceRN4870UUID = '49535343-fe7d-4ae5-8fa9-9fafd205e455';
const kCharacteristicRN4870RwUUID = '49535343-1e4d-4bd9-ba61-23c647249616';

class PageScreen extends ConsumerStatefulWidget {
  const PageScreen({super.key});

  @override
  ConsumerState<PageScreen> createState() => _PageScreenState();
}

class _PageScreenState extends ConsumerState<PageScreen> {
  final _messageStreamController = StreamController.broadcast();
  Stream get message => _messageStreamController.stream;

  String bleState = "";

  int modeNum = 0; // 0~5
  int leftWeight = 0; // 0~50
  int rightWeight = 0; // 0~50

  List<int> writeData = [];
  List<int> readData = [];

  late BluetoothDevice device;
  BluetoothCharacteristic? bleChar;

  // 권한 체크
  Future<void> checkPermission() async {
    if (await GetIt.I<PermissionService>().checkBluetoothPermission() != null) {
      await GetIt.I<PermissionService>().requestBluetoothPermission();
    }
    // await GetIt.I<PermissionService>().requestRunPermission();
  }

  @override
  void initState() {
    if (GetIt.I.get<BleService>().getDevice() != null) {
    } else {
      checkPermission();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text(
                      "보낸 데이터",
                      style: TextStyle(
                        fontSize: 24.0,
                      ),
                    ),
                    Text(
                      writeData
                          .map((int value) =>
                              '${value.toRadixString(16).toUpperCase()}')
                          .join(', '),
                      style: const TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      "받은 데이터",
                      style: TextStyle(fontSize: 24.0),
                    ),
                    Text(
                      readData
                          .map((int value) =>
                              '${value.toRadixString(16).toUpperCase()}')
                          .join(', '),
                      style: const TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("모드(0~5) : "),
                Container(
                  width: 120,
                  height: 45,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        modeNum = int.parse(value);
                      });
                      print(modeNum);
                    },
                  ),
                ),
                Text("왼쪽 무게 (0~50) : "),
                Container(
                  width: 120,
                  height: 45,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        leftWeight = int.parse(value);
                      });
                    },
                  ),
                ),
                Text("오른쪽 무게 (0~50) : "),
                Container(
                  width: 120,
                  height: 45,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        rightWeight = int.parse(value);
                      });
                    },
                  ),
                ),
                // TextField(),
                // TextField(),
              ],
            ),
            const SizedBox(height: 32.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                startBle(),
                const SizedBox(width: 16.0),
                endBle(),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                connectBle(),
                const SizedBox(width: 16.0),
                sendDataBle(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ElevatedButton connectBle() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff304fff),
        foregroundColor: Colors.white,
        minimumSize: const Size(400, 120),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () {
        GetIt.I.get<BleService>().initialize((state) {
          if (state == BluetoothAdapterState.on) {
            FlutterBluePlus.scanResults.listen((results) async {
              if (results.isNotEmpty) {
                ScanResult r = results.last;
                // print(
                //     '${r.device.remoteId}: "${r.device.platformName}" 찾았습니다!');

                if (r.device.platformName.contains("RN4870")) {
                  print('RN4870 기기 발견!');
                  FlutterBluePlus.stopScan();

                  await r.device.connect();
                  print("연결 완료");

                  setState(() {
                    device = r.device;
                  });

                  print("device : ${device.platformName}");

                  bleChar = await _findWriteChar(device);
                  final readCharacteristics =
                      await _findReadCharacteristics(device);

                  _setNotification(readCharacteristics);

                  // FlutterBluePlus.events.onCharacteristicReceived
                  //     .listen((event) {
                  //   print("onCharacteristicReceived");
                  //   print(event.value);
                  // });

                  // final sub = bleChar!.onValueReceived.listen((value) {
                  //   print("onValueReceived");  
                  //   print(value);
                  // });

                  showDialog(
                      context: context,
                      builder: (context) {
                        return Column(
                          children: [
                            Text("연결되었습니다.",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                )),
                            ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text("창 닫기")),
                          ],
                        );
                      });

                  return;
                }
              }
            }, onError: (e) {
              print(e);
            });
            FlutterBluePlus.startScan();
          }
        }, (device) {
          setState(() {
            bleState = "BLE 연결이 완료되었습니다.";
          });
          if (device != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("연결이 완료되었습니다"),
                backgroundColor: Colors.black,
              ),
            );
          }
        });
      },
      child: const Text(
        '블루투스 연결 버튼',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  ElevatedButton startBle() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff304fff),
        foregroundColor: Colors.white,
        minimumSize: const Size(400, 120),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () async {
        await startWorkout();
      },
      child: Text(
        '운동 시작',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  ElevatedButton sendDataBle() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff304fff),
        foregroundColor: Colors.white,
        minimumSize: const Size(400, 120),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () async {
        await sendWorkoutSetting();
      },
      child: Text(
        '모드, 무게 전송',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  ElevatedButton endBle() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff304fff),
        foregroundColor: Colors.white,
        minimumSize: const Size(400, 120),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () async {
        await endWorkout();
      },
      child: Text(
        '운동 종료',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // use Func
  Future<BluetoothCharacteristic> _findWriteChar(BluetoothDevice device) async {
    final services = await device.discoverServices();

    for (var service in services) {
      if (service.uuid.toString() == kServiceRN4870UUID) {
        for (var character in service.characteristics) {
          if (character.uuid.toString() == kCharacteristicRN4870RwUUID) {
            return character;
          }
        }
      }
    }
    throw '잘못된 디바이스 입니다.';
  }

  Future<BluetoothCharacteristic> _findReadCharacteristics(
      BluetoothDevice device) async {
    final services = await device.discoverServices();

    for (var service in services) {
      if (service.uuid.toString() == kServiceRN4870UUID) {
        for (var character in service.characteristics) {
          if (character.uuid.toString() == kCharacteristicRN4870RwUUID) {
            return character;
          }
        }
      }
    }
    throw '잘못된 디바이스 입니다.';
  }

  // use Func
  Future<void> sendWorkoutSetting() async {
    // 예시 입력 바이트
    final headBytes = [0x5B, 0xFD, 0x04];
    final tailBytes = [0x5D];

    final modeByte = modeNum & 0xFF;
    final leftWeightByte = leftWeight & 0xFF;
    final rightWeightByte = rightWeight & 0xFF;

    writeData = [
      ...headBytes,
      modeByte,
      leftWeightByte,
      rightWeightByte,
      ...tailBytes,
    ];

    print("데이터 전송");

    await sendData(writeData);
  }

  Future<void> startWorkout() async {
    // 예시 입력 Value

    // 예시 입력 바이트
    final headBytes = [0x5B, 0xFC, 0x03, 0x00];
    final tailBytes = [0x5D];

    writeData = [
      ...headBytes,
      ...tailBytes,
    ];

    await sendData(writeData);
  }

  Future<void> endWorkout() async {
    // 예시 입력 바이트
    final headBytes = [0x5B, 0xFE, 0x05];
    final tailBytes = [0x5D];

    writeData = [
      ...headBytes,
      ...tailBytes,
    ];

    await sendData(writeData);
  }

  // use Func
  Future<void> onReceivedData(List<int> bytes) async {
    if (bytes.length < 3) return;
    //
    // print("기기로 부터 받은 데이터 ${bytes}");

    print("왼쪽 위치 ${((((bytes[1] << 8) + bytes[2])) - 32768) / 10}");
    print("왼쪽 속도 ${((((bytes[3] << 8) + bytes[4])) - 32768) / 10}");
    print("오른쪽 위치 ${((((bytes[5] << 8) + bytes[6])) - 32768) / 10}");
    print("오른쪽 속도 ${((((bytes[7] << 8) + bytes[8])) - 32768) / 10}");
    // bytes[2];

    setState(() {
      readData = bytes;
    });

    // 기기로 부터 받은 상태 메시지 발생
    // if (bytes[0] == 0x5B &&
    //     bytes[1] == 0x02 &&
    //     bytes[2] == 0x02 &&
    //     bytes.length >= 5) {
    //   var setCnt = bytes[3]; //기기로부터 받은 셋트 수(예시)
    //   var respsCnt = bytes[4]; //기기로부터 받은 반복 횟수(예시)
    //   print("기기로 부터 받은 데이터 ${bytes}");
    // }
  }

  //    ----------- 위 까지 -----------

  _setNotification(BluetoothCharacteristic c) async {
    if (!c.isNotifying) {
      await c.setNotifyValue(true);
    }

    // await _valueChangedSubscription?.cancel();
    // _valueChangedSubscription =
    c.value.listen((d) {
      print("ㅎㅎㅎㅎ ${d}");
      onReceivedData(d);
    });
  }

  // use Func
  Future<void> sendData(List<int> bytes) async {
    if (bleChar == null) {
      throw '시작할 수 있는 디바이스가 없습니다.';
    }
    await bleChar!.write(bytes, withoutResponse: true);
  }

  // use Func
  List<int> _getIntBytes(int value) {
    return [
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }
}
