enum Flavor {
  dev(name: 'dev', appTitle: 'Vantia Dev'),
  prod(name: 'prod', appTitle: 'Vantia'),
  demo(name: 'demo', appTitle: 'Vantia Demo');

  const Flavor({required this.name, required this.appTitle});

  final String name;
  final String appTitle;

  bool get isDev => this == dev;
  bool get isDemo => this == demo;
}
