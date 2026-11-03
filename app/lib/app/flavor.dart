enum Flavor {
  dev(name: 'dev', appTitle: 'Vantia Dev'),
  prod(name: 'prod', appTitle: 'Vantia');

  const Flavor({required this.name, required this.appTitle});

  final String name;
  final String appTitle;

  bool get isDev => this == dev;
}
