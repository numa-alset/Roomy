import 'dart:developer' as developer;

void logI(String msg) => developer.log('[I] $msg');
void logE(Object err, [StackTrace? st]) =>
    developer.log('[E] $err', stackTrace: st);
