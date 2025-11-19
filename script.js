function arrayBufferToBase64(buffer) {
    const bytes = new Uint8Array(buffer);
    let binary = "";
    for (let i = 0; i < bytes.byteLength; i++) {
        binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary);
}

function base64ToArrayBuffer(base64) {
    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
        bytes[i] = binary.charCodeAt(i);
    }
    return bytes.buffer;
}

const SALT = new TextEncoder().encode("salt-fijo-demo");

async function getKeyFromPassword(password) {
    const enc = new TextEncoder();
    const passBytes = enc.encode(password);

    const baseKey = await crypto.subtle.importKey(
        "raw",
        passBytes,
        "PBKDF2",
        false,
        ["deriveKey"]
    );

    return crypto.subtle.deriveKey(
        {
            name: "PBKDF2",
            salt: SALT,
            iterations: 100000,
            hash: "SHA-256",
        },
        baseKey,
        { name: "AES-GCM", length: 256 },
        false,
        ["encrypt", "decrypt"]
    );
}

async function encryptMessage(message, key) {
    const enc = new TextEncoder();
    const data = enc.encode(message);

    const iv = crypto.getRandomValues(new Uint8Array(12));
    const ciphertext = await crypto.subtle.encrypt(
        { name: "AES-GCM", iv },
        key,
        data
    );

    const combined = new Uint8Array(iv.byteLength + ciphertext.byteLength);
    combined.set(iv, 0);
    combined.set(new Uint8Array(ciphertext), iv.byteLength);

    return arrayBufferToBase64(combined.buffer);
}

async function decryptMessage(base64Data, key) {
    const buffer = base64ToArrayBuffer(base64Data);
    const bytes = new Uint8Array(buffer);

    const iv = bytes.slice(0, 12);
    const ciphertext = bytes.slice(12);

    const plaintext = await crypto.subtle.decrypt(
        { name: "AES-GCM", iv },
        key,
        ciphertext
    );

    return new TextDecoder().decode(plaintext);
}

const config = {
    iceServers: [{ urls: "stun:stun.l.google.com:19302" }]
};

let pc = null;
let dataChannel = null;
let encryptionKey = null;

const chatDiv = document.getElementById("chat");

function addMessageToChat(text, from) {
    const p = document.createElement("p");
    p.textContent = from + ": " + text;
    chatDiv.appendChild(p);
    chatDiv.scrollTop = chatDiv.scrollHeight;
}

function waitForIceGatheringComplete(pc) {
    return new Promise((resolve) => {
        if (pc.iceGatheringState === "complete") {
            resolve();
        } else {
            function checkState() {
                if (pc.iceGatheringState === "complete") {
                    pc.removeEventListener("icegatheringstatechange", checkState);
                    resolve();
                }
            }
            pc.addEventListener("icegatheringstatechange", checkState);
        }
    });
}

function initPeerConnection(isInitiator) {
    pc = new RTCPeerConnection(config);

    if (isInitiator) {
        dataChannel = pc.createDataChannel("chat");
        setupDataChannel();
    }

    pc.ondatachannel = (event) => {
        dataChannel = event.channel;
        setupDataChannel();
    };
}

function setupDataChannel() {
    dataChannel.onopen = () => {
        addMessageToChat("Canal P2P establecido", "Sistema");
    };

    dataChannel.onmessage = async (event) => {
        try {
            if (!encryptionKey) {
                addMessageToChat("[ERROR] No hay clave de cifrado cargada", "Sistema");
                return;
            }
            const decrypted = await decryptMessage(event.data, encryptionKey);
            addMessageToChat(decrypted, "Ellos");
        } catch (e) {
            console.error(e);
            addMessageToChat("[Mensaje recibido pero no se pudo descifrar]", "Sistema");
        }
    };
}


const roleSelectDiv = document.getElementById("roleSelect");
const signalingUI = document.getElementById("signalingUI");
let userRole = null;
let signalingStep = 0;

document.getElementById("btnEmisor").onclick = () => {
    userRole = "emisor";
    roleSelectDiv.style.display = "none";
    signalingUI.style.display = "block";
    signalingStep = 0;
    renderSignalingUI();
};
document.getElementById("btnReceptor").onclick = () => {
    userRole = "receptor";
    roleSelectDiv.style.display = "none";
    signalingUI.style.display = "block";
    signalingStep = 0;
    renderSignalingUI();
};

function renderSignalingUI() {
    signalingUI.innerHTML = "";
    if (userRole === "emisor") {

        if (signalingStep === 0) {
            const btn = document.createElement("button");
            btn.textContent = "Crear OFFER";
            btn.onclick = async () => {
                initPeerConnection(true);
                const offer = await pc.createOffer();
                await pc.setLocalDescription(offer);
                await waitForIceGatheringComplete(pc);
                signalingStep = 1;
                renderSignalingUI();
            };
            signalingUI.appendChild(btn);
        }
        if (pc && pc.localDescription) {
            const offerLabel = document.createElement("div");
            offerLabel.textContent = "OFFER generada (copia y envía al receptor):";
            signalingUI.appendChild(offerLabel);
            const offerTextarea = document.createElement("textarea");
            offerTextarea.value = JSON.stringify(pc.localDescription);
            offerTextarea.readOnly = true;
            offerTextarea.style.height = "100px";
            offerTextarea.style.width = "100%";
            signalingUI.appendChild(offerTextarea);
        }
        if (signalingStep === 1) {
            const ansLabel = document.createElement("div");
            ansLabel.textContent = "Pega aquí la ANSWER remota:";
            signalingUI.appendChild(ansLabel);
            const taAns = document.createElement("textarea");
            taAns.style.height = "100px";
            taAns.style.width = "100%";
            signalingUI.appendChild(taAns);
            const btnSetAns = document.createElement("button");
            btnSetAns.textContent = "Usar ANSWER remota";
            btnSetAns.onclick = async () => {
                try {
                    const remoteAnswer = JSON.parse(taAns.value);
                    await pc.setRemoteDescription(remoteAnswer);
                    signalingStep = 2;
                    renderSignalingUI();
                } catch (e) {
                    alert("Formato de ANSWER inválido");
                }
            };
            signalingUI.appendChild(btnSetAns);
        }
        if (signalingStep === 2) {
            signalingUI.appendChild(document.createTextNode("¡Canal P2P listo!"));
        }
    } else if (userRole === "receptor") {
        if (signalingStep === 0) {
            const offerLabel = document.createElement("div");
            offerLabel.textContent = "Pega aquí la OFFER remota:";
            signalingUI.appendChild(offerLabel);
            const ta = document.createElement("textarea");
            ta.style.height = "100px";
            ta.style.width = "100%";
            signalingUI.appendChild(ta);
            const btnSetOffer = document.createElement("button");
            btnSetOffer.textContent = "Usar OFFER remota";
            btnSetOffer.onclick = async () => {
                try {
                    const remoteOffer = JSON.parse(ta.value);
                    initPeerConnection(false);
                    await pc.setRemoteDescription(remoteOffer);
                    const answer = await pc.createAnswer();
                    await pc.setLocalDescription(answer);
                    await waitForIceGatheringComplete(pc);
                    signalingStep = 1;
                    renderSignalingUI();
                } catch (e) {
                    alert("Formato de OFFER inválido");
                }
            };
            signalingUI.appendChild(btnSetOffer);
        }
        if (signalingStep === 1 && pc && pc.localDescription) {
            const ansLabel = document.createElement("div");
            ansLabel.textContent = "Copia y envía esta ANSWER al emisor:";
            signalingUI.appendChild(ansLabel);
            const ta = document.createElement("textarea");
            ta.value = JSON.stringify(pc.localDescription);
            ta.readOnly = true;
            ta.style.height = "100px";
            ta.style.width = "100%";
            signalingUI.appendChild(ta);
            signalingUI.appendChild(document.createElement("br"));
            signalingUI.appendChild(document.createTextNode("¡Canal P2P listo tras enviar la ANSWER!"));
        }
        if (signalingStep === 2) {
            signalingUI.appendChild(document.createTextNode("¡Canal P2P listo!"));
        }
    }
}

document.getElementById("sendBtn").onclick = async () => {
    const text = document.getElementById("messageInput").value;
    if (!text) return;

    if (!dataChannel || dataChannel.readyState !== "open") {
        addMessageToChat("No hay canal P2P abierto todavía", "Sistema");
        return;
    }

    if (!encryptionKey) {
        addMessageToChat("No hay contraseña/clave cargada", "Sistema");
        return;
    }

    const encrypted = await encryptMessage(text, encryptionKey);
    dataChannel.send(encrypted);
    addMessageToChat(text, "Tú");
    document.getElementById("messageInput").value = "";
};

const passwordInput = document.getElementById("passwordInput");
const savePasswordBtn = document.getElementById("savePasswordBtn");

savePasswordBtn.onclick = async () => {
    const pwd = passwordInput.value;
    if (!pwd) return;
    localStorage.setItem("chat-password", pwd);
    encryptionKey = await getKeyFromPassword(pwd);
    addMessageToChat("Contraseña cargada", "Sistema");
};

const savedPass = localStorage.getItem("chat-password");
if (savedPass) {
    passwordInput.value = savedPass;
    getKeyFromPassword(savedPass).then(key => {
        encryptionKey = key;
        addMessageToChat("Contraseña cargada desde localStorage", "Sistema");
    });
}

// Botón para mostrar coordenadas geográficas
document.addEventListener('DOMContentLoaded', function() {
    const btn = document.getElementById('geoBtn');
    const coordsDiv = document.getElementById('coords');
    if (btn) {
        btn.addEventListener('click', function() {
            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(function(position) {
                    const lat = position.coords.latitude;
                    const lon = position.coords.longitude;
                    coordsDiv.textContent = `Tus coordenadas exactas son: Latitud ${lat}, Longitud ${lon}`;
                }, function(error) {
                    coordsDiv.textContent = 'No se pudo obtener la ubicación: ' + error.message;
                });
            } else {
                coordsDiv.textContent = 'La geolocalización no es soportada por este navegador.';
            }
        });
    }
});