import "dart:io";

import "package:dql/parsers/subscribe.dart";

main() {
  test('level as BatteryLevel, estimate as TimeEstimate');
  test('CommandPosition FeedBack_Axis_ActualPosition FeedBack_Axis_ActualPosition.timestamp CommandVelocity');
  test('../../child as FavoriteChild');
  test('proc/dglux-server/Memory_Usage');

  if (hasAnyError) {
    exit(1);
  }
}

test(input) {
  if (input is List) {
    for (var x in input) {
      test(x);
    }
    return;
  }

  input = input.toString();

  print("================================================");
  print("Input: ${input.replaceAll('\n', '\\n').replaceAll('\t', '\\t')}");

  var x = QuerySubscribeParser.doParse(input);
  print("Result: ${x}");
}

bool hasAnyError = false;
