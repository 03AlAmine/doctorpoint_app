import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

class VideoCallService {
  final String appId = 'VOTRE_APP_ID_AGORA';
  late RtcEngine _engine;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: appId,
      areaCode: AreaCode.areaCodeGlob.value(),
    ));
    
    // Configuration du moteur
    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    
    _isInitialized = true;
  }

  Future<void> joinChannel({
    required String channelName,
    required String token,
    required int uid,
  }) async {
    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options:const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> leaveChannel() async {
    await _engine.leaveChannel();
  }

  void dispose() {
    _engine.release();
    _isInitialized = false;
  }

  // Widget pour afficher la vue de l'appel
  Widget localView() {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  Widget remoteView(int uid) {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine,
        canvas: VideoCanvas(uid: uid),
        connection: const RtcConnection(channelId: 'default'),
      ),
    );
  }
}