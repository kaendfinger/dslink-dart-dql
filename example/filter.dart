import "package:dql/parsers/filter.dart";

main() {
  test('"hi"="bye"');
  test('hi="bye"');
  test('latitude!=nil');
  test('@assetApplicable @assetType="Engine Core Stand"');
  test('@assetApplicable or @assetType');
  test('@name="name" or @fi="bye"');
  test('@assetApplicable and @assetType');
  test('@name="name" and @fi="bye"');
  test('@assetApplicable xor @assetType');
  test('@name="name" xor @fi="bye"');

  test('@name="name" || @fi="bye"');
  test('@assetApplicable && @assetType');
  test('@name="name" && @fi="bye"');
  test('@assetApplicable ^ @assetType');
  test('@name="name" ^ @fi="bye"');

  test('@car=true');
  test('@car is true and @truck is false');
  test('@name="name" or @fi="bye" or @peace or @not or @n');
  test('@car is true and @track is false or @name is true');
  test('(@car is true) and (@truck is false or @always is true)');

  test('(../@car is true) and (../../@truck is false or @always is true)', {
    "../@car": true,
    "../../@truck": true,
    "@always": true
  });

  test('@names contains "Alex"', {
    "@names": [
      "Alex",
      "Dennis",
      "Sam",
      "Rick",
      "Logan",
      "Mike"
    ]
  });

  test('@name in ["Alex", "Emily"]', {
    "@name": "Emily"
  });

  test(r'not $disconnectedTs');
  test(r'not not $disconnectedTs');
  test(r'(not $a) and (not $b) or $c');

  test(r'not $disconnectedTs', {
    r"$disconnectedTs": "ABC"
  });
}

test(String filter, [Map m]) {
  print("===========================================");
  print("Input: ${filter}");
  FilterTestCollection test = FilterParser.doParse(filter);
  if (m != null) {
    print("Against: ${m}");
    var result = test.matches(m);
    print("Result: ${result}");
  } else {
    Set<String> keys = FilterTestKeyCollector.collect(test);
    print("Keys: ${keys}");
    print("Parsed: ${test}");
  }
}
