# Chat P2P Cifrado (WebRTC)

Este proyecto es una aplicación web de chat punto a punto (P2P) que utiliza WebRTC para la comunicación directa entre dos navegadores y AES-GCM para el cifrado de mensajes. La señalización se realiza manualmente mediante el intercambio de ofertas y respuestas (OFFER/ANSWER) copiando y pegando los datos entre los usuarios.

## Características principales

- **Comunicación P2P:** Los mensajes se envían directamente entre los navegadores usando WebRTC, sin servidores intermedios para el tráfico de chat.
- **Cifrado extremo a extremo:** Los mensajes se cifran y descifran localmente usando una contraseña compartida, derivando una clave con PBKDF2 y cifrado AES-GCM.
- **Señalización manual:** El intercambio de información de conexión (OFFER/ANSWER) se realiza copiando y pegando los datos entre los usuarios.
- **Interfaz sencilla:** Permite establecer la contraseña, gestionar la señalización y chatear de forma segura.

## ¿Cómo funciona?

1. **Contraseña:**
   - Cada usuario introduce una contraseña que se utiliza para cifrar y descifrar los mensajes.
   - La contraseña nunca se transmite, solo se almacena localmente (localStorage).

2. **Señalización:**
   - Un usuario crea una OFFER y la comparte con el otro usuario.
   - El receptor pega la OFFER, genera una ANSWER y la devuelve al iniciador.
   - Una vez intercambiadas, se establece el canal P2P.

3. **Chat cifrado:**
   - Los mensajes enviados se cifran con la clave derivada de la contraseña y se transmiten por el canal seguro.
   - El receptor descifra los mensajes localmente.

## Tecnologías utilizadas

- **WebRTC:** Para la conexión P2P y el canal de datos.
- **Web Crypto API:** Para la derivación de claves y cifrado AES-GCM.
- **HTML, CSS y JavaScript puro:** Sin dependencias externas.

## Uso

1. Abre el archivo `index.html` en tu navegador.
2. Introduce una contraseña y guárdala.
3. Sigue los pasos de señalización para conectar con otro usuario.
4. ¡Comienza a chatear de forma segura!

## Notas de seguridad
- La contraseña debe ser compartida de forma segura entre los usuarios antes de iniciar el chat.
- El cifrado se realiza completamente en el navegador; la seguridad depende de la fortaleza de la contraseña elegida.
- El intercambio de señalización (OFFER/ANSWER) no está cifrado, pero solo contiene información de conexión, no los mensajes.

## Licencia

Este proyecto es solo para fines educativos y demostrativos. Úsalo bajo tu propio riesgo.