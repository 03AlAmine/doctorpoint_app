import 'package:doctorpoint/data/models/doctor_model.dart';
import 'package:flutter/material.dart';

class VideoCallPage extends StatefulWidget {
  final Doctor doctor;

  const VideoCallPage({super.key, required this.doctor});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = true;
  bool _isCallConnected = false;

  @override
  void initState() {
    super.initState();
    _simulateCallConnection();
  }

  void _simulateCallConnection() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isCallConnected = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vue distante (médecin)
          Positioned.fill(
            child: _isCallConnected
                ? _buildDoctorVideo()
                : _buildConnectingView(),
          ),

          // Vue locale (patient)
          Positioned(
            top: 60,
            right: 20,
            child: _buildLocalVideo(),
          ),

          // Informations du médecin
          Positioned(
            top: 60,
            left: 20,
            child: _buildDoctorInfo(),
          ),

          // Contrôles d'appel
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: _buildCallControls(),
          ),

          // Bouton retour
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Indicateur d'appel
          if (!_isCallConnected)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        'Connexion en cours...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDoctorVideo() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(widget.doctor.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildConnectingView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(widget.doctor.imageUrl),
            ),
            const SizedBox(height: 20),
            Text(
              widget.doctor.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.doctor.specialization,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalVideo() {
    return Container(
      width: 120,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: Colors.grey[800],
          child: const Center(
            child: Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.doctor.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            widget.doctor.specialization,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Temps d\'appel: 05:24',
            style: TextStyle(
              color: Colors.green[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Microphone
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: _isMuted ? 'Activer' : 'Muet',
            color: _isMuted ? Colors.red : Colors.white,
            onTap: () => setState(() => _isMuted = !_isMuted),
          ),

          // Caméra
          _buildControlButton(
            icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
            label: _isVideoOff ? 'Activer' : 'Désactiver',
            color: _isVideoOff ? Colors.red : Colors.white,
            onTap: () => setState(() => _isVideoOff = !_isVideoOff),
          ),

          // Bouton raccrocher (central)
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.call_end, size: 32),
              color: Colors.white,
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appel terminé'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          ),

          // Haut-parleur
          _buildControlButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
            label: _isSpeakerOn ? 'HP' : 'Écouteurs',
            color: _isSpeakerOn ? Colors.green : Colors.white,
            onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
          ),

          // Plus d'options
          _buildControlButton(
            icon: Icons.more_vert,
            label: 'Plus',
            color: Colors.white,
            onTap: () {
              _showMoreOptions();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionItem(
                icon: Icons.chat_bubble,
                title: 'Ouvrir le chat',
                onTap: () {
                  Navigator.pop(context);
                  // Ouvrir le chat
                },
              ),
              _buildOptionItem(
                icon: Icons.file_present,
                title: 'Partager un fichier',
                onTap: () {
                  Navigator.pop(context);
                  // Partager un fichier
                },
              ),
              _buildOptionItem(
                icon: Icons.screen_share,
                title: 'Partager l\'écran',
                onTap: () {
                  Navigator.pop(context);
                  // Partager l'écran
                },
              ),
              _buildOptionItem(
                icon: Icons.record_voice_over,
                title: 'Enregistrer l\'appel',
                onTap: () {
                  Navigator.pop(context);
                  // Enregistrer l'appel
                },
              ),
              _buildOptionItem(
                icon: Icons.flip_camera_android,
                title: 'Changer de caméra',
                onTap: () {
                  Navigator.pop(context);
                  // Changer de caméra
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: onTap,
    );
  }
}