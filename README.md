# CallMe

![License](https://img.shields.io/badge/license-Source--Available-red.svg)
![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=flat&logo=dart&logoColor=white)
![WebRTC](https://img.shields.io/badge/WebRTC-%23333333.svg?style=flat&logo=webrtc&logoColor=white)

**CallMe** é um aplicativo de comunicação por voz de código disponível (Source-Available) focado em garantir chamadas em grupo diretas, seguras e com latência ultra-baixa através de redes **P2P (Peer-to-Peer)**. 

Criado com privacidade e desempenho em mente, o CallMe substitui a infraestrutura tradicional de servidores centrais pesados (como Discord ou TeamSpeak) por uma topologia em malha (Mesh), garantindo que a sua voz vá diretamente para seus amigos.

---

## Principais Funcionalidades

- **Latência Ultra-Baixa**: Usa **WebRTC** para criar conexões P2P diretas entre os usuários. O seu ping é fisicamente o menor possível, sem passar por servidores centrais espalhados pelo mundo. Perfeito para gamers competitivos.
- **Criptografia Ponta-a-Ponta (E2EE)**: Toda comunicação (sinalização e áudio via fallback) é encriptada usando **AES-GCM 256 bits**. Ninguém consegue ouvir suas conversas, nem mesmo a provedora de internet.
- **Stealth Relay (CGNAT Fallback)**: Mora no Brasil e está preso atrás de um CGNAT rígido de provedores de internet móvel? Não tem problema. O CallMe possui uma rede inteligente via MQTT que atua como relé criptografado para garantir que sua voz chegue ao destino sem comprometer a segurança.
- **Identidade Descentralizada**: Exporte e importe sua identidade e lista de servidores livremente usando arquivos `.clmbkp` encriptados nativamente.
- **Acesso Facilitado**: Junte-se rapidamente aos servidores dos amigos escaneando **QR Codes** diretamente do aplicativo!
- **Moderno e Fluido**: Desenvolvido em Flutter, com suporte a temas dinâmicos (Material Design 3).

---

## Por que usar o CallMe em vez do Discord?

O Discord é uma plataforma cliente-servidor (SFU) maravilhosa para grandes comunidades. No entanto, para **pequenos esquadrões (2 a 8 pessoas)**, o CallMe oferece duas grandes vantagens incontestáveis:
1. **Privacidade Absoluta:** No CallMe, não há um "Servidor Central" ouvindo, gravando ou repassando a sua voz. A sua chave é sua.
2. **Ping Direto:** Se você e o seu amigo moram na mesma rua, a voz de vocês viaja de um computador para o outro em `< 5ms`. No Discord, a voz precisa viajar até a capital mais próxima (Data Center da AWS/Google) e voltar.

---

## Entendendo a Arquitetura P2P (Mesh)

Como o CallMe não usa servidores centrais, a topologia da rede se adapta dependendo do tamanho da chamada e das suas condições de rede:

### Em chamadas com 4 usuários
A rede opera perfeitamente. Em uma sala com 4 pessoas (Você, A, B e C), o seu dispositivo envia o seu áudio 3 vezes simultaneamente (para A, B e C) e recebe o áudio deles de volta. O uso de CPU e banda (upload/download) é irrisório e a latência é individualmente perfeita para todos.

### Em chamadas com muitos usuários (5+)
A topologia P2P em malha total exigiria muito da sua banda e processador. Por isso, ao atingir 5 ou mais membros, a nossa engine **`TopologyManager`** entra em cena e muda a topologia instantaneamente para **Supernode SFU Dinâmico**:
* O aplicativo analisa em tempo real o **Ping (RTT)** de todos os membros e suas plataformas (Desktop vs Celular).
* Os membros com as conexões mais fortes e robustas são **eleitos como Supernodes**.
* Se você estiver no celular, o seu CallMe fará upload do seu áudio **apenas 1 vez** diretamente para um Supernode. 
* Os Supernodes conversam entre si e repassam os áudios para os seus grupos designados, atuando como verdadeiros descentralizados!

### E se a conexão P2P falhar? (Stealth Relay)
Em redes corporativas super restritas ou CGNATs simétricos terríveis onde o WebRTC falha completamente, o aplicativo ativa o nosso **MQTT Fallback (Stealth Relay)**. Em vez de desistir da chamada, o seu áudio encriptado é redirecionado via tópicos Pub/Sub em um Broker MQTT público, garantindo conectividade máxima com O(1) de upload em qualquer situação.

### O Poder do IPv6 Público
Se pelo menos **um usuário na chamada** tiver conectividade IPv6 nativa e pública (cada vez mais comum em fibras óticas no Brasil e mundo afora), ocorre uma pequena mudança na rede:
* As conexões P2P furam os temidos firewalls e CGNATs instantaneamente.
* A dependência de servidores STUN/TURN cai drasticamente, pois o IPv6 permite conexões ponto-a-ponto reais e irrestritas, sem gambiarras de NAT.
* Mesmo se os outros usuários estiverem em redes ruins de celular 4G (IPv4), o usuário com IPv6 servirá como uma âncora limpa para que as pontes de voz WebRTC se conectem a ele com a menor latência e perda de pacotes possível.

---

## Apoie o Desenvolvimento

Manter o aplicativo livre de paywalls e fornecer acesso ilimitado a servidores de Sinalização STUN/TURN e Fallback MQTT tem custos. Se você gosta do CallMe e quer nos ajudar a continuar inovando na descentralização:

Considere apoiar com qualquer quantia, pois até o seu café nos ajuda a ficar acordados escrevendo código open-source!

* **Pix**: `eed32d34-8e0c-4cc7-bb5d-adf5d53da60a`
* **BTC**: `bc1qpzdjl8yvn4nh4c3yc3u4drkzgqs9pkmujm787g`
* **USDT (BEP20)**: `0x0e5f6CfB737f429388fa1Edb1Cb1C36504e19A0e`
* **Cartão de Crédito**: [Apoiar via Liberapay](https://liberapay.com/Schicksal)

---

## Estrutura do Projeto

O repositório é dividido em duas partes principais:

* `app/`: Contém todo o front-end e aplicativo mobile escrito em Flutter. Gerencia o design, WebRTC, a árvore de estados e as interações nativas.
* `core_protocol/`: Um pacote Dart independente que define os protocolos de arquivos criptografados (`.clm`, `.clmbkp`), assinaturas digitais, criptografia AES e as pontes MQTT.

---

## Como Executar e Compilar

### Pré-requisitos
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (Recomendado: v3.12.2 ou superior)
- Git

### 1. Clonando o Repositório
```bash
git clone https://github.com/Michael-Jhonathan/CallMe.git
cd CallMe
```

### 2. Configurando o Protocolo (Core Protocol)
O pacote central não é publicado no `pub.dev` e vive localmente. Obtenha as dependências dele primeiro:
```bash
cd core_protocol
flutter pub get
cd ..
```

### 3. Rodando o App
```bash
cd app
flutter pub get

# Para rodar no navegador (Ambiente de Teste)
flutter run -d chrome

# Para rodar ou compilar no Android
flutter build apk
```

### Configurações de Ambiente (`.env`)
O CallMe utiliza um arquivo `.env` para apontar para os brokers MQTT públicos/privados e credenciais de anúncios (opcional). Crie um arquivo `.env` na raiz do diretório `app/` seguindo a documentação do Core.

---

## Licença

O código-fonte deste projeto é disponibilizado sob um modelo **Source-Available**. 
É permitido visualizar, auditar e enviar contribuições para o repositório original. O uso pessoal e não comercial é permitido.
No entanto, **é estritamente proibida** a redistribuição, publicação ou qualquer uso comercial deste software.
Veja o arquivo [LICENSE](LICENSE) para ler os termos detalhados.
