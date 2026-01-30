import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appName = '';
  String _appVersion = '';
  String _appBuildNumber = '';
  String _packageName = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appName = info.appName;
        _appVersion = info.version;
        _appBuildNumber = info.buildNumber;
        _packageName = info.packageName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAppIcon(),
            const SizedBox(height: 24),
            _buildAppName(),
            const SizedBox(height: 8),
            _buildVersion(),
            const SizedBox(height: 24),
            _buildDescription(),
            const SizedBox(height: 24),
            _buildInfoSection('Application Information', [
              _buildInfoTile('App Name', _appName),
              _buildInfoTile('Version', _appVersion),
              _buildInfoTile('Build Number', _appBuildNumber),
              _buildInfoTile('Package Name', _packageName),
            ]),
            const SizedBox(height: 24),
            _buildInfoSection('Developer', [
              _buildInfoTile('Developer', 'Prompt Memo Team'),
              _buildInfoTile(
                'Website',
                'https://github.com/yourusername/prompt-memo',
              ),
            ]),
            const SizedBox(height: 24),
            _buildInfoSection('License', [_buildLicenseTile()]),
            const SizedBox(height: 24),
            _buildLinksSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Symbols.note_stack, size: 60, color: Colors.white),
    );
  }

  Widget _buildAppName() {
    return Text(
      'Prompt Memo',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildVersion() {
    return Text(
      'Version $_appVersion',
      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
    );
  }

  Widget _buildDescription() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Prompt Memo is a simple and efficient prompt management application. '
          'Organize your AI prompts, create collections, and keep track of your prompt library with ease.',
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseTile() {
    return ExpansionTile(
      title: const Text('MIT License'),
      leading: const Icon(Icons.description),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '''Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.''',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinksSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Links',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildLinkTile(
              Icons.code,
              'GitHub Repository',
              'https://github.com/Q-Bug4/prompt-memo',
            ),
            _buildLinkTile(
              Icons.bug_report,
              'Report Issues',
              'https://github.com/Q-Bug4/prompt-memo/issues',
            ),
            _buildLinkTile(
              Icons.description,
              'Documentation',
              'https://github.com/Q-Bug4/prompt-memo/wiki',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile(IconData icon, String title, String url) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.open_in_new),
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
