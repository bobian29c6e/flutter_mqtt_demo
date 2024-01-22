import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';

String deviceId = 'Dr.xia/umic';
String inMessage = 'hello';


class MqttDemo extends StatefulWidget {
  @override
  _MqttDemoState createState() => _MqttDemoState();
}

class _MqttDemoState extends State<MqttDemo> {

  // 建立MQTT服务器连接
  late MqttServerClient _client;
  // 接收消息内容
  String _message = '';

  //生命周期
  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() async {
  
  // 设置服务器地址和客户端标识符
  _client = MqttServerClient('broker.emqx.io', 'clientId');
  // 启动后台日志
  // _client.logging(on: true);

  // 连接
  final connMessage = MqttConnectMessage()
      .withClientIdentifier('clientId')   // 客户端标识符
      .startClean()                       // 清理会话（每次连接都会创建一个新的会话
      .keepAliveFor(60)                   // 保持连接时间为60s，60s内没有活动就会断连
      .withWillTopic('willTopic')         // 遗嘱消息主题（客户端端开发发布的消息
      .withWillMessage('Disconnected')    // 遗嘱消息内容
      .withWillQos(MqttQos.atMostOnce);   // 遗嘱消息质量等级为最多传递一次

  // 接收到消息
  _client.connectionMessage = connMessage;

  // 成功连接后调用setState
  try {
    print("连接成功");
    await _client.connect();
    setState(() {
      _message = 'Connected';
    });

    // 监听器，将接收的内容转换为‘MqttReceivedMessage’
    _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final MqttPublishMessage message = messages[0].payload as MqttPublishMessage;
      final String payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
      // 将payload转换json格式
      final Map<String, dynamic> getData = jsonDecode(payload);
      print("接收内容 : $getData");

      print("接收内容的数据类型 : ${getData.runtimeType}");
      setState(() {
        _message = payload;
      });
    });

    // 订阅 ｜ 指定消息质量等级
    _client.subscribe('testtopic/$deviceId', MqttQos.exactlyOnce);
      } catch (e) {
        setState(() {
          _message = 'Failed to connect: $e';
        });
      }
    }

  void _publish(String message) {
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client.publishMessage('testtopic/$deviceId', MqttQos.exactlyOnce, builder.payload!);
    } else {
      print('Connection is not established. Unable to publish message.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              onChanged: (value) => inMessage = value,
            ),

            Text(
              _message,
              style: TextStyle(fontSize: 18),
            ),
            ElevatedButton(
              onPressed: () {
                _publish(inMessage);
              },
              child: Text('Publish Message'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MqttDemo(),
  ));
} 