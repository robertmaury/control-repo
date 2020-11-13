# Change log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v0.8.0](https://github.com/puppetlabs/comply/tree/v0.8.0) (2020-09-16)

[Full Changelog](https://github.com/puppetlabs/comply/compare/v0.7.0...v0.8.0)

### Added

- \(CISC-661,CISC-665\) Add graphQL Layer into our stack, import graphql metadata into production [\#244](https://github.com/puppetlabs/comply/pull/244) ([Ioannis-Karasavvaidis](https://github.com/Ioannis-Karasavvaidis))

### Fixed

- \(CISC-683\) ciscat task set java memory options, fqdn match in lowercase [\#249](https://github.com/puppetlabs/comply/pull/249) ([tphoney](https://github.com/tphoney))
- \(CISC-672\) Fix path issues in script.sh [\#245](https://github.com/puppetlabs/comply/pull/245) ([eimlav](https://github.com/eimlav))

## [v0.7.0](https://github.com/puppetlabs/comply/tree/v0.7.0) (2020-08-27)

[Full Changelog](https://github.com/puppetlabs/comply/compare/v0.6.0...v0.7.0)

### Added

- \(CISC-615\) Use string for scan\_hash in ciscat task [\#237](https://github.com/puppetlabs/comply/pull/237) ([HelenCampbell](https://github.com/HelenCampbell))
- \(CISC-457\) ciscat scan task allows a hash of benchmark/profile [\#229](https://github.com/puppetlabs/comply/pull/229) ([tphoney](https://github.com/tphoney))
- \(CISC-491\) add release helper action [\#226](https://github.com/puppetlabs/comply/pull/226) ([maxiegit](https://github.com/maxiegit))

### Fixed

- \(CISC-622\) Modify ciscat to negate need to reboot on Windows [\#238](https://github.com/puppetlabs/comply/pull/238) ([eimlav](https://github.com/eimlav))
- \(CISC-402\) Add idempotency check for Assessor-CLI installation [\#235](https://github.com/puppetlabs/comply/pull/235) ([eimlav](https://github.com/eimlav))

## [v0.6.0](https://github.com/puppetlabs/comply/tree/v0.6.0) (2020-07-17)

[Full Changelog](https://github.com/puppetlabs/comply/compare/v0.5.1...v0.6.0)

### Added

- \(CISC-534\) add assessor version fact and tests [\#228](https://github.com/puppetlabs/comply/pull/228) ([tphoney](https://github.com/tphoney))
- \(CISC-480\) add more ubuntu OSes [\#225](https://github.com/puppetlabs/comply/pull/225) ([tphoney](https://github.com/tphoney))

### Fixed

- \(CISC-459\) Improve error reporting when Java is not present [\#224](https://github.com/puppetlabs/comply/pull/224) ([da-ar](https://github.com/da-ar))
- \(bugfix\) Fix `image\_helper.sh` issue with Postgres image [\#223](https://github.com/puppetlabs/comply/pull/223) ([da-ar](https://github.com/da-ar))

## [v0.5.1](https://github.com/puppetlabs/comply/tree/v0.5.1) (2020-06-15)

[Full Changelog](https://github.com/puppetlabs/comply/compare/v0.5.0...v0.5.1)

### Fixed

- \(fix\) remove adminer, update postgres to latest [\#217](https://github.com/puppetlabs/comply/pull/217) ([tphoney](https://github.com/tphoney))

## [v0.5.0](https://github.com/puppetlabs/comply/tree/v0.5.0) (2020-06-03)

[Full Changelog](https://github.com/puppetlabs/comply/compare/v0.4.0...v0.5.0)

### Added

- \(feat\) Make scarp address configurable [\#204](https://github.com/puppetlabs/comply/pull/204) ([tphoney](https://github.com/tphoney))
- \(CISC-377\) add extra oses to scanner matrix [\#199](https://github.com/puppetlabs/comply/pull/199) ([maxiegit](https://github.com/maxiegit))

### Fixed

- \(bugfix\) allow the passing of profile as a string to ciscat [\#203](https://github.com/puppetlabs/comply/pull/203) ([tphoney](https://github.com/tphoney))

## [v0.4.0](https://github.com/puppetlabs/comply/tree/v0.4.0) (2020-05-27)

[Full Changelog](https://github.com/puppetlabs/comply/compare/v0.3.0...v0.4.0)

### Added

- \(feat\) remove ratel and dgraph connections [\#197](https://github.com/puppetlabs/comply/pull/197) ([maxiegit](https://github.com/maxiegit))

## [v0.3.0](https://github.com/puppetlabs/comply/tree/v0.3.0) (2020-05-14)

[Full Changelog](https://github.com/puppetlabs/comply/compare/v0.2.1...v0.3.0)

### Added

- \(feat\) adding postgres to the application stack [\#193](https://github.com/puppetlabs/comply/pull/193) ([tphoney](https://github.com/tphoney))
- \(CISC-292\) Automate comply tar upload [\#185](https://github.com/puppetlabs/comply/pull/185) ([maxiegit](https://github.com/maxiegit))

### Fixed

- \(bugfix\) Limit profile values in ciscat scan task [\#189](https://github.com/puppetlabs/comply/pull/189) ([tom-krieger](https://github.com/tom-krieger))

## [v0.2.1](https://github.com/puppetlabs/comply/tree/v0.2.1) (2020-04-20)

[Full Changelog](https://github.com/puppetlabs/comply/compare/0.2.0...v0.2.1)

### Added

- \(feat\) initial commit, of using a single task for scanning and uploading [\#184](https://github.com/puppetlabs/comply/pull/184) ([tphoney](https://github.com/tphoney))
- \(CISC-284\) Switch to change log generator  [\#183](https://github.com/puppetlabs/comply/pull/183) ([maxiegit](https://github.com/maxiegit))

## 0.2.0

Initial release of the comply module.


\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*
