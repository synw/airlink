import 'package:err/err.dart';

var log = ErrRouter(
    errorRoute: [ErrRoute.screen, ErrRoute.console],
    warningRoute: [ErrRoute.screen, ErrRoute.console],
    infoRoute: [ErrRoute.screen, ErrRoute.console],
    deviceConsole: true);
