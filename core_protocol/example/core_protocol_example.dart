import 'dart:io';
import '../lib/src/clm_file.dart';

void main() async {
  print('--- INICIANDO TESTE DO ARQUIVO .CLM ---');
  
  // 1. CRIAR AS INFORMAÇÕES ORIGINAIS
  final originalFile = ClmFile(
    serverId: 'CHAVE_PUBLICA_JOAO_123',
    timestamp: DateTime.now().millisecondsSinceEpoch,
    serverName: 'Taverna dos Amigos',
    members: [
      ClmMember(id: 'CHAVE_PUBLICA_JOAO_123', name: 'João (Admin)', isAdmin: true),
      ClmMember(id: 'CHAVE_PUBLICA_MARCOS_456', name: 'Marcos', isAdmin: false),
    ],
    channels: [
      ClmChannel(id: 'CH_01', name: 'Lobby Principal'),
      ClmChannel(id: 'CH_02', name: 'Jogatina de Sexta'),
    ],
  );

  // 2. CONVERTER PARA BINÁRIO E SALVAR NO DISCO
  final bytes = originalFile.toBytes();
  final file = File('teste_servidor.clm');
  await file.writeAsBytes(bytes);
  
  print('✅ Arquivo salvo com sucesso: teste_servidor.clm');
  print('✅ Tamanho total do arquivo: ${bytes.length} bytes (Extremamente leve!)\n');
  
  // 3. LER O ARQUIVO DO DISCO (Simulando o recebimento por outro celular)
  final bytesLidos = await file.readAsBytes();
  
  // 4. RECONSTRUIR OS DADOS
  final parsedFile = ClmFile.fromBytes(bytesLidos);
  
  print('--- LENDO INFORMAÇÕES DE DENTRO DO .CLM ---');
  print('Nome do Servidor: ${parsedFile.serverName}');
  print('ID do Criador: ${parsedFile.serverId}');
  print('Carimbo de Tempo: ${parsedFile.timestamp}');
  
  print('\nMembros (${parsedFile.members.length}):');
  for (var m in parsedFile.members) {
    print(' - ${m.name} (Admin? ${m.isAdmin}) -> ID: ${m.id}');
  }
  
  print('\nCanais de Voz (${parsedFile.channels.length}):');
  for (var c in parsedFile.channels) {
    print(' - ${c.name} -> ID: ${c.id}');
  }
  
  print('\n✅ TESTE CONCLUÍDO COM SUCESSO!');
}
