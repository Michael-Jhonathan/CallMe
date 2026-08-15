import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

class ServerAdminDialog extends StatefulWidget {
  const ServerAdminDialog({super.key});

  @override
  State<ServerAdminDialog> createState() => _ServerAdminDialogState();
}

class _ServerAdminDialogState extends State<ServerAdminDialog> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    if (appState.currentServer != null) {
      _nameController.text = appState.currentServer!.serverName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return DefaultTabController(
      length: 3,
      child: Dialog(
        backgroundColor: CallMeTheme.surfaceLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.all(isMobile ? 16 : 40),
        child: Container(
          width: 800,
          height: 600,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: CallMeTheme.surfaceContainer,
                    padding: const EdgeInsets.only(
                      top: 8,
                      right: 48,
                    ), // right padding to avoid close button overlap
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: CallMeTheme.primary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: CallMeTheme.primary,
                      unselectedLabelColor: CallMeTheme.onSurfaceVariant,
                      labelStyle: CallMeTheme.textTheme.titleSmall,
                      unselectedLabelStyle: CallMeTheme.textTheme.titleSmall,
                      tabs: const [
                        Tab(text: "Visão Geral"),
                        Tab(text: "Membros"),
                        Tab(text: "Solicitações"),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: CallMeTheme.surface,
                      padding: EdgeInsets.all(isMobile ? 16 : 40),
                      child: TabBarView(
                        children: [
                          _buildGeneralTab(isMobile),
                          _buildMembersTab(isMobile),
                          _buildRequestsTab(isMobile),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: CallMeTheme.onSurfaceVariant,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralTab(bool isMobile) {
    final appState = context.watch<AppState>();
    final server = appState.currentServer;
    if (server == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(right: isMobile ? 24 : 32),
            child: Text(
              'Visão Geral do Servidor',
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: CallMeTheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'NOME DO SERVIDOR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: CallMeTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                maxLength: 15,
                style: const TextStyle(color: CallMeTheme.onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: CallMeTheme.surfaceLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  appState.renameServer(_nameController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CallMeTheme.primaryContainer,
                  foregroundColor: CallMeTheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Salvar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: CallMeTheme.outlineVariant),
          const SizedBox(height: 32),
          const Text(
            'CÓDIGO DE CONVITE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: CallMeTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: CallMeTheme.surfaceLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  server.serverAesKey != null 
                      ? '${server.serverId}@${server.serverAesKey}'
                      : server.serverId,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: CallMeTheme.primaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  final inviteCode = server.serverAesKey != null 
                      ? '${server.serverId}@${server.serverAesKey}'
                      : server.serverId;
                  Clipboard.setData(ClipboardData(text: inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado!')),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copiar Código'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CallMeTheme.surfaceVariant,
                  foregroundColor: CallMeTheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMembersTab(bool isMobile) {
    final appState = context.watch<AppState>();
    final server = appState.currentServer;
    if (server == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: isMobile ? 24 : 32),
          child: Text(
            'Membros',
            style: TextStyle(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: CallMeTheme.onSurface,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 16 : 32),
        Expanded(
          child: ListView.builder(
            itemCount: server.members.length,
            itemBuilder: (context, index) {
              final member = server.members[index];
              final isMe = member.id == appState.publicKeyHex;

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: CallMeTheme.surfaceVariant,
                  child: Icon(
                    Icons.person,
                    color: CallMeTheme.onSurfaceVariant,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        color: CallMeTheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (member.isAdmin) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.stars, color: Colors.amber, size: 16),
                    ],
                  ],
                ),
                subtitle: Text(
                  'ID: ${member.id.length > 8 ? member.id.substring(0, 8) : member.id}...',
                  style: const TextStyle(color: CallMeTheme.onSurfaceVariant),
                ),
                trailing: isMe
                    ? const Text(
                        'Você',
                        style: TextStyle(color: CallMeTheme.onSurfaceVariant),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.person_remove,
                          color: CallMeTheme.secondaryFixed,
                        ),
                        tooltip: 'Expulsar Membro',
                        onPressed: () => appState.kickMember(member.id),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab(bool isMobile) {
    final appState = context.watch<AppState>();
    final requests = appState.getPendingRequests();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: isMobile ? 24 : 32),
          child: Text(
            'Solicitações',
            style: TextStyle(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: CallMeTheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Esses usuários pediram para se conectar via P2P.',
          style: TextStyle(
            color: CallMeTheme.onSurfaceVariant,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
        SizedBox(height: isMobile ? 16 : 32),
        if (requests.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'Nenhuma solicitação pendente no momento.',
                style: TextStyle(color: CallMeTheme.onSurfaceVariant),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];

                return Card(
                  color: CallMeTheme.surfaceLow,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: CallMeTheme.surfaceVariant,
                          child: Icon(
                            Icons.wifi_tethering,
                            color: CallMeTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                req.name,
                                style: const TextStyle(
                                  color: CallMeTheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Chave Pública: ${req.id}',
                                style: const TextStyle(
                                  color: CallMeTheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                              tooltip: 'Aprovar',
                              onPressed: () => appState.approveJoinRequest(req),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: CallMeTheme.secondaryFixed,
                              ),
                              tooltip: 'Recusar',
                              onPressed: () => appState.denyJoinRequest(req.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
