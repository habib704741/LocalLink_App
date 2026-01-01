import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_client/core/api/api_client.dart';
import 'package:web_client/core/constants/app_constants.dart';
import 'package:web_client/core/theme/app_theme.dart';
import 'package:web_client/features/connection/providers/connection_provider.dart';

// Contacts provider
final contactsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final contacts = await apiClient.getAllContacts();
  return contacts ?? [];
});

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredContacts = [];
  List<dynamic> _allContacts = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts(List<dynamic> contacts) {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = contacts;
      } else {
        _filteredContacts = contacts.where((contact) {
          final name = (contact['displayName'] ?? '').toLowerCase();
          final phone = (contact['phoneNumber'] ?? '').toLowerCase();
          final email = (contact['email'] ?? '').toLowerCase();
          return name.contains(query) ||
              phone.contains(query) ||
              email.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);

    return contactsAsync.when(
      data: (contacts) {
        if (_allContacts != contacts) {
          _allContacts = contacts;
          _filteredContacts = contacts;
        }

        if (contacts.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildContactsList(context, contacts);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
        ),
      ),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.contacts_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'No contacts found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 64),
          const SizedBox(height: 16),
          Text(
            'Error loading contacts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(contactsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(BuildContext context, List<dynamic> contacts) {
    return Column(
      children: [
        // Header with Search
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${contacts.length} ${contacts.length == 1 ? 'Contact' : 'Contacts'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _filterContacts(contacts);
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (_) => _filterContacts(contacts),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.refresh(contactsProvider),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        // Contacts List or Search Results
        Expanded(
          child: _filteredContacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.white24,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No contacts match your search',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.white54),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;

                    if (isWide) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(
                          AppConstants.paddingMedium,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 350,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 3,
                            ),
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          return _buildContactCard(_filteredContacts[index]);
                        },
                      );
                    } else {
                      return ListView.builder(
                        padding: const EdgeInsets.all(
                          AppConstants.paddingMedium,
                        ),
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          return _buildContactListItem(
                            _filteredContacts[index],
                          );
                        },
                      );
                    }
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    final name = contact['displayName'] ?? 'Unknown';
    final phone = contact['phoneNumber'];
    final email = contact['email'];
    final initials = contact['initials'] ?? '?';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryGreen,
              radius: 24,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (phone != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 14,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            phone,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (email != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.email,
                          size: 14,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            email,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactListItem(Map<String, dynamic> contact) {
    final name = contact['displayName'] ?? 'Unknown';
    final phone = contact['phoneNumber'];
    final email = contact['email'];
    final initials = contact['initials'] ?? '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (phone != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(phone, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
            if (email != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.email, size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      email,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
