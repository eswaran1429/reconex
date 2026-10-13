abstract class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';

  // Arguments: domainId (String) unless noted.
  static const String domainDetail = '/domain';
  static const String scans = '/scans';
  static const String scanDetail = '/scan'; // scanId
  static const String changes = '/changes'; // ChangesArgs
  static const String changeDetail = '/change'; // changeId
  static const String subdomains = '/subdomains';
  static const String subdomainDetail = '/subdomain'; // subdomainId
  static const String dns = '/dns';
  static const String ports = '/ports';
  static const String technologies = '/technologies';
  static const String security = '/security'; // SecurityArgs
}
