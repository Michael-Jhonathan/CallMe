import 'dart:io';
import '../lib/src/clm_file.dart';
import '../lib/src/clm_deltas.dart';

void main() async {
  print('--- INICIANDO TESTE DO MOTOR DE DELTAS ---');
  
  // 1. O arquivo base que ambos os usuários já possuem localmente
  var arquivoBase = ClmFile(
    serverId: 'PUB_KEY_JOAO',
    timestamp: 1000,
    serverName: 'Servidor do João',
    members: [
      ClmMember(id: 'PUB_KEY_JOAO', name: 'João', isAdmin: true),
    ],
    channels: [
      ClmChannel(id: 'CH_1', name: 'Lobby'),
    ],
  );

  print('📍 ESTADO INICIAL (Celular do Marcos):');
  print('Canais atuais (${arquivoBase.channels.length}): ${arquivoBase.channels.map((c) => c.name).join(', ')}');

  // 2. João (em seu celular) adiciona um novo canal
  final deltaCriacao = AddChannelDelta(
    timestamp: 2000, // Tempo mais recente que o arquivo base
    channel: ClmChannel(id: 'CH_2', name: 'Sala de Música'),
  );

  // 3. O celular do João empacota apenas a instrução (o Delta) para enviar pela rede
  final pacoteBinario = deltaCriacao.toBytes();
  print('\n🚀 Enviando Instrução pela Rede (MQTT/Nostr)...');
  print('✅ Tamanho do pacote: Apenas ${pacoteBinario.length} bytes! (Economia gigantesca de dados)');

  // 4. O celular do Marcos recebe os bytes puros da rede e reconstrói a instrução
  final deltaRecebido = ClmDelta.fromBytes(pacoteBinario);
  
  print('\n--- APLICANDO A INSTRUÇÃO NO ARQUIVO LOCAL ---');
  
  // 5. O app do Marcos aplica a instrução no arquivo dele, gerando o novo estado
  final novoArquivo = deltaRecebido.applyTo(arquivoBase);

  print('📍 ESTADO FINAL (Celular do Marcos):');
  print('Canais atuais (${novoArquivo.channels.length}): ${novoArquivo.channels.map((c) => c.name).join(', ')}');
  print('Carimbo de Tempo atualizado de [${arquivoBase.timestamp}] para [${novoArquivo.timestamp}]');
  
  print('\n✅ TESTE DO MOTOR DE DELTAS CONCLUÍDO COM SUCESSO!');
}
