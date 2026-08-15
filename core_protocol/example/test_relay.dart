import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../lib/src/clm_relay.dart';

void main() async {
  print('--- INICIANDO TESTE DE REDE NO CORREIO PÚBLICO (MQTT) ---');
  
  final idDoServidor = 'SERV_TESTE_OFICIAL_123';

  // ==============================================================
  // 1. CELULAR DO MARCOS (Ouvinte)
  // ==============================================================
  print('\n[+] Conectando o celular do Marcos à internet (broker.emqx.io)...');
  final relayMarcos = ClmRelay('CLIENT_MARCOS_${DateTime.now().millisecondsSinceEpoch}');
  bool marcosConectado = await relayMarcos.connect();
  
  if (marcosConectado) {
    print('✅ Marcos conectado ao servidor público com sucesso!');
  } else {
    print('❌ Falha na conexão do Marcos.');
    return;
  }

  // O celular do Marcos fica escutando a "caixa de correio" do servidor em background
  print('👀 Marcos está de vigia na caixa de correio do servidor aguardando alterações...');
  relayMarcos.onMessageReceived = (topic, payload) {
    final mensagem = utf8.decode(payload);
    print('\n📬 [ALERTA] MARCOS RECEBEU A MENSAGEM INSTANTANEAMENTE!');
    print('   -> Topico/Caixa: $topic');
    print('   -> Instrução (Delta) recebida: "$mensagem"');
    
    // Desconecta e finaliza o script após receber
    relayMarcos.disconnect();
    print('\n✅ TESTE DE REDE CONCLUÍDO COM SUCESSO! A Sincronização Assíncrona funciona perfeitamente.');
    
    exit(0);
  };
  relayMarcos.listenToServerDeltas(idDoServidor);

  // ==============================================================
  // 2. CELULAR DO JOÃO (Emissor)
  // ==============================================================
  print('\n[+] Conectando o celular do João à internet...');
  final relayJoao = ClmRelay('CLIENT_JOAO_${DateTime.now().millisecondsSinceEpoch}');
  bool joaoConectado = await relayJoao.connect();
  
  if (joaoConectado) {
    print('✅ João conectado com sucesso!');
  }

  // 3. João despacha o pacote
  print('\n⏳ Simulando... (João vai publicar um pacote em 2 segundos)');
  await Future.delayed(Duration(seconds: 2));
  
  print('🚀 João despachou o pacote criptografado pela internet...');
  final payloadSimulado = utf8.encode('João adicionou o Marcos como Administrador!');
  relayJoao.publishDelta(idDoServidor, Uint8List.fromList(payloadSimulado));
  
  // João desconecta após o envio
  relayJoao.disconnect();
}
