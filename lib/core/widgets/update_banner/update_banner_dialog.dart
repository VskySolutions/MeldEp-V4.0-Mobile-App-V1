import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:test_project/core/services/local_storage.dart';
import 'package:test_project/core/services/update_banner_service.dart';
import 'package:test_project/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:version/version.dart';

class UpdateBannerDialog extends StatefulWidget {
  const UpdateBannerDialog({Key? key}) : super(key: key);

  @override
  State<UpdateBannerDialog> createState() => _UpdateBannerDialogState();
}

class _UpdateBannerDialogState extends State<UpdateBannerDialog> {
  final service = UpdateBannerService();
  String? notesHtml;
  String? downloadUrl;
  String? newVersion;
  String? releseDate = "23/23/2332";
  bool shouldShow = false;
  int ignoreCount = 0;
  final int ignoreLimit = 5;

  @override
  void initState() {
    super.initState();
    _loadIgnoreCount();
    _checkForUpdate();
  }

  Future<void> _loadIgnoreCount() async {
    final count = await LocalStorage.getUpdateIgnoreCount();
    setState(() {
      ignoreCount = count;
    });
  }

  Future<void> _handleIgnore() async {
    await LocalStorage.incrementUpdateIgnoreCount();
    setState(() {
      shouldShow = false;
    });
  }

  Future _checkForUpdate() async {
    final flavor = const String.fromEnvironment("FLAVOR", defaultValue: 'dev');
    final envVersion = dotenv.env['VERSION'] ?? "0.0.0";
    final currentVersion = Version.parse(envVersion.trim());

    final files = await service.listBuildFiles(flavor);

    String extractVer(String name) {
      final m = RegExp(r'V(\d+\.\d+\.\d+)').firstMatch(name);
      return m?.group(1) ?? '0.0.0';
    }

    final apkFiles = files.where((f) => f['name'].endsWith('.apk')).toList();

    if (apkFiles.isEmpty) return;

    final latest = apkFiles
        .map((f) => Version.parse(extractVer(f['name'].toString())))
        .fold<Version>(
          Version.parse("0.0.0"),
          (prev, curr) => curr > prev ? curr : prev,
        );

    if (latest <= currentVersion) return;

    newVersion = latest.toString();

    final targetApk = apkFiles.firstWhere(
        (f) => extractVer(f['name'].toString()) == latest.toString());

    final mdFiles = files
        .where((f) =>
            f['name'].toString().endsWith('.md') &&
            f['name'].toString().contains(latest.toString()))
        .toList();

    if (mdFiles.isEmpty) return;

    final mdName = mdFiles.first['name'] as String;

    final apkDetails =
        await service.fetchFileDetails(flavor, targetApk['name'] as String);
    final mdDetails = await service.fetchFileDetails(flavor, mdName);

    final rawMd = service.decodeBase64(mdDetails['content'] as String);
    final lines = rawMd.split('\n').where((l) => l.trim().isNotEmpty).toList();

    final contentLines = lines.skip(2).map((l) {
      final cleaned = l.replaceFirst(RegExp(r'^-\s*'), '');
      return '<li>$cleaned</li>';
    }).join();

    final datePart = lines[1].split(' ')[1];
    final formattedDate = datePart.replaceAll('-', '/');

    final contentHtml = '''
      <style>
        ul {
          margin: 0;
          padding-left: 0;
          text-align: left;
        }
        li {
          margin-bottom: 4px;
        }
      </style>
      <ul>
        $contentLines
      </ul>
    ''';

    setState(() {
      shouldShow = true;
      downloadUrl = apkDetails['download_url'] as String;
      notesHtml = contentHtml;
      releseDate = formattedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();
    return SafeArea(
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(0),
        child: Container(
          color: Colors.black.withOpacity(0.6),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Material(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RawGestureDetector(
                                  gestures: {
                                    LongPressGestureRecognizer:
                                        GestureRecognizerFactoryWithHandlers<
                                                LongPressGestureRecognizer>(
                                            () => LongPressGestureRecognizer(
                                                duration: Duration(seconds: 4)),
                                            (LongPressGestureRecognizer
                                                instance) {
                                      instance.onLongPress = () =>
                                          setState(() => shouldShow = false);
                                    })
                                  },
                                  child: Container(
                                    height: 44,
                                    child: Image.asset(
                                        'assets/images/meld-epLogo.png'),
                                  ),
                                ),
                                if (releseDate != null) ...[
                                  SizedBox(
                                    height: 4,
                                  ),
                                  Text(
                                    "Release Date: $releseDate",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ]
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.arrow_circle_up,
                                  size: 20,
                                  color: AppColors.PRIMARY,
                                ),
                                Text(
                                  'V$newVersion',
                                  style: const TextStyle(
                                    color: AppColors.PRIMARY,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      if (notesHtml != null)
                        Flexible(
                          child: SingleChildScrollView(
                              padding: const EdgeInsets.only(
                                  top: 14, left: 14, right: 14),
                              child: Column(
                                children: [
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'What\'s New',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Html(data: notesHtml!),
                                ],
                              )),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 14, right: 14, bottom: 14, top: 4),
                        child: Row(
                          children: [
                            if (ignoreCount < ignoreLimit) ...[
                              Expanded(
                                flex: 1,
                                child: OutlinedButton.icon(
                                  onPressed: _handleIgnore,
                                  icon: const Icon(Icons.block,
                                      color: Colors.grey),
                                  label: const Text(
                                    'Ignore',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: Colors.grey, width: 1.5),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              flex: 3,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    launchUrlString(downloadUrl ?? ''),
                                icon: const Icon(Icons.download,
                                    color: AppColors.PRIMARY),
                                label: Text(
                                  'Download V$newVersion',
                                  style: TextStyle(color: AppColors.PRIMARY),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: AppColors.PRIMARY, width: 1.5),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
