// Sending a share link: WhatsApp, other apps, the QR code as a picture, copy.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:banigoba/modules/shop/models/shop_link.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class ShareShopLinkController extends GetxController {
  ShareShopLinkController(this.link);

  final ShopLink link;

  Future<void> whatsApp() async {
    final opened = await launchUrl(
      whatsAppShareUri(shareMessage(link)),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && !isClosed) AppToast.say('WhatsApp could not be opened.');
  }

  Future<void> more() async {
    await SharePlus.instance.share(
      ShareParams(text: shareMessage(link), subject: link.title),
    );
  }

  Future<void> qr() async {
    final image = await QrPainter(
      data: link.url,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(color: Colors.black),
      dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
    ).toImageData(900, format: ui.ImageByteFormat.png);
    if (image == null) {
      if (!isClosed) AppToast.say('The QR code could not be made.');
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        text: shareMessage(link),
        files: [
          XFile.fromData(
            image.buffer.asUint8List(),
            mimeType: 'image/png',
            name: 'banigoba-${link.id}.png',
          ),
        ],
      ),
    );
  }

  Future<void> copy() async {
    await Clipboard.setData(ClipboardData(text: link.url));
    if (!isClosed) AppToast.say('Link copied.');
  }
}
