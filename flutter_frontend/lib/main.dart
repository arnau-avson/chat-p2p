
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';

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
      MaterialPageRoute(builder: (_) => RoleSelectScreen(password: pwd)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141E30), Color(0xFF243B55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text('1. Contraseña del chat', style: titleStyle),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Introduce contraseña',
                        labelStyle: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                        ),
                        prefixIcon: const Icon(
                          Icons.vpn_key,
                          color: Colors.white70,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Colors.indigoAccent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _savePassword,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Continuar',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona tu rol'),
        backgroundColor: const Color(0xFF141E30),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141E30), Color(0xFF243B55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('2. ¿Qué rol tienes?', style: titleStyle),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _roleButton(
                          context,
                          icon: Icons.send,
                          label: 'Emisor',
                          color: Colors.indigoAccent,
                          onTap: () {
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
                        _roleButton(
                          context,
                          icon: Icons.reply,
                          label: 'Receptor',
                          color: Colors.tealAccent.shade400,
                          onTap: () {
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: onTap,
    );
  }
}

// -----------------------------------------------------------------------------
// 3) CHAT SCREEN (WebRTC + AES + ICE EXCHANGE)
//   - Si NO conectado -> solo UI de conexión bonica
//   - Si conectado -> solo chat con burbujas
// -----------------------------------------------------------------------------

class ChatScreen extends StatefulWidget {
  final String password;
  final bool isInitiator;
  const ChatScreen({
    super.key,
    required this.password,
    required this.isInitiator,
  });

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
        {"urls": "stun:stun.l.google.com:19302"},
      ],
    };

    pc = await createPeerConnection(config);

    pc!.onConnectionState = (state) {
      setState(() {
        connected =
            state == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
      });
    };

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

    offerCtrl.text = jsonEncode({"sdp": offer.sdp, "type": offer.type});
  }

  Future<void> applyAnswer() async {
    if (answerCtrl.text.trim().isEmpty) return;

    final data = jsonDecode(answerCtrl.text.trim());
    final desc = RTCSessionDescription(data["sdp"], data["type"]);
    await pc!.setRemoteDescription(desc);

    _applyRemoteCandidates();
  }

  Future<void> applyOfferGenerateAnswer() async {
    if (offerCtrl.text.trim().isEmpty) return;

    final data = jsonDecode(offerCtrl.text.trim());
    final desc = RTCSessionDescription(data["sdp"], data["type"]);
    await pc!.setRemoteDescription(desc);

    final answer = await pc!.createAnswer();
    await pc!.setLocalDescription(answer);

    answerCtrl.text = jsonEncode({"sdp": answer.sdp, "type": answer.type});

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

    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = aes.encrypt(msgCtrl.text, iv: iv).base64;
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
      appBar: AppBar(
        title: Text("P2P cifrado ($role)"),
        backgroundColor: const Color(0xFF141E30),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141E30), Color(0xFF243B55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: connected
                ? _buildChatView(context)
                : _buildConnectionView(context),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW 1: SOLO CONEXIÓN (antes de connected)
  // ---------------------------------------------------------------------------

  Widget _buildConnectionView(BuildContext context) {
    final subtitleStyle = TextStyle(
      color: Colors.white.withOpacity(0.85),
      fontSize: 14,
    );

    return SingleChildScrollView(
      key: const ValueKey('connectionView'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Paso 3. Establecer conexión P2P",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Sigue estos pasos con la otra persona. Cuando la conexión se establezca, se abrirá el chat cifrado.",
            style: subtitleStyle,
          ),
          const SizedBox(height: 16),

          // CARD PRINCIPAL DE SEÑALIZACIÓN
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isInitiator ? "Eres el EMISOR" : "Eres el RECEPTOR",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isInitiator
                      ? "1) Pulsa «Crear oferta» y envíala al receptor.\n"
                            "2) Pega aquí la respuesta del receptor y pulsa «Aplicar respuesta».\n"
                            "3) Intercambiad los ICE candidates."
                      : "1) Pega aquí la oferta del emisor y pulsa «Aplicar oferta y generar respuesta».\n"
                            "2) Envía tu respuesta al emisor.\n"
                            "3) Intercambiad los ICE candidates.",
                  style: subtitleStyle,
                ),
                const SizedBox(height: 16),
                widget.isInitiator ? _initiatorPanel() : _receiverPanel(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // CARD DE CANDIDATES
          _buildGlassCard(child: _candidatesPanel()),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: child,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW 2: SOLO CHAT (cuando connected = true)
  // ---------------------------------------------------------------------------

  Widget _buildChatView(BuildContext context) {
    return Column(
      key: const ValueKey('chatView'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildGlassCard(
            child: Row(
              children: const [
                Icon(Icons.lock, color: Colors.greenAccent, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Conexión establecida • Chat cifrado con AES + WebRTC",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: messages.length,
            itemBuilder: (_, i) {
              final msg = messages[i];
              final isMe = msg.startsWith("Tú:");
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  constraints: const BoxConstraints(maxWidth: 260),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.indigoAccent.withOpacity(0.85)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16).subtract(
                      BorderRadius.only(
                        bottomLeft: Radius.circular(isMe ? 16 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 16),
                      ),
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    msg,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ).copyWith(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: msgCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Escribe un mensaje...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: Colors.indigoAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.indigoAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: sendMsg,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SUBPANELS (reutilizados dentro de las cards)
  // ---------------------------------------------------------------------------

  Widget _initiatorPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: createOffer,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigoAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text("Crear oferta"),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: offerCtrl,
                maxLines: 4,
                readOnly: true,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration("Tu oferta"),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white),
              tooltip: 'Copiar oferta',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: offerCtrl.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Oferta copiada')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: answerCtrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration("Respuesta del receptor"),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white),
              tooltip: 'Copiar respuesta',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: answerCtrl.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Respuesta copiada')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: applyAnswer,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent.shade400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text("Aplicar respuesta"),
        ),
      ],
    );
  }

  Widget _receiverPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: offerCtrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration("Oferta del emisor"),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white),
              tooltip: 'Copiar oferta',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: offerCtrl.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Oferta copiada')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: applyOfferGenerateAnswer,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigoAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text("Aplicar oferta y generar respuesta"),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: answerCtrl,
                maxLines: 4,
                readOnly: true,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration("Tu respuesta (envíala al emisor)"),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white),
              tooltip: 'Copiar respuesta',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: answerCtrl.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Respuesta copiada')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _candidatesPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ICE candidates",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          "Copia tus candidates y envíalos al otro dispositivo. Pega los suyos abajo y pulsa «Aplicar candidates remotos».",
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
        ),
        const SizedBox(height: 8),
        const Text("Tus candidates:", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: candidatesLocalCtrl,
                maxLines: 4,
                readOnly: true,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration(null),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white),
              tooltip: 'Copiar primer candidate',
              onPressed: () {
                final firstLine = candidatesLocalCtrl.text.trim().split('\n').firstWhere(
                  (line) => line.trim().isNotEmpty,
                  orElse: () => '',
                );
                Clipboard.setData(ClipboardData(text: firstLine));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Primer candidate copiado')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          "Candidates remotos:",
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: candidatesRemoteCtrl,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: _fieldDecoration(null),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _applyRemoteCandidates,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purpleAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text("Aplicar candidates remotos"),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String? label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.85)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.indigoAccent, width: 2),
      ),
    );
  }
}
