import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSvgIcon extends StatelessWidget {
  final String asset;
  final double size;
  final Color? color;

  const AppSvgIcon({
    super.key,
    required this.asset,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      errorBuilder: (_, _, _) {
        return SvgPicture.asset(
          'assets/icons/broken_image.svg',
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(
            color ?? Theme.of(context).colorScheme.error,
            BlendMode.srcIn,
          ),
        );
      },
    );
  }
}

class AppIcons {
  static const admin = 'assets/icons/admin.svg';
  static const admin1 = 'assets/icons/admin1.svg';

  static const arrow_down = 'assets/icons/arrow_down.svg';
  static const arrow_left = 'assets/icons/arrow_left.svg';
  static const arrow_right = 'assets/icons/arrow_right.svg';
  static const close = 'assets/icons/close.svg';

  static const avatar = 'assets/icons/avatar.svg';
  static const blur = 'assets/icons/blur.svg';

  static const book = 'assets/icons/book.svg';
  static const calender = 'assets/icons/calender.svg';
  static const certificate = 'assets/icons/certificate.svg';
  static const checkmark = 'assets/icons/checkmark.svg';

  static const course = 'assets/icons/course.svg';
  static const delete = 'assets/icons/delete.svg';
  static const description = 'assets/icons/description.svg';
  static const developer = 'assets/icons/developer.svg';
  static const download = 'assets/icons/download.svg';
  static const edit = 'assets/icons/edit.svg';

  static const email = 'assets/icons/email.svg';
  static const eye = 'assets/icons/eye.svg';
  static const folder = 'assets/icons/folder.svg';
  static const gender = 'assets/icons/gender.svg';

  static const home = 'assets/icons/home.svg';
  static const id = 'assets/icons/id.svg';
  static const info = 'assets/icons/info.svg';
  static const label = 'assets/icons/label.svg';
  static const link = 'assets/icons/link.svg';
  static const logout = 'assets/icons/logout.svg';

  static const notification = 'assets/icons/notification.svg';
  static const order = 'assets/icons/order.svg';
  static const paint = 'assets/icons/paint.svg';
  static const password = 'assets/icons/password.svg';
  static const pdf = 'assets/icons/pdf.svg';
  static const phone = 'assets/icons/phone.svg';

  static const play = 'assets/icons/play.svg';
  static const plus = 'assets/icons/plus.svg';
  static const progress = 'assets/icons/progress.svg';
  static const refresh = 'assets/icons/refresh.svg';
  static const remove = 'assets/icons/remove.svg';

  static const rocket = 'assets/icons/rocket.svg';
  static const search = 'assets/icons/search.svg';
  static const settings = 'assets/icons/settings.svg';
  static const shape = 'assets/icons/shape.svg';
  static const sheet = 'assets/icons/sheet.svg';
  static const shield = 'assets/icons/shield.svg';

  static const student = 'assets/icons/student.svg';
  static const subject = 'assets/icons/subject.svg';
  static const subtitle = 'assets/icons/subtitle.svg';
  static const sun = 'assets/icons/sun.svg';
  static const level = 'assets/icons/level.svg';

  static const task = 'assets/icons/task.svg';
  static const time = 'assets/icons/time.svg';
  static const title = 'assets/icons/title.svg';

  static const trend_down = 'assets/icons/trend_down.svg';
  static const trend_up = 'assets/icons/trend_up.svg';

  static const user = 'assets/icons/user.svg';
  static const user_block = 'assets/icons/user_block.svg';
  static const user_group = 'assets/icons/user_group.svg';

  static const video = 'assets/icons/video.svg';
  static const view = 'assets/icons/view.svg';
  static const view_off = 'assets/icons/view_off.svg';

  static const vision = 'assets/icons/vision.svg';
  static const google = 'assets/icons/google.svg';
  static const camera_add = 'assets/icons/camera_add.svg';
}
