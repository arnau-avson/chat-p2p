import 'dart:convert';
import 'dart:ui';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat P2P Cifrado',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const PasswordScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// 1) Password screen
// -----------------------------------------------------------------------------


class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _controller = TextEditingController();

  void _savePassword() {
    final pwd = _controller.text.trim();
    if (pwd.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoleSelectScreen(password: pwd),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '1. Contraseña del chat',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Introduce contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar y continuar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: _savePassword,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2) Role selection
// -----------------------------------------------------------------------------

class RoleSelectScreen extends StatelessWidget {
  final String password;
  const RoleSelectScreen({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona tu rol')),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Emisor'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      password: password,
                      isInitiator: true,
                    ),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.reply),
              label: const Text('Receptor'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      password: password,
                      isInitiator: false,
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3) CHAT SCREEN (WebRTC + AES + ICE EXCHANGE)
// -----------------------------------------------------------------------------

class ChatScreen extends StatefulWidget {
  final String password;
  final bool isInitiator;
  const ChatScreen({super.key, required this.password, required this.isInitiator});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  RTCPeerConnection? pc;
  RTCDataChannel? dc;

  final msgCtrl = TextEditingController();
  final offerCtrl = TextEditingController();
  final answerCtrl = TextEditingController();
  final candidatesLocalCtrl = TextEditingController();
  final candidatesRemoteCtrl = TextEditingController();

  final List<String> messages = [];

  late encrypt.Encrypter aes;
  late encrypt.IV iv;

  bool connected = false;

  @override
  void initState() {
    super.initState();

    // Prepare AES encryption
    final key = encrypt.Key.fromUtf8(
      widget.password.padRight(32, '0').substring(0, 32),
    );
    aes = encrypt.Encrypter(encrypt.AES(key));
    iv = encrypt.IV.fromLength(16);

    _init();
  }

  Future<void> _init() async {
    final config = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"}
      ]
    };

    pc = await createPeerConnection(config);

    pc!.onConnectionState = (state) {
      setState(() {
        connected = state == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
      });
    };

    // ------------------------------
    // HANDLE ICE CANDIDATES
    // ------------------------------
    pc!.onIceCandidate = (c) {
      if (c.candidate != null) {
        final json = jsonEncode({
          "candidate": c.candidate,
          "sdpMid": c.sdpMid ?? "",
          "sdpMLineIndex": c.sdpMLineIndex ?? 0,
        });
        candidatesLocalCtrl.text += "$json\n";
      }
    };

    // ------------------------------
    // HANDLE DATACHANNEL
    // ------------------------------

    if (widget.isInitiator) {
      dc = await pc!.createDataChannel("chat", RTCDataChannelInit());
      _setupDataChannel();
    } else {
      pc!.onDataChannel = (channel) {
        dc = channel;
        _setupDataChannel();
      };
    }
  }

  void _setupDataChannel() {
    dc?.onMessage = (msg) {
      try {
        // Separar IV y mensaje cifrado
        final parts = msg.text.split(':');
        if (parts.length != 2) return;
        final iv = encrypt.IV.fromBase64(parts[0]);
        final encryptedMsg = parts[1];
        final decrypted = aes.decrypt64(encryptedMsg, iv: iv);
        setState(() {
          messages.add("Ellos: $decrypted");
        });
      } catch (e) {
        setState(() {
          messages.add("[ERROR al descifrar mensaje]");
        });
      }
    };
  }

  // ---------------------------------------------------------------------------
  // OFFER / ANSWER
  // ---------------------------------------------------------------------------

  Future<void> createOffer() async {
    final offer = await pc!.createOffer();
    await pc!.setLocalDescription(offer);

    offerCtrl.text = jsonEncode({
      "sdp": offer.sdp,
      "type": offer.type,
    });
  }

  Future<void> applyAnswer() async {
    if (answerCtrl.text.trim().isEmpty) return;

    final data = jsonDecode(answerCtrl.text.trim());
    final desc = RTCSessionDescription(data["sdp"], data["type"]);
    await pc!.setRemoteDescription(desc);

    // ALSO APPLY REMOTE CANDIDATES
    _applyRemoteCandidates();
  }

  Future<void> applyOfferGenerateAnswer() async {
    if (offerCtrl.text.trim().isEmpty) return;

    final data = jsonDecode(offerCtrl.text.trim());
    final desc = RTCSessionDescription(data["sdp"], data["type"]);
    await pc!.setRemoteDescription(desc);

    final answer = await pc!.createAnswer();
    await pc!.setLocalDescription(answer);

    answerCtrl.text = jsonEncode({
      "sdp": answer.sdp,
      "type": answer.type,
    });

    _applyRemoteCandidates();
  }

  // ---------------------------------------------------------------------------
  // ICE CANDIDATES
  // ---------------------------------------------------------------------------

  Future<void> _applyRemoteCandidates() async {
    final lines = candidatesRemoteCtrl.text.trim().split("\n");
    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final data = jsonDecode(line.trim());

      final cand = RTCIceCandidate(
        data["candidate"],
        data["sdpMid"],
        data["sdpMLineIndex"],
      );

      await pc!.addCandidate(cand);
    }
  }

  // ---------------------------------------------------------------------------
  // SEND MESSAGE
  // ---------------------------------------------------------------------------

  void sendMsg() {
    if (dc == null || msgCtrl.text.isEmpty) return;

    // Generar IV aleatorio para cada mensaje
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = aes.encrypt(msgCtrl.text, iv: iv).base64;
    // Enviar el IV junto con el mensaje cifrado, separado por ':'
    final payload = iv.base64 + ':' + encrypted;
    dc!.send(RTCDataChannelMessage(payload));

    setState(() {
      messages.add("Tú: ${msgCtrl.text}");
      msgCtrl.clear();
    });
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final role = widget.isInitiator ? "Emisor" : "Receptor";

    return Scaffold(
      appBar: AppBar(title: Text("Chat P2P cifrado ($role)")),
      body: Column(
        children: [
          // PANEL DE SEÑALIZACIÓN
          ExpansionTile(
            initiallyExpanded: true,
            title: Text(
              "Paso 3. Conexión P2P (señalización manual)",
              style: const TextStyle(fontSize: 16),
            ),
            subtitle: Text(
              connected ? "Estado: CONECTADO" : "Estado: Conectando...",
              style: TextStyle(
                color: connected ? Colors.green : Colors.orange,
              ),
            ),
            childrenPadding: const EdgeInsets.all(12),
            children: [
              SizedBox(
                height: 350,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Guía rápida para conectar:",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      const SizedBox(height: 4),
                      Text("1. El Emisor pulsa 'Crear oferta' y copia el texto generado."),
                      Text("2. El Receptor pega la oferta y pulsa 'Aplicar oferta y generar respuesta'."),
                      Text("3. El Receptor copia la respuesta y la envía al Emisor."),
                      Text("4. El Emisor pega la respuesta y pulsa 'Aplicar respuesta'."),
                      Text("5. Copia los ICE candidates locales y pégalos en el campo de candidates remotos del otro lado, pulsa 'Aplicar candidates remotos' en ambos."),
                      Text("6. Cuando el estado cambie a 'CONECTADO', ya puedes chatear."),
                      const SizedBox(height: 8),
                      if (!connected)
                        Text(
                          "Si no conecta, revisa que ambos hayan pegado los candidates y que la red permita WebRTC.",
                          style: TextStyle(color: Colors.red),
                        ),
                      widget.isInitiator ? _initiatorPanel() : _receiverPanel(),
                      const SizedBox(height: 8),
                      _candidatesPanel(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // MENSAJES
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (_, i) => Text(messages[i]),
            ),
          ),

          // INPUT
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: msgCtrl,
                  enabled: connected,
                  decoration: const InputDecoration(hintText: "Mensaje..."),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: connected ? sendMsg : null, child: const Text("Enviar")),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI SUBPANELS
  // ---------------------------------------------------------------------------

  Widget _initiatorPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(onPressed: createOffer, child: const Text("Crear oferta")),
        TextField(
          controller: offerCtrl,
          maxLines: 5,
          readOnly: true,
          decoration: const InputDecoration(labelText: "Tu oferta"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: answerCtrl,
          maxLines: 5,
          decoration: const InputDecoration(labelText: "Respuesta del receptor"),
        ),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: applyAnswer, child: const Text("Aplicar respuesta")),
      ],
    );
  }

  Widget _receiverPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: offerCtrl,
          maxLines: 5,
          decoration: const InputDecoration(labelText: "Oferta del emisor"),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
            onPressed: applyOfferGenerateAnswer,
            child: const Text("Aplicar oferta y generar respuesta")),
        const SizedBox(height: 12),
        TextField(
          controller: answerCtrl,
          maxLines: 5,
          readOnly: true,
          decoration: const InputDecoration(labelText: "Tu respuesta"),
        ),
      ],
    );
  }

  Widget _candidatesPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text("ICE candidates (cópialos y pégalos en el otro dispositivo)"),
        const SizedBox(height: 8),
        const Text("Tus candidates:"),
        TextField(
          controller: candidatesLocalCtrl,
          maxLines: 6,
          readOnly: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        const Text("Candidates remotos:"),
        TextField(
          controller: candidatesRemoteCtrl,
          maxLines: 6,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _applyRemoteCandidates,
          child: const Text("Aplicar candidates remotos"),
        ),
      ],
    );
  }
}
